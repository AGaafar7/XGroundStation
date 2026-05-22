    //
    //  VisionAnalyticsEngine.swift
    //  XGroundStation
    //
    //  Created by Ahmed Gaafar on 23/04/2026.
    //


import Vision
import CoreImage

class VisionAnalyticsEngine {
    private var sequenceHandler = VNSequenceRequestHandler()
    
    func detectLandingPad(in image: CGImage, completion: @escaping (CGRect?) -> Void) {
        let request = VNDetectRectanglesRequest { request, error in
            guard let results = request.results as? [VNRectangleObservation], let best = results.first else {
                completion(nil)
                return
            }
            completion(best.boundingBox)
        }
        
        request.minimumAspectRatio = 0.9
        request.maximumObservations = 1
        
        try? sequenceHandler.perform([request], on: image)
    }
}
