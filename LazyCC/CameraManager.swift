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
    
    var isTorchOn: Bool = false
    
    //var detectedColor: ResistorColor? = nil
    var detectedBands : [ResistorColor] = []
    var calculatedValue: String = "Siktar..."
    
    
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
            if connection.isVideoRotationAngleSupported(90.0) {
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
            
            let centerX = width / 2
            let centerY = height / 2
            let boxHeight = 40
            
            // Relativa positioner för de 5 ringarna (procentuellt över siktet)
            // Ring 1, 2, 3 sitter tätt till vänster, Ring 4 (multiplikator), Ring 5 (tolerans) till höger
            let relativeOffsets: [CGFloat] = [-0.35, -0.20, -0.05, 0.15, 0.35]
            let boxWidth: CGFloat = 190.0
            
            var detected: [ResistorColor] = []
            
            for offset in relativeOffsets {
                let pointX = Int(CGFloat(centerX) + (offset * boxWidth))
                
                var sumR = 0.0
                var sumG = 0.0
                var sumB = 0.0
                var pixelCount = 0.0
                
                // Ta medelvärde i en smal vertikal pelare vid varje markör
                let startY = max(0, centerY - (boxHeight / 2))
                let endY = min(height, centerY + (boxHeight / 2))
                
                for y in startY..<endY {
                    let bytesOffset = (y * bytesPerRow) + (pointX * 4)
                    let b = Double(buffer[bytesOffset]) / 255.0
                    let g = Double(buffer[bytesOffset + 1]) / 255.0
                    let r = Double(buffer[bytesOffset + 2]) / 255.0
                    
                    sumR += r
                    sumG += g
                    sumB += b
                    pixelCount += 1.0
                }
                
                let avgR = sumR / pixelCount
                let avgG = sumG / pixelCount
                let avgB = sumB / pixelCount
                
                // Om vi får en giltig färg på den punkten sparar vi den
                if let matched = ResistorColorMatcher.match(r: avgR, g: avgG, b: avgB) {
                    detected.append(matched)
                }
            }
            
            DispatchQueue.main.async {
                self.detectedBands = detected
                
                if detected.count >= 3 {
                    self.calculatedValue = ResistorCalculator.calculate(bands: detected)
                } else {
                    self.calculatedValue = "Passa in ringarna i siktet..."
                }
            }
        }
    
    func toggleTorch(){
        guard let device = currentInput?.device, device.hasTorch else { return }
        
        do{
            try device.lockForConfiguration()
            if device.torchMode == .on{
                device.torchMode = .off
                isTorchOn = false
            }else{
                device.torchMode = .on
            }
            
            device.unlockForConfiguration()
        }catch{
            print("Kunde inte ändra lampans status: \(error)")
        }
    }
}
