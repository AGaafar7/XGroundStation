    //
    //  SerialDevice.swift
    //  XGroundStation
    //
    //  Created by Ahmed Gaafar on 20/04/2026.
    //

import Foundation

struct SerialDevice: Identifiable, Hashable {
    let id = UUID()
    let path: String
    let name: String
    
        /// Returns true for Pixhawk/Cube (usbmodem), false for Radios (usbserial)
    var isUSB: Bool {
        path.contains("usbmodem")
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(path)
    }
    static func == (lhs: SerialDevice, rhs: SerialDevice) -> Bool {
        lhs.path == rhs.path
    }
    
}

class SerialScanner {
        /// Scans the /dev directory for MAVLink-compatible hardware
    static func findPotentialDevices() -> [SerialDevice] {
        let fm = FileManager.default
        do {
            let devices = try fm.contentsOfDirectory(atPath: "/dev")
            
                // Filter for:
                // cu.usbmodem* (Direct USB)
                // cu.usbserial* (Telemetry Radio)
            return devices
                .filter { $0.starts(with: "cu.usbmodem") || $0.starts(with: "cu.usbserial") }
                .map { SerialDevice(path: "/dev/\($0)", name: $0) }
        } catch {
            print("Error scanning /dev: \(error)")
            return []
        }
    }
}

    /// Global helper function to satisfy your AppMenuPopup UI
func listSerialDevices() -> [SerialDevice] {
    return SerialScanner.findPotentialDevices()
}
