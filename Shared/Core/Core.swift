//
//  Core.swift
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

enum Core {
    
    static var cancelBag = Set<AnyCancellable>()
    
    static let ruleDirectoryURL: URL = {
        let url = FileManager
            .default
            .containerURL(forSecurityApplicationGroupIdentifier: RSSBud.appGroupIdentifier)!
            .appendingPathComponent("Core", isDirectory: true)
            .appendingPathComponent("Rules", isDirectory: true)
        
        try! FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
        
        return url
    }()
    
    static let onFinishReloadingChangedRules = ObservableObjectPublisher()
    
    private static func loadRules(for context: JSContext) {
        _ = context.evaluateScript("""
            var ruleFiles = new Map();
            """)
        for (info, file) in zip(RuleManager.shared.ruleFilesInfo, RuleManager.shared.ruleFiles) {
            context.setObject(info.filename, forKeyedSubscript: "filename" as NSString)
            context.setObject(context.evaluateScript(file.content), forKeyedSubscript: "content" as NSString)
            _ = context.evaluateScript("""
                ruleFiles.set(filename, content);
                """)
        }
    }
    
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
        loadRules(for: context)
        
        // Polyfills
        context.setObject(context.globalObject, forKeyedSubscript: "window" as NSString)
        
        _ = context.evaluateScript("""
            function setTimeout() { }
            function clearTimeout() { }
            function setInterval() { }
            """)
        
        // Load Radar
        _ = context.evaluateScript(fileNamed: "core.min")
        
        _ = context.evaluateScript("""
            const { URL } = require('whatwg-url');
            const core = require('core');
            """)
        
        // Reload Rules on Changes
        RuleManager.shared.onRuleFilesChange
            .debounce(for: 0.5, scheduler: DispatchQueue.main)
            .sink { rules in
                print("Reloading rules...")
                loadRules(for: context)
                onFinishReloadingChangedRules.send()
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
    
    static func analyzing(url: URLComponents, html: String) -> AnyPublisher<AnalysisResult, Error> {
        Future { promise in
            guard url.host != nil else { promise(.failure(DetectionError.hostNotFound(url: url))); return }
            print("Core Start Analyzing: \(url)")
            
            Core.jsContext.setObject(html, forKeyedSubscript: "html" as NSString)
            
            let jsonString = Core.jsContext.evaluateScript("""
                JSON.stringify(core.analyze(
                    "\(url.string ?? "")",
                    html,
                    ruleFiles
                ));
                """
            )!.toString()!
            let data = jsonString.data(using: .utf8)!
            let result = Result { try JSONDecoder().decode(AnalysisResult.self, from: data) }
            print("Core Finish Analyzing: \(result)")
            promise(result)
        }.flatMap { (result: AnalysisResult) -> AnyPublisher<AnalysisResult, Never> in
            let uncertainRSSFeeds = result.rssFeeds.filter { !$0.isCertain }
            if uncertainRSSFeeds.isEmpty {
                return Just(result).eraseToAnyPublisher()
            } else {
                let certainRSSFeeds = result.rssFeeds.filter { $0.isCertain }
                return uncertainRSSFeeds.publisher
                    .flatMap { $0.validated() }
                    .collect()
                    .map { verifiedFeeds in
                        AnalysisResult(rssFeeds: certainRSSFeeds + verifiedFeeds, rssHubFeeds: result.rssHubFeeds)
                    }.prepend(AnalysisResult(rssFeeds: certainRSSFeeds, rssHubFeeds: result.rssHubFeeds))
                    .eraseToAnyPublisher()
            }
        }.eraseToAnyPublisher()
    }
    
    static func analyzing(contentsOf url: URLComponents) -> AnyPublisher<AnalysisResult, Error> {
        Core.asyncExpandURLAndGetHTML(for: url)
            .prepend((url: url, html: ""))
            .flatMap { tuple in
                Core.analyzing(url: tuple.url, html: tuple.html ?? "")
            }.scan(Core.AnalysisResult()) {
                Core.AnalysisResult.combine($0, $1)
            }.replaceEmpty(with: Core.AnalysisResult())
            .eraseToAnyPublisher()
    }
    
    struct AnalysisResult: Codable {
        var rssFeeds: [RSSFeed] = []
        var rssHubFeeds: [RSSHubFeed] = []
        
        static func combine(_ left: Self, _ right: Self) -> Self {
            var result = left
            if left.rssFeeds.count < right.rssFeeds.count {
                result.rssFeeds = right.rssFeeds
            }
            if left.rssHubFeeds.count < right.rssHubFeeds.count {
                result.rssHubFeeds = right.rssHubFeeds
            }
            return result
        }
    }
    
}


struct RSSFeed: Codable {
    @URLString var url: URLComponents
    var title: String
    @URLString var imageURL: URLComponents
    var isCertain: Bool
    
    func validated() -> AnyPublisher<Self, Never> {
        RSSFeed.isValid(url: self.url)
            .filter { $0 }
            .map { _ in
                var copy = self
                copy.isCertain = true
                return copy
            }.eraseToAnyPublisher()
    }
    
    static func isValid(url: URLComponents) -> AnyPublisher<Bool, Never> {
        guard let _url = url.url else {
            assertionFailure()
            return Just(false).eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: _url)
        request.httpMethod = "HEAD"
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .map {
                let isValid = $0.response.mimeType.map(mimeTypes.contains) ?? false
                print("RSSFeed Validity of \(url): \(isValid) (MIME Type: \($0.response.mimeType ?? "N/A"))")
                return isValid
            }.replaceError(with: false)
            .eraseToAnyPublisher()
    }
    
    static let mimeTypes: [String] = [
        "application/rss+xml",
        "application/atom+xml",
        "application/rdf+xml",
        "application/rss",
        "application/atom",
        "application/rdf",
        "text/rss+xml",
        "text/atom+xml",
        "text/rdf+xml",
        "text/rss",
        "text/atom",
        "text/rdf"
    ]
}

struct RSSHubFeed: Codable {
    var title: String
    var path: String
    @URLString var docsURL: URLComponents
}

extension Core {
    enum DetectionError: LocalizedError {
        case hostNotFound(url: URLComponents)
        case decodingFailure(error: DecodingError)
        
        var errorDescription: String? {
            switch self {
            case .hostNotFound(let url):
                return String(localized: "Host not found in URL \(url.string ?? "").")
            case .decodingFailure(let error):
                return error.errorDescription
            }
        }
    }
}

