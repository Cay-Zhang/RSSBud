//
//  RuleManager.swift
//  RSSBud
//
//  Created by Cay Zhang on 2020/12/5.
//

import SwiftUI
import Combine
import BackgroundTasks

struct RuleFileInfo: Hashable, Codable, Identifiable {
    var id = UUID()
    var filename: String
    var remoteURL: URLComponents
    
    var isValid: Bool {
        filename.isValidFilename
    }
}

extension Sequence where Element == RuleFileInfo {
    var isValid: Bool {
        map(\.filename).isUnique() && map(\.remoteURL).isUnique() && allSatisfy(\.isValid)
    }
}

class RuleManager: ObservableObject {
    
    static let shared: RuleManager = RuleManager()
    
    static let bundledRuleFilesInfo: [RuleFileInfo] = [
        RuleFileInfo(filename: "radar-rules.js", remoteURL: "https://raw.githubusercontent.com/Cay-Zhang/RSSBudRules/main/rules/radar-rules.js"),
        RuleFileInfo(filename: "rssbud-rules.js", remoteURL: "https://raw.githubusercontent.com/Cay-Zhang/RSSBudRules/main/rules/rssbud-rules.js"),
    ]
    
    let remoteRulesFetchTaskIdentifier = "me.CayZhang.RSSBud.fetchRemoteRSSHubRadarRules"
    
    @Published var isFetchingRemoteRules: Bool = false
    
    @AppStorage("lastRSSHubRadarRemoteRulesFetchDate", store: RSSBud.userDefaults) var _lastRemoteRulesFetchDate: Double?
    @AppStorage("rules", store: RSSBud.userDefaults) @CodableAdaptor private(set) var ruleFilesInfo: [RuleFileInfo] = RuleManager.defaultRuleFilesInfo()
   
    private(set) lazy var ruleFiles: [PersistentFile] = RuleManager.ruleFiles(from: ruleFilesInfo)
    
    let onRuleFilesChange = ObservableObjectPublisher()
    
    private var ruleFilesMonitoringCancellable: AnyCancellable! = nil  // Never read
    var cancelBag = Set<AnyCancellable>()
    
    init() {
        ruleFilesMonitoringCancellable = Publishers.MergeMany(ruleFiles.map { $0.contentPublisher.dropFirst() })
            .map { _ in () }
            .receive(on: DispatchQueue.main)
            .sink { [onRuleFilesChange] in onRuleFilesChange.send() }
    }
    
    var lastRemoteRulesFetchDate: Date? {
        get { _lastRemoteRulesFetchDate.map(Date.init(timeIntervalSinceReferenceDate:)) }
        set { _lastRemoteRulesFetchDate = newValue?.timeIntervalSinceReferenceDate }
    }
    
    @discardableResult
    func updateRuleFilesInfo(_ newValue: [RuleFileInfo]) -> Bool {
        guard newValue.isValid else { return false }
        ruleFilesInfo = newValue
        ruleFiles = RuleManager.ruleFiles(from: newValue)
        ruleFilesMonitoringCancellable = Publishers.MergeMany(ruleFiles.map { $0.contentPublisher.dropFirst() })
            .map { _ in () }
            .prepend(())
            .sink { [onRuleFilesChange] in onRuleFilesChange.send() }
        return true
    }
    
    func fetchRemoteRules(withAppRefreshTask task: BGAppRefreshTask? = nil) {
        if let task {
            task.expirationHandler = {
                task.setTaskCompleted(success: false)
                self.cancelBag = []
            }
        }
        
        DispatchQueue.main.async {
            withAnimation { self.isFetchingRemoteRules = true }
        }
        
        remoteRuleFiles()
            .sink { [weak self] completion in
                DispatchQueue.main.async {
                    withAnimation {
                        self?.isFetchingRemoteRules = false
                    }
                    print("Task completed.")
                    task?.setTaskCompleted(success: completion == .finished)
                    if completion == .finished {
                        self?.lastRemoteRulesFetchDate = Date()
                    }
                }
            } receiveValue: { [weak self] ruleContents in
                for (filename, content) in ruleContents {
                    guard let index = self?.ruleFilesInfo.firstIndex(where: { $0.filename == filename }) else {
                        continue
                    }
                    self?.ruleFiles[index].content = content
                }
            }.store(in: &self.cancelBag)
    }
    
    func fetchRemoteRulesIfNeeded() {
        if lastRemoteRulesFetchDate.map({ Date().timeIntervalSince($0) >= 5 * 60 * 60 }) ?? true {
            fetchRemoteRules()
        }
    }
    
    private static func defaultRuleFileContentURL(for remoteURL: URLComponents) -> URL {
        if let info = bundledRuleFilesInfo.first(where: { $0.remoteURL == remoteURL }), let bundledRuleFileURL = Bundle.main.url(forResource: info.filename, withExtension: nil) {
            return bundledRuleFileURL
        } else {
            return Bundle.main.url(forResource: "empty-rules", withExtension: "js")!
        }
    }
    
    private static func defaultRuleFilesInfo() -> [RuleFileInfo] {
        guard let language = Bundle.preferredLocalizations(from: ["zh", "en-US"]).first, language != "zh" else { return bundledRuleFilesInfo }
        return [
            RuleFileInfo(filename: "radar-rules.\(language).js", remoteURL: URLComponents(string: "https://raw.githubusercontent.com/Cay-Zhang/RSSBudRules/main/rules/\(language)/radar-rules.js")!),
            RuleFileInfo(filename: "rssbud-rules.\(language).js", remoteURL: URLComponents(string: "https://raw.githubusercontent.com/Cay-Zhang/RSSBudRules/main/rules/\(language)/rssbud-rules.js")!),
        ]
    }
    
    private static func ruleFiles(from ruleFilesInfo: [RuleFileInfo]) -> [PersistentFile] {
        ruleFilesInfo.map { info in
            try! PersistentFile(
                url: Core.ruleDirectoryURL.appendingPathComponent("\(info.filename)", isDirectory: false),
                defaultContentURL: defaultRuleFileContentURL(for: info.remoteURL)
            )
        }
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
    
    func remoteRuleFiles() -> AnyPublisher<[String: String], URLError> {
        ruleFilesInfo
            .publisher
            .flatMap { info -> AnyPublisher<(String, String), URLError> in
                return URLSession.shared.dataTaskPublisher(for: info.remoteURL.url!)
                    .compactMap { output in
                        String(data: output.data, encoding: .utf8)
                    }.map { (content: String) -> (filename: String, content: String) in
                        (info.filename,  content)
                    }.eraseToAnyPublisher()
            }.collect()
            .map(Dictionary.init(uniqueKeysWithValues:))
            .eraseToAnyPublisher()
    }
}
