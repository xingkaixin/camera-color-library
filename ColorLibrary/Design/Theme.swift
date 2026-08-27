import ColorKit
import SwiftUI

enum Theme {
    static let paper = Color(red: 0.965, green: 0.953, blue: 0.922)
    static let ink = Color(red: 0.16, green: 0.20, blue: 0.16)
    static let olive = Color(red: 0.27, green: 0.34, blue: 0.24)
    static let muted = Color(red: 0.43, green: 0.44, blue: 0.39)
    static let line = Color(red: 0.86, green: 0.85, blue: 0.80)
    static let card = Color(red: 0.995, green: 0.988, blue: 0.969)
}

extension RGBColor {
    var displayColor: Color {
        Color(.sRGB, red: Double(red) / 255, green: Double(green) / 255, blue: Double(blue) / 255)
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .semibold))
            .frame(maxWidth: .infinity, minHeight: 54)
            .foregroundStyle(.white)
            .background(Theme.olive, in: RoundedRectangle(cornerRadius: 18))
            .opacity(configuration.isPressed ? 0.8 : 1)
    }
}

struct RoundIcon: View {
    let symbol: String

    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: 18, weight: .regular))
            .frame(width: 44, height: 44)
            .background(Theme.card, in: Circle())
            .overlay(Circle().stroke(Theme.line, lineWidth: 0.7))
    }
}

struct PaletteStrip: View {
    let swatches: [ColorSwatch]
    var height: CGFloat = 40

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(swatches.enumerated()), id: \.offset) { _, swatch in
                swatch.color.displayColor.frame(maxWidth: .infinity)
            }
        }
        .frame(height: height)
        .accessibilityLabel(swatches.map(\.color.hex).joined(separator: ", "))
    }
}

struct BrandMark: View {
    var body: some View {
        HStack(spacing: 9) {
            ZStack {
                RoundedRectangle(cornerRadius: 3).fill(Color(red: 0.71, green: 0.45, blue: 0.32))
                    .frame(width: 15, height: 24).rotationEffect(.degrees(-23)).offset(x: -5, y: 1)
                RoundedRectangle(cornerRadius: 3).fill(Theme.olive).frame(width: 15, height: 24)
                    .rotationEffect(.degrees(13)).offset(x: 4)
            }.frame(width: 29, height: 30)
            Text("Color Library.").font(.system(size: 25, weight: .medium, design: .serif)).tracking(-0.7)
        }
        .foregroundStyle(Theme.ink)
        .accessibilityLabel("色彩手记 Color Library")
    }
}
