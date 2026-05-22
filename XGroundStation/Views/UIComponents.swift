    //
    //  UIComponents.swift
    //  XGroundStation
    //
    //  Created by Ahmed Gaafar on 19/04/2026.
    //

import SwiftUI

struct ActionTile: View {
    let icon: String; let label: String
    var color: Color = .white; var action: () -> Void
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon).font(.system(size: 18))
                Text(label.uppercased()).font(.system(size: 8, weight: .black))
            }
            .frame(width: 55, height: 50).background(Color.qgcPanelBg)
            .foregroundColor(color).border(Color.white.opacity(0.1), width: 0.5)
        }.buttonStyle(.plain)
    }
}

struct TelemetryRow: View {
    let label: String; let value: String; let unit: String; var isLast: Bool = false
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(label).font(.system(size: 9, weight: .bold)).foregroundColor(.qgcTextGrey)
                Spacer()
                Text(value).font(.system(size: 13, weight: .black, design: .monospaced))
                Text(unit).font(.system(size: 9)).foregroundColor(.qgcTextGrey)
            }
            .padding(.horizontal, 10).frame(height: 28)
            if !isLast { Divider().background(Color.white.opacity(0.1)) }
        }
    }
}
