//
//  ResistorColorMatcher.swift
//  LazyCC
//
//  Created by Joakim Gårdhagen on 2026-08-12.
//

import Foundation

struct ResistorColorMatcher {
    
    static func match(r: Double,g: Double,b: Double)->ResistorColor? {
        let maxVal = max(r,max(g,b))
        let minVal = min(r,min(g,b))
        let delta = maxVal - minVal
        
        var hue: Double = 0
        let brightness: Double = maxVal
        let saturation: Double = delta == 0 ? 0 : delta / maxVal
        
        if delta != 0 {
            if maxVal == r {
                hue = (g - b) / delta + (g < b ? 6 : 0)
            }else if maxVal == g {
                hue = (b - r) / delta + 2
            }else{
                hue = (r - g) / delta + 4
            }
            hue *= 60
        }
        
            if brightness < 0.18{ return .svart}
            if saturation < 0.22{return brightness > 0.65 ? .vit : .grå}
            
            switch hue {
            case 0..<16,340...360: return brightness < 0.45 ? .brun : .röd
            case 16..<42: return .orange
            case 42..<70: return .gul
            case 70..<156: return .grön
            case 165..<250: return .blå
            case 250..<320: return .violett
            default: return nil
            }
        
        }
    static func extractBands(from colors: [ResistorColor?]) -> [ResistorColor]{
        var detectedBands : [ResistorColor] = []
        var lastColor: ResistorColor? = nil
        
        for color in colors {
            guard let color = color else {
                lastColor = nil
                continue
            }
            
            if color == .grå || color == .vit {
                lastColor = nil
                continue
            }
            if color != lastColor {
                detectedBands.append(color)
                lastColor = color
            }
        }
        return detectedBands
    }
}
