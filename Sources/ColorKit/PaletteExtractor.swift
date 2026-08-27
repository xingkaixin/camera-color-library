import Foundation

public struct ColorSwatch: Codable, Hashable, Sendable {
    public let color: RGBColor
    public let weight: Double

    public init(color: RGBColor, weight: Double = 1) {
        self.color = color
        self.weight = weight
    }
}

public enum PaletteExtractor {
    public static func extract(from pixels: [RGBColor], count: Int = 5) -> [ColorSwatch] {
        guard !pixels.isEmpty, count > 0 else { return [] }
        let strideLength = max(1, Int(ceil(Double(pixels.count) / 4096)))
        let samples = stride(from: 0, to: pixels.count, by: strideLength).map { pixels[$0].oklab }
        let targetCount = min(count, 8)
        var centers = [samples[samples.count / 2]]

        while centers.count < targetCount {
            let distances = samples.map { point in
                centers.map { point.distanceSquared(to: $0) }.min() ?? 0
            }
            guard let farthest = distances.indices.max(by: { distances[$0] < distances[$1] }),
                  distances[farthest] > 0.0025 else { break }
            centers.append(samples[farthest])
        }

        var counts = [Int](repeating: 0, count: centers.count)
        for _ in 0..<16 {
            var sums = [OKLab](repeating: OKLab(l: 0, a: 0, b: 0), count: centers.count)
            counts = [Int](repeating: 0, count: centers.count)
            for point in samples {
                let closest = centers.indices.min {
                    point.distanceSquared(to: centers[$0]) < point.distanceSquared(to: centers[$1])
                } ?? 0
                sums[closest].l += point.l
                sums[closest].a += point.a
                sums[closest].b += point.b
                counts[closest] += 1
            }
            var movement = 0.0
            for index in centers.indices where counts[index] > 0 {
                let n = Double(counts[index])
                let next = OKLab(l: sums[index].l / n, a: sums[index].a / n, b: sums[index].b / n)
                movement += centers[index].distanceSquared(to: next)
                centers[index] = next
            }
            if movement < 0.000001 { break }
        }

        return centers.indices.filter { counts[$0] > 0 }
            .sorted { counts[$0] == counts[$1] ? $0 < $1 : counts[$0] > counts[$1] }
            .map { ColorSwatch(color: centers[$0].rgb, weight: Double(counts[$0]) / Double(samples.count)) }
    }

    public static func stableColor(from pixels: [RGBColor]) -> RGBColor? {
        guard !pixels.isEmpty else { return nil }
        let midtones = pixels.filter {
            let channels = [Int($0.red), Int($0.green), Int($0.blue)]
            return channels.max()! > 12 && channels.min()! < 243
        }
        let samples = midtones.count >= pixels.count / 3 && !midtones.isEmpty ? midtones : pixels
        let index = samples.count / 2
        return RGBColor(
            red: samples.map(\.red).sorted()[index],
            green: samples.map(\.green).sorted()[index],
            blue: samples.map(\.blue).sorted()[index]
        )
    }
}

public struct ColorStabilizer: Sendable {
    private var previous: OKLab?

    public init() {}

    public mutating func update(_ color: RGBColor) -> RGBColor {
        let current = color.oklab
        guard let previous else {
            self.previous = current
            return color
        }
        let amount = current.distanceSquared(to: previous) > 0.025 ? 1.0 : 0.3
        let next = OKLab(
            l: previous.l + (current.l - previous.l) * amount,
            a: previous.a + (current.a - previous.a) * amount,
            b: previous.b + (current.b - previous.b) * amount
        )
        self.previous = next
        return next.rgb
    }
}
