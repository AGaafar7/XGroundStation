//
//  FirmwareManager.swift
//  XGroundStation
//
//  Created by Ahmed Gaafar on 23/05/2026.
//
import Foundation

class FirmwareManager {
    static let shared = FirmwareManager()
    private let firmwareURL = "https://firmware.ardupilot.org/Copter/stable/CubeOrange/arducopter.apj"
    
    func downloadLatest() async throws -> URL {
        let (localURL, _) = try await URLSession.shared.download(from: URL(string: firmwareURL)!)
        return localURL
    }
    
    private let STK_GET_SYNC: UInt8 = 0x20
    private let STK_INSYNC: UInt8 = 0x10
    private let STK_OK: UInt8 = 0x11
    private let STK_PROG_MULTI: UInt8 = 0x13
    
    func flash(fd: Int32, apjUrl: URL, progress: @escaping (Double) -> Void) async -> Bool {
        guard let data = try? Data(contentsOf: apjUrl),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let imageHex = json["image"] as? String else { return false }
        guard sync(fd: fd) else { return false }
    
        let bytes = hexToBytes(imageHex)
        let chunkSize = 256
        let totalChunks = bytes.count / chunkSize
        for i in 0..<totalChunks {
            let start = i * chunkSize
            let end = min(start + chunkSize, bytes.count)
            let chunk = Array(bytes[start..<end])
            
            if !sendChunk(fd: fd, data: chunk) { return false }
            
            progress(Double(i) / Double(totalChunks))
            try? await Task.sleep(nanoseconds: 1_000_000)
        }
        
        return true
    }
    
    private func sync(fd: Int32) -> Bool {
        let cmd: [UInt8] = [STK_GET_SYNC, 0x20]
        write(fd, cmd, 2)
        var resp = [UInt8](repeating: 0, count: 2)
        read(fd, &resp, 2)
        return resp[0] == STK_INSYNC
    }
    
    private func sendChunk(fd: Int32, data: [UInt8]) -> Bool {
        var packet: [UInt8] = [STK_PROG_MULTI, UInt8(data.count)] + data + [0x20]
        write(fd, packet, packet.count)
        var resp = [UInt8](repeating: 0, count: 2)
        read(fd, &resp, 2)
        return resp[0] == STK_INSYNC
    }
    
    private func hexToBytes(_ hex: String) -> [UInt8] {
        var bytes = [UInt8]()
        var hex = hex
        while hex.count > 0 {
            let index = hex.index(hex.startIndex, offsetBy: 2)
            let byteStr = String(hex[..<index])
            if let byte = UInt8(byteStr, radix: 16) { bytes.append(byte) }
            hex = String(hex[index...])
        }
        return bytes
    }
}
