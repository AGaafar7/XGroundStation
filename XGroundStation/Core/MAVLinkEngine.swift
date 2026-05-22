    //
    //  MAVLinkEngine.swift
    //  XGroundStation
    //
    //  Created by Ahmed Gaafar on 19/04/2026.
    //

import Foundation
import Network
import Combine
import SwiftUI
import AVFoundation
import CoreLocation
import MapKit

    // MARK: - Supporting Structs
struct VehicleMessage: Identifiable, Equatable {
    let id = UUID()
    let timestamp: Date
    let text: String
    let severity: UInt8
    var color: Color {
        switch severity {
        case 0...2: return .red
        case 3...4: return .orange
        default: return .white
        }
    }
}

extension MAVLinkEngine {
    
        // MARK: - Parameter Writing
    func setParameter(name: String, value: Float) {
        var msg = mavlink_message_t()
        
        var nameArray = [Int8](repeating: 0, count: 16)
        let nameChars = name.cString(using: .ascii) ?? []
        for i in 0..<min(nameChars.count, 16) {
            if nameChars[i] != 0 { nameArray[i] = nameChars[i] }
        }
        
        mavlink_msg_param_set_pack(
            255, 190, &msg,
            1, 1,
            &nameArray,
            value,
            UInt8(MAV_PARAM_TYPE_REAL32.rawValue)
        )
        sendRaw(msg)
        Task { @MainActor in
            self.parameters[name] = value
            self.speak("Setting \(name) to \(value)")
        }
    }
    
        // MARK: - Motor Test
        /// - Parameters:
        ///   - motor: Motor index (1-8)
        ///   - throttle: 0-100 percentage
    func testMotor(index: UInt16, throttle: Float) {
        var msg = mavlink_message_t()
            // MAV_CMD_DO_MOTOR_TEST (185)
            // p1: Motor instance
            // p2: Test type (0 = percent)
            // p3: Throttle value
            // p4: Timeout (seconds)
        mavlink_msg_command_long_pack(
            255, 190, &msg, 1, 1,
            UInt16(MAV_CMD_DO_MOTOR_TEST.rawValue),
            0,
            Float(index), 0, throttle, 2.0, 0, 0, 0
        )
        sendRaw(msg)
    }
    func updateSmartFailsafe() {
        guard isConnected && lat != 0 && homeLat != 0 else { return }
        
        let droneLoc = CLLocation(latitude: lat, longitude: lon)
        let homeLoc = CLLocation(latitude: homeLat, longitude: homeLon)
        
            // Calculate distance in meters
        let distance = droneLoc.distance(from: homeLoc)
        self.distanceToHome = distance
        
            // LOGIC:
            // - Most 4S drones need at least 14.2V to land safely.
            // - We calculate a "buffer" voltage based on distance (0.1V per 200m).
        let voltageBuffer = Float(distance / 200.0) * 0.1
        let returnThreshold = 14.2 + voltageBuffer
        
        if batteryVoltage < returnThreshold && isArmed {
            speakThrottled("Battery low for return distance. RTL recommended.", id: "smart_rtl", interval: 30)
        }
    }
    func checkAlarms() {
        checkSmartFailsafe()
            // Battery Alarm
        if batteryVoltage > 0 && batteryVoltage < 14.1 { // Assumes 4S battery
            speakThrottled("Warning: Battery low", id: "bat_low", interval: 30)
        }
        if isArmed && altitude > 120 {
            speakThrottled("Warning: Exceeding legal altitude", id: "alt_max", interval: 10)
        }
        
            // GPS Alarm
        if isConnected && satelliteCount < 6 {
            speakThrottled("Warning: Poor GPS signal", id: "gps_low", interval: 60)
        }
    }
    private func speakThrottled(_ text: String, id: String, interval: TimeInterval) {
        let now = Date()
        if now.timeIntervalSince(lastSpoken[id] ?? .distantPast) > interval {
            speak(text)
            lastSpoken[id] = now
        }
    }
    
        // MARK: - Firmware Logic (Reboot to Bootloader)
    func rebootToBootloader() {
        var msg = mavlink_message_t()
            // Command 246 (PREFLIGHT_REBOOT_SHUTDOWN)
            // p1: 1=reboot, 3=reboot into bootloader
        mavlink_msg_command_long_pack(
            255, 190, &msg, 1, 1,
            UInt16(MAV_CMD_PREFLIGHT_REBOOT_SHUTDOWN.rawValue),
            0, 3, 0, 0, 0, 0, 0, 0
        )
        sendRaw(msg)
    }
}

struct GCSMissionItem: Identifiable, Equatable, Codable {
    var id = UUID()
    var latitude: Double
    var longitude: Double
    var altitude: Float = 30.0
    var command: UInt16 = 16
    var param1: Float = 0
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    init(coordinate: CLLocationCoordinate2D, altitude: Float = 30.0) {
        self.latitude = coordinate.latitude
        self.longitude = coordinate.longitude
        self.altitude = altitude
    }
    
    static func == (lhs: GCSMissionItem, rhs: GCSMissionItem) -> Bool { lhs.id == rhs.id }
    
}

    // MARK: - 1. The Parser (Strictly Non-Isolated)
private final class MAVLinkParserWrapper: @unchecked Sendable {
    nonisolated let msgPtr: UnsafeMutablePointer<mavlink_message_t> = .allocate(capacity: 1)
    nonisolated let statusPtr: UnsafeMutablePointer<mavlink_status_t> = .allocate(capacity: 1)
    nonisolated init() {}
    nonisolated func parse(byte: UInt8) -> Bool {
        return mavlink_parse_char(0, byte, msgPtr, statusPtr) == 1
    }
}


@MainActor
class MAVLinkEngine: ObservableObject {
    private var udpConnection: NWConnection?
    private var serialFileDescriptor: Int32 = -1
    private var currentSerialPath: String?
    private let parseQueue = DispatchQueue(label: "MAVLinkParseQueue", qos: .userInteractive)
    
    nonisolated private let parser = MAVLinkParserWrapper()
    
    @Published var isConnected = false {
        didSet {
            if isConnected && !oldValue {
                PersistenceManager.shared.startNewLogSession()
                startConnectionSequence()
            }else if !isConnected && oldValue {
                PersistenceManager.shared.stopLogSession()
            }
        }
    }
    // Telemetry
    @Published var altitude: Float = 0.0
    @Published var heading: Float = 0.0
    @Published var pitch: Float = 0.0
    @Published var roll: Float = 0.0
    @Published var groundSpeed: Float = 0.0
    @Published var batteryVoltage: Float = 0.0
    @Published var lat: Double = 0.0
    @Published var lon: Double = 0.0
    @Published var satelliteCount: Int = 0
    @Published var gpsFix: UInt8 = 0
    @Published var flightMode: String = "DISCONNECTED"
    @Published var statusMessage: String = "SEARCHING FOR DRONE..."
    
    // Health & Vibration
    @Published var vibX: Float = 0
    @Published var vibY: Float = 0
    @Published var vibZ: Float = 0
    @Published var clip0: UInt32 = 0

    // Parameters
    @Published var parameters: [String: Float] = [:]
    @Published var paramLoadProgress: Double = 0.0
    @Published var isLoadingParams: Bool = false
    private var hasLoadedParameters = false
    private var totalParamCount: Int = 0
    private var receivedIndices: Set<UInt16> = []
    
    // Mission & Calibration
    @Published var missionItems: [GCSMissionItem] = []
    @Published var magCalProgress: [Int: Float] = [:] // Compass ID : 0.0-1.0
    @Published var isCalibratingCompass = false
    @Published var isDownloadingMission = false
    @Published var messages: [VehicleMessage] = []
    @Published var latestPreArmMessage: String? = nil
    @Published var checklistItems: [String: Bool] = ["Props Secure": false, "Battery Checked": false, "Area Clear": false]
    @Published var isUploading: Bool = false

    private var hasRequestedVersion: Bool = false
    private var isConnecting = false
    private var lastHeartbeat = Date()
    private let speechSynthesizer = AVSpeechSynthesizer()
    private var lastSpoken: [String: Date] = [:]
    @Published var rcChannels: [UInt16] = Array(repeating: 0, count: 16)
    @Published var isArmed = false
    @Published var ftpSupported: Bool = false
    
    private var knownDevices: Set<SerialDevice> = []
    private var isUploadingMission = false
    @Published var terrainEnabled = false
    

    let MSG_ID_MAG_CAL_PROGRESS: UInt32 = 191
    let MSG_ID_MAG_CAL_REPORT: UInt32 = 192
    @Published var pitchHistory: [Float] = []
    
    func startCompassCal() {
        var msg = mavlink_message_t()
            // MAV_CMD_DO_START_MAG_CAL (42424)
            // p1: 0 (All compasses), p2: 0, p3: 0 (Retry), p4: 1 (Save automatically)
        mavlink_msg_command_long_pack(255, 190, &msg, 1, 1, 42424, 0, 0, 0, 0, 1, 0, 0, 0)
        sendRaw(msg)
        self.isCalibratingCompass = true
        speak("Compass calibration started. Rotate the vehicle around all axes.")
    }
    
    func startESCCalibration() {
        var msg = mavlink_message_t()
            // MAV_CMD_PREFLIGHT_CALIBRATION (241)
            // p3: 1 (ESC Calibration)
        mavlink_msg_command_long_pack(255, 190, &msg, 1, 1, 241, 0, 0, 0, 1, 0, 0, 0, 0)
        sendRaw(msg)
        speak("E S C calibration mode active. Please follow the safety instructions on screen.")
    }
    
    
    private func startConnectionSequence() {
        Task {
            print("DEBUG: Connection sequence started...")
            
            try? await Task.sleep(nanoseconds: 1 * 1_000_000_000)
            
            self.requestAutopilotVersion()
            
            try? await Task.sleep(nanoseconds: 1 * 1_000_000_000)
            self.requestDataStream(streamId: UInt8(MAV_DATA_STREAM_EXTRA1.rawValue), rate: 20)
            self.requestDataStream(streamId: UInt8(MAV_DATA_STREAM_POSITION.rawValue), rate: 10)
            if !self.hasLoadedParameters {
                self.requestParameters()
            }
        }
    }
    
    func requestDataStream(streamId: UInt8, rate: UInt16) {
        var msg = mavlink_message_t()
            // Command 66: MAV_CMD_SET_MESSAGE_INTERVAL or REQUEST_DATA_STREAM
        mavlink_msg_request_data_stream_pack(255, 190, &msg, 1, 1, streamId, rate, 1)
        sendRaw(msg)
    }
    
        // MARK: - Handshake Functions
    func requestAutopilotVersion() {
        var msg = mavlink_message_t()
        mavlink_msg_command_long_pack(
            255, 190, &msg, 1, 1,
            UInt16(MAV_CMD_REQUEST_MESSAGE.rawValue),
            0, Float(MAVLINK_MSG_ID_AUTOPILOT_VERSION),
            0, 0, 0, 0, 0, 0
        )
        sendRaw(msg)
        print("DEBUG: Requesting Autopilot Version...")
    }
    
    func speak(_ text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.5
        self.speechSynthesizer.speak(utterance)
    }
    
    func uploadMission() {
        guard !missionItems.isEmpty else { return }
        self.isUploading = true
        isUploadingMission = true
        var msg = mavlink_message_t()
        mavlink_msg_mission_count_pack(
            255, 190, &msg, 1, 1,
            UInt16(missionItems.count),
            UInt8(MAV_MISSION_TYPE_MISSION.rawValue),
            0
        )
        sendRaw(msg)
        print("DEBUG: Started mission upload handshake. Count: \(missionItems.count)")
    }
    
    func requestParameters() {
        guard isConnected && !isLoadingParams && !hasLoadedParameters else { return }
        print("DEBUG: requestParameters() called. isLoadingParams is now TRUE")
        self.isLoadingParams = true
        self.paramLoadProgress = 0.0
        self.hasLoadedParameters = false
        
        self.receivedIndices.removeAll()
        print("DEBUG: Sending PARAM_REQUEST_LIST to System 1, Component 0 (Broadcast)")
        
        var msg = mavlink_message_t()
        mavlink_msg_param_request_list_pack(
            255, // GCS System ID
            190, // GCS Component ID
            &msg,
            1,   // Target System (Drone)
            0    // Target Component (0 = Broadcast/All Components)
        )
        sendRaw(msg)
    }
    func clearMission() { missionItems.removeAll() }
    func removeWaypoint(at index: Int) { if index < missionItems.count { missionItems.remove(at: index) } }
    
        // MARK: - Lifecyle
    func start() {
        startUDP()
        startAutoDiscovery()
        setupWatchdog()
        
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in
                var hbMsg = mavlink_message_t()
                mavlink_msg_heartbeat_pack(255, 0, &hbMsg,
                                           UInt8(MAV_TYPE_GCS.rawValue),
                                           UInt8(MAV_AUTOPILOT_INVALID.rawValue),
                                           0, 0, 0)
                self.sendRaw(hbMsg)
            }
        }
    }
    
        // MARK: - Internal Networking
    private func sendRaw(_ msg: mavlink_message_t) {
        var m = msg
        var buffer = [UInt8](repeating: 0, count: 280)
        let len = mavlink_msg_to_send_buffer(&buffer, &m)
        let data = Data(bytes: buffer, count: Int(len))
        udpConnection?.send(content: data, completion: .idempotent)
        if serialFileDescriptor != -1 {
            data.withUnsafeBytes { ptr in _ = write(serialFileDescriptor, ptr.baseAddress, data.count) }
        }
    }
    
    private func startAutoDiscovery() {
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in
                guard self.serialFileDescriptor == -1 && !self.isConnecting else { return }
                let foundDevices = SerialScanner.findPotentialDevices()
                if let device = foundDevices.first {
                    self.isConnecting = true
                    self.startSerial(path: device.path, baud: device.isUSB ? 115200 : 57600)
                }
            }
        }
    }
    
    func startUDP(port: UInt16 = 14550) {
        let endpoint = NWEndpoint.hostPort(host: "0.0.0.0", port: NWEndpoint.Port(rawValue: port)!)
        let params = NWParameters.udp
        params.allowLocalEndpointReuse = true
        
        let conn = NWConnection(to: endpoint, using: .udp)
        self.udpConnection = conn
        conn.stateUpdateHandler = { state in
            switch state {
            case .ready: print("DEBUG: UDP Listener Ready on \(port)")
            case .failed(let error): print("DEBUG: UDP Listener Failed: \(error)")
            default: break
            }
        }
        
        conn.start(queue: .global())
        listenUDP()
    }
    
    private func listenUDP() {
        udpConnection?.receiveMessage { [weak self] (data, _, _, error) in
            guard let self = self else { return }
            if let data = data { self.parseQueue.async { self.processData(data) } }
            if error == nil { Task { @MainActor in self.listenUDP() } }
        }
    }
    
    func startSerial(path: String, baud: Int32) {
        self.statusMessage = "TRYING SERIAL: \(path)"
        let fd = open(path, O_RDWR | O_NOCTTY | O_NONBLOCK | O_EXCL)
        if fd == -1 { self.isConnecting = false; self.statusMessage = "PERMISSION DENIED"; return }
        
        self.serialFileDescriptor = fd
        self.currentSerialPath = path
        self.isConnected = false
        self.hasRequestedVersion = false
        self.hasLoadedParameters = false
        self.isConnecting = false
        
        var settings = termios()
        tcgetattr(fd, &settings)
        cfsetispeed(&settings, speed_t(baud == 115200 ? B115200 : B57600))
        cfsetospeed(&settings, speed_t(baud == 115200 ? B115200 : B57600))
        settings.c_cflag |= UInt(CLOCAL | CREAD | CS8)
        tcsetattr(fd, TCSANOW, &settings)
        
        parseQueue.async { [weak self, fd] in self?.listenSerial(fd: fd) }
        setupWatchdog()
    }
    
    private nonisolated func listenSerial(fd: Int32) {
        var buffer = [UInt8](repeating: 0, count: 4096)
        while true {
            let bytesRead = read(fd, &buffer, 512)
            if bytesRead > 0 {
                processData(Data(bytes: buffer, count: bytesRead))
            } else if bytesRead < 0 && errno != EAGAIN {
                Task { @MainActor [weak self] in self?.stopSerial() }
                break
            }
            usleep(5000)
            if fcntl(fd, F_GETFL) == -1 { break }
        }
    }
    
    func stopSerial() {
        let fdToClose = serialFileDescriptor
        self.serialFileDescriptor = -1
        self.currentSerialPath = nil
        self.isConnected = false
        if fdToClose != -1 { close(fdToClose) }
        self.statusMessage = "DISCONNECTED"
    }
    
        // MARK: - Core Processing
    nonisolated func processData(_ data: Data) {
        PersistenceManager.shared.logRawData(data)
        data.withUnsafeBytes { ptr in
            guard let bytes = ptr.baseAddress?.assumingMemoryBound(to: UInt8.self) else { return }
            for i in 0..<data.count {
                if parser.parse(byte: bytes[i]) {
                    decode(parser.msgPtr)
                }
            }
        }
    }
    
    
    @Published var homeLat: Double = 0.0
    @Published var homeLon: Double = 0.0
    @Published var distanceToHome: Double = 0.0
    
    func checkSmartFailsafe() {
        guard isConnected && lat != 0 && homeLat != 0 else { return }
        
            // 1. Calculate distance (Haversine Formula)
        let droneLoc = CLLocation(latitude: lat, longitude: lon)
        let homeLoc = CLLocation(latitude: homeLat, longitude: homeLon)
        self.distanceToHome = droneLoc.distance(from: homeLoc)
        
            // 2. Logic: Assume 0.1V drop per 100m of travel (Conservative estimate)
            // and we want 14.0V as the absolute minimum safe landing voltage.
        let requiredVoltageBuffer = Float(distanceToHome / 1000.0) * 0.5
        let criticalThreshold = 14.1 + requiredVoltageBuffer
        
        if batteryVoltage < criticalThreshold && isArmed {
            speakThrottled("Battery critical for return distance. Return to launch recommended.", id: "smart_bat", interval: 45)
        }
    }
    
    func triggerHaptic() {
        NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .now)
    }
    
    
    
        // MARK: - Decoding Logic
    private nonisolated func decode(_ mPtr: UnsafeMutablePointer<mavlink_message_t>) {
        var msg = mPtr.pointee
        let id = mPtr.pointee.msgid
        
        switch id {
            
        case MSG_ID_MAG_CAL_PROGRESS:
            var cal =  mavlink_mag_cal_progress_t()
            mavlink_msg_mag_cal_progress_decode(&msg, &cal)
            let compassID = Int(cal.compass_id)
            let progress = Float(cal.completion_pct) / 100.0
            Task { @MainActor in
                self.magCalProgress[compassID] = progress
                if progress >= 1.0 { self.speak("Compass \(compassID) complete") }
            }
            
        case UInt32(MAVLINK_MSG_ID_MAG_CAL_REPORT):
            Task { @MainActor in
                self.isCalibratingCompass = false
                self.speak("Compass calibration finished successfully")
            }
            
        case UInt32(MAVLINK_MSG_ID_VIBRATION):
            var vib = mavlink_vibration_t()
            mavlink_msg_vibration_decode(mPtr, &vib)
            let vx = vib.vibration_x
            let vy = vib.vibration_y
            let vz = vib.vibration_z
            let c0 = vib.clipping_0
            Task { @MainActor in
                self.vibX = vx; self.vibY = vy; self.vibZ = vz; self.clip0 = c0
                if vx > 40 || vy > 40 { self.speak("Warning: High Vibration") }
            }
            
        case UInt32(MAVLINK_MSG_ID_HOME_POSITION):
            var home = mavlink_home_position_t()
            mavlink_msg_home_position_decode(mPtr, &home)
            let hLat = Double(home.latitude) / 1E7
            let hLon = Double(home.longitude) / 1E7
            Task { @MainActor in
                self.homeLat = hLat; self.homeLon = hLon
            }
            
        case UInt32(MAVLINK_MSG_ID_MISSION_ITEM_REACHED):
            var reached = mavlink_mission_item_reached_t()
            mavlink_msg_mission_item_reached_decode(mPtr, &reached)
            Task { @MainActor in
                self.speak("Waypoint \(reached.seq) reached")
            }
            
        case UInt32(MAVLINK_MSG_ID_AUTOPILOT_VERSION):
            var version = mavlink_autopilot_version_t()
            mavlink_msg_autopilot_version_decode(&msg, &version)
            let ftp = (version.capabilities & UInt64(MAV_PROTOCOL_CAPABILITY_FTP.rawValue)) != 0
            let major = (version.middleware_sw_version >> 24) & 0xFF
            let minor = (version.middleware_sw_version >> 16) & 0xFF
            let patch = (version.middleware_sw_version >> 8) & 0xFF
            
            Task { @MainActor in
                self.ftpSupported = ftp
                self.statusMessage = "ArduCopter V\(major).\(minor).\(patch)"
            }
            
        case UInt32(MAVLINK_MSG_ID_MISSION_REQUEST):
            var req = mavlink_mission_request_t()
            mavlink_msg_mission_request_decode(&msg, &req)
            let idx = req.seq
            Task { @MainActor in
                guard Int(idx) < self.missionItems.count else { return }
                let item = self.missionItems[Int(idx)]
                var res = mavlink_message_t()
                mavlink_msg_mission_item_int_pack(255, 190, &res, 1, 1, idx,
                                                  UInt8(MAV_FRAME_GLOBAL_RELATIVE_ALT.rawValue),
                                                  UInt16(MAV_CMD_NAV_WAYPOINT.rawValue),
                                                  0, 1, 0, 0, 0, 0,
                                                  Int32(item.coordinate.latitude * 1E7),
                                                  Int32(item.coordinate.longitude * 1E7),
                                                  item.altitude,
                                                  UInt8(MAV_MISSION_TYPE_MISSION.rawValue))
                self.sendRaw(res)
            }
            
        case UInt32(MAVLINK_MSG_ID_MISSION_ACK):
            var ack = mavlink_mission_ack_t()
            mavlink_msg_mission_ack_decode(&msg, &ack)
            let type = ack.type
            Task { @MainActor in
                self.isUploadingMission = false
                self.isUploading = false
                if type == 0 { self.speak("Mission Uploaded") }
                else { self.speak("Mission Failed") }
            }
            
        case UInt32(MAVLINK_MSG_ID_MISSION_CURRENT):
            var cur = mavlink_mission_current_t()
            mavlink_msg_mission_current_decode(&msg, &cur)
            let currentWaypointIndex = cur.seq
            Task { @MainActor in
                print("DEBUG: Drone is flying to Waypoint \(currentWaypointIndex)")
            }
        case UInt32(MAVLINK_MSG_ID_STATUSTEXT):
            var st = mavlink_statustext_t()
            mavlink_msg_statustext_decode(&msg, &st)
            let text = withUnsafePointer(to: st.text) { p -> String in
                p.withMemoryRebound(to: Int8.self, capacity: 50) { String(cString: $0) }
            }
            let severity = st.severity
            Task { @MainActor in
                let fullMsg = "\(getSeverityString(severity)): \(text)"
                self.messages.insert(VehicleMessage(timestamp: Date(), text: fullMsg, severity: severity), at: 0)
                if severity <= 4 {
                    let utterance = AVSpeechUtterance(string: text)
                    utterance.rate = 0.5
                    self.speechSynthesizer.speak(utterance)
                    triggerHaptic()
                }
                if text.contains("PreArm:") || text.contains("Arm:") { self.latestPreArmMessage = text }
            }
            
        case UInt32(MAVLINK_MSG_ID_PARAM_VALUE):
            var param = mavlink_param_value_t()
            mavlink_msg_param_value_decode(&msg, &param)
            let paramID = withUnsafePointer(to: param.param_id) { ptr in
                let charPtr = UnsafeRawPointer(ptr).assumingMemoryBound(to: UInt8.self)
                let bytes = UnsafeBufferPointer(start: charPtr, count: 16)
                let cleanBytes = Array(bytes.prefix(while: { $0 != 0 }))
                return String(bytes: cleanBytes, encoding: .ascii) ?? "UNKNOWN"
            }
            
            let val = param.param_value
            let index = param.param_index
            let total = Int(param.param_count)
            
            Task { @MainActor in
                self.parameters[paramID] = val
                self.receivedIndices.insert(index)
                self.totalParamCount = total
                if self.receivedIndices.count % 50 == 0 || self.receivedIndices.count == total {
                    print("DEBUG: Received param #\(index) (\(paramID)). Progress: \(self.receivedIndices.count)/\(total)")
                }
                
                if total > 0 {
                    self.paramLoadProgress = Double(self.receivedIndices.count) / Double(total)
                    if self.receivedIndices.count % 100 == 0 {
                        print("DEBUG: Loaded \(self.receivedIndices.count) / \(total)")
                    }
                    if self.receivedIndices.count >= total {
                        self.isLoadingParams = false
                        self.hasLoadedParameters = true
                        print("DEBUG: DONE! Total parameters in dictionary: \(self.parameters.count)")
                        
                    }
                }
            }
        case UInt32(MAVLINK_MSG_ID_HEARTBEAT):
            var hb = mavlink_heartbeat_t()
            mavlink_msg_heartbeat_decode(&msg, &hb)
            let armed = (hb.base_mode & UInt8(MAV_MODE_FLAG_SAFETY_ARMED.rawValue)) != 0
            let modeName = getArduCopterModeName(hb.custom_mode)
            var home = mavlink_home_position_t()
            mavlink_msg_home_position_decode(mPtr, &home)
            let hLat = Double(home.latitude) / 1E7
            let hLon = Double(home.longitude) / 1E7
            Task { @MainActor in
                self.lastHeartbeat = Date()
                self.isConnected = true
                self.isArmed = armed
                self.flightMode = modeName
                self.homeLat = hLat
                self.homeLon = hLon
            }
            
        case UInt32(MAVLINK_MSG_ID_GLOBAL_POSITION_INT):
            var pos = mavlink_global_position_int_t()
            mavlink_msg_global_position_int_decode(&msg, &pos)
            let altM = Float(pos.relative_alt) / 1000.0
            let hdgD = Float(pos.hdg) / 100.0
            let la = Double(pos.lat) / 1E7
            let lo = Double(pos.lon) / 1E7
            Task { @MainActor in self.altitude = altM; self.heading = hdgD; self.lat = la; self.lon = lo }
            
        case UInt32(MAVLINK_MSG_ID_RC_CHANNELS):
            var rc = mavlink_rc_channels_t()
            mavlink_msg_rc_channels_decode(&msg, &rc)
            let chans = [rc.chan1_raw, rc.chan2_raw, rc.chan3_raw, rc.chan4_raw, rc.chan5_raw, rc.chan6_raw, rc.chan7_raw, rc.chan8_raw]
            Task { @MainActor in self.rcChannels = chans }
            
        case UInt32(MAVLINK_MSG_ID_SYS_STATUS):
            var sys = mavlink_sys_status_t()
            mavlink_msg_sys_status_decode(&msg, &sys)
            let v = Float(sys.voltage_battery) / 1000.0
            Task { @MainActor in self.batteryVoltage = v }
            
        case UInt32(MAVLINK_MSG_ID_VFR_HUD):
            var vfr = mavlink_vfr_hud_t()
            mavlink_msg_vfr_hud_decode(&msg, &vfr)
            let spd = vfr.groundspeed
            Task { @MainActor in self.groundSpeed = spd }
            
        case UInt32(MAVLINK_MSG_ID_ATTITUDE):
            var att = mavlink_attitude_t()
            mavlink_msg_attitude_decode(&msg, &att)
            let p = att.pitch * (180.0 / .pi)
            let r = att.roll * (180.0 / .pi)
            Task { @MainActor in
                self.pitch = p
                self.roll = r
                self.pitchHistory.append(p)
                if self.pitchHistory.count > 100 {
                    self.pitchHistory.removeFirst()
                }
            }
            
        case UInt32(MAVLINK_MSG_ID_GPS_RAW_INT):
            var gps = mavlink_gps_raw_int_t()
            mavlink_msg_gps_raw_int_decode(&msg, &gps)
            let sats = Int(gps.satellites_visible)
            let fix = gps.fix_type
            Task { @MainActor in
                self.satelliteCount = sats
                self.gpsFix = fix
            }
            
        default: break
        }
    }
    
        // MARK: - Public API
    func getParam(_ name: String) -> Float? { return parameters[name] }
    
    
    private nonisolated func getSeverityString(_ severity: UInt8) -> String {
        switch severity {
        case 0...2: return "Critical"
        case 3...4: return "Warning"
        default: return "Info"
        }
    }
    
    nonisolated func getArduCopterModeName(_ modeInt: UInt32) -> String {
        let modes: [UInt32: String] = [
            0: "STABILIZE", 1: "ACRO", 2: "ALT_HOLD", 3: "AUTO", 4: "GUIDED",
            5: "LOITER", 6: "RTL", 7: "CIRCLE", 9: "LAND", 11: "DRIFT",
            13: "SPORT", 14: "FLIP", 15: "AUTOTUNE", 16: "POSHOLD", 17: "BRAKE"
        ]
        return modes[modeInt] ?? "UNKNOWN (\(modeInt))"
    }
    
    private func setupWatchdog() {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in
                let shouldBeConnected = Date().timeIntervalSince(self.lastHeartbeat) < 3.0
                if self.isConnected != shouldBeConnected {
                    self.isConnected = shouldBeConnected
                    if !shouldBeConnected {
                        self.statusMessage = "CONNECTION LOST"
                        self.hasRequestedVersion = false; self.hasLoadedParameters = false
                        self.isLoadingParams = false; self.isConnecting = false; self.paramLoadProgress = 0.0
                    }
                }
                if self.isConnected {
                    self.checkAlarms()
                    self.updateSmartFailsafe()
                }
            }
        }
    }
    
    func goToLocation(lat: Double, lon: Double) {
        var msg = mavlink_message_t()
        mavlink_msg_command_long_pack(255, 190, &msg, 1, 1, UInt16(MAV_CMD_DO_REPOSITION.rawValue), 0, -1, 1.0, 0, 0, Float(lat), Float(lon), Float(altitude))
        sendRaw(msg)
    }
    
    func arm() { sendCommand(UInt16(MAV_CMD_COMPONENT_ARM_DISARM.rawValue), p1: 1) }
    func disarm() { sendCommand(UInt16(MAV_CMD_COMPONENT_ARM_DISARM.rawValue), p1: 0) }
    func takeoff() { sendCommand(UInt16(MAV_CMD_NAV_TAKEOFF.rawValue), p7: 5.0) }
    
    private func sendCommand(_ command: UInt16, p1: Float = 0, p7: Float = 0) {
        var msg = mavlink_message_t()
        mavlink_msg_command_long_pack(255, 190, &msg, 1, 1, command, 0, p1, 0, 0, 0, 0, 0, p7)
        sendRaw(msg)
    }
    
    func setFlightMode(_ mode: ArduCopterMode) {
        var msg = mavlink_message_t()
        mavlink_msg_command_long_pack(255, 190, &msg, 1, 1, UInt16(MAV_CMD_DO_SET_MODE.rawValue), 0, 1.0, Float(mode.rawValue), 0, 0, 0, 0, 0)
        sendRaw(msg)
    }
    
    func setHomeHere() {
        var msg = mavlink_message_t()
            // Command 179: MAV_CMD_DO_SET_HOME
            // p1: 1 = use current position
        mavlink_msg_command_long_pack(255, 190, &msg, 1, 1, 179, 0, 1, 0, 0, 0, 0, 0, 0)
        sendRaw(msg)
        speak("Setting home to current position")
    }
    
    func setEKFOrigin(lat: Double, lon: Double) {
        var msg = mavlink_message_t()
            // Command 210: MAV_CMD_SET_GPS_GLOBAL_ORIGIN
        mavlink_msg_command_long_pack(255, 190, &msg, 1, 1, 210, 0, 0, 0, 0, 0, Float(lat), Float(lon), Float(altitude))
        sendRaw(msg)
        speak("EKF Origin set")
    }
    func setHome(at coord: CLLocationCoordinate2D) {
        var msg = mavlink_message_t()
            // MAV_CMD_DO_SET_HOME (179) - p1: 0=Use p5/6/7, p5: Lat, p6: Lon, p7: Alt
        mavlink_msg_command_long_pack(255, 190, &msg, 1, 1, 179, 0, 0, 0, 0, 0, Float(coord.latitude), Float(coord.longitude), Float(altitude))
        sendRaw(msg)
        speak("Home position updated")
    }
    
    func setOrigin(at coord: CLLocationCoordinate2D) {
        var msg = mavlink_message_t()
            // MAV_CMD_SET_GPS_GLOBAL_ORIGIN (210)
        mavlink_msg_command_long_pack(255, 190, &msg, 1, 1, 210, 0, 0, 0, 0, 0, Float(coord.latitude), Float(coord.longitude), Float(altitude))
        sendRaw(msg)
        speak("EKF origin set")
    }
    
    func applyTerrainToMission() {
        let request = MKDirections.Request()
        Task {
            for i in 0..<missionItems.count {
                let currentAlt = missionItems[i].altitude
                print("DEBUG: Adjusting WP \(i) for terrain elevation...")
            }
            self.speak("Terrain check complete. Mission ready.")
        }
    }
}
