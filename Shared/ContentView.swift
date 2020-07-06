//
//  ContentView.swift
//  Shared
//
//  Created by Cay Zhang on 2020/7/5.
//

import SwiftUI
import Combine

struct ContentView: View {
    
    @ObservedObject var viewModel = ViewModel()
    
    var body: some View {
        VStack(spacing: 50) {
            // Original URL
            VStack(spacing: 30) {
                Text(viewModel.originalURL?.absoluteString ?? "No Original URL")
                HStack(spacing: 20) {
                    if viewModel.isProcessing {
                        ProgressView()
                    }
                    Button {
                        if let url = UIPasteboard.general.url {
                            viewModel.process(originalURL: url)
                        }
                    } label: {
                        Text("Read from Clipboard").foregroundColor(.white)
                    }.padding(20).background(Color.accentColor).clipShape(Capsule())
                }
            }
            
            // Derived URL
            VStack(spacing: 30) {
                Text(viewModel.derivedURL?.absoluteString ?? "No Derived URL")
                
                Button {
                    viewModel.derivedURL.map { UIPasteboard.general.url = $0 }
                } label: {
                    Text("Copy").foregroundColor(.white)
                }.padding(20)
                .background(Color.accentColor)
                .clipShape(Capsule())
            }
        }.padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

extension ContentView {
    class ViewModel: ObservableObject {
        @Published var originalURL: URL? = nil
        @Published var derivedURL: URL? = nil
        @Published var isProcessing: Bool = false
        var cancelBag = Set<AnyCancellable>()
        
        let baseComponents = URLComponents(string: "http://157.230.150.17:1200")!
        
        func process(originalURL: URL) {
//            guard self.originalURL != originalURL else { return }
            withAnimation {
                self.originalURL = originalURL
                self.isProcessing = true
            }
            originalURL.expanding().receive(on: DispatchQueue.main).sink(
                receiveCompletion: { [weak self] _ in
                    withAnimation {
                        self?.isProcessing = false
                    }
                }, receiveValue: { [weak self] url in
                    withAnimation {
                        self?.originalURL = url
                        self?.derivedURL = self?.derive(from: url)
                    }
                }
            ).store(in: &cancelBag)
        }
        
        func derive(from url: URL) -> URL? {
            guard let originalComponents = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
                return nil
            }
            
            if originalComponents.host == "space.bilibili.com" {
                if let id = Int(originalComponents.path.trimmingCharacters(in: ["/"])) {
                    print(id)
                    let path = "/bilibili/user/video/\(id)"
                    var derivedComponents = baseComponents
                    derivedComponents.path = path
                    return derivedComponents.url
                } else {
                    return nil
                }
            } else {
                return nil
            }
        }
        
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
