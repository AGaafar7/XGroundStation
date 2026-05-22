    //
    //  GCSMode.swift
    //  XGroundStation
    //
    //  Created by Ahmed Gaafar on 19/04/2026.
    //


import SwiftUI

enum GCSMode { case fly, plan, analyze, setup }

extension Color {
    static let qgcMainBg = Color(red: 0.11, green: 0.11, blue: 0.11)
    static let qgcTopBar = Color(red: 0.15, green: 0.15, blue: 0.15)
    static let qgcAccent = Color(red: 0.95, green: 0.77, blue: 0.06)
    static let qgcTextGrey = Color(white: 0.7)
    static let qgcPanelBg = Color.black.opacity(0.85)
    static let qgcDisconnectedPurple = Color(red: 0.23, green: 0.16, blue: 0.31)
    static let qgcArduPilotOrange = Color(red: 0.95, green: 0.55, blue: 0.1)
}
