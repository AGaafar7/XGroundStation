    //
    //  CompassCalView.swift
    //  XGroundStation
    //
    //  Created by Ahmed Gaafar on 23/04/2026.
    //

import SwiftUI

struct CompassCalView: View {
    @ObservedObject var vm: DroneViewModel
    
    var body: some View {
        VStack(spacing: 30) {
            Text("Onboard Compass Calibration").font(.title).bold()
            
            ZStack {
                Circle().stroke(Color.white.opacity(0.1), lineWidth: 20)
                Circle()
                    .trim(from: 0, to: CGFloat(vm.system.magCalProgress[0] ?? 0))
                    .stroke(Color.qgcAccent, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                
                VStack {
                    Text("\(Int((vm.system.magCalProgress[0] ?? 0) * 100))%")
                        .font(.system(size: 40, weight: .black, design: .monospaced))
                }
            }
            .frame(width: 200, height: 200)
            
            VStack(alignment: .leading, spacing: 10) {
                ForEach(vm.system.magCalProgress.keys.sorted(), id: \.self) { id in
                    HStack {
                        Text("Compass \(id)")
                        ProgressView(value: vm.system.magCalProgress[id] ?? 0)
                            .tint(.green)
                    }
                }
            }
            .frame(width: 300)
            
            Button("START CALIBRATION") {
                vm.system.startCompassCal()
            }
            .buttonStyle(.borderedProminent).tint(.qgcAccent)
            .disabled(vm.system.isCalibratingCompass)
        }
        .padding(40)
    }
}
