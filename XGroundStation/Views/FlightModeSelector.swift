    //
    //  FlightModeSelector.swift
    //  XGroundStation
    //
    //  Created by Ahmed Gaafar on 20/04/2026.
    //


import SwiftUI

struct FlightModeSelector: View {
    @ObservedObject var vm: DroneViewModel
    let modes: [(name: String, mode: ArduCopterMode)] = [
        ("Stabilize", .stabilize),
        ("Altitude Hold", .altHold),
        ("Auto", .auto),
        ("Loiter", .loiter),
        ("RTL", .rtl),
        ("Land", .land),
        ("Position Hold", .posHold),
        ("Avoid ADSB", .drift),
        ("Smart RTL", .brake)
    ]
    
    var body: some View {
        VStack(spacing: 1) {
            ForEach(modes, id: \.name) { item in
                Button(action: {
                    vm.system.setFlightMode(item.mode)
                    withAnimation { vm.showModeMenu = false }
                }) {
                    Text(item.name)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(vm.system.flightMode == item.name.uppercased() ? Color.qgcAccent.opacity(0.3) : Color.white.opacity(0.05))
                }
                .buttonStyle(.plain)
                Divider().background(Color.white.opacity(0.1))
            }
            
            Text("Some Modes Hidden")
                .font(.system(size: 8))
                .foregroundColor(.gray)
                .padding(.vertical, 4)
        }
        .frame(width: 120)
        .background(Color(red: 0.15, green: 0.15, blue: 0.15))
        .cornerRadius(4)
        .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.white.opacity(0.2), lineWidth: 1))
        .shadow(radius: 10)
    }
}
