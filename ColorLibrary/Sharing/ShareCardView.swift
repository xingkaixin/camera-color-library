import ColorKit
import OSLog
import SwiftUI

struct ShareCardView: View {
    @Environment(LibraryStore.self) private var library
    @Environment(\.dismiss) private var dismiss
    let entry: LibraryEntry
    @State private var renderedImage: UIImage?
    @State private var showsActivity = false
    @State private var renderFailed = false

    private var sourceImage: UIImage? {
        library.imageURL(for: entry).flatMap { UIImage(contentsOfFile: $0.path) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 7) {
                        Text("好颜色，值得被看见").font(.system(size: 25, weight: .medium, design: .serif))
                        Text("一张小卡片，装下这一刻。")
                            .font(.system(size: 12)).foregroundStyle(Theme.muted)
                    }
                    if let renderedImage {
                        Image(uiImage: renderedImage).resizable().scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: 3))
                            .shadow(color: Theme.ink.opacity(0.13), radius: 18, y: 8)
                            .padding(.horizontal, 10)
                            .accessibilityLabel("\(entry.title)分享卡预览")
                            .accessibilityIdentifier("shareCardPreview")
                    } else if renderFailed {
                        ContentUnavailableView("暂时无法生成分享卡", systemImage: "photo.badge.exclamationmark")
                        Button("重新生成") { render() }
                    } else {
                        ProgressView().frame(height: 400)
                    }
                    Text("含照片、配色与 HEX 色值 · 高清图片")
                        .font(.system(size: 11)).foregroundStyle(Theme.muted)
                }.padding(24)
            }
            .background(Theme.paper).foregroundStyle(Theme.ink)
            .navigationTitle("分享色彩").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("完成") { dismiss() } } }
            .safeAreaInset(edge: .bottom) {
                Button { showsActivity = true } label: { Label("分享图片", systemImage: "square.and.arrow.up") }
                    .buttonStyle(PrimaryButtonStyle()).disabled(renderedImage == nil)
                    .padding(24).background(Theme.paper).accessibilityIdentifier("shareImageButton")
            }
            .task { render() }
            .sheet(isPresented: $showsActivity) {
                if let renderedImage { ActivitySheet(image: renderedImage) }
            }
        }
    }

    private func render() {
        let renderer = ImageRenderer(content: ShareArtwork(entry: entry, image: sourceImage).environment(\.colorScheme, .light))
        renderer.scale = 3
        renderer.isOpaque = true
        renderedImage = renderer.uiImage
        renderFailed = renderedImage == nil
        Logger(subsystem: "studio.colorlibrary.app", category: "Sharing")
            .info("Share card rendered: \(renderedImage != nil)")
    }
}

struct ShareArtwork: View {
    let entry: LibraryEntry
    let image: UIImage?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("A MOMENT IN COLOR").font(.system(size: 8, weight: .medium)).tracking(2)
                Spacer()
                Text(entry.createdAt.formatted(.dateTime.year().month(.twoDigits).day(.twoDigits)))
                    .font(.system(size: 8, design: .monospaced))
            }.foregroundStyle(Theme.muted).padding(.bottom, 18)
            if let image {
                PhotoFrame(image: Image(uiImage: image), height: 290)
            } else {
                PaletteStrip(swatches: entry.swatches, height: 290)
            }
            PaletteStrip(swatches: entry.swatches, height: 57)
            HStack(spacing: 0) {
                ForEach(Array(entry.swatches.enumerated()), id: \.offset) { _, swatch in
                    Text(swatch.color.hex).font(.system(size: 8, weight: .medium, design: .monospaced))
                        .frame(maxWidth: .infinity)
                }
            }.padding(.top, 10).foregroundStyle(Theme.muted)
            Text(entry.title).font(.system(size: 25, weight: .medium, design: .serif))
                .lineLimit(2).padding(.top, 25).padding(.bottom, 8)
            Text(entry.collection).font(.system(size: 11)).foregroundStyle(Theme.muted)
            Rectangle().fill(Theme.line).frame(height: 0.7).padding(.vertical, 21)
            HStack(alignment: .firstTextBaseline) {
                Text("Color Library.").font(.system(size: 19, weight: .medium, design: .serif)).tracking(-0.5)
                Spacer()
                Text("把喜欢的颜色，留在身边。")
                    .font(.system(size: 8)).foregroundStyle(Theme.muted)
            }
        }
        .padding(23).frame(width: 346).background(Theme.paper).foregroundStyle(Theme.ink)
    }
}

private struct ActivitySheet: UIViewControllerRepresentable {
    let image: UIImage

    func makeUIViewController(context: Context) -> UIActivityViewController {
        Logger(subsystem: "studio.colorlibrary.app", category: "Sharing")
            .notice("Presenting system share sheet: \(image.size.width * image.scale) x \(image.size.height * image.scale)")
        return UIActivityViewController(activityItems: [image], applicationActivities: nil)
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
