    //
    //  FlyViewHUD.swift
    //  XGroundStation
    //
    //  Created by Ahmed Gaafar on 19/04/2026.
    //


import SwiftUI

struct FlyViewHUD: View {
    @ObservedObject var vm: DroneViewModel
    @State private var showConsole = false
    var body: some View {
        ZStack {
            HStack(alignment: .top, spacing: 0) {
                if showConsole {
                    VehicleConsoleView(vm: vm)
                        .transition(.move(edge: .leading))
                }
                Button(action: { withAnimation { showConsole.toggle() } }) {
                    Image(systemName: showConsole ? "chevron.left" : "chevron.right")
                        .font(.system(size: 10, weight: .black))
                        .padding(8)
                        .background(Color.qgcPanelBg)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .offset(x: -10, y: 10)
                
                Spacer()
            }
            .padding(.leading, 10)
            
            if let preArmText = vm.system.latestPreArmMessage {
                PreArmPopupView(message: preArmText) {
                    vm.system.latestPreArmMessage = nil
                }
            }
            
            VStack(alignment: .leading, spacing: 2) {
                ActionTile(icon: "checkmark.circle", label: "Checklist") {}
                ActionTile(icon: vm.system.isArmed ? "lock.open.fill" : "lock.fill",
                           label: vm.system.isArmed ? "DISARM" : "ARM",
                           color: vm.system.isArmed ? .red : .qgcAccent) {
                    vm.system.isArmed ? vm.system.disarm() : vm.system.arm()
                }
                ActionTile(icon: "arrow.up.circle", label: "Takeoff") { vm.system.takeoff() }
                ActionTile(icon: "arrow.uturn.down.circle", label: "Return") { vm.system.setFlightMode(.rtl) }
            }
            .padding(10)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            
            VStack(alignment: .trailing, spacing: 5) {
                Spacer()
                
                HStack{
                    ArtificialHorizonView(pitch: vm.system.pitch, roll: vm.system.roll)
                        .frame(width: 120, height: 120)
                    
                    VStack(spacing: 0) {
                        TelemetryRow(label: "ALT", value: String(format: "%.1f", vm.system.altitude), unit: "m")
                        TelemetryRow(label: "SPD", value: String(format: "%.1f", vm.system.groundSpeed), unit: "m/s")
                        TelemetryRow(label: "BAT", value: String(format: "%.1f", vm.system.batteryVoltage), unit: "V", isLast: true)
                        TelemetryRow(label: "HOME", value: String(format: "%.0f", vm.system.distanceToHome), unit: "m")
                    }
                    .frame(width: 160)
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(4)
                    .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.white.opacity(0.2), lineWidth: 1))
                    ZStack {
                        Circle().stroke(Color.white.opacity(0.2), lineWidth: 4)
                        ForEach(0..<4) { i in
                            Text(["N","E","S","W"][i]).font(.caption2.bold())
                                .offset(y: -30).rotationEffect(.degrees(Double(i) * 90))
                        }
                        Image(systemName: "arrow.up").foregroundColor(.red).font(.title3.bold())
                    }
                    .rotationEffect(.degrees(Double(-vm.system.heading)))
                    .frame(width: 80, height: 80)
                    .background(Circle().fill(Color.black.opacity(0.6)))
                    
                    
                    
                }
                .padding(15)
            }
            .padding(15)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
        }
    }
}
