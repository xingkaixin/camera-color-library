import Foundation
import Observation
import OSLog

@MainActor @Observable
public final class LibraryStore {
    public private(set) var entries: [LibraryEntry] = []
    public private(set) var loadError: String?
    public let directory: URL
    private let logger = Logger(subsystem: "studio.colorlibrary.app", category: "Library")

    public var collections: [String] { Array(Set(entries.map(\.collection))).sorted() }
    private var archiveURL: URL { directory.appendingPathComponent("library.json") }

    public init(directory: URL) {
        self.directory = directory
        reload()
    }

    public func reload() {
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let loaded: [LibraryEntry]
            if FileManager.default.fileExists(atPath: archiveURL.path) {
                loaded = try JSONDecoder().decode([LibraryEntry].self, from: Data(contentsOf: archiveURL))
                guard loaded.allSatisfy(\.isValid), Set(loaded.map(\.id)).count == loaded.count else {
                    throw CocoaError(.fileReadCorruptFile)
                }
            } else {
                loaded = []
            }
            entries = loaded.sorted { $0.createdAt > $1.createdAt }
            loadError = nil
            logger.info("Library loaded: \(loaded.count) entries")
        } catch {
            logger.error("Library load failed: \(error.localizedDescription, privacy: .public)")
            loadError = "暂时无法读取收藏。原始文件已保留，请重试。"
        }
    }

    public func save(title: String, collection: String, swatches: [ColorSwatch], photo: Data?) throws -> LibraryEntry {
        let entry = LibraryEntry(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            collection: collection.trimmingCharacters(in: .whitespacesAndNewlines),
            swatches: swatches, hasPhoto: photo != nil
        )
        guard entry.isValid else { throw CocoaError(.coderInvalidValue) }
        guard loadError == nil else { throw CocoaError(.fileReadCorruptFile) }
        let photoURL = imageURL(for: entry)
        if let photo, let photoURL { try photo.write(to: photoURL, options: .atomic) }
        do {
            try persist([entry] + entries)
            logger.info("Saved entry: \(entry.id.uuidString, privacy: .public)")
            return entry
        } catch {
            if let photoURL { try? FileManager.default.removeItem(at: photoURL) }
            throw error
        }
    }

    public func update(_ entry: LibraryEntry, title: String, collection: String) throws {
        guard let index = entries.firstIndex(where: { $0.id == entry.id }) else { return }
        var updated = entries
        updated[index].title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        updated[index].collection = collection.trimmingCharacters(in: .whitespacesAndNewlines)
        guard updated[index].isValid else { throw CocoaError(.coderInvalidValue) }
        try persist(updated)
    }

    public func delete(_ entry: LibraryEntry) throws {
        try persist(entries.filter { $0.id != entry.id })
        if let photoURL = imageURL(for: entry), FileManager.default.fileExists(atPath: photoURL.path) {
            do { try FileManager.default.removeItem(at: photoURL) }
            catch { logger.error("Photo cleanup failed: \(error.localizedDescription, privacy: .public)") }
        }
        logger.info("Deleted entry: \(entry.id.uuidString, privacy: .public)")
    }

    public func imageURL(for entry: LibraryEntry) -> URL? {
        entry.hasPhoto ? directory.appendingPathComponent(entry.id.uuidString + ".jpg") : nil
    }

    private func persist(_ updated: [LibraryEntry]) throws {
        guard loadError == nil else { throw CocoaError(.fileReadCorruptFile) }
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(updated).write(to: archiveURL, options: .atomic)
        entries = updated
    }
}
