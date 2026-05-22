//
//  MissionGenerator.swift
//  XGroundStation
//
//  Created by Ahmed Gaafar on 22/05/2026.
//


import Foundation
import CoreLocation

class MissionGenerator {
    static func generateSearchGrid(topLeft: CLLocationCoordinate2D, bottomRight: CLLocationCoordinate2D, spacingMeters: Double, altitude: Float) -> [GCSMissionItem] {
        var gridItems: [GCSMissionItem] = []
        let latStep = (spacingMeters / 111111.0)
        let lonStep = (spacingMeters / (111111.0 * cos(topLeft.latitude * .pi / 180.0)))
        
        let minLat = min(topLeft.latitude, bottomRight.latitude)
        let maxLat = max(topLeft.latitude, bottomRight.latitude)
        let minLon = min(topLeft.longitude, bottomRight.longitude)
        let maxLon = max(topLeft.longitude, bottomRight.longitude)
        
        var currentLat = maxLat
        var direction: Double = 1.0
        
        while currentLat > minLat {
            let p1 = CLLocationCoordinate2D(latitude: currentLat, longitude: minLon)
            let p2 = CLLocationCoordinate2D(latitude: currentLat, longitude: maxLon)
            
            if direction > 0 {
                gridItems.append(GCSMissionItem(coordinate: p1, altitude: altitude))
                gridItems.append(GCSMissionItem(coordinate: p2, altitude: altitude))
            } else {
                gridItems.append(GCSMissionItem(coordinate: p2, altitude: altitude))
                gridItems.append(GCSMissionItem(coordinate: p1, altitude: altitude))
            }
            currentLat -= latStep
            direction *= -1
        }
        return gridItems
    }
}
