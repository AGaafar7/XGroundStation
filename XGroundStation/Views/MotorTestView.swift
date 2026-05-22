    //
    //  MotorTestView.swift
    //  XGroundStation
    //
    //  Created by Ahmed Gaafar on 23/04/2026.
    //
import SwiftUI
struct MotorTestView: View {
    @ObservedObject var vm: DroneViewModel
    @State private var throttle: Float = 10.0
    
    var motorCount: Int {
        let fClass = vm.system.getParam("FRAME_CLASS") ?? 1
        switch Int(fClass) {
        case 1: return 4
        case 2: return 6
        case 3: return 8
        case 5: return 6
        default: return 4
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 30) {
            Text("Motor Test").font(.title).bold()
            
            HStack {
                Text("Test Power: \(Int(throttle))%")
                Slider(value: $throttle, in: 5...30).frame(width: 200)
            }
            
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 20) {
                ForEach(1...motorCount, id: \.self) { i in
                    Button(action: { vm.system.testMotor(index: UInt16(i), throttle: throttle) }) {
                        VStack {
                            Image(systemName: "arrow.up")
                                .font(.system(size: 30))
                            Text("Motor \(i)")
                        }
                        .frame(width: 100, height: 100)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
            }
            
            Button("STOP ALL MOTORS") {
                vm.system.testMotor(index: 0, throttle: 0)
            }
            .buttonStyle(.borderedProminent).tint(.red)
        }
        .padding(40)
    }
}
