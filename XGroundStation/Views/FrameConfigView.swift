    //
    //  FrameConfigView.swift
    //  XGroundStation
    //
    //  Created by Ahmed Gaafar on 23/04/2026.
    //


import SwiftUI

struct FrameConfigView: View {
    @ObservedObject var vm: DroneViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Frame Setup").font(.title2).bold()
            
            Text("Select your vehicle frame type below. This affects motor mapping and flight physics.")
                .font(.caption).foregroundColor(.gray)
            
            HStack(spacing: 20) {
                FrameTypeBox(name: "Quad X", icon: "plus.circle", isSelected: vm.system.getParam("FRAME_CLASS") == 1, value: 1, vm: vm)
                FrameTypeBox(name: "Hexa X", icon: "hexagon", isSelected: vm.system.getParam("FRAME_CLASS") == 2, value: 2, vm: vm)
                FrameTypeBox(name: "Y6", icon: "triangle", isSelected: vm.system.getParam("FRAME_CLASS") == 5, value: 5, vm: vm)            }
            Text("Current: \(ArduPilotMapping.frameClass(vm.system.getParam("FRAME_CLASS") ?? 0))")
                .foregroundColor(.qgcAccent)
            
            Spacer()
        }
        .padding(30)
    }
}

struct FrameTypeBox: View {
    let name: String; let icon: String; let isSelected: Bool; let value: Float
    var vm: DroneViewModel
    var body: some View {
        Button(action: {
            vm.system.setParameter(name: "FRAME_CLASS", value: value)
            vm.system.speak("Changing frame class to \(name)")
        }) {
            VStack {
                Image(systemName: icon).font(.system(size: 40))
                Text(name).font(.caption).bold()
            }
            .frame(width: 100, height: 100)
            .background(isSelected ? Color.qgcAccent : Color.white.opacity(0.1))
            .foregroundColor(isSelected ? .black : .white)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}
