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

struct RootView: View {
    var contentViewModel: ContentView.ViewModel
    var openURLInSystem: (URL) -> Void = { _ in }
    var done: () -> Void = { }
    
    var body: some View {
        ContentView(done: done, viewModel: contentViewModel)
            .modifier(CustomOpenURLModifier(openInSystem: openURLInSystem))
    }
}

class ActionViewController: UIViewController {
    
    var contentViewModel = ContentView.ViewModel()
    var cancelBag = Set<AnyCancellable>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
            .flatMap { (provider: NSItemProvider) -> Future<URLComponents?, Never> in
                
                if provider.canLoadObject(ofClass: URL.self) {
                    
                    return Future { promise in
                        _ = provider.loadObject(ofClass: URL.self) { url, error in
                            promise(.success(url?.components))
                        }
                    }
                    
                } else {
                    
                    return Future { promise in
                        provider.loadItem(forTypeIdentifier: kUTTypePlainText as String, options: nil) { string, error in
                            promise(.success((string as? String).flatMap(URLComponents.init(autoPercentEncoding:))))
                        }
                    }
                    
                }
                
            }.compactMap { $0 }
            .first()
            .receive(on: DispatchQueue.main)
            .sink { [weak viewModel = contentViewModel] url in
                viewModel?.process(url: url)
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
