//
//  LogReplayView.swift
//  XGroundStation
//
//  Created by Ahmed Gaafar on 23/05/2026.
//

import Foundation
import SwiftUI
internal import UniformTypeIdentifiers

struct LogReplayView: View {
    @ObservedObject var vm: DroneViewModel
    @State private var replayProgress: Double = 0
    @State private var logData: Data = Data()
    
    var body: some View {
        VStack {
            if logData.isEmpty {
                Button("LOAD T-LOG FROM SSD") {
                    let panel = NSOpenPanel()
                    if panel.runModal() == .OK {
                        logData = try! Data(contentsOf: panel.url!)
                    }
                }
            } else {
                Slider(value: $replayProgress, in: 0...Double(logData.count))
                    .onChange(of: replayProgress) { newValue in
                        scrubTo(index: Int(newValue))
                    }
                Text("Byte Index: \(Int(replayProgress))")
            }
        }
    }
    
    func scrubTo(index: Int) {
        let chunk = logData.prefix(index)
        vm.system.processData(chunk) // Re-parse up to this point
    }
}
