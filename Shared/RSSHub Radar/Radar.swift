//
//  Radar.swift
//  RSSBud
//
//  Created by Cay Zhang on 2020/7/6.
//

import SwiftUI
import JavaScriptCore
import Combine
import BackgroundTasks

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
            _ = context.evaluateScript(rulesCenter.rules)
            
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

extension RSSHub.Radar {
    
    static let rulesCenter = RulesCenter()
    
    class RulesCenter: ObservableObject {
        
        let remoteRulesFetchTaskIdentifier = "me.cayZ.RSSBud.fetchRemoteRSSHubRadarRules"
        
        @Published var isFetchingRemoteRules: Bool = false
        
        lazy var localRulesURL: URL = RSSHub.Radar.directoryURL.appendingPathComponent("radar-rules.js", isDirectory: false)
        
        lazy var rules: String = {
            
            if FileManager.default.fileExists(atPath: self.localRulesURL.path),
               let string = try? String(contentsOf: localRulesURL, encoding: .utf8) {
                print("Loading local rules")
                return string
            } else {
                print("Loading bundled rules")
                return bundledRules()
            }
            
        }()
        
        @AppStorage("lastRSSHubRadarRemoteRulesFetchDate", store: RSSBud.userDefaults) var _lastRemoteRulesFetchDate: Double?
        
        var cancelBag = Set<AnyCancellable>()
        
        func setRules(_ string: String) {
            // Var
            self.rules = string
            // jscontext
            _ = RSSHub.Radar.jsContext.evaluateScript(string)
            // local
            try? string.write(to: localRulesURL, atomically: true, encoding: .utf8)
        }
        
        func fetchRemoteRules() {
            withAnimation { isFetchingRemoteRules = true }
            
            remoteRules()
                .sink { completion in
                    
                } receiveValue: { [weak self] string in
                    self?.setRules(string)
                    DispatchQueue.main.async {
                        withAnimation {
                            self?.isFetchingRemoteRules = false
                            self?.lastRemoteRulesFetchDate = Date()
                        }
                    }
                }.store(in: &self.cancelBag)
        }
        
        var lastRemoteRulesFetchDate: Date? {
            get { _lastRemoteRulesFetchDate.map(Date.init(timeIntervalSinceReferenceDate:)) }
            set { _lastRemoteRulesFetchDate = newValue?.timeIntervalSinceReferenceDate }
        }
        
        func fetchRemoteRules(withAppRefreshTask task: BGAppRefreshTask) {
            task.expirationHandler = {
                task.setTaskCompleted(success: false)
                self.cancelBag = []
            }
            
            DispatchQueue.main.sync {
                withAnimation { self.isFetchingRemoteRules = true }
            }
            
            remoteRules()
                .sink { completion in
                    if case .failure(_) = completion {
                        task.setTaskCompleted(success: false)
                    }
                } receiveValue: { [weak self] string in
                    self?.setRules(string)
                    DispatchQueue.main.async {
                        withAnimation {
                            self?.isFetchingRemoteRules = false
                            self?.lastRemoteRulesFetchDate = Date()
                        }
                        print("Task completed.")
                        task.setTaskCompleted(success: true)
                    }
                }.store(in: &self.cancelBag)
        }
        
        func scheduleRemoteRulesFetchTask() {
            let earliestBeginDate: Date
            if !isFetchingRemoteRules, let date = lastRemoteRulesFetchDate {
                earliestBeginDate = date.addingTimeInterval(5 * 60 * 60)
            } else {
                earliestBeginDate = Date(timeIntervalSinceNow: 5 * 60 * 60)
            }
            
            print("Scheduling task...")
            let taskRequest = BGAppRefreshTaskRequest(identifier: remoteRulesFetchTaskIdentifier)
            taskRequest.earliestBeginDate = earliestBeginDate
            do {
                try BGTaskScheduler.shared.submit(taskRequest)
            } catch {
                print("Unable to submit task: \(error.localizedDescription)")
            }
        }
        
        func remoteRules() -> Publishers.CompactMap<URLSession.DataTaskPublisher, String> {
            URLSession.shared.dataTaskPublisher(for: URL(string: "https://cdn.jsdelivr.net/gh/DIYgod/RSSHub@master/assets/radar-rules.js")!)
                .compactMap { output in
                    String(data: output.data, encoding: .utf8)
                }.map { "var rules = " + $0 }
        }
        
        func bundledRules() -> String {
            guard let path = Bundle.main.path(forResource: "radar-rules", ofType: "js") else { fatalError() }
            return try! String(contentsOfFile: path)
        }
    }
}
