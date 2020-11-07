//
//  App.swift
//  Shared
//
//  Created by Cay Zhang on 2020/7/5.
//

import SwiftUI
import BackgroundTasks

extension RSSBud {
    
    @main
    struct App: SwiftUI.App {
        
        @StateObject var contentViewModel = ContentView.ViewModel()
        
        init() {
            BGTaskScheduler.shared.register(forTaskWithIdentifier: RSSHub.Radar.rulesCenter.remoteRulesFetchTaskIdentifier, using: nil) { task in
                print("Running task...")
                RSSHub.Radar.rulesCenter.fetchRemoteRules(withAppRefreshTask: task as! BGAppRefreshTask)
                RSSHub.Radar.rulesCenter.scheduleRemoteRulesFetchTask()
            }
            RSSHub.Radar.rulesCenter.scheduleRemoteRulesFetchTask()
            
            // temp workaround for list background
            UITableView.appearance().backgroundColor = UIColor.clear
            
            #if DEBUG
            // prepare for promo asset generation
            let pageIndex = UserDefaults.standard.integer(forKey: "promo-asset-generation")
            if pageIndex != 0 {
                prepareForPromoAssetGeneration(pageIndex: pageIndex)
            }
            #endif
        }
        
        var body: some Scene {
            WindowGroup {
                ContentView(
                    openURL: { urlComponents in
                        guard let url = urlComponents.url else {
                            assertionFailure("URL conversion failed.")
                            return
                        }
                        UIApplication.shared.open(url)
                    }, viewModel: contentViewModel
                )
            }
        }
    }
    
}

#if DEBUG
extension RSSBud.App {
    mutating func prepareForPromoAssetGeneration(pageIndex: Int) {
        if pageIndex == 1 {
            AppStorage<Bool?>("isOnboarding", store: RSSBud.userDefaults).wrappedValue = false
            Integration().wrappedValue = [.reeder]
            
            let contentViewModel = ContentView.ViewModel(
                originalURL: URLComponents(string: "https://space.bilibili.com/50333369/"),
                detectedFeeds: [
                    RSSHub.Radar.DetectedFeed(title: "当前 UP 主动态", path: "/bilibili/video/reply/test1"),
                    RSSHub.Radar.DetectedFeed(title: "当前 UP 主投稿", path: "/bilibili/video/reply/test2")
                ], queryItems: [
                    URLQueryItem(name: "filter_title", value: "上海")
                ]
            )
            
            self._contentViewModel = StateObject(wrappedValue: contentViewModel)
        } else if pageIndex == 2 {
            AppStorage<Bool?>("isOnboarding", store: RSSBud.userDefaults).wrappedValue = false
            RSSHub.BaseURL().string = RSSHub.officialDemoBaseURLString
            let _lastRemoteRulesFetchDate = AppStorage<Double?>("lastRSSHubRadarRemoteRulesFetchDate", store: RSSBud.userDefaults)
            _lastRemoteRulesFetchDate.wrappedValue = Date(timeIntervalSinceNow: -60 * 5 + 3).timeIntervalSinceReferenceDate
        }
    }
}
#endif
