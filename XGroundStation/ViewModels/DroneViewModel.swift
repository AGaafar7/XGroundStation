    //
    //  DroneViewModel.swift
    //  XGroundStation
    //
    //  Created by Ahmed Gaafar on 19/04/2026.
    //

import Foundation
import Combine


import SwiftUI

@MainActor
class DroneViewModel: ObservableObject {
    @Published var system = MAVLinkEngine()
    @Published var currentMode: GCSMode = .fly
    @Published var showAppMenu = false
    @Published var showModeMenu = false
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        system.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
    
    func connect() {
        system.start()
    }
}
