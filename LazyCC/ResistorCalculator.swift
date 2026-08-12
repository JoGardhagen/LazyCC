//
//  ResistorCalculator.swift
//  LazyCC
//
//  Created by Joakim Gårdhagen on 2026-08-12.
//

import Foundation

struct ResistorCalculator {
    static func calculate(band1: ResistorColor,band2: ResistorColor,multiplier: ResistorColor)->String{
        let d1 = band1.digitalValue ?? 0
        let d2 = band2.digitalValue ?? 0
        
        let baseValue = (d1 * 10) + d2
        let totalOhm = Double(baseValue) * multiplier.multiplier
        
        return formatOhm(totalOhm)
    }
    
    private static func formatOhm(_ ohm: Double) -> String {
        if ohm >= 1_000_000 {
            return String(format:"%.1f M-Ohm",ohm/1_000_000)
        }else if ohm >= 1_000 {
            return String(format:"%.1f k-Ohm",ohm/1_000)
        }else {
            return String(format:"%.1f Ohm",ohm)
        }
    }
}
