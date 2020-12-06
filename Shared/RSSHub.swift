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
        
        /// The default access key can't be empty.
        static let defaultAccessKey: String = "ILoveRSSHub"
        
        @State private var viewRefresher = false
        @Binding var isAccessControlEnabled: Bool
        @Binding var accessKey: String?
        @Binding var unwrappedAccessKey: String
        
        init() {
            _isAccessControlEnabled = .constant(false)
            _accessKey = .constant(nil)
            _unwrappedAccessKey = .constant("")
            update()
        }
        
        mutating func update() {
            _accessKey = Binding<String?>(
                get: { [_viewRefresher] in
                    let _ = _viewRefresher.wrappedValue
                    return try? RSSBud.valet.string(forKey: AccessControl.valetKey)
                }, set: { [_viewRefresher] newValue in
                    if let newKey = newValue {
                        try? RSSBud.valet.setString(newKey, forKey: AccessControl.valetKey)
                    } else {
                        try? RSSBud.valet.removeObject(forKey: AccessControl.valetKey)
                    }
                    _viewRefresher.wrappedValue.toggle()
                }
            )
            
            _isAccessControlEnabled = Binding<Bool>(
                get: { [_accessKey] in
                    _accessKey.wrappedValue != nil
                }, set: { [_accessKey] newValue in
                    withAnimation {
                        if newValue && _accessKey.wrappedValue == nil {
                            _accessKey.wrappedValue = AccessControl.defaultAccessKey
                        } else if !newValue && _accessKey.wrappedValue != nil {
                            _accessKey.wrappedValue = nil
                        }
                    }
                }
            )
            
            _unwrappedAccessKey = Binding<String>(
                get: { [_accessKey] in
                    _accessKey.wrappedValue ?? ""
                }, set: { [_accessKey] newValue in
                    _accessKey.wrappedValue = newValue
                }
            )
        }
        
        func accessCode(for route: String) -> String? {
            accessKey.map { key in
                (route + key).md5()
            }
        }
    }
}
