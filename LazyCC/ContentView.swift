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
    
    var body: some View {
        ZStack {
                    // 2. Kameraströmmen fyller hela bakgrunden
                    CameraPreview(session: camera.session)
                        .ignoresSafeArea()
                    
                    // 3. Sikte i mitten av skärmen
                    VStack {
                        Spacer()
                        
                        ZStack {
                            Circle()
                                .stroke(Color.red, lineWidth: 2)
                                .frame(width: 30, height: 30)
                            
                            Circle()
                                .fill(Color.red)
                                .frame(width: 4, height: 4)
                        }
                        
                        Text("Rikta siktet mot en färgring")
                            .font(.caption)
                            .bold()
                            .padding(6)
                            .background(Color.black.opacity(0.7))
                            .foregroundColor(.white)
                            .cornerRadius(6)
                        
                        Spacer()
                    }
                    
                    // 4. Kontrollpanelen längst ner på skärmen
                    VStack {
                        Spacer()
                        
                        VStack(spacing: 15) {
                            // Resultat från kalkylatorn
                            Text(ResistorCalculator.calculate(band1: band1, band2: band2, multiplier: multiplier))
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.blue)

                            // Menyer för att fortfarande kunna ändra manuellt
                            HStack {
                                Picker("Ring 1", selection: $band1) {
                                    ForEach(ResistorColor.allCases) { color in
                                        Text(color.rawValue).tag(color)
                                    }
                                }
                                
                                Picker("Ring 2", selection: $band2) {
                                    ForEach(ResistorColor.allCases) { color in
                                        Text(color.rawValue).tag(color)
                                    }
                                }
                                
                                Picker("Mult", selection: $multiplier) {
                                    ForEach(ResistorColor.allCases) { color in
                                        Text(color.rawValue).tag(color)
                                    }
                                }
                            }
                            .pickerStyle(.menu)
                        }
                        .padding()
                        .background(.ultraThinMaterial) // Halvgenomskinlig frosted-glass effekt
                        .cornerRadius(16)
                        .padding(.horizontal)
                        .padding(.bottom, 10)
                    }
                }
                // 5. Starta kameran när vyn visas, och stoppa den när vyn försvinner
                .onAppear {
                    camera.start()
                }
                .onDisappear {
                    camera.stop()
                }
    }
}

#Preview {
    ContentView()
}
