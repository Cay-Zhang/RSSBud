//
//  RuleManager.swift
//  RSSBud
//
//  Created by Cay Zhang on 2020/12/5.
//

import SwiftUI
import Combine
import BackgroundTasks

class RuleManager: ObservableObject {
    
    static let shared: RuleManager = RuleManager()
    
    let remoteRulesFetchTaskIdentifier = "me.CayZhang.RSSBud.fetchRemoteRSSHubRadarRules"
    
    @Published var isFetchingRemoteRules: Bool = false
    
    @AppStorage("lastRSSHubRadarRemoteRulesFetchDate", store: RSSBud.userDefaults) var _lastRemoteRulesFetchDate: Double?
    
    var cancelBag = Set<AnyCancellable>()
    
    init() {
        Core.localRadarRuleFile.contentPublisher
            .dropFirst()
            .map { _ in Date() }
            .receive(on: DispatchQueue.main)
            .assign(to: \.lastRemoteRulesFetchDate, on: self)
            .store(in: &cancelBag)
    }
    
    func fetchRemoteRules() {
        withAnimation { isFetchingRemoteRules = true }
        
        remoteRules()
            .sink { completion in
                if case let .failure(error) = completion {
                    print(error)
                }
            } receiveValue: { [weak self] string in
                Core.localRadarRuleFile.content = string
                DispatchQueue.main.async {
                    withAnimation {
                        self?.isFetchingRemoteRules = false
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
                Core.localRadarRuleFile.content = string
                DispatchQueue.main.async {
                    withAnimation {
                        self?.isFetchingRemoteRules = false
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
    
    func remoteRules() -> AnyPublisher<String, URLError> {
        let urls = ["https://rsshub.js.org/build/radar-rules.js", "https://cdn.jsdelivr.net/gh/DIYgod/RSSHub@gh-pages/build/radar-rules.js"]
            .compactMap(URL.init(string:))
        
        return urls
            .enumerated()
            .publisher
            .flatMap(maxPublishers: .max(1)) { tuple -> AnyPublisher<String, URLError> in
                let (index, url) = tuple
                return URLSession.shared.dataTaskPublisher(for: url)
                    .compactMap { output in
                        String(data: output.data, encoding: .utf8)
                    }.catch { (error: URLError) -> AnyPublisher<String, URLError> in
                        if index == urls.count - 1 {
                            return Fail(outputType: String.self, failure: error).eraseToAnyPublisher()
                        } else {
                            return Empty(completeImmediately: true).eraseToAnyPublisher()
                        }
                    }.eraseToAnyPublisher()
            }.first()
            .eraseToAnyPublisher()
    }
}
