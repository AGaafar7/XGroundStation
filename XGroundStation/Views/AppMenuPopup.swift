    //
    //  AppMenuPopup.swift
    //  XGroundStation
    //
    //  Created by Ahmed Gaafar on 19/04/2026.
    //

import SwiftUI
import Combine

struct AppMenuPopup: View {
    @ObservedObject var vm: DroneViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                QGCMenuButton(icon: "map.fill", text: "Plan Flight") {
                    vm.currentMode = .plan
                    vm.showAppMenu = false
                }
                
                QGCMenuButton(icon: "chart.bar.xaxis", text: "Analyze Tools") {
                    vm.currentMode = .analyze
                    vm.showAppMenu = false
                }
                
                QGCMenuButton(icon: "gearshape.2.fill", text: "Vehicle Configuration") {
                    withAnimation {
                        vm.currentMode = .setup
                        vm.showAppMenu = false
                    }
                }
                
                QGCMenuButton(icon: "q.circle.fill", text: "Application Settings") {
                    vm.showAppMenu = false
                }
            }
            
            Spacer()
            
            VStack(spacing: 2) {
                Text("StationX Version")
                Text("v1.0.0 64 bit")
            }
            .font(.system(size: 11, weight: .regular))
            .foregroundColor(.gray)
            .frame(maxWidth: .infinity)
            .padding(.bottom, 20)
        }
        .frame(width: 300, height: 380)
        .background(Color(red: 0.15, green: 0.15, blue: 0.15))
        .cornerRadius(2)
        .shadow(color: .black.opacity(0.4), radius: 20, x: 10, y: 10)
    }
}

struct QGCMenuButton: View {
    let icon: String
    let text: String
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 0) {
                ZStack {
                    Color.black.opacity(0.2)
                    Image(systemName: icon)
                        .font(.system(size: 35, weight: .light))
                        .foregroundColor(.white)
                }
                .frame(width: 80, height: 80)
                Text(text)
                    .font(.system(size: 20, weight: .light))
                    .foregroundColor(.white)
                    .padding(.leading, 20)
                
                Spacer()
            }
        }
        .buttonStyle(PlainButtonStyle())
        .frame(height: 80)
        .border(Color.white.opacity(0.05), width: 0.5)
    }
}
