    //
    //  ContentView.swift
    //  XGroundStation
    //
    //  Created by Ahmed Gaafar on 19/04/2026.
    //

import SwiftUI
import MapKit

struct ContentView: View {
    @StateObject var vm = DroneViewModel()
    @StateObject var ai = AIVisionManager()
    @State private var isDrawingSearchArea = false
    @State private var gridStartCorner: CLLocationCoordinate2D?
    @State private var locationCursor: CLLocationCoordinate2D?
    
    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 30.0444, longitude: 31.2357),
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        )
    )
    
    private func updateMapCamera() {
        if vm.system.lat != 0 && vm.system.isConnected {
            cameraPosition = .region(MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: vm.system.lat, longitude: vm.system.lon),
                span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
            ))
        }
    }
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            if vm.currentMode == .setup {
                Color.qgcMainBg.ignoresSafeArea()
            } else {
                MapReader { proxy in
                    Map(position: $cameraPosition) {
                        if vm.system.lat != 0 {
                            Annotation("Drone", coordinate: CLLocationCoordinate2D(latitude: vm.system.lat, longitude: vm.system.lon)) {
                                ZStack {
                                    Circle().fill(.white).frame(width: 26, height: 26)
                                    Image(systemName: "airplane")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 18, height: 18)
                                        .foregroundColor(.red)
                                        .rotationEffect(.degrees(Double(vm.system.heading)))
                                }
                            }
                        }
                        
                        ForEach(Array(vm.system.missionItems.enumerated()), id: \.element.id) { index, item in
                            Annotation("\(index + 1)", coordinate: item.coordinate) {
                                Circle().fill(.yellow).frame(width: 20, height: 20)
                                    .overlay(Text("\(index + 1)").font(.caption2).foregroundColor(.black))
                            }
                        }
                        
                        MapPolyline(coordinates: vm.system.missionItems.map { $0.coordinate })
                            .stroke(.yellow, lineWidth: 2)
                        ForEach(ai.detectedTargets) { target in
                            Annotation("PERSON", coordinate: target.coordinate) {
                                Image(systemName: "person.fill.viewfinder")
                                    .font(.title)
                                    .foregroundColor(.red)
                                    .background(Circle().fill(.black).frame(width: 40, height: 40))
                            }
                        }
                    }
                    .onChange(of: vm.system.lat) { updateMapCamera() }
                    .mapStyle(.hybrid(elevation: .realistic))
                    .ignoresSafeArea()
                    .onTapGesture { screenPoint in
                        guard let coordinate = proxy.convert(screenPoint, from: .local) else { return }
                        if isDrawingSearchArea {
                            if let start = gridStartCorner {
                                let grid = MissionGenerator.generateSearchGrid(
                                    topLeft: start,
                                    bottomRight: coordinate,
                                    spacingMeters: 20,
                                    altitude: 30
                                )
                                vm.system.missionItems = grid
                                gridStartCorner = nil
                                isDrawingSearchArea = false
                                vm.system.speak("Grid generated with \(grid.count) points")
                            } else {
                                    // FIRST CLICK: Set Corner
                                gridStartCorner = coordinate
                                vm.system.speak("Mark opposite corner")
                            }
                        }
                    }
                    .onContinuousHover { phase in
                        if case .active(let point) = phase {
                            locationCursor = proxy.convert(point, from: .local)
                        }
                    }
                    .contextMenu {
                        if let coord = locationCursor {
                            Button("Fly To Here") {
                                vm.system.goToLocation(lat: coord.latitude, lon: coord.longitude)
                            }
                            Divider()
                            Button("Set Home Here") {
                                vm.system.setHome(at: coord)
                            }
                            Button("Set EKF Origin Here") {
                                vm.system.setOrigin(at: coord)
                            }
                            Divider()
                            Button("Add Waypoint") {
                                vm.system.missionItems.append(GCSMissionItem(coordinate: coord))
                            }
                            Divider()
                            Button("Generate Search Grid") {
                                isDrawingSearchArea = true
                                gridStartCorner = nil
                                vm.system.speak("Mark first corner of search area")
                            }
                            Divider()
                            Button("Save Mission to SSD") {
                                PersistenceManager.shared.saveMission(vm.system.missionItems, name: "AutoMission")
                            }
                        }
                    }
                }
            }
            
            VStack(spacing: 0) {
                if vm.currentMode == .setup {
                    VehicleConfigurationView(vm: vm)
                } else {
                    if vm.system.isConnected { ConnectedTopBar(vm: vm) } else { DisconnectedTopBar(vm: vm) }
                    
                    HStack(spacing: 0) {
                        FlyViewHUD(vm: vm)
                    }
                }
            }
            
            if vm.showAppMenu {
                Color.black.opacity(0.01).onTapGesture { withAnimation { vm.showAppMenu = false } }
                AppMenuPopup(vm: vm).padding(.top, 40)
            }
            
            if vm.showModeMenu {
                Color.black.opacity(0.01).onTapGesture { withAnimation { vm.showModeMenu = false } }
                FlightModeSelector(vm: vm).padding(.top, 42).padding(.leading, 120)
            }
        }
        .onAppear { vm.connect() }
    }
    
    private func handleMapTap(coordinate: CLLocationCoordinate2D) {
        if vm.currentMode == .plan {
            vm.system.missionItems.append(GCSMissionItem(coordinate: coordinate))
        } else {
            vm.system.goToLocation(lat: coordinate.latitude, lon: coordinate.longitude)
        }
    }
}

struct DisconnectedTopBar: View {
    @ObservedObject var vm: DroneViewModel
    var body: some View {
        HStack(spacing: 0) {
            Button(action: { withAnimation { vm.showAppMenu.toggle() } }) {
                ZStack {
                    Color.qgcDisconnectedPurple
                    Image(systemName: "x.circle.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                }
                .frame(width: 50)
            }
            .buttonStyle(.plain)
            Text("Disconnected - Click to manually connect 💬")
                .font(.system(size: 14))
                .padding(.leading, 15)
            Spacer()
        }
        .frame(height: 40)
        .background(Color.qgcDisconnectedPurple.opacity(0.8))
        .border(Color.black.opacity(0.3), width: 1)
    }
}

struct ConnectedTopBar: View {
    @ObservedObject var vm: DroneViewModel
    var body: some View {
        VStack(spacing: 0){
            HStack(spacing: 15) {
                Button(action: { withAnimation { vm.showAppMenu.toggle() } }) {
                    Image(systemName: "x.circle.fill")
                        .font(.title2)
                        .foregroundColor(vm.showAppMenu ? .black : .qgcAccent)
                }
                .frame(width: 50, height: 40)
                .background(vm.showAppMenu ? Color.qgcAccent : Color.clear)
                .buttonStyle(.plain)
                
                HStack(spacing: 8) {
                    Text(vm.system.isArmed ? "ARMED" : "Not Ready")
                        .foregroundColor(vm.system.isArmed ? .red : .orange)
                        .font(.system(size: 13, weight: .bold))
                    Image(systemName: "message.fill").font(.caption).foregroundColor(.red)
                }
                if vm.system.isUploading {
                    ProgressView().scaleEffect(0.5).padding(.trailing)
                }
                
                Button(action: { withAnimation { vm.showModeMenu.toggle() } }) {
                    HStack(spacing: 5) {
                        Image(systemName: "lines.measurement.horizontal")
                        Text(vm.system.flightMode.uppercased()).font(.system(size: 13, weight: .bold))
                        Image(systemName: "chevron.down").font(.system(size: 10))
                    }
                    .padding(.horizontal, 8).frame(height: 30)
                    .background(vm.showModeMenu ? Color.white.opacity(0.2) : Color.clear)
                    .cornerRadius(4)
                }
                .buttonStyle(.plain)
                
                Spacer()
                Text("ARDUPILOT").font(.system(size: 18, weight: .black)).italic().opacity(0.8).padding(.trailing, 10)
            }
            .frame(height: 38)
            
            if vm.system.isLoadingParams {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Rectangle().fill(Color.white.opacity(0.1))
                        Rectangle()
                            .fill(Color.green)
                            .frame(width: geo.size.width * CGFloat(vm.system.paramLoadProgress))
                    }
                }
                .frame(height: 2)
            } else {
                Rectangle().fill(Color.black).frame(height: 2)
            }
        }
        .frame(height: 40)
        .background(Color.qgcTopBar)
    }
}
