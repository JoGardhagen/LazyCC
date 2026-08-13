//
//  ContentView.swift
//  LazyCC
//
//  Created by Joakim Gårdhagen on 2026-08-09.
//

import SwiftUI

struct ContentView: View {
    @State private var camera = CameraManager()
    @State private var zoomLevel: CGFloat = 1.0

    var body: some View {
        ZStack {
            // 1. Kamerabakgrund
            CameraPreview(session: camera.session)
                .ignoresSafeArea()
            
            // 2. Sikte och automatiskt avlästa ringar i mitten
            aimingSight
            
            // 3. Zoom-slider på höger sida
            HStack {
                Spacer()
                VStack {
                    Image(systemName: "plus.magnifyingglass")
                        .foregroundColor(.white)
                    
                    Slider(value: $zoomLevel, in: 1.0...6.0, step: 0.1)
                        .rotationEffect(.degrees(-90))
                        .frame(width: 50, height: 100)
                        .accentColor(.white)
                        .onChange(of: zoomLevel) { _, newValue in
                            camera.setZoom(factor: newValue)
                        }
                    
                    Image(systemName: "minus.magnifyingglass")
                        .foregroundColor(.white)
                }
                .padding(.vertical, 25)
                .padding(.horizontal, 6)
                .background(Color.black.opacity(0.5))
                .cornerRadius(30)
                .padding(.trailing, 10)
            }
            
            // 4. Live-resultat längst ner
            VStack {
                Spacer()
                
                VStack(spacing: 8) {
                    Text("AUTOMATISK AVLÄSNING")
                        .font(.caption2)
                        .bold()
                        .foregroundColor(.gray)
                    
                    Text(camera.calculatedValue)
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.green)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(.ultraThinMaterial)
                .cornerRadius(20)
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
        }
        .onAppear {
            camera.start()
            camera.setZoom(factor: 1.0)
        }
        .onDisappear { camera.stop() }
    }
    
    // Centrerat sikte som visar vilka ringar kameran upptäckt just nu
    var aimingSight: some View {
        VStack(spacing: 12) {
            // Visa upptäckta färgringar som små bubblor ovanför rektangeln
            HStack(spacing: 8) {
                ForEach(0..<camera.detectedBands.count, id: \.self) { i in
                    let band = camera.detectedBands[i]
                    Text(band.rawValue)
                        .font(.caption2)
                        .bold()
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(band.color)
                        .foregroundColor(.white)
                        .cornerRadius(6)
                }
            }
            .frame(height: 25)

            // Rektangeln där motståndet ska placeras vågrätt
            Rectangle()
                .stroke(Color.red, lineWidth: 3)
                .frame(width: 140, height: 40)
                .overlay(
                    // En streckad linje som visar var koden scannar
                    Rectangle()
                        .fill(Color.red.opacity(0.4))
                        .frame(height: 2)
                )
        }
    }
}
#Preview {
    ContentView()
}
