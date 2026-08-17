//
//  ResistorImageProcessor.swift
//  LazyCC
//
//  Created by Joakim Gårdhagen on 2026-08-17.
//
import AVFoundation
import CoreGraphics


struct ResistorImageProcessor {
    
    static func process(sampleBuffer: CMSampleBuffer) -> [ResistorColor]{
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return []}
        
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }
        
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        guard let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer) else { return [] }
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
        return detected
    }
}
