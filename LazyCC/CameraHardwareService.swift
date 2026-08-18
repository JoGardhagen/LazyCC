//
//  CameraHardwareService.swift
//  LazyCC
//
//  Created by Joakim Gårdhagen on 2026-08-18.
//
import AVFoundation

class CameraHardwareService{
    var isTorchOn: Bool = false
     
    func toggleTorch(device : AVCaptureDevice?){
        guard let device = device, device.hasTorch else { return }
        
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
    
    func setZoom(factor: CGFloat, device: AVCaptureDevice?) {
        guard let device = device else { return }
        
        do {
            try device.lockForConfiguration()
            let clamped = max(device.minAvailableVideoZoomFactor, min(factor, 8.0))
            device.videoZoomFactor = clamped
            device.unlockForConfiguration()
        } catch { print("Zoom-fel: \(error)") }
    }
}
