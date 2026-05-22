    //
    //  HealthDashboardView.swift
    //  XGroundStation
    //
    //  Created by Ahmed Gaafar on 23/04/2026.
    //

import SwiftUI

struct HealthDashboardView: View {
    @ObservedObject var vm: DroneViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("M4 System Health").font(.title2).bold()
            
            VStack(spacing: 15) {
                VibrationBar(label: "Vib X", value: vm.system.vibX)
                VibrationBar(label: "Vib Y", value: vm.system.vibY)
                VibrationBar(label: "Vib Z", value: vm.system.vibZ)
            }
            .padding()
            .background(Color.black.opacity(0.3))
            
            HStack {
                Text("Clip Count:")
                Text("\(vm.system.clip0)")
                    .foregroundColor(vm.system.clip0 > 0 ? .red : .green)
                    .monospaced()
            }
            
            if vm.system.vibX > 30 {
                Text("⚠️ CRITICAL VIBRATION DETECTED").foregroundColor(.red).bold()
            }
        }
        .padding(30)
    }
}

struct VibrationBar: View {
    let label: String; let value: Float
    var body: some View {
        HStack {
            Text(label).frame(width: 50, alignment: .leading)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle().fill(Color.white.opacity(0.1))
                    Rectangle()
                        .fill(value > 30 ? Color.red : Color.green)
                        .frame(width: geo.size.width * CGFloat(min(value/60.0, 1.0)))
                }
            }.frame(height: 10)
            Text(String(format: "%.1f", value)).frame(width: 40)
        }
    }
}
