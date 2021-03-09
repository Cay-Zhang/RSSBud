//
//  CustomOpenURL.swift
//  RSSBud
//
//  Created by Cay Zhang on 2020/12/29.
//

import SwiftUI
import SafariServices
import BetterSafariView

struct CustomOpenURLAction {
    
    enum Mode: Int, RawRepresentable {
        case inApp = 0
        case system = 1
    }
    
    var defaultMode: Mode
    var openInApp: (URL) -> Void = { _ in }
    var openInSystem: (URL) -> Void = { _ in }
    
    func callAsFunction(_ url: URLComponents, mode: Mode) {
        guard let url = url.url else {
            assertionFailure("URL conversion failed.")
            return
        }
        
        guard mode == .system || ["http", "https"].contains(url.scheme?.lowercased() ?? "") else {
            assertionFailure("In app mode only supports http and https schemes.")
            return
        }
        
        switch mode {
        case .inApp:
            openInApp(url)
        case .system:
            openInSystem(url)
        }
    }
    
    func callAsFunction(_ url: URLComponents) {
        if ["http", "https"].contains(url.scheme?.lowercased() ?? "") {
            callAsFunction(url, mode: defaultMode)
        } else {
            callAsFunction(url, mode: .system)
        }
    }
    
}

struct CustomOpenURLEnvironmentKey: EnvironmentKey {
    static var defaultValue = CustomOpenURLAction(defaultMode: .inApp)
}

extension EnvironmentValues {
    var customOpenURLAction: CustomOpenURLAction {
        get { self[CustomOpenURLEnvironmentKey.self] }
        set { self[CustomOpenURLEnvironmentKey.self] = newValue }
    }
}

struct CustomOpenURLModifier: ViewModifier {
    
    var openInSystem: (URL) -> Void = { _ in }
    
    @State var urlForSafariView: URL? = nil
    @AppStorage("defaultOpenURLMode", store: RSSBud.userDefaults) var defaultMode: CustomOpenURLAction.Mode = .inApp
    
    var action: CustomOpenURLAction {
        CustomOpenURLAction(
            defaultMode: defaultMode,
            openInApp: { url in
                urlForSafariView = url
            }, openInSystem: openInSystem
        )
    }
    
    func body(content: Content) -> some View {
        content
            .safariView(item: $urlForSafariView) { url in
                SafariView(
                    url: url,
                    configuration: SFSafariViewController.Configuration(entersReaderIfAvailable: false, barCollapsingEnabled: true)
                ).dismissButtonStyle(.close)
                .preferredControlAccentColor(.orange)
            }.environment(\.customOpenURLAction, action)
    }
}
