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
                if let url = viewModel.originalURL {
                    LinkPresentation(previewURL: url)
                } else {
                    Text("No Original URL")
                }
                
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
                Text(viewModel.finalURL?.absoluteString ?? "No Derived URL")
                
                Button {
                    viewModel.finalURL.map { UIPasteboard.general.url = $0 }
                } label: {
                    Text("Copy").foregroundColor(.white)
                }.padding(20)
                .background(Color.accentColor)
                .clipShape(Capsule())
            }
            
            TextField("Keep Title", text: queryItemBinding(for: "filter_title"))
                .font(.title2)
            
            TextField("Remove Title", text: queryItemBinding(for: "filterout_title"))
                .font(.title2)
        }.padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    func queryItemBinding(for name: String) -> Binding<String> {
        Binding(get: {
            viewModel.queryItems.first(where: { $0.name == name })?.value ?? ""
        }, set: { newValue in
            if newValue.isEmpty {
                if let index = viewModel.queryItems.firstIndex(where: { $0.name == name }) {
                    viewModel.queryItems.remove(at: index)
                }
            } else {
                if let index = viewModel.queryItems.firstIndex(where: { $0.name == name }) {
                    viewModel.queryItems[index].value = newValue
                } else {
                    viewModel.queryItems.append(URLQueryItem(name: name, value: newValue))
                }
            }
        })
    }
}

extension ContentView {
    class ViewModel: ObservableObject {
        @Published var originalURL: URL? = URL(string: "https://medium.com/better-programming/ios-13-rich-link-previews-with-swiftui-e61668fa2c69")
        @Published var derivedURL: URL? = nil
        @Published var queryItems: [URLQueryItem] = []
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
        
        var finalURL: URL? {
            guard let derivedURL = derivedURL,
                  var components = URLComponents(url: derivedURL, resolvingAgainstBaseURL: false)
            else { return nil }
            components.queryItems = self.queryItems
            return components.url
        }
        
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
