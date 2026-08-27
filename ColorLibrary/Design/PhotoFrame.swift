import SwiftUI

struct PhotoFrame: View {
    let image: Image
    let height: CGFloat

    var body: some View {
        GeometryReader { geometry in
            image.resizable().scaledToFill()
                .frame(width: geometry.size.width, height: height)
                .clipped()
        }
        .frame(height: height)
        .contentShape(Rectangle())
        .accessibilityHidden(true)
    }
}
