    //
    //  SideTabStrip.swift
    //  XGroundStation
    //
    //  Created by Ahmed Gaafar on 23/04/2026.
    //


import SwiftUI

struct SideTab: View {
    let icon: String
    let label: String
    let active: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                Text(label)
                    .font(.system(size: 8, weight: .black))
            }
            .frame(width: 55, height: 55)
            .foregroundColor(active ? .qgcAccent : .white)
            .background(active ? Color.white.opacity(0.05) : Color.clear)
            .overlay(
                Rectangle()
                    .fill(active ? Color.qgcAccent : .clear)
                    .frame(width: 2), 
                alignment: .leading
            )
        }
        .buttonStyle(.plain)
    }
}
