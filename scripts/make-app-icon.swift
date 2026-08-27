import AppKit

let destination = CommandLine.arguments[1]
let size = 1024
let space = CGColorSpace(name: CGColorSpace.sRGB)!
let context = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: size * 4, space: space, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
context.setFillColor(CGColor(red: 0.25, green: 0.32, blue: 0.23, alpha: 1))
context.fill(CGRect(x: 0, y: 0, width: size, height: size))

func card(x: CGFloat, y: CGFloat, angle: CGFloat, color: CGColor) {
    context.saveGState()
    context.translateBy(x: x, y: y)
    context.rotate(by: angle * .pi / 180)
    context.setFillColor(color)
    context.addPath(CGPath(roundedRect: CGRect(x: -155, y: -225, width: 310, height: 450), cornerWidth: 36, cornerHeight: 36, transform: nil))
    context.fillPath()
    context.setFillColor(CGColor(red: 0.98, green: 0.96, blue: 0.90, alpha: 0.55))
    context.fill(CGRect(x: -113, y: -153, width: 122, height: 12))
    context.restoreGState()
}

card(x: 381, y: 540, angle: 22, color: CGColor(red: 0.73, green: 0.43, blue: 0.30, alpha: 1))
card(x: 540, y: 516, angle: -5, color: CGColor(red: 0.80, green: 0.66, blue: 0.43, alpha: 1))
card(x: 659, y: 475, angle: -23, color: CGColor(red: 0.94, green: 0.90, blue: 0.80, alpha: 1))
let image = NSBitmapImageRep(cgImage: context.makeImage()!)
try image.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: destination))
print("Generated app icon: \(destination)")
