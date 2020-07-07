import Foundation
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
    private static let jsContext: JSContext = {
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
    
}

extension Radar {
    struct DetectedFeed {
        var title: String
        var path: String
    }
}

extension Radar {
    enum DetectionError: Error {
        case hostNotFound(url: URL)
        case noResults
    }
}

let cancellable = Radar.detecting(url: URL(string: "https://matters.news/@mh111000/comments")!)
    .sink { completion in
        
    } receiveValue: { feeds in
        print(feeds)
    }

