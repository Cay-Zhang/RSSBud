//
//  Integration.swift
//  RSSBud
//
//  Created by Cay Zhang on 2020/8/17.
//

import SwiftUI


@propertyWrapper struct Integration: DynamicProperty {
    @AppStorage("integrations", store: RSSBud.userDefaults) var integrationKeys: String = Key.reeder.rawValue + "\n" + Key.inoreader.rawValue
    
    var wrappedValue: [Key] {
        get {
            integrationKeys.split(separator: "\n").compactMap { Key(rawValue: String($0)) }
        }
        nonmutating set {
            integrationKeys = newValue.map(\.rawValue).joined(separator: "\n")
        }
    }
    
    var projectedValue: Binding<Set<Key>> {
        Binding(get: {
            Set(wrappedValue)
        }, set: { newValue in
            wrappedValue = Array(newValue)
        })
    }
    
    static func url(forAdding feedURL: URLComponents, to key: Integration.Key) -> URLComponents? {
        switch key {
        case .inoreader:
            return feedURL.string
                .map { [URLQueryItem(name: "add_feed", value: $0)] }
                .flatMap {
                    URLComponents(string: "https://www.inoreader.com")?.appending(queryItems: $0)
                }
        case .reeder:
            var url = feedURL
            url.scheme = "reeder"
            return url
        }
    }
    
}

extension Integration {
    enum Key: String, Identifiable, Hashable, CaseIterable {
        case inoreader = "Inoreader"
        case reeder = "Reeder"
        
        var id: String { rawValue }
    }
}
