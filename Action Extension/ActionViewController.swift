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

class ActionViewController: UIHostingController<ContentView> {
    
    var contentViewModel = ContentView.ViewModel()
    var cancelBag = Set<AnyCancellable>()
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        let contentView = ContentView(viewModel: contentViewModel)
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
                viewModel?.process(originalURL: url)
            }.store(in: &self.cancelBag)
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
