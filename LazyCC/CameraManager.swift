//
//  CameraManager.swift
//  LazyCC
//
//  Created by Joakim Gårdhagen on 2026-08-12.
//
import AVFoundation
import SwiftUI

@Observable
class CameraManager: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    let session = AVCaptureSession()
    private var isConfigured = false
    private var currentInput: AVCaptureDeviceInput?
    
    var detectedColor: ResistorColor? = nil

    override init() {
        super.init()
        #if !TARGET_INTERFACE_BUILDER
        setupCamera()
        #endif
    }
    
    private func setupCamera() {
        session.beginConfiguration()
        defer { session.commitConfiguration() }
        
        let discovery = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInTripleCamera, .builtInDualWideCamera, .builtInWideAngleCamera],
            mediaType: .video, position: .back
        )
        
        guard let device = discovery.devices.first,
              let input = try? AVCaptureDeviceInput(device: device) else { return }
        
        self.currentInput = input
        if session.canAddInput(input) { session.addInput(input) }
        
        let output = AVCaptureVideoDataOutput()
        output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "cameraProcessingQueue"))
        
        if session.canAddOutput(output) {
            session.addOutput(output)
            isConfigured = true
        }
    }
    
    func start() {
        guard isConfigured else { return }
        DispatchQueue.global(qos: .userInitiated).async {
            if !self.session.isRunning { self.session.startRunning() }
        }
    }
    
    func stop() {
        guard isConfigured else { return }
        DispatchQueue.global(qos: .userInitiated).async {
            if self.session.isRunning { self.session.stopRunning() }
        }
    }
    
    func setZoom(factor: CGFloat) {
        guard let device = currentInput?.device else { return }
        do {
            try device.lockForConfiguration()
            let clamped = max(device.minAvailableVideoZoomFactor, min(factor, 8.0))
            device.videoZoomFactor = clamped
            device.unlockForConfiguration()
        } catch { print("Zoom-fel: \(error)") }
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if connection.isVideoRotationAngleSupported(90.0){
            connection.videoRotationAngle = 90.0
        }
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }
        
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        guard let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer) else { return }
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        let buffer = baseAddress.assumingMemoryBound(to: UInt8.self)
        
        // Genomsnitt av pixlarna i mitten
        let centerX = width / 2, centerY = height / 2, sample = 4
        var totalR = 0.0, totalG = 0.0, totalB = 0.0, count = 0.0
        
        for x in (centerX - sample)...(centerX + sample) {
            for y in (centerY - sample)...(centerY + sample) {
                let offset = (y * bytesPerRow) + (x * 4)
                totalB += Double(buffer[offset])
                totalG += Double(buffer[offset + 1])
                totalR += Double(buffer[offset + 2])
                count += 1
            }
        }
        
        let color = ResistorColorMatcher.match(
            r: (totalR / count) / 255.0,
            g: (totalG / count) / 255.0,
            b: (totalB / count) / 255.0
        )
        
        DispatchQueue.main.async { self.detectedColor = color }
    }
}
