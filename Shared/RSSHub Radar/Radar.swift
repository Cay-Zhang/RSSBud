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
        
        static var cancelBag = Set<AnyCancellable>()
        
        static let directoryURL: URL = {
            let url = FileManager
                .default
                .containerURL(forSecurityApplicationGroupIdentifier: RSSBud.appGroupIdentifier)!
                .appendingPathComponent("RSSHub", isDirectory: true)
                .appendingPathComponent("Radar", isDirectory: true)
            
            try! FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
            
            return url
        }()
        
        static let localRules = try! PersistentFile(
            url: RSSHub.Radar.directoryURL.appendingPathComponent("radar-rules.js", isDirectory: false),
            defaultContentURL: Bundle.main.url(forResource: "radar-rules", withExtension: "js")!
        )
        
        static let onFinishReloadingRules = ObservableObjectPublisher()
        
        static let jsContext: JSContext = {
            let context = JSContext()!
            
            context.exceptionHandler = { context, value in
                guard let value = value,
                      let stack = value.objectForKeyedSubscript("stack").toString(),
                      let line = value.objectForKeyedSubscript("line").toString(),
                      let column = value.objectForKeyedSubscript("column").toString()
                else { assertionFailure("Can't get error info."); return }
                print("Radar JSContext Error [\(line):\(column)]: \(value)\nTraceback:\n\(stack)")
            }
            
            // Load Rules
            _ = context.evaluateScript(localRules.content)
            
            // Polyfills
            context.setObject(context.globalObject, forKeyedSubscript: "window" as NSString)
            
            _ = context.evaluateScript("""
                function setTimeout() { }
                function clearTimeout() { }
                function setInterval() { }
                """)
            
            // Load Radar
            _ = context.evaluateScript(fileNamed: "radar.min")
            
            _ = context.evaluateScript("""
                const radar = require('radar');
                """)
            
            // Reload Rules on Changes
            localRules.contentPublisher
                .dropFirst()
                .debounce(for: 0.5, scheduler: DispatchQueue.main)
                .removeDuplicates()
                .sink { rules in
                    print("Reloading rules...")
                    _ = context.evaluateScript(rules)
                    onFinishReloadingRules.send()
                }.store(in: &cancelBag)
            
            return context
        }()
        
        static func asyncExpandURLAndGetHTML(for urlComponents: URLComponents) -> AnyPublisher<(url: URLComponents, html: String?), Never> {
            guard let url = urlComponents.url else { return Empty(completeImmediately: true).eraseToAnyPublisher() }
            var request = URLRequest(url: url)
            let userAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_6) AppleWebKit/605.1.12 (KHTML, like Gecko) Version/11.1 Safari/605.1.12"
            request.addValue(userAgent, forHTTPHeaderField: "User-Agent")

            return URLSession.shared.dataTaskPublisher(for: request)
                .compactMap {
                    let url = $0.response.url?.components ?? urlComponents
                    let html = String(data: $0.data, encoding: .utf8)
                        ?? String(data: $0.data, encoding: .ascii)
                    return (url: url, html: html)
                }.replaceError(with: (url: urlComponents, html: nil))
                .eraseToAnyPublisher()
        }
        
        static func detecting(url: URLComponents, html: String = "") -> AnyPublisher<[DetectedFeed], Error> {
            Future { promise in
                guard url.host != nil else { promise(.failure(DetectionError.hostNotFound(url: url))); return }
                print(html)
                
                RSSHub.Radar.jsContext.setObject(html, forKeyedSubscript: "html" as NSString)
                
                let jsonString = RSSHub.Radar.jsContext.evaluateScript("""
                    JSON.stringify(radar.getPageRSSHub({
                        url: "\(url.string ?? "")",
                        html: html,
                        rules: rules
                    }));
                    """
                )!.toString()!
                let data = jsonString.data(using: .utf8)!
                let result = Result { try JSONDecoder().decode([RSSHub.Radar.DetectedFeed].self, from: data) }
                promise(result)
            }.eraseToAnyPublisher()
        }
        
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
        
        var localizedDescription: String {
            switch self {
            case .hostNotFound(let url):
                return "Host not found in URL \"\(url)\"."
            case .decodingFailure(let error):
                return error.localizedDescription
            }
        }
    }
}

