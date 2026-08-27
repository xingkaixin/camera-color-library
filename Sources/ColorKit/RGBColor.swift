import Foundation

public struct RGBColor: Codable, Hashable, Sendable {
    public let red: UInt8
    public let green: UInt8
    public let blue: UInt8

    public init(red: UInt8, green: UInt8, blue: UInt8) {
        self.red = red
        self.green = green
        self.blue = blue
    }

    public init(hex: UInt32) {
        red = UInt8((hex >> 16) & 0xFF)
        green = UInt8((hex >> 8) & 0xFF)
        blue = UInt8(hex & 0xFF)
    }

    public var hex: String {
        String(format: "#%02X%02X%02X", red, green, blue)
    }

    public var rgb: String { "\(red), \(green), \(blue)" }

    public var prefersDarkInk: Bool {
        0.2126 * Self.linear(red) + 0.7152 * Self.linear(green) + 0.0722 * Self.linear(blue) > 0.179
    }

    var oklab: OKLab {
        let r = Self.linear(red)
        let g = Self.linear(green)
        let b = Self.linear(blue)
        let l = cbrt(0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b)
        let m = cbrt(0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b)
        let s = cbrt(0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b)
        return OKLab(
            l: 0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s,
            a: 1.9779984951 * l - 2.4285922050 * m + 0.4505937099 * s,
            b: 0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s
        )
    }

    private static func linear(_ byte: UInt8) -> Double {
        let value = Double(byte) / 255
        return value <= 0.04045 ? value / 12.92 : pow((value + 0.055) / 1.055, 2.4)
    }
}

struct OKLab: Sendable {
    var l: Double
    var a: Double
    var b: Double

    func distanceSquared(to other: Self) -> Double {
        pow(l - other.l, 2) + pow(a - other.a, 2) + pow(b - other.b, 2)
    }

    var rgb: RGBColor {
        let x = pow(l + 0.3963377774 * a + 0.2158037573 * b, 3)
        let y = pow(l - 0.1055613458 * a - 0.0638541728 * b, 3)
        let z = pow(l - 0.0894841775 * a - 1.2914855480 * b, 3)
        return RGBColor(
            red: Self.encode(4.0767416621 * x - 3.3077115913 * y + 0.2309699292 * z),
            green: Self.encode(-1.2684380046 * x + 2.6097574011 * y - 0.3413193965 * z),
            blue: Self.encode(-0.0041960863 * x - 0.7034186147 * y + 1.7076147010 * z)
        )
    }

    private static func encode(_ linear: Double) -> UInt8 {
        let value = min(1, max(0, linear))
        let encoded = value <= 0.0031308 ? value * 12.92 : 1.055 * pow(value, 1 / 2.4) - 0.055
        return UInt8(clamping: Int((encoded * 255).rounded()))
    }
}
