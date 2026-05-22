    //
    //  SummaryGridView.swift
    //  XGroundStation
    //
    //  Created by Ahmed Gaafar on 23/04/2026.
    //


import SwiftUI

struct SummaryGridView: View {
    @ObservedObject var vm: DroneViewModel
    let columns = [GridItem(.flexible(), spacing: 15), GridItem(.flexible(), spacing: 15)]
    
    var body: some View {
        VStack {
            LazyVGrid(columns: columns, spacing: 15) {
                SummaryCard(title: "Frame", status: vm.system.isConnected ? .green : .red) {
                    if !vm.system.isConnected {
                        Text("No Vehicle Connected").foregroundColor(.red).font(.caption)
                    } else if vm.system.isLoadingParams {
                        ProgressView().scaleEffect(0.5)
                        Text("Syncing...").font(.caption).foregroundColor(.yellow)
                    } else {
                        let fClass = vm.system.getParam("FRAME_CLASS") ?? 0
                        SummaryRow(label: "Frame Class", value: ArduPilotMapping.frameClass(fClass))
                        
                        let fType = vm.system.getParam("FRAME_TYPE") ?? 0
                        SummaryRow(label: "Frame Type", value: ArduPilotMapping.frameType(fType))
                    }
                }
                SummaryCard(title: "Radio", status: vm.system.rcChannels[0] > 0 ? .green : .red) {
                    SummaryRow(label: "Roll", value: "Channel 1")
                    SummaryRow(label: "Pitch", value: "Channel 2")
                    SummaryRow(label: "Throttle", value: "Channel 3")
                    SummaryRow(label: "Yaw", value: "Channel 4")
                }
                
                
                SummaryCard(title: "Flight Modes", status: .green) {
                    ForEach(1...3, id: \.self) { i in
                        let modeVal = vm.system.getParam("FLTMODE\(i)") ?? 0
                        SummaryRow(label: "Mode \(i)", value: vm.system.getArduCopterModeName(UInt32(modeVal)))
                    }
                }
                
                
                SummaryCard(title: "Sensors", status: .green) {
                    let compass = vm.system.getParam("MAG_ENABLE") ?? 0
                    SummaryRow(label: "Compass", value: compass == 1 ? "Enabled" : "Disabled")
                    let primaryMag = vm.system.getParam("COMPASS_PRIMARY") ?? 0
                    SummaryRow(label: "Primary Mag", value: "ID: \(Int(primaryMag))")
                }
                
                
                SummaryCard(title: "Power", status: .gray) {
                    let monitor = vm.system.getParam("BATT_MONITOR") ?? 0
                    let capacity = vm.system.getParam("BATT_CAPACITY") ?? 0
                    SummaryRow(label: "Monitor", value: monitor > 0 ? "Enabled" : "Disabled")
                    SummaryRow(label: "Capacity", value: "\(Int(capacity)) mAh")
                }
                
                
                SummaryCard(title: "Safety", status: .green) {
                    let fence = vm.system.getParam("FENCE_ENABLE") ?? 0
                    SummaryRow(label: "GeoFence", value: fence == 1 ? "Enabled" : "Disabled")
                    let rtlAlt = vm.system.getParam("RTL_ALT") ?? 0
                    SummaryRow(label: "RTL Altitude", value: "\(Int(rtlAlt / 100)) m")
                }
            }
            .padding(20)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}


struct SummaryCard<Content: View>: View {
    let title: String
    let status: Color
    let content: Content
    
    init(title: String, status: Color, @ViewBuilder content: () -> Content) {
        self.title = title
        self.status = status
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            
            HStack {
                Text(title.uppercased())
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white.opacity(0.9))
                Spacer()
                Circle()
                    .fill(status)
                    .frame(width: 8, height: 8)
                    .shadow(color: status.opacity(0.5), radius: 2)
            }
            .padding(.horizontal, 12)
            .frame(height: 30)
            .background(Color.white.opacity(0.08))
            
            
            VStack(alignment: .leading, spacing: 8) {
                content
            }
            .padding(12)
        }
        .background(Color(white: 0.15))
        .cornerRadius(2)
        .overlay(RoundedRectangle(cornerRadius: 2).stroke(Color.white.opacity(0.1), lineWidth: 0.5))
    }
}

struct SummaryRow: View {
    let label: String
    let value: String
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.gray)
            Spacer()
            Text(value)
                .foregroundColor(.white)
                .fontWeight(.medium)
        }
        .font(.system(size: 11, design: .monospaced)) 
    }
}
