    //
    //  RadioConfigView.swift
    //  XGroundStation
    //
    //  Created by Ahmed Gaafar on 23/04/2026.
    //

import SwiftUI

struct RadioConfigView: View {
    @ObservedObject var vm: DroneViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Radio Calibration").font(.title2).bold()
            
            Text("Move your RC sticks to their limits to verify connection.")
                .font(.caption).foregroundColor(.gray)
            
            VStack(spacing: 10) {
                ForEach(0..<8, id: \.self) { index in
                    HStack {
                        Text("Channel \(index + 1)").frame(width: 80, alignment: .leading)
                        
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Rectangle().fill(Color.white.opacity(0.1))
                                
                                let rawValue = vm.system.rcChannels[index]
                                let percent = CGFloat(max(0, min(1, (Float(rawValue) - 1000) / 1000.0)))
                                
                                Rectangle()
                                    .fill(Color.qgcAccent)
                                    .frame(width: geo.size.width * percent)
                            }
                        }
                        .frame(height: 15)
                        
                        Text("\(vm.system.rcChannels[index])").frame(width: 50)
                    }
                }
            }
            .padding()
            .background(Color.black.opacity(0.3))
        }
        .padding(30)
    }
}
