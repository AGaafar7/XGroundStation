    //
    //  VehicleConsoleView.swift
    //  XGroundStation
    //
    //  Created by Ahmed Gaafar on 23/04/2026.
    //


import SwiftUI

struct VehicleConsoleView: View {
    @ObservedObject var vm: DroneViewModel
    let df: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        return f
    }()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            
            HStack {
                Button(action: { vm.system.isArmed ? vm.system.disarm() : vm.system.arm() }) {
                    Text(vm.system.isArmed ? "Disarm" : "Arm")
                        .font(.system(size: 12, weight: .bold))
                        .padding(.horizontal, 15)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(4)
                }
                .buttonStyle(.plain)
                Spacer()
            }
            .padding(10)
            
            Text("Vehicle Messages")
                .font(.system(size: 14, weight: .medium))
                .padding(.horizontal, 10)
                .padding(.bottom, 5)
            
            
            ScrollView {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(vm.system.messages) { msg in
                        HStack(alignment: .top, spacing: 4) {
                            Text("[\(df.string(from: msg.timestamp))]")
                                .foregroundColor(.gray)
                            Text(msg.text)
                                .foregroundColor(msg.color)
                        }
                        .font(.system(size: 11, design: .monospaced))
                        .padding(.horizontal, 5)
                    }
                }
            }
            .frame(maxHeight: 300)
            .background(Color.black.opacity(0.3))
            .cornerRadius(4)
            .padding(10)
            
            
            VStack(alignment: .leading, spacing: 5) {
                Text("Sensor Status").font(.system(size: 12))
                
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.1)).frame(height: 12)
                    Capsule()
                        .fill(Color.green.opacity(0.6))
                        .frame(width: 260 * CGFloat(vm.system.paramLoadProgress), height: 12)
                }
            }
            .padding(10)
        }
        .frame(width: 280)
        .background(Color.black.opacity(0.7))
        .cornerRadius(8)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.1), lineWidth: 1))
    }
}
