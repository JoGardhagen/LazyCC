//
//  CameraManager.swift
//  LazyCC
//
//  Created by Joakim Gårdhagen on 2026-08-12.
//
import AVFoundation
import SwiftUI

@Observable
class CameraManager: NSObject {
    let session = AVCaptureSession()
    private var isConfigured = false
    
    override init() {
        super.init()
        setupCamera()
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
        
        if session.canAddInput(input) {
            session.addInput(input)
            isConfigured = true
        }
        //self.session.commitConfiguration()
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
            
}

struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: CGRect.zero)
        
        let prewviewLayer = AVCaptureVideoPreviewLayer(session: session)
        prewviewLayer.videoGravity = .resizeAspectFill
        
        view.layer.addSublayer(prewviewLayer)
        
        context.coordinator.previewLayer = prewviewLayer
        
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


