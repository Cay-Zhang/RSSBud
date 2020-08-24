//
//  SettingsView.swift
//  RSSBud
//
//  Created by Cay Zhang on 2020/8/10.
//

import SwiftUI

struct SettingsView: View {
    var storedBaseURL = RSSHub.BaseURL()
    @State var baseURLString: String
    @State var isAlertPresented = false
    
    @Integration var integrations
    
    init() {
        _baseURLString = State(wrappedValue: storedBaseURL.string)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("RSSHub")) {
                    TextField(
                        "Base URL",
                        text: $baseURLString,
                        onCommit: {
                            if storedBaseURL.validate(string: baseURLString) {
                                storedBaseURL.string = baseURLString
                            } else {
                                isAlertPresented = true
                            }
                        }
                    )
                    
                    Button("Refresh Rules") {
                        RSSHub.Radar.refreshRules()
                    }
                }
                
                NavigationLink("Integrations", destination:
                    List(selection: $integrations) {
                        ForEach(Integration.Key.allCases) { key in
                            Text(key.rawValue).tag(key)
                        }
                    }.listStyle(InsetListStyle())
                    .navigationTitle("Integrations")
                    .environment(\.editMode, .constant(.active))
                )
            }.navigationTitle("Settings")
        }.alert(isPresented: $isAlertPresented) {
            Alert(title: Text("Base URL is invalid."))
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
