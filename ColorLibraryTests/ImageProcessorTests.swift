import ColorKit
import SwiftUI
import Testing
@testable import ColorLibrary

@Test func extractsActualBundledPhotographs() async throws {
    for sample in Inspiration.samples {
        let image = try #require(UIImage(named: sample.asset))
        let data = try #require(image.jpegData(compressionQuality: 0.92))
        let draft = try await ImageProcessor.extract(data: data, title: sample.title)
        #expect(draft.swatches.count == 5)
        #expect(draft.image != nil)
        #expect(draft.suggestedTitle == sample.title)
        print("EXTRACTION \(sample.asset): \(draft.swatches.map { $0.color.hex }.joined(separator: ", "))")
    }
}

@Test func rejectsInvalidImageData() async {
    await #expect(throws: (any Error).self) {
        try await ImageProcessor.extract(data: Data([0, 1, 2]))
    }
}

@Test @MainActor func shareCardProducesHighResolutionImage() throws {
    let entry = LibraryEntry(title: "一份色彩记忆", collection: "日常", swatches: [ColorSwatch(color: RGBColor(hex: 0xB96F52))], hasPhoto: false)
    let renderer = ImageRenderer(content: ShareArtwork(entry: entry, image: nil))
    renderer.scale = 3
    let image = try #require(renderer.uiImage)
    #expect(image.size.width * image.scale == 1038)
    #expect(image.size.height * image.scale > 1500)
}

@Test func wideGamutPixelsAreConvertedRatherThanRelabeled() throws {
    let p3 = try #require(CGColorSpace(name: CGColorSpace.displayP3))
    let srgb = try #require(CGColorSpace(name: CGColorSpace.sRGB))
    let input = try #require(CGColor(colorSpace: p3, components: [0.7, 0.4, 0.2, 1]))
    let expected = try #require(input.converted(to: srgb, intent: .defaultIntent, options: nil)?.components)
    let context = try #require(CGContext(data: nil, width: 4, height: 4, bitsPerComponent: 8, bytesPerRow: 16, space: p3, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
    context.setFillColor(input)
    context.fill(CGRect(x: 0, y: 0, width: 4, height: 4))
    let pixels = try ImageProcessor.pixels(in: #require(context.makeImage()), dimension: 4)
    let pixel = try #require(pixels.first)
    #expect(abs(Int(pixel.red) - Int((expected[0] * 255).rounded())) <= 2)
    #expect(abs(Int(pixel.green) - Int((expected[1] * 255).rounded())) <= 2)
    #expect(abs(Int(pixel.blue) - Int((expected[2] * 255).rounded())) <= 2)
}

@Test func transparentPixelsUseTheSameWhiteBackgroundAsThePreview() throws {
    let space = try #require(CGColorSpace(name: CGColorSpace.sRGB))
    let context = try #require(CGContext(data: nil, width: 2, height: 2, bitsPerComponent: 8, bytesPerRow: 8, space: space, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
    context.clear(CGRect(x: 0, y: 0, width: 2, height: 2))
    let pixels = try ImageProcessor.pixels(in: #require(context.makeImage()), dimension: 2)
    #expect(pixels.allSatisfy { $0 == RGBColor(hex: 0xFFFFFF) })
    #expect(try ImageProcessor.pixels(in: #require(context.makeImage()), dimension: Int.max).count <= 128 * 128)
}

@Test @MainActor func importedPhotoHonorsExifOrientation() async throws {
    let renderer = UIGraphicsImageRenderer(size: CGSize(width: 40, height: 20))
    let raw = renderer.image { context in
        UIColor.red.setFill()
        context.fill(CGRect(x: 0, y: 0, width: 20, height: 20))
        UIColor.blue.setFill()
        context.fill(CGRect(x: 20, y: 0, width: 20, height: 20))
    }
    let rotated = UIImage(cgImage: try #require(raw.cgImage), scale: raw.scale, orientation: .right)
    let data = try #require(rotated.jpegData(compressionQuality: 1))
    let draft = try await ImageProcessor.extract(data: data)
    let imported = try #require(draft.image)
    #expect(imported.size.height == imported.size.width * 2)
    #expect(imported.imageOrientation == .up)
    #expect(draft.swatches.count == 2)
}

@Test @MainActor func transparentImportKeepsItsColorsAfterJPEGStorage() async throws {
    let space = try #require(CGColorSpace(name: CGColorSpace.sRGB))
    let context = try #require(CGContext(data: nil, width: 8, height: 8, bitsPerComponent: 8, bytesPerRow: 32, space: space, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
    context.clear(CGRect(x: 0, y: 0, width: 8, height: 8))
    let image = UIImage(cgImage: try #require(context.makeImage()))
    let imported = try await ImageProcessor.extract(data: #require(image.pngData()))
    let stored = try await ImageProcessor.extract(data: #require(imported.image?.jpegData(compressionQuality: 0.88)))
    print("TRANSPARENCY imported: \(imported.swatches.map(\.color.hex)), stored: \(stored.swatches.map(\.color.hex))")
    #expect(imported.swatches == stored.swatches)
}
