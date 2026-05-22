//
//  ArtificialHorizonView.swift
//  XGroundStation
//
//  Created by Ahmed Gaafar on 24/04/2026.
//


import SwiftUI

struct ArtificialHorizonView: View {
    let pitch: Float
    let roll: Float
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                Color.blue.frame(height: 300)
                Rectangle().fill(.white).frame(height: 2)
                Color.brown.frame(height: 300)
            }
            .offset(y: CGFloat(pitch * 2.5))
            .rotationEffect(.degrees(Double(-roll)))
        
            VStack(spacing: 25) {
                ForEach([-20, -10, 10, 20], id: \.self) { deg in
                    HStack {
                        Rectangle().fill(.white).frame(width: 40, height: 1)
                        Text("\(abs(deg))").font(.system(size: 8)).foregroundColor(.white)
                        Rectangle().fill(.white).frame(width: 40, height: 1)
                    }
                }
            }
            .rotationEffect(.degrees(Double(-roll)))
            .offset(y: CGFloat(pitch * 2.5))
            
            Path { path in
                path.move(to: CGPoint(x: 30, y: 75)); path.addLine(to: CGPoint(x: 65, y: 75))
                path.move(to: CGPoint(x: 85, y: 75)); path.addLine(to: CGPoint(x: 120, y: 75))
                path.move(to: CGPoint(x: 75, y: 75)); path.addLine(to: CGPoint(x: 75, y: 85))
            }
            .stroke(Color.qgcAccent, lineWidth: 3)
        }
        .frame(width: 150, height: 150)
        .clipShape(Circle())
        .overlay(Circle().stroke(Color.white.opacity(0.5), lineWidth: 2))
    }
}
