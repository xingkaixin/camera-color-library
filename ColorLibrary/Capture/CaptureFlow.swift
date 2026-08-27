import ColorKit
import Observation
import OSLog
import PhotosUI
import SwiftUI

@MainActor @Observable
final class CaptureFlow {
    var draft: CaptureDraft?
    var error: String?
    private(set) var isProcessing = false
    private let logger = Logger(subsystem: "studio.colorlibrary.app", category: "Import")

    func extract(data: Data, title: String = "偶遇的配色") async {
        guard !isProcessing else { return }
        isProcessing = true
        defer { isProcessing = false }
        do {
            draft = try await ImageProcessor.extract(data: data, title: title)
        } catch {
            logger.error("Photo extraction failed: \(error.localizedDescription, privacy: .public)")
            self.error = "这张照片暂时无法读取，请换一张照片再试。"
        }
    }

    func openSample(_ sample: Inspiration) async {
        guard let image = UIImage(named: sample.asset), let data = image.jpegData(compressionQuality: 0.92) else {
            error = "示例图片未能加载。你仍然可以导入自己的照片。"
            return
        }
        await extract(data: data, title: sample.title)
    }
}

struct PhotoImportButton: View {
    let flow: CaptureFlow
    var compact = false
    @State private var selection: PhotosPickerItem?

    var body: some View {
        PhotosPicker(selection: $selection, matching: .images, photoLibrary: .shared()) {
            if compact {
                RoundIcon(symbol: "photo")
            } else {
                Label("导入照片", systemImage: "photo")
                    .font(.system(size: 15, weight: .medium))
                    .frame(maxWidth: .infinity, minHeight: 54)
                    .background(Theme.card, in: RoundedRectangle(cornerRadius: 18))
                    .overlay(RoundedRectangle(cornerRadius: 18).stroke(Theme.line, lineWidth: 0.8))
            }
        }
        .foregroundStyle(Theme.ink)
        .accessibilityLabel("导入照片")
        .disabled(flow.isProcessing)
        .onChange(of: selection) { _, item in
            guard let item else { return }
            Task {
                do {
                    guard let data = try await item.loadTransferable(type: Data.self) else {
                        throw CocoaError(.fileReadCorruptFile)
                    }
                    await flow.extract(data: data)
                } catch {
                    Logger(subsystem: "studio.colorlibrary.app", category: "Import")
                        .error("Picker load failed: \(error.localizedDescription, privacy: .public)")
                    flow.error = "照片下载失败，请检查网络或选择已下载的照片。"
                }
                selection = nil
            }
        }
    }
}

extension View {
    func capturePresentation(_ flow: CaptureFlow) -> some View {
        modifier(CapturePresentation(flow: flow))
    }
}

private struct CapturePresentation: ViewModifier {
    @Bindable var flow: CaptureFlow

    func body(content: Content) -> some View {
        content
            .sheet(item: $flow.draft) { draft in CaptureReviewView(draft: draft) }
            .alert("暂时无法完成", isPresented: Binding(get: { flow.error != nil }, set: { if !$0 { flow.error = nil } })) {
                Button("知道了", role: .cancel) { flow.error = nil }
            } message: { Text(flow.error ?? "") }
            .overlay {
                if flow.isProcessing {
                    ZStack {
                        Theme.paper.opacity(0.85).ignoresSafeArea()
                        VStack(spacing: 18) {
                            ProgressView().tint(Theme.olive).scaleEffect(1.2)
                            Text("正在发现照片里的颜色…").font(.subheadline)
                            Text("在设备上完成，不上传照片").font(.caption).foregroundStyle(Theme.muted)
                        }
                    }
                    .accessibilityElement(children: .combine)
                }
            }
    }
}

struct Inspiration: Identifiable {
    let asset: String
    let title: String
    let caption: String
    let colors: [UInt32]
    var id: String { asset }
    var swatches: [ColorSwatch] { colors.map { ColorSwatch(color: RGBColor(hex: $0), weight: 0.2) } }

    static let samples = [
        Inspiration(asset: "Cafe", title: "午后的咖啡馆", caption: "陶土、暖阳，和一杯慢下来的咖啡。", colors: [0xA76442, 0xCE9F69, 0xE6D2A8, 0x777047, 0x3B3529]),
        Inspiration(asset: "Coast", title: "海岸的来信", caption: "把海风的颜色，带回日常。", colors: [0x176B75, 0x579189, 0xB8BDA2, 0xD4B18B, 0xE5D8C3])
    ]
}
