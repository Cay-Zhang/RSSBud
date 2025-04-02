//
//  CustomOpenURL.swift
//  RSSBud
//
//  Created by Cay Zhang on 2020/12/29.
//

import SwiftUI
import SafariServices
#if canImport(BetterSafariView)
import BetterSafariView
#endif

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
#if canImport(BetterSafariView)
        CustomOpenURLAction(
            defaultMode: defaultMode,
            openInApp: { url in
                urlForSafariView = url
            },
            openInSystem: openInSystem
        )
#else
        CustomOpenURLAction(
            defaultMode: defaultMode,
            openInApp: openInSystem,
            openInSystem: openInSystem
        )
#endif
    }
    
    func body(content: Content) -> some View {
        content
#if canImport(BetterSafariView)
            .sheet(item: $urlForSafariView) { url in
                CustomSafariView(url: url) { safariViewController in
                    safariViewController.configuration.barCollapsingEnabled = true
                    safariViewController.dismissButtonStyle = .close
                    safariViewController.preferredControlTintColor = .orange
                }
            }
#endif
            .environment(\.customOpenURLAction, action)
    }
}

struct CustomSafariView: UIViewControllerRepresentable {
    var url: URL
    var configuration: (SFSafariViewController) -> () = { _ in }

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let controller = SFSafariViewController(url: url)
        configuration(controller)
        return controller
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) { }
}
