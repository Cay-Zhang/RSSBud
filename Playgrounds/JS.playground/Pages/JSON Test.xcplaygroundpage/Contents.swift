//: [Previous](@previous)

import SwiftUI
import JavaScriptCore
import Combine

let urlString = "https://space.bilibili.com/53456?spm_id_from=333.788.b_765f7570696e666f.2"
let encoded = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
let url = URL(string: encoded!)!

let results = Radar.jsContext.evaluateScript("""
    getPageRSSHub({
        url: "\(url.absoluteString)",
        host: "\(url.host!)",
        path: "\(url.path)",
        html: "",
        rules: rules
    });
    """
)?.toArray() as? [[String : Any]]

let feeds = results.map { (dicts: [[String : Any]]) -> [Radar.DetectedFeed] in
    dicts.compactMap { (dict: [String : Any]) -> Radar.DetectedFeed? in
        if let title = dict["title"] as? String, let path = dict["path"] as? String {
            return Radar.DetectedFeed(title: title, path: path)
        } else {
            return nil
        }
    }
}

let results2 = Radar.jsContext.evaluateScript("""
    JSON.stringify(getPageRSSHub({
        url: "\(url.absoluteString)",
        host: "\(url.host!)",
        path: "\(url.path)",
        html: "",
        rules: rules
    }));
    """
)!.toString()!
let results2_data = results2.data(using: .utf8)!
let feeds2 = try JSONDecoder().decode([Radar.DetectedFeed].self, from: results2_data)

//
//  Radar.swift
//  RSSBud
//
//  Created by Cay Zhang on 2020/7/6.
//

extension JSContext {
    func evaluateScript(fileNamed fileName: String) -> JSValue! {
        guard let path = Bundle.main.path(forResource: fileName, ofType: "js") else { fatalError() }
        let code = try! String(contentsOfFile: path)
        return evaluateScript(code, withSourceURL: URL(string: path))
    }
}

enum Radar {
    static var baseURL = URLComponents(string: "http://157.230.150.17:1200")!
    
    static let jsContext: JSContext = {
        let context = JSContext()!

        context.exceptionHandler = { _, value in
            guard let value = value else { return }
            print(value)
        }

        // Load Dependencies
        _ = context.evaluateScript(fileNamed: "psl.min")
        _ = context.evaluateScript(fileNamed: "route-recognizer.min")

        // Load Rules
        _ = context.evaluateScript(fileNamed: "radar-rules")

        // Load Utils
        _ = context.evaluateScript(fileNamed: "utils")
        return context
    }()
    
    static func detecting(url: URL) -> Future<[DetectedFeed], DetectionError> {
        Future { promise in
            guard let host = url.host else { promise(.failure(.hostNotFound(url: url))); return }
            
            let results = Radar.jsContext.evaluateScript("""
                getPageRSSHub({
                    url: "\(url.absoluteString)",
                    host: "\(host)",
                    path: "\(url.path)",
                    html: "",
                    rules: rules
                });
                """
            )?.toArray() as? [[String : Any]]
            
            let feeds = results.map { (dicts: [[String : Any]]) -> [DetectedFeed] in
                dicts.compactMap { (dict: [String : Any]) -> DetectedFeed? in
                    if let title = dict["title"] as? String, let path = dict["path"] as? String {
                        return DetectedFeed(title: title, path: path)
                    } else {
                        return nil
                    }
                }
            }
            
            if let feeds = feeds {
                promise(.success(feeds))
            } else {
                promise(.failure(.noResults))
            }
        }
    }
    
    static func addToInoreaderURL(forFeedURL feedURL: URLComponents) -> URLComponents {
        var url = URLComponents(string: "https://www.inoreader.com")!
        url.queryItems = [URLQueryItem(name: "add_feed", value: feedURL.string!)]
        return url
    }
    
}

extension Radar {
    struct DetectedFeed: Codable {
        var title: String
        var _url: String = ""
        var path: String
        var _isDocs: Bool?
        
        var url: URLComponents {
            var result = Radar.baseURL
            result.path = path
            return result
        }
        
        var isDocs: Bool {
            _isDocs == .some(true)
        }
        
        enum CodingKeys: String, CodingKey {
            case title
            case _url = "url"
            case path
            case _isDocs = "isDocs"
        }
    }
}

extension Radar {
    enum DetectionError: Error {
        case hostNotFound(url: URL)
        case noResults
    }
}
