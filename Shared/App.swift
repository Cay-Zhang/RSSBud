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
