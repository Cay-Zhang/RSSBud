//
//  RSSBud.swift
//  RSSBud
//
//  Created by Cay Zhang on 2020/8/13.
//

import SwiftUI

enum RSSBud {
    static let appGroupContainerName: String = "group.me.cayZ.RSSBud"
    static let userDefaults: UserDefaults = UserDefaults(suiteName: appGroupContainerName)!
    static var defaultBaseURLString: String = "https://example.com"
}

extension RSSBud {
    @propertyWrapper struct BaseURL: DynamicProperty {
        @AppStorage("baseURLString", store: RSSBud.userDefaults) var string: String = RSSBud.defaultBaseURLString
        
        var wrappedValue: URLComponents {
            get {
                URLComponents(string: string)!
            }
        }
        
        func validate(string: String) -> Bool {
            URLComponents(string: string)?.host != nil
        }
    }
}
