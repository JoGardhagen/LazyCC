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
            
            let centerY = height / 2
            let startX = width / 2 - 60 // Vänster sida av rektangeln
            let endX = width / 2 + 60   // Höger sida av rektangeln
            
            var scannedLineColors: [ResistorColor?] = []
            
            // Scanna var 3:e pixel tvärs över rektangeln
            for x in stride(from: startX, to: endX, by: 3) {
                let offset = (centerY * bytesPerRow) + (x * 4)
                let b = Double(buffer[offset]) / 255.0
                let g = Double(buffer[offset + 1]) / 255.0
                let r = Double(buffer[offset + 2]) / 255.0
                
                let color = ResistorColorMatcher.match(r: r, g: g, b: b)
                scannedLineColors.append(color)
            }
            
            // Extrahera unika färgband från linjen
            let bands = ResistorColorMatcher.extractBands(from: scannedLineColors)
            
            DispatchQueue.main.async {
                self.detectedBands = bands
                
                // Om vi hittar minst 3 ringar beräknar vi Ohm direkt!
                if bands.count >= 3 {
                    let b1 = bands[0]
                    let b2 = bands[1]
                    let mult = bands[2]
                    self.calculatedValue = ResistorCalculator.calculate(band1: b1, band2: b2, multiplier: mult)
                } else {
                    self.calculatedValue = "Hittar \(bands.count)/3 ringar..."
                }
            }
        }
    }
