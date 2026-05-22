    //
    //  ParameterListView.swift
    //  XGroundStation
    //
    //  Created by Ahmed Gaafar on 23/04/2026.
    //


import SwiftUI

struct ParameterListView: View {
    @ObservedObject var vm: DroneViewModel
    @State private var searchText = ""
    @State private var editingParam: String?
    @State private var newValue: String = ""
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Parameters (\(vm.system.parameters.count))").bold()
                Spacer()
                Button("FORCE REFRESH") {
                    vm.system.requestParameters()
                }
                .buttonStyle(.bordered)
                .tint(.qgcAccent)
            }
            .padding()
            
            
            HStack {
                Image(systemName: "magnifyingglass").foregroundColor(.gray)
                TextField("Search Parameters...", text: $searchText)
                    .textFieldStyle(.plain)
            }
            .padding()
            .background(Color.black.opacity(0.2))
            
            
            HStack {
                Text("Parameter").frame(width: 200, alignment: .leading)
                Text("Value").frame(width: 100, alignment: .leading)
                Spacer()
            }
            .font(.system(size: 11, weight: .bold))
            .padding(.horizontal)
            .frame(height: 30)
            .background(Color.white.opacity(0.05))
            
            
            ScrollView {
                VStack(spacing: 0) {
                    let sortedKeys = vm.system.parameters.keys.sorted().filter {
                        searchText.isEmpty || $0.contains(searchText.uppercased())
                    }
                    
                    ForEach(sortedKeys, id: \.self) { key in
                        Button(action: {
                            self.editingParam = key
                            self.newValue = String(format: "%.4f", vm.system.parameters[key] ?? 0)
                        }) {
                            HStack {
                                Text(key).font(.system(size: 12, design: .monospaced))
                                    .frame(width: 200, alignment: .leading)
                                
                                Text(String(format: "%.4f", vm.system.parameters[key] ?? 0))
                                    .font(.system(size: 12, weight: .bold))
                                    .frame(width: 100, alignment: .leading)
                                    .foregroundColor(.qgcAccent)
                                
                                Spacer()
                                Image(systemName: "pencil.line").foregroundColor(.gray).font(.caption)
                            }
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal)
                        .frame(height: 35)
                        .background(Color.white.opacity(0.02))
                        
                        Divider().background(Color.white.opacity(0.05))
                    }
                }
            }
        }
        .alert("Change Parameter", isPresented: Binding(get: { editingParam != nil }, set: { if !$0 { editingParam = nil } })) {
            TextField("New Value", text: $newValue)
            Button("CANCEL", role: .cancel) { editingParam = nil }
            Button("WRITE TO VEHICLE") {
                if let key = editingParam, let val = Float(newValue) {
                    vm.system.setParameter(name: key, value: val)
                }
                editingParam = nil
            }
        } message: {
            Text("Enter new value for \(editingParam ?? "")")
        }
    }
}
