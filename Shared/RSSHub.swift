//
//  RSSHub.swift
//  RSSBud
//
//  Created by Cay Zhang on 2020/8/24.
//

import SwiftUI

enum RSSHub {
    static var defaultBaseURLString: String = "https://rsshub.example.com"
    static var officialDemoBaseURLString: String = "https://rsshub.app"
}

extension RSSHub {
    @propertyWrapper struct BaseURL: DynamicProperty {
        @AppStorage("baseURLString", store: RSSBud.userDefaults) var string: String = RSSHub.defaultBaseURLString
        
        var wrappedValue: URLComponents {
            get {
                URLComponents(string: string)!
            }
        }
        
        func validate(string: String) -> Bool {
            URLComponents(string: string)?.host != nil
        }
    }
    
    struct AccessControl: DynamicProperty {
        static let valetKey: String = "rssHubAccessKey"
        
        @AppStorage("isRSSHubAccessControlEnabled", store: RSSBud.userDefaults) var isAccessControlEnabled: Bool = false
        @Binding var accessKey: String
        @State private var viewRefresher = false
        
        init() {
            _accessKey = .constant("")
            update()
        }
        
        mutating func update() {
            _accessKey = Binding<String>(
                get: { [_viewRefresher] in
                    let _ = _viewRefresher.wrappedValue
                    return (try? RSSBud.valet.string(forKey: AccessControl.valetKey)) ?? ""
                }, set: { [_viewRefresher] newValue in
                    if !newValue.isEmpty {
                        try? RSSBud.valet.setString(newValue, forKey: AccessControl.valetKey)
                    } else {
                        try? RSSBud.valet.removeObject(forKey: AccessControl.valetKey)
                    }
                    _viewRefresher.wrappedValue.toggle()
                }
            )
        }
        
        func accessCodeQueryItem(for route: String) -> [URLQueryItem] {
            if isAccessControlEnabled {
                return [URLQueryItem(name: "code", value: (route + accessKey).md5())]
            } else {
                return []
            }
        }
    }
}
