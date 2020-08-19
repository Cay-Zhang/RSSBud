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
        case .systemDefaultReader:
            return feedURL.replacing(scheme: "feed")
        case .reeder:
            return feedURL.replacing(scheme: "reeder")
        case .fieryFeeds:
            return feedURL.string
                .flatMap {
                    URLComponents(string: "fiery://subscribe/\($0)")
                }
        
        case .feedly:
            return feedURL.string
                .flatMap {
                    URLComponents(string: "https://feedly.com/i/subscription/feed/\($0)")
                }
        case .inoreader:
            return feedURL.string
                .map { [URLQueryItem(name: "add_feed", value: $0)] }
                .flatMap {
                    URLComponents(string: "https://www.inoreader.com")?.appending(queryItems: $0)
                }
        case .feedbin:
            return feedURL.string
                .map { [URLQueryItem(name: "subscribe", value: $0)] }
                .flatMap {
                    URLComponents(string: "https://feedbin.com")?.appending(queryItems: $0)
                }
        case .theOldReader:
            return feedURL.string
                .map { [URLQueryItem(name: "url", value: $0)] }
                .flatMap {
                    URLComponents(string: "https://theoldreader.com/feeds/subscribe")?.appending(queryItems: $0)
                }
        case .feedsPub:
            return feedURL.string
                .flatMap {
                    URLComponents(string: "https://feeds.pub/feed/\($0)")
                }
        }
    }
    
}

extension Integration {
    enum Key: String, Identifiable, Hashable, CaseIterable {
        case systemDefaultReader = "Default"
        case reeder = "Reeder"
        case fieryFeeds = "Fiery Feeds"
        
        case feedly = "Feedly"
        case inoreader = "Inoreader"
        case feedbin = "Feedbin"
        case theOldReader = "The Old Reader"
        case feedsPub = "Feeds Pub"
        
        var id: String { rawValue }
    }
}
