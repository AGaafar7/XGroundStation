    //
    //  ArduPilotMapping.swift
    //  XGroundStation
    //
    //  Created by Ahmed Gaafar on 23/04/2026.
    //


import Foundation

struct ArduPilotMapping {
    static func frameClass(_ value: Float) -> String {
        switch Int(value) {
        case 0: return "Undefined"
        case 1: return "Quad"
        case 2: return "Hexa"
        case 3: return "Octa"
        case 4: return "OctaQuad"
        case 5: return "Y6"
        case 6: return "Heli"
        case 7: return "Tri"
        default: return "Other (\(Int(value)))"
        }
    }
    
    static func frameType(_ value: Float) -> String {
        switch Int(value) {
        case 0: return "Plus (+)"
        case 1: return "X"
        case 2: return "V"
        case 3: return "H"
        case 4: return "V-Tail"
        case 5: return "A-Tail"
        case 10: return "Y6B"
        default: return "Custom"
        }
    }
}
