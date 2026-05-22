//
//  TuningView.swift
//  XGroundStation
//
//  Created by Ahmed Gaafar on 23/05/2026.
//


import SwiftUI
import Charts

struct TuningView: View {
    @ObservedObject var vm: DroneViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Real-time Tuning").font(.title2).bold()
            
            Chart {
                let history = vm.system.pitchHistory
                ForEach(0..<history.count, id: \.self) { index in
                    LineMark(
                        x: .value("Time", index),
                        y: .value("Pitch", history[index])
                    )
                    .foregroundStyle(.red)
                }
            }
            .frame(height: 300)
            .chartYScale(domain: -30...30)
            .background(Color.black.opacity(0.3))
            .chartXAxis(.hidden)
            
            HStack {
                Circle().fill(.red).frame(width: 10, height: 10)
                Text("Pitch Degrees").font(.caption).foregroundColor(.gray)
                Spacer()
                Text("Last: \(String(format: "%.1f°", vm.system.pitch))")
                    .font(.system(.caption, design: .monospaced))
            }

        }
        .padding(30)
    }
}
