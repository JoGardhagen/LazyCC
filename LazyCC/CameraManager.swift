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
            
            let detected = ResistorImageProcessor.process(sampleBuffer: sampleBuffer)
            
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
