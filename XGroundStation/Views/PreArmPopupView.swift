    //
    //  PreArmPopupView.swift
    //  XGroundStation
    //
    //  Created by Ahmed Gaafar on 23/04/2026.
    //


import SwiftUI

struct PreArmPopupView: View {
    let message: String
    var onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 15) {
            Text(message)
                .font(.system(size: 14, weight: .medium))
                .multilineTextAlignment(.center)
            
            Text("The vehicle has failed a pre-arm check. In order to arm the vehicle, resolve the failure.")
                .font(.system(size: 12))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            
            Button("DISMISS") { onDismiss() }
                .buttonStyle(.bordered)
                .tint(.blue)
        }
        .padding(25)
        .frame(width: 350)
        .background(Color.black.opacity(0.9))
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.2), lineWidth: 1))
        .shadow(radius: 20)
    }
}
