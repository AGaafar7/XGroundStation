    //
    //  MessageConsoleView.swift
    //  XGroundStation
    //
    //  Created by Ahmed Gaafar on 23/04/2026.
    //


import SwiftUI

struct MessageConsoleView: View {
    @ObservedObject var vm: DroneViewModel
    let df: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        return f
    }()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Vehicle Messages").font(.system(size: 11, weight: .bold))
                Spacer()
                Button(action: { vm.system.messages.removeAll() }) {
                    Image(systemName: "trash").font(.caption)
                }.buttonStyle(.plain)
            }
            .padding(10)
            .background(Color.white.opacity(0.05))
            
            ScrollView {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(vm.system.messages) { msg in
                        HStack(alignment: .top, spacing: 5) {
                            Text("[\(df.string(from: msg.timestamp))]")
                                .foregroundColor(.gray)
                            Text(msg.text)
                                .foregroundColor(msg.color)
                        }
                        .font(.system(size: 10, design: .monospaced))
                        Divider().background(Color.white.opacity(0.05))
                    }
                }
                .padding(10)
            }
        }
        .frame(width: 300, height: 400)
        .background(Color.black.opacity(0.85))
        .cornerRadius(8)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.1), lineWidth: 1))
    }
}
