//
//  Radar.swift
//  RSSBud
//
//  Created by Cay Zhang on 2020/7/6.
//

import SwiftUI
import JavaScriptCore
import Combine

extension JSContext {
    func evaluateScript(fileNamed fileName: String) -> JSValue! {
        guard let path = Bundle.main.path(forResource: fileName, ofType: "js") else { fatalError() }
        let code = try! String(contentsOfFile: path)
        return evaluateScript(code, withSourceURL: URL(string: path))
    }
}

extension RSSHub {
    enum Radar {
        
        static let directoryURL: URL = {
            let url = FileManager
                .default
                .containerURL(forSecurityApplicationGroupIdentifier: RSSBud.appGroupIdentifier)!
                .appendingPathComponent("RSSHub", isDirectory: true)
                .appendingPathComponent("Radar", isDirectory: true)
            
            try! FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
            
            return url
        }()
        
        static let localRulesURL: URL = directoryURL.appendingPathComponent("radar-rules.js", isDirectory: false)
        
        static func refreshRules() {
            URLSession.shared.dataTaskPublisher(for: URL(string: "https://cdn.jsdelivr.net/gh/DIYgod/RSSHub@master/assets/radar-rules.js")!)
                .compactMap { output in
                    String(data: output.data, encoding: .utf8)
                }.sink { _ in
                    
                } receiveValue: { string in
                    
                    do {
                        try storeRules(string: "var rules = " + string)
                        print("Rules stored")
                        jsContext.evaluateScript("var rules = " + string)
                        print("Rules loaded")
                    } catch {
                        print(error)
                    }
                    
                }.store(in: &cancelBag)
        }
        
        static func storeRules(string: String) throws {
            try string.write(to: localRulesURL, atomically: true, encoding: .utf8)
        }
        
        static let jsContext: JSContext = {
            let context = JSContext()!
            
            context.exceptionHandler = { _, value in
                guard let value = value else { return }
                print(value)
            }

            // Load Dependencies
            _ = context.evaluateScript(fileNamed: "url.min")
            _ = context.evaluateScript(fileNamed: "psl.min")
            _ = context.evaluateScript(fileNamed: "route-recognizer.min")

            // Load Rules
            if FileManager.default.fileExists(atPath: localRulesURL.path) {
                print("Loading local rules")
                _ = context.evaluateScript(try! String(contentsOf: localRulesURL, encoding: .utf8))
            } else {
                print("Loading bundled rules")
                _ = context.evaluateScript(fileNamed: "radar-rules")
            }
            
            // Load Utils
            _ = context.evaluateScript(fileNamed: "utils")
            return context
        }()
        
        static func detecting(url: URLComponents) -> Future<[DetectedFeed], DetectionError> {
            Future { promise in
                guard let host = url.host else { promise(.failure(.hostNotFound(url: url))); return }
                
                let result = Result<[DetectedFeed], Error> {
                    let jsonString = RSSHub.Radar.jsContext.evaluateScript("""
                        JSON.stringify(getPageRSSHub({
                            url: "\(url.string ?? "")",
                            host: "\(host)",
                            path: "\(url.path)",
                            html: "",
                            rules: rules
                        }));
                        """
                    )!.toString()!
                    let data = jsonString.data(using: .utf8)!
                    return try JSONDecoder().decode([RSSHub.Radar.DetectedFeed].self, from: data)
                }.mapError {
                    DetectionError.decodingFailure(error: $0 as! DecodingError)
                }
                
                promise(result)
                
            }
        }
        
        static var cancelBag: Set<AnyCancellable> = []
        
    }
}

extension RSSHub.Radar {
    struct DetectedFeed: Codable {
        var title: String
        var _url: String = ""
        var path: String
        var _isDocs: Bool?
        
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

extension RSSHub.Radar {
    enum DetectionError: Error {
        case hostNotFound(url: URLComponents)
        case decodingFailure(error: DecodingError)
        case noResults
    }
}
