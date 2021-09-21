//
//  ActionViewController.swift
//  Action Extension
//
//  Created by Cay Zhang on 2020/8/12.
//

import UIKit
import SwiftUI
import Combine
import MobileCoreServices
import UniformTypeIdentifiers

struct RootView: View {
    var contentViewModel: ContentView.ViewModel
    var openURLInSystem: (URL) -> Void = { _ in }
    var done: () -> Void = { }
    
    var body: some View {
        ContentView(done: done, viewModel: contentViewModel)
            .modifier(CustomOpenURLModifier(openInSystem: openURLInSystem))
    }
}

@MainActor
class ActionViewController: UIViewController {
    
    var contentViewModel = ContentView.ViewModel()
    var cancelBag = Set<AnyCancellable>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // if host view cannot fit the preferred content size,
        // a sheet will be used instead of a popover
        // size class is not assigned properly
        preferredContentSize = CGSize(width: 450, height: 900)
        
        // temp workaround for list background
        UITableView.appearance().backgroundColor = UIColor.clear
        
        var view = RootView(contentViewModel: contentViewModel)
        view.openURLInSystem = { [weak self] url in
            self?.open(url: url)
        }
        view.done = { [weak self] in
            self?.extensionContext?.completeRequest(returningItems: self?.extensionContext?.inputItems, completionHandler: nil)
        }
        
        let hostingController = UIHostingController(rootView: view)
        self.addChild(hostingController)
        self.view.addSubview(hostingController.view)
        hostingController.didMove(toParent: self)
        
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingController.view.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            hostingController.view.topAnchor.constraint(equalTo: self.view.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
        ])
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let extensionItems = self.extensionContext!.inputItems as! [NSExtensionItem]
        
        extensionItems.publisher
            .flatMap { item in
                item.attachments!.publisher
            }.print()
            .flatMap { (provider: NSItemProvider) -> AsyncFuture<(url: URLComponents, html: String?)?> in
                AsyncFuture {
                    if let item = try? await provider.loadItem(forTypeIdentifier: UTType.propertyList.identifier, options: nil) as? Dictionary<String, Dictionary<String, String>>,
                       let results = item[NSExtensionJavaScriptPreprocessingResultsKey],
                       let urlString = results["url"],
                       let url = URLComponents(string: urlString),
                       let html = results["html"] {
                        // from safari webpage
                        return (url, html)
                    } else if let url = try? await provider.loadObject(ofClass: URL.self).components {
                        return (url, nil)
                    } else if let text = try? await provider.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) as? String,
                              let url = text.detect(types: .link).compactMap(\.url?.components).first {
                        return (url, nil)
                    } else {
                        return nil
                    }
                }
            }.compactMap { $0 }
            .first()
            .receive(on: DispatchQueue.main)
            .sink { [weak viewModel = contentViewModel] tuple in
                viewModel?.process(url: tuple.url, html: tuple.html)
            }.store(in: &self.cancelBag)
    }
    
    func open(url: URL) {
        let selector = sel_registerName("openURL:")
        var responder = self as UIResponder?
        while let r = responder, !r.responds(to: selector) {
            responder = r.next
        }
        _ = responder?.perform(selector, with: url)
    }
    
}
