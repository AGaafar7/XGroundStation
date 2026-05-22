    //
    //  ArduCopterMode.swift
    //  XGroundStation
    //
    //  Created by Ahmed Gaafar on 20/04/2026.
    //

enum ArduCopterMode: UInt32, CaseIterable {
    case stabilize = 0
    case acro = 1
    case altHold = 2
    case auto = 3
    case guided = 4
    case loiter = 5
    case rtl = 6
    case circle = 7
    case land = 9
    case drift = 11
    case sport = 13
    case posHold = 16
    case brake = 17
}
