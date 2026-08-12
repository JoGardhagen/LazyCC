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
        
            if brightness < 0.18{ return .black}
            if saturation < 0.22{return brightness > 0.65 ? .white : .grey}
            
            switch hue {
            case 0..<16,340...360: return brightness < 0.45 ? .brown : .red
            case 16..<42: return .orange
            case 42..<70: return .yellow
            case 70..<156: return .green
            case 165..<250: return .blue
            case 250..<320: return .violett
            default: return nil
            }
        
        }
    }
