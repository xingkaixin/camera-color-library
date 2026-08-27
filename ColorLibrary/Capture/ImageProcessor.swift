import ColorKit
import ImageIO
import OSLog
import UIKit

struct CaptureDraft: Identifiable {
    let id = UUID()
    let image: UIImage?
    let swatches: [ColorSwatch]
    let suggestedTitle: String
}

enum ImageProcessor {
    private static let logger = Logger(subsystem: "studio.colorlibrary.app", category: "Extraction")

    static func extract(data: Data, title: String = "偶遇的配色") async throws -> CaptureDraft {
        let result = try await Task.detached(priority: .userInitiated) {
            guard let source = CGImageSourceCreateWithData(data as CFData, nil),
                  let thumbnail = CGImageSourceCreateThumbnailAtIndex(source, 0, [
                    kCGImageSourceCreateThumbnailFromImageAlways: true,
                    kCGImageSourceCreateThumbnailWithTransform: true,
                    kCGImageSourceThumbnailMaxPixelSize: 1600
                  ] as CFDictionary) else {
                throw CocoaError(.fileReadCorruptFile)
            }
            let pixels = try pixels(in: thumbnail, dimension: 72)
            let swatches = PaletteExtractor.extract(from: pixels)
            guard !swatches.isEmpty else { throw CocoaError(.fileReadCorruptFile) }
            logger.info("Extracted \(swatches.count) colors from \(pixels.count) sRGB samples")
            return (UIImage(cgImage: thumbnail), swatches)
        }.value
        return CaptureDraft(image: result.0, swatches: result.1, suggestedTitle: title)
    }

    static func pixels(in image: CGImage, dimension: Int) throws -> [RGBColor] {
        let edge = max(1, min(128, dimension))
        let ratio = Double(image.width) / Double(max(1, image.height))
        let width = ratio >= 1 ? edge : max(1, Int(Double(edge) * ratio))
        let height = ratio >= 1 ? max(1, Int(Double(edge) / ratio)) : edge
        var bytes = [UInt8](repeating: 255, count: width * height * 4)
        guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) else { throw CocoaError(.featureUnsupported) }
        try bytes.withUnsafeMutableBytes { buffer in
            guard let context = CGContext(
                data: buffer.baseAddress, width: width, height: height,
                bitsPerComponent: 8, bytesPerRow: width * 4, space: colorSpace,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
            ) else { throw CocoaError(.featureUnsupported) }
            context.setFillColor(CGColor(gray: 1, alpha: 1))
            context.fill(CGRect(x: 0, y: 0, width: width, height: height))
            context.interpolationQuality = .medium
            context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        }
        return stride(from: 0, to: bytes.count, by: 4).map {
            RGBColor(red: bytes[$0], green: bytes[$0 + 1], blue: bytes[$0 + 2])
        }
    }
}
