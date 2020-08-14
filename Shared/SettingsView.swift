//
//  SettingsView.swift
//  RSSBud
//
//  Created by Cay Zhang on 2020/8/10.
//

import SwiftUI

struct SettingsView: View {
    var storedBaseURL = RSSBud.BaseURL()
    @State var baseURLString: String
    @State var isAlertPresented = false
    
    init() {
        _baseURLString = State(wrappedValue: storedBaseURL.string)
    }
    
    var body: some View {
        NavigationView {
            Form {
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
