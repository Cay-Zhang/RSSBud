//
//  RSSBudApp.swift
//  Shared
//
//  Created by Cay Zhang on 2020/7/5.
//

import SwiftUI

@main
struct RSSBudApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView(openURL: { urlComponents in
                guard let url = urlComponents.url else {
                    assertionFailure("URL conversion failed.")
                    return
                }
                UIApplication.shared.open(url)
            })
        }
    }
}
