//
//  ContentView.swift
//  LazyCC
//
//  Created by Joakim Gårdhagen on 2026-08-09.
//

import SwiftUI

struct ContentView: View {
    
    @State private var camera = CameraManager()
    
    @State private var band1: ResistorColor = .brown
    @State private var band2: ResistorColor = .black
    @State private var multiplier: ResistorColor = .red
    
    @State private var activeBandIndex: Int = 1
    
    @State private var zoomLevel: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            CameraPreview(session: camera.session)
                .ignoresSafeArea()
            
            // 2. Mitten-området med sikte och Zoom-sidebar
            HStack {
                Spacer() // Skjut siktet till mitten
                
                // --- Siktet (Rektangel) ---
                VStack(spacing: 10) {
                    // Visar live-etiketten OVANFÖR rektangeln
                    if let liveColor = camera.detectedColor {
                        Text("Ser: \(liveColor.rawValue)")
                            .font(.caption)
                            .bold()
                            .padding(6)
                            .background(liveColor.color)
                            .foregroundColor(.white)
                            .cornerRadius(6)
                    }
                    
                    // Själva siktet: En avlång röd rektangel
                    Rectangle()
                        .stroke(Color.red, lineWidth: 3)
                        .frame(width: 80, height: 40) // Passar bra för en färgring
                }
                
                Spacer() // Skjut siktet till mitten
                
                // --- Zoom Sidebar (Vertikal Slider) ---
                VStack {
                    Image(systemName: "plus.magnifyingglass")
                        .foregroundColor(.white)
                    
                    // En vertikal slider
                    Slider(value: $zoomLevel, in: 1.0...5.0, step: 0.1)
                        .rotationEffect(.degrees(-90)) // Gör slidern vertikal
                        .frame(width: 150, height: 40) // Justera ramen efter rotationen
                        .accentColor(.white)
                    // 3. När slidern ändras -> uppdatera kameran
                        .onChange(of: zoomLevel) { _, newValue in
                            camera.setZoom(factor: newValue)
                        }
                    
                    Image(systemName: "minus.magnifyingglass")
                        .foregroundColor(.white)
                    
                    Text(String(format: "%.1fx", zoomLevel))
                        .font(.caption2)
                        .foregroundColor(.white)
                        .bold()
                }
                .padding(.vertical, 30)
                .padding(.horizontal, 8)
                .background(Color.black.opacity(0.5))
                .cornerRadius(40)
                .padding(.trailing, 10) // Lite marginal från kanten
            }
            
            // 4. Kontrollpanelen längst ner (Samma som tidigare)
            VStack {
                Spacer()
                VStack(spacing: 12) {
                    Text(ResistorCalculator.calculate(band1: band1, band2: band2, multiplier: multiplier))
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.blue)
                    
                    Button(action: scanCurrentColor) {
                        HStack {
                            Image(systemName: "camera.viewfinder")
                            Text("Spara till Ring \(activeBandIndex)")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(12)
                    }
                    
                    HStack {
                        Picker("Ring 1", selection: $band1) {
                            ForEach(ResistorColor.allCases) { color in Text(color.rawValue).tag(color) }
                        }
                        Picker("Ring 2", selection: $band2) {
                            ForEach(ResistorColor.allCases) { color in Text(color.rawValue).tag(color) }
                        }
                        Picker("Mult", selection: $multiplier) {
                            ForEach(ResistorColor.allCases) { color in Text(color.rawValue).tag(color) }
                        }
                    }
                    .pickerStyle(.menu)
                }
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(20)
                .padding(.horizontal)
                .padding(.bottom, 10)
            }
        }
        .onAppear {
            camera.start()
            // Säkerställ att zoomen är återställd när vi startar
            camera.setZoom(factor: 1.0)
        }
        .onDisappear { camera.stop() }
    }
    
    private func scanCurrentColor() {
        guard let scannedColor = camera.detectedColor else { return }
        
        switch activeBandIndex {
        case 1: band1 = scannedColor; activeBandIndex = 2
        case 2: band2 = scannedColor; activeBandIndex = 3
        case 3: multiplier = scannedColor; activeBandIndex = 1
        default: break
        }
    }
}

#Preview {
    ContentView()
}
