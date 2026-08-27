import ColorKit
import SwiftUI

struct EntryCard: View {
    let entry: LibraryEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            EntryImage(entry: entry, height: 145)
            PaletteStrip(swatches: entry.swatches, height: 24)
            VStack(alignment: .leading, spacing: 6) {
                Text(entry.title).font(.system(size: 14, weight: .medium)).lineLimit(1)
                HStack(spacing: 4) {
                    Text(entry.collection).lineLimit(1)
                    Spacer(minLength: 0)
                    Text("\(entry.swatches.count) 色")
                }.font(.system(size: 10)).foregroundStyle(Theme.muted)
            }.padding(12)
        }
        .background(Theme.card).clipShape(RoundedRectangle(cornerRadius: 16))
        .contentShape(RoundedRectangle(cornerRadius: 16))
        .accessibilityElement(children: .combine)
    }
}

struct EntryImage: View {
    @Environment(LibraryStore.self) private var library
    let entry: LibraryEntry
    let height: CGFloat

    var body: some View {
        Group {
            if let url = library.imageURL(for: entry), let image = UIImage(contentsOfFile: url.path) {
                PhotoFrame(image: Image(uiImage: image), height: height)
            } else {
                Rectangle().fill(entry.swatches.first?.color.displayColor ?? Theme.olive)
                    .overlay(alignment: .bottomLeading) {
                        Text(entry.swatches.first?.color.hex ?? "")
                            .font(.system(size: 15, weight: .medium, design: .monospaced))
                            .foregroundStyle(entry.swatches.first?.color.prefersDarkInk == true ? .black : .white)
                            .padding(16)
                    }
            }
        }.frame(height: height).contentShape(Rectangle())
    }
}
