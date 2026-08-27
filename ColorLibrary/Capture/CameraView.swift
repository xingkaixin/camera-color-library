import AVFoundation
import ColorKit
import SwiftUI

struct CameraView: View {
    private enum Mode: String, CaseIterable { case color = "单色", palette = "整幅配色" }
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @State private var camera = CameraModel()
    @State private var flow = CaptureFlow()
    @State private var mode = Mode.color
    @State private var isCapturing = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    HStack {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("把此刻，收进色卡").font(.system(size: 25, weight: .medium, design: .serif))
                            Text("LOOK CLOSER. THERE IS COLOR EVERYWHERE.")
                                .font(.system(size: 8)).tracking(1.1).foregroundStyle(Theme.muted)
                        }
                        Spacer()
                    }
                    viewfinder
                    HStack(spacing: 6) {
                        ForEach(Mode.allCases, id: \.self) { item in
                            Button { mode = item } label: {
                                Text(item.rawValue).font(.system(size: 13, weight: .medium))
                                    .padding(.horizontal, 24).padding(.vertical, 11)
                                    .background(mode == item ? Theme.olive : .clear, in: Capsule())
                                    .foregroundStyle(mode == item ? .white : Theme.muted)
                            }
                        }
                    }.padding(4).background(Theme.card, in: Capsule())
                    HStack {
                        PhotoImportButton(flow: flow, compact: true)
                        Spacer()
                        Button { Task { await capture() } } label: {
                            ZStack {
                                Circle().stroke(Theme.olive, lineWidth: 2).frame(width: 76, height: 76)
                                Circle().fill(Theme.olive).frame(width: 64, height: 64)
                                Image(systemName: mode == .color ? "eyedropper" : "camera")
                                    .font(.system(size: 23)).foregroundStyle(.white)
                            }
                        }
                        .disabled(camera.status != .running || camera.color == nil || isCapturing)
                        .opacity(camera.status == .running ? 1 : 0.35)
                        .accessibilityLabel(mode == .color ? "冻结并保存颜色" : "拍摄并提取配色")
                        Spacer()
                        Button { camera.toggleExposureLock() } label: {
                            RoundIcon(symbol: camera.exposureLocked ? "lock.fill" : "lock.open")
                        }
                        .disabled(camera.status != .running)
                        .accessibilityLabel(camera.exposureLocked ? "解锁曝光与白平衡" : "锁定曝光与白平衡")
                    }.padding(.horizontal, 19)
                    Text(mode == .color ? "对准中央区域，轻点快门冻结颜色" : "轻点快门，提取整个画面的主要配色")
                        .font(.system(size: 12)).foregroundStyle(Theme.muted)
                    Button { Task { await flow.openSample(Inspiration.samples[0]) } } label: {
                        Label("先用示例体验一下", systemImage: "sparkles").font(.system(size: 13, weight: .medium))
                    }.accessibilityIdentifier("cameraSampleButton")
                    Text("色值会受光线、曝光与白平衡影响。\n这是镜头所见的颜色，不是物体的绝对真色。")
                        .font(.system(size: 10)).foregroundStyle(Theme.muted)
                        .multilineTextAlignment(.center).lineSpacing(4)
                }.padding(24)
            }
            .background(Theme.paper).foregroundStyle(Theme.ink)
            .navigationTitle("捕捉色彩").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { Button("完成") { dismiss() } }
            }
            .capturePresentation(flow)
            .task { await camera.start() }
            .onDisappear { camera.stop() }
            .onChange(of: flow.draft != nil) { _, isReviewing in
                if isReviewing { camera.stop() }
                else if scenePhase == .active { Task { await camera.start() } }
            }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active && flow.draft == nil { Task { await camera.start() } }
                else { camera.stop() }
            }
            .onReceive(NotificationCenter.default.publisher(for: .AVCaptureSessionWasInterrupted, object: camera.capture.session)) { _ in
                camera.handleInterruption()
            }
            .onReceive(NotificationCenter.default.publisher(for: .AVCaptureSessionRuntimeError, object: camera.capture.session)) { _ in
                camera.handleInterruption()
            }
            .onReceive(NotificationCenter.default.publisher(for: .AVCaptureSessionInterruptionEnded, object: camera.capture.session)) { _ in
                if scenePhase == .active && flow.draft == nil { Task { await camera.start() } }
            }
        }
    }

    private var viewfinder: some View {
        GeometryReader { geometry in
            ZStack {
                if camera.status == .running || camera.status == .starting {
                    CameraPreview(session: camera.capture.session)
                    if camera.status == .starting { ProgressView().tint(.white) }
                    if mode == .color && camera.status == .running {
                        RoundedRectangle(cornerRadius: 12).stroke(.white, lineWidth: 1.5)
                            .frame(width: geometry.size.width * 0.16, height: geometry.size.width * 0.16)
                            .overlay { Image(systemName: "plus").font(.system(size: 13, weight: .ultraLight)).foregroundStyle(.white) }
                    }
                } else {
                    Image("Cafe").resizable().scaledToFill().frame(width: geometry.size.width, height: geometry.size.height).clipped()
                    Color.black.opacity(0.5)
                    cameraUnavailable
                }
            }
            .overlay(alignment: .topLeading) {
                HStack(spacing: 6) {
                    Circle().fill(camera.status == .running ? .green : .white.opacity(0.6)).frame(width: 5, height: 5)
                    Text(camera.status == .running ? "LIVE · sRGB" : "CAMERA").font(.system(size: 9, weight: .medium)).tracking(1)
                }.padding(12).background(.black.opacity(0.25), in: Capsule()).padding(15).foregroundStyle(.white)
            }
            .overlay(alignment: .bottom) {
                if let color = camera.color {
                    HStack(spacing: 12) {
                        RoundedRectangle(cornerRadius: 9).fill(color.displayColor).frame(width: 44, height: 44)
                            .overlay(RoundedRectangle(cornerRadius: 9).stroke(.white.opacity(0.5)))
                        VStack(alignment: .leading, spacing: 4) {
                            Text(color.hex).font(.system(size: 22, weight: .medium, design: .monospaced))
                            Text("RGB  \(color.rgb)").font(.system(size: 10, design: .monospaced)).opacity(0.8)
                        }
                        Spacer()
                        Text(camera.exposureLocked ? "曝光已锁定" : "区域稳定采样").font(.system(size: 10))
                    }.padding(17).foregroundStyle(.white).background(.black.opacity(0.4))
                }
            }
        }
        .frame(height: 350).background(Theme.ink).clipShape(RoundedRectangle(cornerRadius: 25))
    }

    private var cameraUnavailable: some View {
        VStack(spacing: 14) {
            Image(systemName: "camera.viewfinder").font(.system(size: 34, weight: .ultraLight))
            Text(unavailability.title)
                .font(.system(size: 20, weight: .medium, design: .serif))
            Text(unavailability.message)
                .font(.system(size: 12)).lineSpacing(5).multilineTextAlignment(.center).opacity(0.85)
            if camera.status == .denied {
                Button("打开设置") {
                    if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
                }.font(.subheadline).padding(.horizontal, 20).padding(.vertical, 9).background(.white.opacity(0.2), in: Capsule())
            }
            if camera.status == .interrupted {
                Button("重试相机") { Task { await camera.start() } }.font(.subheadline)
            }
        }.foregroundStyle(.white).padding(18)
    }

    private var unavailability: (title: String, message: String) {
        switch camera.status {
        case .denied:
            ("让镜头发现颜色", "请在设置中允许相机访问\n也可以直接导入照片")
        case .interrupted:
            ("相机暂时被中断", "系统或其他应用暂时占用了镜头\n恢复后将重新连接，也可以轻点重试")
        default:
            ("暂时没有可用的镜头", "模拟器或当前设备无法使用相机\n导入照片，也能收集好颜色")
        }
    }

    private func capture() async {
        isCapturing = true
        defer { isCapturing = false }
        let (data, color) = await camera.snapshot()
        guard let data, let color else {
            flow.error = "还没有接收到画面，请稍后再试。"
            return
        }
        if mode == .palette {
            await flow.extract(data: data)
        } else {
            flow.draft = CaptureDraft(image: UIImage(data: data), swatches: [ColorSwatch(color: color)], suggestedTitle: "此刻的颜色")
        }
    }
}

private struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ view: PreviewView, context: Context) {
        if let connection = view.previewLayer.connection, connection.isVideoRotationAngleSupported(90) {
            connection.videoRotationAngle = 90
        }
    }
}

private final class PreviewView: UIView {
    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
    var previewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
}
