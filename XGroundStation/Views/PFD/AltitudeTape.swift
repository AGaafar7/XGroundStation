//
//  AltitudeTape.swift
//  XGroundStation
//
//  Created by Ahmed Gaafar on 22/05/2026.
//


import SwiftUI

struct AltitudeTape: View {
    let altitude: Float
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                // Background
                Color.black.opacity(0.5).frame(width: 60, height: 250)
                
                // The Ticks
                VStack(spacing: 20) {
                    ForEach(0..<20) { i in
                        let val = (Int(altitude) / 10) * 10 + (10 - i) * 10
                        HStack {
                            Text("\(val)").font(.system(size: 10, design: .monospaced))
                            Rectangle().fill(.white).frame(width: 10, height: 1)
                        }
                    }
                }
                .offset(y: CGFloat(fmod(altitude, 10.0) * 2.0)) // Smooth scrolling
                
                // Current Value Box
                ZStack {
                    Rectangle().fill(.red).frame(width: 70, height: 25)
                    Text("\(Int(altitude))").bold().foregroundColor(.white)
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}