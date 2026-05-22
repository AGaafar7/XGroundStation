    //
    //  FirmwareView.swift
    //  XGroundStation
    //
    //  Created by Ahmed Gaafar on 23/04/2026.
    //

import SwiftUI

struct FirmwareView: View {
    @ObservedObject var vm: DroneViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Firmware Information").font(.title).bold()
            
            SummaryCard(title: "Autopilot Details", status: .blue) {
                SummaryRow(label: "Type", value: "ArduPilot (ArduCopter)")
                SummaryRow(label: "Mavlink Version", value: "2.0")
                SummaryRow(label: "Board ID", value: "Pixhawk / Cube")
            }
            
            Button(action: { vm.system.rebootToBootloader() }) { 
                Text("REBOOT VEHICLE").foregroundColor(.red).padding().border(Color.red)
            }.buttonStyle(.plain)
            
            Text("To flash new firmware, connect via USB and ensure no other GCS is running.")
                .font(.caption).foregroundColor(.gray)
        }.padding(40)
    }
}
