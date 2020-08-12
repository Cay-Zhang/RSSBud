//
//  ActionViewController.swift
//  Action Extension
//
//  Created by Cay Zhang on 2020/8/12.
//

import UIKit
import SwiftUI
import MobileCoreServices

class ActionViewController: UIHostingController<ContentView> {
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        let contentView = ContentView()
        super.init(rootView: contentView)
        rootView.openURL = { [weak self] url in
            self?.open(url: url)
        }
        rootView.done = { [weak self] in
            self?.extensionContext?.completeRequest(returningItems: self?.extensionContext?.inputItems, completionHandler: nil)
        }
    }
    
    @objc required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        var urlFound = false
        for item in self.extensionContext!.inputItems as! [NSExtensionItem] {
            for provider in item.attachments! {
                print(provider.registeredTypeIdentifiers)
                if provider.canLoadObject(ofClass: URL.self) {
                    _ = provider.loadObject(ofClass: URL.self) { [weak self] url, error in
                        guard let url = url?.components else {
                            fatalError()
                        }
                        OperationQueue.main.addOperation {
                            self?.rootView.viewModel.process(originalURL: url)
                        }
                    }
                    
                    urlFound = true
                    break
                }
            }
            
            if urlFound { break }
        }
    }
    
    func open(url urlComponents: URLComponents) {
        guard let url = urlComponents.url else {
            assertionFailure("URL conversion failed.")
            return
        }
        let selector = sel_registerName("openURL:")
        var responder = self as UIResponder?
        while let r = responder, !r.responds(to: selector) {
            responder = r.next
        }
        _ = responder?.perform(selector, with: url)
    }
    
}
