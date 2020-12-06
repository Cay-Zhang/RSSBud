//
//  RSSBud.swift
//  RSSBud
//
//  Created by Cay Zhang on 2020/8/13.
//

import SwiftUI
import Valet

enum RSSBud {
    static let appGroupIdentifier: String = "group.me.CayZhang.RSSBud"
    static let userDefaults: UserDefaults = UserDefaults(suiteName: appGroupIdentifier)!
    static let valet = Valet.sharedGroupValet(with: SharedGroupIdentifier(groupPrefix: "group", nonEmptyGroup: "me.CayZhang.RSSBud")!, accessibility: .whenUnlocked)
}
