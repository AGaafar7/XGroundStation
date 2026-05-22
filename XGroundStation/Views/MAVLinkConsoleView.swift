//
//  MAVLinkConsoleView.swift
//  XGroundStation
//
//  Created by Ahmed Gaafar on 23/05/2026.
//

import SwiftUI
import Foundation
import AVFoundation
import Network

struct MAVLinkConsoleView: View {
    @ObservedObject var vm: DroneViewModel
    @State private var cmd = ""
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("System Terminal").font(.headline).padding()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(vm.system.messages) { msg in
                        Text(msg.text)
                            .foregroundColor(msg.color)
                            .font(.system(size: 11, design: .monospaced))
                    }
                }
                .padding()
            }
            .background(Color.black)
            
            HStack {
                TextField("Enter NSH Command...", text: $cmd)
                    .textFieldStyle(.plain)
                    .padding(8)
                    .background(Color.white.opacity(0.1))
                Button("SEND") { cmd = "" } // Logic for raw commands
            }
            .padding()
        }
    }
}
