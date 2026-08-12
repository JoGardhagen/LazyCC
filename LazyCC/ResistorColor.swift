//
//  ResistorColor.swift
//  LazyCC
//
//  Created by Joakim Gårdhagen on 2026-08-11.
//
import SwiftUI

enum ResistorColor: String, CaseIterable, Identifiable {
    case black = "Svart"
    case brown = "Brun"
    case red = "Röd"
    case orange = "Orange"
    case yellow = "Gul"
    case green = "Grön"
    case blue = "Blå"
    case violett = "Violett"
    case grey = "Grå"
    case white = "Vit"
    case gold = "Guld"
    case silver = "Silver"
    
    var id: String { self.rawValue }
    
    var digitalValue: Int? {
        switch self {
        case .black: return 0
        case .brown: return 1
        case .red: return 2
        case .orange: return 3
        case .yellow: return 4
        case .green: return 5
        case .blue: return 6
        case .violett: return 7
        case .grey: return 8
        case .white: return 9
        case .gold, .silver: return nil
        }
    }
    
    var multiplier: Double {
        switch self {
        case .black: return 1.0
        case .brown: return 10.0
        case .red: return 100.0
        case .orange: return 1_000.0
        case .yellow: return 10_000.0
        case .green: return 100_000.0
        case .blue: return 1_000_000.0
        case .violett: return 10_000_000.0
        case .grey: return 100_000_000.0
        case .white: return 1_000_000_000.0
        case .gold: return 0.1
        case .silver: return 0.01
        }
    }
    
    var color: Color {
        switch self {
        case .black: return .black
        case .brown: return .brown
        case .red: return .red
        case .orange: return .orange
        case .yellow: return .yellow
        case .green: return .green
        case .blue: return .blue
        case .violett: return .purple
        case .grey: return .gray
        case .white: return .white
        case .gold: return Color(red:0.85,green: 0.65,blue: 0.13)
        case .silver: return Color(red:0.75,green: 0.75,blue: 0.75)
        
        }
    }
    
}
