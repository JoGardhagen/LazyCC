//
//  ResistorColor.swift
//  LazyCC
//
//  Created by Joakim Gårdhagen on 2026-08-11.
//
import SwiftUI

enum ResistorColor: String, CaseIterable, Identifiable {
    case svart = "Svart"
    case brun = "Brun"
    case röd = "Röd"
    case orange = "Orange"
    case gul = "Gul"
    case grön = "Grön"
    case blå = "Blå"
    case violett = "Violett"
    case grå = "Grå"
    case vit = "Vit"
    case guld = "Guld"
    case silver = "Silver"
    
    var id: String { self.rawValue }
    
    var digitalValue: Int? {
        switch self {
        case .svart: return 0
        case .brun: return 1
        case .röd: return 2
        case .orange: return 3
        case .gul: return 4
        case .grön: return 5
        case .blå: return 6
        case .violett: return 7
        case .grå: return 8
        case .vit: return 9
        case .guld, .silver: return nil
        }
    }
    
    var multiplier: Double {
        switch self {
        case .svart: return 1.0
        case .brun: return 10.0
        case .röd: return 100.0
        case .orange: return 1_000.0
        case .gul: return 10_000.0
        case .grön: return 100_000.0
        case .blå: return 1_000_000.0
        case .violett: return 10_000_000.0
        case .grå: return 100_000_000.0
        case .vit: return 1_000_000_000.0
        case .guld: return 0.1
        case .silver: return 0.01
        }
    }
    
    var color: Color {
        switch self {
        case .svart: return .black
        case .brun: return .brown
        case .röd: return .red
        case .orange: return .orange
        case .gul: return .yellow
        case .grön: return .green
        case .blå: return .blue
        case .violett: return .purple
        case .grå: return .gray
        case .vit: return .white
        case .guld: return Color(red: 0.85, green: 0.65, blue: 0.13)
        case .silver: return Color(red: 0.75, green: 0.75, blue: 0.75)
        
        }
    }
    
}
