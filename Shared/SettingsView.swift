//
//  SettingsView.swift
//  RSSBud
//
//  Created by Cay Zhang on 2020/8/10.
//

import SwiftUI

struct SettingsView: View {
    
    @AppStorage("baseURLString", store: UserDefaults(suiteName: RSSBud.appGroupContainerName)) var storedBaseURLString: String = Radar.defaultBaseURLString
    @State var baseURLString: String
    @State var isAlertPresented = false
    
    init() {
        _baseURLString = State(wrappedValue: _storedBaseURLString.wrappedValue)
    }
    
    var body: some View {
        NavigationView {
            Form {
                TextField(
                    "Base URL",
                    text: $baseURLString,
                    onCommit: {
                        if URLComponents(string: baseURLString)?.host != nil {
                            storedBaseURLString = baseURLString
                        } else {
                            isAlertPresented = true
                        }
                    }
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
