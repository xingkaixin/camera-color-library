@preconcurrency import AVFoundation
import ColorKit
import CoreImage
import OSLog
import UIKit

final class CameraSession: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate, @unchecked Sendable {
    let session = AVCaptureSession()
    private let queue = DispatchQueue(label: "studio.colorlibrary.camera", qos: .userInitiated)
    private let context = CIContext(options: [.workingColorSpace: CGColorSpace(name: CGColorSpace.sRGB)!])
    private let logger = Logger(subsystem: "studio.colorlibrary.app", category: "Camera")
    private var device: AVCaptureDevice?
    private var latestImage: CIImage?
    private var latestColor: RGBColor?
    private var lastSampleTime = 0.0
    private var stabilizer = ColorStabilizer()
    private var onColor: (@Sendable (RGBColor) -> Void)?

    func start(onColor: @escaping @Sendable (RGBColor) -> Void, completion: @escaping @Sendable (Bool) -> Void) {
        queue.async {
            do {
                if self.session.inputs.isEmpty { try self.configure() }
                self.onColor = onColor
                self.stabilizer = ColorStabilizer()
                if !self.session.isRunning { self.session.startRunning() }
                self.logger.info("Capture session running: \(self.session.isRunning)")
                completion(self.session.isRunning)
            } catch {
                self.logger.error("Capture configuration failed: \(error.localizedDescription, privacy: .public)")
                completion(false)
            }
        }
    }

    func stop() {
        queue.async {
            if self.session.isRunning { self.session.stopRunning() }
            self.latestImage = nil
            self.latestColor = nil
            self.logger.info("Capture session stopped")
        }
    }

    func snapshot(completion: @escaping @Sendable (Data?, RGBColor?) -> Void) {
        queue.async {
            guard let image = self.latestImage,
                  let cgImage = self.context.createCGImage(image, from: image.extent) else {
                completion(nil, nil)
                return
            }
            completion(UIImage(cgImage: cgImage).jpegData(compressionQuality: 0.9), self.latestColor)
        }
    }

    func setExposureLocked(_ locked: Bool, completion: @escaping @Sendable (Bool) -> Void) {
        queue.async {
            guard let device = self.device else { completion(false); return }
            do {
                try device.lockForConfiguration()
                defer { device.unlockForConfiguration() }
                let exposure: AVCaptureDevice.ExposureMode = locked ? .locked : .continuousAutoExposure
                let balance: AVCaptureDevice.WhiteBalanceMode = locked ? .locked : .continuousAutoWhiteBalance
                guard device.isExposureModeSupported(exposure), device.isWhiteBalanceModeSupported(balance) else {
                    completion(false)
                    return
                }
                device.exposureMode = exposure
                device.whiteBalanceMode = balance
                completion(true)
            } catch {
                self.logger.error("Exposure lock failed: \(error.localizedDescription, privacy: .public)")
                completion(false)
            }
        }
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        let time = CMSampleBufferGetPresentationTimeStamp(sampleBuffer).seconds
        guard time - lastSampleTime >= 0.12, let buffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        lastSampleTime = time
        let image = CIImage(cvPixelBuffer: buffer)
        latestImage = image
        let side = min(image.extent.width, image.extent.height) * 0.16
        let region = CGRect(x: image.extent.midX - side / 2, y: image.extent.midY - side / 2, width: side, height: side)
        guard let cropped = context.createCGImage(image, from: region, format: .RGBA8, colorSpace: CGColorSpace(name: CGColorSpace.sRGB)) else { return }
        do {
            let pixels = try ImageProcessor.pixels(in: cropped, dimension: 24)
            guard let sampled = PaletteExtractor.stableColor(from: pixels) else { return }
            let color = stabilizer.update(sampled)
            latestColor = color
            onColor?(color)
        } catch {
            logger.error("Frame sampling failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func configure() throws {
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            throw CocoaError(.featureUnsupported)
        }
        let input = try AVCaptureDeviceInput(device: device)
        let output = AVCaptureVideoDataOutput()
        output.alwaysDiscardsLateVideoFrames = true
        output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        output.setSampleBufferDelegate(self, queue: queue)
        session.beginConfiguration()
        defer { session.commitConfiguration() }
        session.sessionPreset = .hd1280x720
        guard session.canAddInput(input) else { throw CocoaError(.featureUnsupported) }
        session.addInput(input)
        guard session.canAddOutput(output) else {
            session.removeInput(input)
            throw CocoaError(.featureUnsupported)
        }
        session.addOutput(output)
        if let connection = output.connection(with: .video), connection.isVideoRotationAngleSupported(90) {
            connection.videoRotationAngle = 90
        }
        try device.lockForConfiguration()
        if device.activeFormat.supportedColorSpaces.contains(.sRGB) { device.activeColorSpace = .sRGB }
        if device.isFocusModeSupported(.continuousAutoFocus) { device.focusMode = .continuousAutoFocus }
        device.unlockForConfiguration()
        self.device = device
    }
}
