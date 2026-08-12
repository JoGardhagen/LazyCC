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
    
    private var videoDevice: AVCaptureDevice?
    
    var detectedHue: Double = 0.0
    var detectedSaturation: Double = 0.0
    var detectedColor: ResistorColor? = nil
    
    override init() {
        super.init()
        
        #if !TARGET_INTERFACE_BUILDER
        setupCamera()
        #endif
    }
    
    private func setupCamera() {
        session.beginConfiguration()
        
        defer {
            session.commitConfiguration()
        }
        
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera,for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: device) else {
            print("Kamera saknas eller kunde inte initieras (vanligt i Xcode Simulator).")
            return
        }
        self.videoDevice = device
        
        if session.canAddInput(input) {
            session.addInput(input)
            //isConfigured = true
        }
        //self.session.commitConfiguration()
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.videoSettings = [kCVPixelBufferMetalCompatibilityKey as String: kCVPixelFormatType_32BGRA]
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "cameraProcessingQueue"))
        
        if session.canAddOutput(videoOutput){
            session.addOutput(videoOutput)
            isConfigured = true
        }
    }
    
    func start() {
        guard isConfigured else { return }
        DispatchQueue.global(qos: .background).async {
            if !self.session.isRunning {
                self.session.startRunning()
            }
        }
    }
    
    func stop() {
        guard isConfigured else { return }
        DispatchQueue.global(qos: .background).async {
            if self.session.isRunning {
                self.session.stopRunning()
            }
        }
    }
    
    func setZoom(factor: CGFloat){
        guard let device = videoDevice else { return }
        
        do{
            
            try device.lockForConfiguration()
            
            let maxZoom = device.activeFormat.videoMaxZoomFactor
            let clamperdFactor = min(1.0,min(factor,maxZoom))
            
            device.videoZoomFactor = clamperdFactor
            
            device.unlockForConfiguration()
        }catch{
            print("kunde inte ändra zoom: \(error)")
        }
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer {CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)}
        
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        
        let centerX = width/2
        let centerY = height/2
        
        guard let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer) else { return }
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        let pixelOffset = bytesPerRow * centerY + centerX * 4
        
        let buffer = baseAddress.assumingMemoryBound(to: UInt8.self)
        let b = Double(buffer[pixelOffset]) / 255.0
        let g = Double(buffer[pixelOffset + 1]) / 255.0
        let r = Double(buffer[pixelOffset + 2]) / 255.0
        //let a = Double(buffer[pixelOffset + 3]) / 255.0
        
        let (hue, saturation, _) = rgbToHSV(r: r, g: g, b: b)
        
        let color = matchingColor(hue: hue, saturation: saturation)
        
        DispatchQueue.main.async {
            self.detectedHue = hue
            self.detectedSaturation = saturation
            self.detectedColor = color
        }
    }
    
    private func rgbToHSV(r: Double, g: Double, b: Double) -> (h: Double, s: Double, v: Double) {
        let maxVal = max(r,max(g,b)); let minVal = min(r,min(g,b));
        let delta = maxVal - minVal;
        var h: Double = 0
        let v: Double = maxVal
        let s: Double = maxVal == 0 ? 0 : delta/maxVal
        if delta != 0 {
            if maxVal == r { h = (g-b) / delta + (g < b ? 6 : 0) }
            else if maxVal == g { h = (b-r) / delta + 2 }
            else { h = (r-g) / delta + 4}; h *= 60;
        }
        return(h, s, v)
    }
    
    private func matchingColor(hue: Double, saturation: Double) -> ResistorColor? {
        if saturation < 0.20 {return .grey}
        switch hue {
        case 0..<18,340...360: return .red
        case 18..<45: return .orange
        case 45..<70: return .yellow
        case 70..<165: return .green
        case 165..<255: return .blue
        case 255..<315: return .violett
        default : return nil
            
            
            
        }
        
    }
    
}

struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: CGRect.zero)
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        
        view.layer.addSublayer(previewLayer)
        
        context.coordinator.previewLayer = previewLayer
        
        return view
    }
    func updateUIView(_ uiView: UIView, context: Context) {
        DispatchQueue.main.async {
            context.coordinator.previewLayer?.frame = uiView.bounds
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator {
        var previewLayer: AVCaptureVideoPreviewLayer?
    }
}


