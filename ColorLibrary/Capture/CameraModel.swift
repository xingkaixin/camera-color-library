import AVFoundation
import ColorKit
import Observation
import OSLog

@MainActor @Observable
final class CameraModel {
    enum Status: Equatable {
        case starting, running, denied, unavailable, interrupted
    }

    let capture = CameraSession()
    private(set) var status: Status = .starting
    private(set) var color: RGBColor?
    private(set) var exposureLocked = false
    private var wantsCamera = false
    private let logger = Logger(subsystem: "studio.colorlibrary.app", category: "CameraUI")

    func start() async {
        wantsCamera = true
        guard AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) != nil else {
            status = .unavailable
            logger.info("No camera hardware; photo import remains available")
            return
        }
        status = .starting
        let allowed = await AVCaptureDevice.requestAccess(for: .video)
        guard wantsCamera else { return }
        guard allowed else { status = .denied; return }
        capture.start { [weak self] color in
            Task { @MainActor in
                guard let self, self.wantsCamera else { return }
                self.color = color
            }
        } completion: { [weak self] running in
            Task { @MainActor in
                guard let self, self.wantsCamera else { return }
                self.status = running ? .running : .interrupted
            }
        }
    }

    func stop() {
        wantsCamera = false
        capture.stop()
        color = nil
    }

    func handleInterruption() {
        guard wantsCamera, status == .running || status == .starting else { return }
        logger.notice("Capture interrupted; discard stale color and stop the session")
        stop()
        status = .interrupted
    }

    func toggleExposureLock() {
        let requested = !exposureLocked
        capture.setExposureLocked(requested) { [weak self] success in
            Task { @MainActor in
                if success { self?.exposureLocked = requested }
            }
        }
    }

    func snapshot() async -> (Data?, RGBColor?) {
        await withCheckedContinuation { continuation in
            capture.snapshot { data, color in continuation.resume(returning: (data, color)) }
        }
    }
}
