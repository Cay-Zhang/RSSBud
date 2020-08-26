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
    
    @ObservedObject var rulesCenter = RSSHub.Radar.rulesCenter
    
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
                }
                
                Section(header: Text("RSSHub Radar")) {
                    HStack {
                        Button(
                            rulesCenter.isRefreshing ? "Fetching Remote Rules" : "Fetch Remote Rules"
                        ) {
                            rulesCenter.fetchRemoteRules()
                        }.environment(\.isEnabled, !rulesCenter.isRefreshing)
                        
                        Spacer()
                        
                        if rulesCenter.isRefreshing {
                            ProgressView()
                        }
                    }
                    
                    NavigationLink(
                        "Edit Rules",
                        destination: RSSHub.Radar.RulesEditor()
                    )
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
        }
        .alert(isPresented: $isAlertPresented) {
            Alert(title: Text("Base URL is invalid."))
        }
    }
}

extension RSSHub.Radar {
    struct RulesEditor: View {
        @State var rules: String = RSSHub.Radar.rulesCenter.rules
        
        var body: some View {
            TextEditor(text: $rules)
                .font(.system(size: 12, weight: .light, design: .monospaced))
                .disableAutocorrection(true)
                .navigationTitle("Rules")
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            SettingsView()
            
            NavigationView {
                RSSHub.Radar.RulesEditor()
            }
        }
    }
}
