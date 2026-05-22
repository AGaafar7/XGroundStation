import Foundation

class PersistenceManager {
    static let shared = PersistenceManager()
    private let ssdPath: URL = URL(fileURLWithPath: "/Volumes/ExternalSSD/XGroundStationData/", isDirectory: true)
    private var logFileHandle: FileHandle?
    
    init() {
           
        try? FileManager.default.createDirectory(at: ssdPath, withIntermediateDirectories: true)
    }
    
    func startNewLogSession() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let fileName = "session_\(formatter.string(from: Date())).tlog"
        
           
        let logsFolder = ssdPath.appendingPathComponent("Logs", isDirectory: true)
        let fileURL = logsFolder.appendingPathComponent(fileName, isDirectory: false)
        
        do {
            try FileManager.default.createDirectory(at: logsFolder, withIntermediateDirectories: true)
            
               
            if !FileManager.default.fileExists(atPath: fileURL.path) {
                FileManager.default.createFile(atPath: fileURL.path, contents: nil)
            }
            
            self.logFileHandle = try FileHandle(forWritingTo: fileURL)
            print("DEBUG: T-Log recording started: \(fileURL.path)")
        } catch {
            print("DEBUG: Failed to start logging: \(error)")
        }
    }
    
    func logRawData(_ data: Data) {
        guard let handle = logFileHandle else { return }
        
        try? handle.seekToEnd()
        try? handle.write(contentsOf: data)
    }
    
    func stopLogSession() {
        try? logFileHandle?.close()
        logFileHandle = nil
        print("DEBUG: T-Log recording stopped.")
    }
    
        // Mission Saving/Loading
    func saveMission(_ items: [GCSMissionItem], name: String) {
        let url = ssdPath.appendingPathComponent("\(name).plan", isDirectory: false)
        do {
            let data = try JSONEncoder().encode(items)
            try data.write(to: url)
            print("DEBUG: Mission saved to SSD")
        } catch {
            print("DEBUG: Mission save failed: \(error)")
        }
    }
    
    func readLogFile(url: URL) -> Data? {
        return try? Data(contentsOf: url)
    }

}
