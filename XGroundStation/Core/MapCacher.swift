    //
    //  MapCacher.swift
    //  XGroundStation
    //
    //  Created by Ahmed Gaafar on 23/04/2026.
    //

import MapKit
import AppKit
class MapCacher {
    func cacheArea(center: CLLocationCoordinate2D, radiusKM: Double) {
        let options = MKMapSnapshotter.Options()
        options.region = MKCoordinateRegion(center: center, latitudinalMeters: radiusKM * 1000, longitudinalMeters: radiusKM * 1000)
        options.size = CGSize(width: 2000, height: 2000)
        options.mapType = .hybrid
        
        let snapshotter = MKMapSnapshotter(options: options)
        snapshotter.start { snapshot, error in
            if let error = error{
                print("DEBUG: Snapshot error: \(error.localizedDescription)")
                return
            }
            if let image = snapshot?.image {
                if let data = image.tiffRepresentation {
                    let path = "/Volumes/ExternalSSD/DroneMaps/cache_\(Date().timeIntervalSince1970).tiff"
                    let url = URL(fileURLWithPath: path)
                    do {
                        try data.write(to: url)
                        print("DEBUG: Map area cached to SSD at \(path)")
                    }catch {
                        print("DEBUG: Failed to save map: \(error)")
                    }
                }
            }
            
        }
    }
}

