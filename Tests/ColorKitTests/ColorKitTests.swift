import Foundation
import Testing
@testable import ColorKit

@Test func colorConversionRoundTrips() {
    for hex: UInt32 in [0, 0xFFFFFF, 0xFF0000, 0x00FF00, 0x0000FF, 0xB96F52, 0x76836A] {
        let color = RGBColor(hex: hex)
        let converted = color.oklab.rgb
        #expect(abs(Int(color.red) - Int(converted.red)) <= 1)
        #expect(abs(Int(color.green) - Int(converted.green)) <= 1)
        #expect(abs(Int(color.blue) - Int(converted.blue)) <= 1)
    }
    #expect(RGBColor(hex: 0xB96F52).hex == "#B96F52")
    #expect(RGBColor(hex: 0xFFFFFF).prefersDarkInk)
    #expect(!RGBColor(hex: 0).prefersDarkInk)
}

@Test func paletteKeepsDominanceAndDoesNotInventColorsForFlatImages() {
    let red = RGBColor(hex: 0xD55040)
    let blue = RGBColor(hex: 0x3050C0)
    let pixels = Array(repeating: red, count: 75) + Array(repeating: blue, count: 25)
    let palette = PaletteExtractor.extract(from: pixels)
    #expect(palette.count == 2)
    #expect(palette.first?.color == red)
    #expect(abs((palette.first?.weight ?? 0) - 0.75) < 0.001)
    #expect(abs(palette.reduce(0) { $0 + $1.weight } - 1) < 0.001)
    #expect(PaletteExtractor.extract(from: Array(repeating: red, count: 300)).count == 1)
    #expect(PaletteExtractor.extract(from: []).isEmpty)
    #expect(PaletteExtractor.extract(from: pixels, count: 0).isEmpty)
    #expect(PaletteExtractor.extract(from: pixels, count: Int.max).count <= 8)
    #expect(PaletteExtractor.extract(from: pixels) == palette)
}

@Test func centerSampleRejectsHighlightsWithoutLosingWhiteOrBlackScenes() {
    let clay = RGBColor(hex: 0xB96F52)
    let white = RGBColor(hex: 0xFFFFFF)
    let black = RGBColor(hex: 0)
    let noisy = Array(repeating: clay, count: 70)
        + Array(repeating: white, count: 20) + Array(repeating: black, count: 10)
    #expect(PaletteExtractor.stableColor(from: noisy) == clay)
    #expect(PaletteExtractor.stableColor(from: [white, white]) == white)
    #expect(PaletteExtractor.stableColor(from: [black, black]) == black)
    #expect(PaletteExtractor.stableColor(from: []) == nil)
}

@Test func stabilizerSmoothsSmallChangesAndTracksNewSubjects() {
    var stabilizer = ColorStabilizer()
    let first = RGBColor(hex: 0xA06040)
    let nearby = RGBColor(hex: 0xA86848)
    #expect(stabilizer.update(first) == first)
    let smoothed = stabilizer.update(nearby)
    #expect(smoothed != nearby)
    #expect(smoothed.oklab.distanceSquared(to: first.oklab) < nearby.oklab.distanceSquared(to: first.oklab))
    #expect(stabilizer.update(RGBColor(hex: 0x0044FF)) == RGBColor(hex: 0x0044FF))
}

@Test @MainActor func libraryPersistsEditsCollectionsAndDeletion() throws {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: directory) }
    let store = LibraryStore(directory: directory)
    let entry = try store.save(
        title: "  午后  ", collection: "日常",
        swatches: [ColorSwatch(color: RGBColor(hex: 0xB96F52))], photo: Data([1, 2, 3])
    )
    #expect(entry.title == "午后")
    #expect(store.collections == ["日常"])
    #expect(entry.matches("b96f"))
    #expect(entry.matches("日常"))
    #expect(!entry.matches("海边"))
    #expect(try Data(contentsOf: #require(store.imageURL(for: entry))) == Data([1, 2, 3]))
    let reopened = LibraryStore(directory: directory)
    #expect(reopened.entries == [entry])
    try reopened.update(entry, title: "咖啡馆", collection: "旅行")
    #expect(LibraryStore(directory: directory).entries.first?.title == "咖啡馆")
    #expect(reopened.collections == ["旅行"])
    try reopened.delete(entry)
    #expect(LibraryStore(directory: directory).entries.isEmpty)
    #expect(!FileManager.default.fileExists(atPath: store.imageURL(for: entry)!.path))
}

@Test @MainActor func unreadableArchiveIsNeverOverwritten() throws {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: directory) }
    let archive = directory.appendingPathComponent("library.json")
    let corruptData = Data("not a library".utf8)
    try corruptData.write(to: archive)
    let store = LibraryStore(directory: directory)
    #expect(store.loadError != nil)
    #expect(throws: (any Error).self) {
        try store.save(title: "新色卡", collection: "日常", swatches: [ColorSwatch(color: RGBColor(hex: 0))], photo: nil)
    }
    #expect(try Data(contentsOf: archive) == corruptData)
}

@Test @MainActor func failedSaveDoesNotChangeMemoryOrLeavePhotoBehind() throws {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: directory) }
    let store = LibraryStore(directory: directory)
    try FileManager.default.createDirectory(at: directory.appendingPathComponent("library.json"), withIntermediateDirectories: true)
    #expect(throws: (any Error).self) {
        try store.save(title: "失败测试", collection: "日常", swatches: [ColorSwatch(color: RGBColor(hex: 0))], photo: Data([1]))
    }
    #expect(store.entries.isEmpty)
    #expect(try FileManager.default.contentsOfDirectory(atPath: directory.path) == ["library.json"])
}
