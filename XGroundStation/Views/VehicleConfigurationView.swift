    //
    //  VehicleConfigurationView.swift
    //  XGroundStation
    //
    //  Created by Ahmed Gaafar on 23/04/2026.
    //


import SwiftUI

enum ConfigPage {
    case summary, frame, radio, parameters, motors, firmware, analyze, tuning, console, replay ,flightModes, sensors
}

struct VehicleConfigurationView: View {
    @ObservedObject var vm: DroneViewModel
    @State private var currentPage: ConfigPage = .summary
    
    var body: some View {
        VStack(spacing: 0) {
            
            HStack {
                Button(action: {
                    withAnimation { vm.currentMode = .fly }
                }) {
                    HStack(spacing: 5) {
                        Image(systemName: "chevron.left")
                        Text("Exit Vehicle Configuration")
                    }
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 15)
                    .frame(maxHeight: .infinity)
                    .background(Color.white.opacity(0.1))
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                if !vm.system.isConnected {
                    Text("VEHICLE DISCONNECTED").foregroundColor(.red).font(.caption).bold().padding(.trailing)
                }
            }
            .frame(height: 40)
            .background(Color.qgcTopBar)
            .border(Color.black, width: 1)
            
            HStack(spacing: 0) {
                
                VStack(alignment: .leading, spacing: 0) {
                    ConfigSidebarItem(title: "Summary", icon: "paperplane.fill", isSelected: currentPage == .summary) { currentPage = .summary }
                    ConfigSidebarItem(title: "Frame", icon: "gearshape.2", isSelected: currentPage == .frame) { currentPage = .frame }
                    
                    ConfigSidebarItem(title: "Radio", icon: "antenna.radiowaves.left.and.right", isSelected: currentPage == .radio) { currentPage = .radio }
                    ConfigSidebarItem(title: "Motors", icon: "arrow.up", isSelected: currentPage == .motors) { currentPage = .motors }
                    
                    ConfigSidebarItem(title: "Parameters", icon: "list.bullet", isSelected: currentPage == .parameters) { currentPage = .parameters }
                    ConfigSidebarItem(title: "Firmware", icon: "externaldrive.fill.badge.plus", isSelected: currentPage == .firmware) { currentPage = .firmware }
                    ConfigSidebarItem(title: "HealthDashboardView", icon: "heart.fill", isSelected: currentPage == .analyze) { currentPage = .analyze }
                    ConfigSidebarItem(title: "Sensors", icon: "dot.radiowaves.left.and.right", isSelected: currentPage == .sensors) { currentPage = .sensors }
                    ConfigSidebarItem(title: "Live Tuning", icon: "waveform.path.ecg", isSelected: currentPage == .tuning) { currentPage = .tuning }
                    ConfigSidebarItem(title: "Console", icon: "terminal", isSelected: currentPage == .console) { currentPage = .console }
                    ConfigSidebarItem(title: "Log Replay", icon: "arrow.clockwise.circle", isSelected: currentPage == .replay) { currentPage = .replay }
                    
                    Spacer()
                    Spacer()
                }
                .frame(width: 180)
                .background(Color.qgcMainBg)
                
                
                ScrollView {
                    VStack {
                        switch currentPage {
                        case .summary:
                            SummaryGridView(vm: vm)
                        case .frame:
                            FrameConfigView(vm: vm)
                        case .radio:
                            RadioConfigView(vm: vm)
                        case .parameters:
                            ParameterListView(vm: vm)
                        case .motors: MotorTestView(vm: vm)
                        case .firmware: FirmwareView(vm: vm)
                            
                        case .sensors: CompassCalView(vm: vm)
                        case .analyze: HealthDashboardView(vm: vm)
                        case .tuning: TuningView(vm: vm)       
                        case .console: MAVLinkConsoleView(vm: vm)
                        case .replay: LogReplayView(vm: vm)
                        default:
                            Text("Page Under Construction").foregroundColor(.gray).padding()
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .background(Color(white: 0.12))
            }
        }
    }
}

struct SidebarItem: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .frame(width: 20)
                
                Text(title.uppercased())
                    .font(.system(size: 11, weight: isSelected ? .black : .regular))
            }
            .padding(.leading, 15)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 35)
            .background(isSelected ? Color.qgcAccent : Color.clear)
            .foregroundColor(isSelected ? .black : .white)
        }
        .buttonStyle(.plain)
    }
}

struct ConfigSidebarItem: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .frame(width: 20)
                
                Text(title.uppercased())
                    .font(.system(size: 11, weight: isSelected ? .black : .regular))
            }
            .padding(.leading, 15)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 40)
            .background(isSelected ? Color.qgcAccent : Color.clear)
            .foregroundColor(isSelected ? .black : .white)
        }
        .buttonStyle(.plain)
    }
}
