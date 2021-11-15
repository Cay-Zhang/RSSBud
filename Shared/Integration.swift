//
//  Integration.swift
//  RSSBud
//
//  Created by Cay Zhang on 2020/8/17.
//

import SwiftUI


@propertyWrapper struct Integration: DynamicProperty {
    @AppStorage("integrations", store: RSSBud.userDefaults) var integrationKeys: String = Key.reeder.rawValue + "\n" + Key.inoreader.rawValue
    
    @AppStorage("ttrssBaseURL", store: RSSBud.userDefaults) var ttrssBaseURLString: String = "https://tt-rss.example.com"
    @AppStorage("minifluxBaseURL", store: RSSBud.userDefaults) var minifluxBaseURLString: String = "https://miniflux.example.com"
    @AppStorage("freshRSSBaseURL", store: RSSBud.userDefaults) var freshRSSBaseURLString: String = "https://fresh-rss.example.com"
    
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
    
    func url(forAdding feedURL: URLComponents, to key: Integration.Key) -> URLComponents? {
        switch key {
        case .systemDefaultReader:
            return feedURL.prepending("feed:")
        case .egoReader:
            return feedURL.string
                .map { [URLQueryItem(name: "url", value: $0)] }
                .flatMap {
                    URLComponents(string: "egoreader://subscribe")?.appending(queryItems: $0)
                }
        case .reeder:
            return feedURL.prepending("reeder:")
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
        
        case .tinyTinyRSS:
            return ttrssBaseURL?
                .appending(path: "/public.php")
                .appending(queryItems: [URLQueryItem(name: "op", value: "bookmarklets--subscribe"), URLQueryItem(name: "feed_url", value: feedURL.string)])
        case .miniflux:
            return minifluxBaseURL?
                .appending(path: "/bookmarklet")
                .appending(queryItems: [URLQueryItem(name: "uri", value: feedURL.string)])
        case .freshRSS:
            return freshRSSBaseURL?
                .appending(path: "/i/")
                .appending(queryItems: [
                    URLQueryItem(name: "c", value: "feed"),
                    URLQueryItem(name: "a", value: "add"),
                    URLQueryItem(name: "url_rss", value: feedURL.string)
                ])
        }
    }
    
}

extension Integration {
    enum Key: String, Identifiable, Hashable, CaseIterable {
        case systemDefaultReader = "Default"
        case egoReader = "Ego Reader"
        case reeder = "Reeder"
        case fieryFeeds = "Fiery Feeds"
        
        case feedly = "Feedly"
        case inoreader = "Inoreader"
        case feedbin = "Feedbin"
        case theOldReader = "The Old Reader"
        case feedsPub = "Feeds Pub"
        
        case tinyTinyRSS = "Tiny Tiny RSS"
        case miniflux = "Miniflux"
        case freshRSS = "Fresh RSS"
        
        var id: String { rawValue }
    }
}

extension Integration {
    var ttrssBaseURL: URLComponents? {
        get { URLComponents(string: ttrssBaseURLString) }
    }
    
    var minifluxBaseURL: URLComponents? {
        get { URLComponents(string: minifluxBaseURLString) }
    }
    
    var freshRSSBaseURL: URLComponents? {
        get { URLComponents(string: freshRSSBaseURLString) }
    }
}
