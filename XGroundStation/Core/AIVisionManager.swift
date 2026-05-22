    //
    //  AIVisionManager.swift
    //  XGroundStation
    //
    //  Created by Ahmed Gaafar on 23/04/2026.
    //


import Vision
import AVFoundation
import Combine
import CoreLocation

struct DetectedTarget: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let timestamp: Date
}


class AIVisionManager: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    @Published var detectedTargets: [DetectedTarget] = []
    private let sequenceHandler = VNSequenceRequestHandler()
    
        /// Processes a video frame and drops a pin if a human is found
    func processVideoFrame(pixelBuffer: CVPixelBuffer, currentDroneLoc: CLLocationCoordinate2D, engine: MAVLinkEngine) {
        let request = VNDetectHumanRectanglesRequest { request, error in
            guard let results = request.results as? [VNHumanObservation], !results.isEmpty else { return }
            
            DispatchQueue.main.async {
                let target = DetectedTarget(coordinate: currentDroneLoc, timestamp: Date())
                
                if !self.detectedTargets.contains(where: {
                    abs($0.coordinate.latitude - target.coordinate.latitude) < 0.00005
                }) {
                    self.detectedTargets.append(target)
                    engine.speak("Target detected. Dropping GPS pin.")
                }
            }
        }
        
        request.revision = VNDetectHumanRectanglesRequestRevision1
        try? sequenceHandler.perform([request], on: pixelBuffer)
    }
}
