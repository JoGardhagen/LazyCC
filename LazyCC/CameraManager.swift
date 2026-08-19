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
    let hardware = CameraHardwareService()
    
    private var isConfigured = false
    private var currentInput: AVCaptureDeviceInput?
    
    //var isTorchOn: Bool = false
    
    //var detectedColor: ResistorColor? = nil
    var detectedBands : [ResistorColor] = []
    var calculatedValue: String = "Aiming..."
    
    
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
    // --- Delegerade hårdvarukontroller ---
    func toggleTorch() {
        hardware.toggleTorch(device: currentInput?.device)
    }
        
    func setZoom(factor: CGFloat) {
        hardware.setZoom(factor: factor, device: currentInput?.device)
    }
        
    var isTorchOn: Bool {
        hardware.isTorchOn
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
                    self.calculatedValue = "Aim at bands..."
                }
            }
        }
    
    
}
