//
//  ResistorCalculator.swift
//  LazyCC
//
//  Created by Joakim Gårdhagen on 2026-08-12.
//

import Foundation

struct ResistorCalculator{
    
    static func calculate(bands: [ResistorColor]) -> String {
        guard bands.count >= 3 else {return "Siktar. . ."}
        
        if bands.count >= 5 {
            guard let d1 = bands[0].digitalValue,
                  let d2 = bands[1].digitalValue,
                  let d3 = bands[2].digitalValue else {return "Ogiltig ring"}
            
            let baseValue = Double(d1 * 100 + d2 * 10 + d3)
            let multiplier = bands[3].multiplier
            let totalOhms = baseValue * multiplier
            
            let tolerance = toleranceString(for: bands[4])
            return formatOhms(totalOhms) + " " + tolerance
            
        }
        
        else {
            guard let d1 = bands[0].digitalValue,
                  let d2 = bands[1].digitalValue else {return "Ogiltig ring"}
            
            let baseValue = Double(d1 * 10 + d2)
            let multiplier = bands[2].multiplier
            let totalOhms = baseValue * multiplier
            
            var tolerance = ""
            if bands.count == 4 {
                tolerance = toleranceString(for: bands[3])
            }
            
            return formatOhms(totalOhms) + (tolerance.isEmpty ? "" : " " + tolerance)
        }
    }
    
    private static func formatOhms(_ ohms: Double) -> String {
        if ohms >= 1_000_000 {
            let val = ohms / 1_000_000
            return String(format: val.truncatingRemainder(dividingBy: 1) == 0 ? "%.0f MOhm" : "%.2f Mohm",val)
        }else if ohms >= 1_000 {
            let val = ohms / 1_000
            return String(format: val.truncatingRemainder(dividingBy: 1) == 0 ? "%.0f kOhm" : "%.2f kOhm",val)
        }else {
            return String(format: ohms.truncatingRemainder(dividingBy: 1) == 0 ? "%.0f Ohms" : "%.1f Ohms",ohms)
        }
    }
    
    private static func toleranceString(for color: ResistorColor) -> String {
        switch color {
        case .brun: return "±1%"
        case .röd: return "±2%"
        case .grön: return "±0.5%"
        case .blå: return "±0.25%"
        case .violett: return "±0.1%"
        case .grå: return "±0.05%"
        case .guld: return "±5%"
        case .silver: return "±10%"
        default: return ""
        }
    }
}
