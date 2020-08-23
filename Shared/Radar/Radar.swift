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

enum Radar {
    
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
        _ = context.evaluateScript(fileNamed: "radar-rules")

        // Load Utils
        _ = context.evaluateScript(fileNamed: "utils")
        return context
    }()
    
    static func detecting(url: URLComponents) -> Future<[DetectedFeed], DetectionError> {
        Future { promise in
            guard let host = url.host else { promise(.failure(.hostNotFound(url: url))); return }
            
            let result = Result<[DetectedFeed], Error> {
                let jsonString = Radar.jsContext.evaluateScript("""
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
                return try JSONDecoder().decode([Radar.DetectedFeed].self, from: data)
            }.mapError {
                DetectionError.decodingFailure(error: $0 as! DecodingError)
            }
            
            promise(result)
            
        }
    }
    
}

extension Radar {
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

extension Radar {
    enum DetectionError: Error {
        case hostNotFound(url: URLComponents)
        case decodingFailure(error: DecodingError)
        case noResults
    }
}
