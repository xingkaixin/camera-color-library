import Foundation

public struct LibraryEntry: Codable, Identifiable, Hashable, Sendable {
    public let id: UUID
    public var title: String
    public var collection: String
    public let createdAt: Date
    public let swatches: [ColorSwatch]
    public let hasPhoto: Bool

    public var isSingleColor: Bool { swatches.count == 1 }

    public init(
        id: UUID = UUID(), title: String, collection: String,
        createdAt: Date = .now, swatches: [ColorSwatch], hasPhoto: Bool
    ) {
        self.id = id
        self.title = title
        self.collection = collection
        self.createdAt = createdAt
        self.swatches = swatches
        self.hasPhoto = hasPhoto
    }

    public func matches(_ query: String) -> Bool {
        let term = query.trimmingCharacters(in: .whitespacesAndNewlines)
        return term.isEmpty || ([title, collection] + swatches.map(\.color.hex))
            .contains { $0.localizedCaseInsensitiveContains(term) }
    }

    var isValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !collection.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && (1...8).contains(swatches.count)
            && swatches.allSatisfy { $0.weight.isFinite && $0.weight > 0 && $0.weight <= 1 }
            && abs(swatches.reduce(0) { $0 + $1.weight } - 1) < 0.001
    }
}
