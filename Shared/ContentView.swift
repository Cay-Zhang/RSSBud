//
//  ContentView.swift
//  Shared
//
//  Created by Cay Zhang on 2020/7/5.
//

import SwiftUI
import Combine
import Regex

struct ContentView: View {
    
    @ObservedObject var viewModel = ViewModel()
    @State var isSettingsViewPresented = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 30) {
                    // Original URL
                    VStack(spacing: 30) {
                        if let url = viewModel.originalURL?.url {
                            LinkPresentation(previewURL: url)
                                .frame(height: 200)
                        } else {
                            Text("No Original URL")
                        }
                        
                        HStack(spacing: 20) {
                            if viewModel.isProcessing {
                                ProgressView()
                            }
                            Button {
                                if let url = UIPasteboard.general.url?.components {
                                    viewModel.process(originalURL: url)
                                } else if let url = UIPasteboard.general.string.flatMap(URLComponents.init(autoPercentEncoding:)) {
                                    viewModel.process(originalURL: url)
                                }
                            } label: {
                                Label("Read from Clipboard", systemImage: "arrow.up.doc.on.clipboard")
                            }.buttonStyle(RoundedRectangleButtonStyle())
                        }
                    }
                    
                    // Derived URL
                    VStack(spacing: 30) {
                        ForEach(viewModel.detectedFeeds, id: \.title) { feed in
                            VStack(spacing: 10.0) {
                                Text(feed.title).fontWeight(.semibold)
                                    .padding(.horizontal, 15)
                                Text((feed.url + viewModel.queryItems).string ?? "URL Conversion Failed")
                                    .padding(.horizontal, 15)
                                
                                HStack(spacing: 0) {
                                    Button {
                                        (feed.url + viewModel.queryItems).url.map { UIPasteboard.general.url = $0 }
                                    } label: {
                                        Label("Copy", systemImage: "doc.on.doc.fill")
                                    }.buttonStyle(RoundedRectangleButtonStyle())
                                    
                                    if let url = Radar.addToInoreaderURL(forFeedURL: feed.url + viewModel.queryItems).url {
                                        Button {
                                            UIApplication.shared.open(url, options: [:], completionHandler: nil)
                                        } label: {
                                            Label("Inoreader", systemImage: "arrowshape.turn.up.right.fill")
                                        }.buttonStyle(RoundedRectangleButtonStyle())
                                    }
                                }.padding(.horizontal, 4)
                            }.padding(.top, 15)
                            .padding(.bottom, 4)
                            .frame(maxWidth: .infinity)
                            .background(Color(UIColor.secondarySystemFill))
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                    }.listStyle(InsetListStyle())
                    
                    TextField("Keep Title", text: queryItemBinding(for: "filter_title"))
                        .font(.title2)
                    
                    TextField("Remove Title", text: queryItemBinding(for: "filterout_title"))
                        .font(.title2)
                }.padding(20)
            }.navigationTitle("RSSBud")
            .toolbar {
                ToolbarItem(placement: ToolbarItemPlacement.navigationBarTrailing) {
                    Button {
                        isSettingsViewPresented.toggle()
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .frame(width: 40, height: 40)
                    }
                }
            }.sheet(isPresented: $isSettingsViewPresented) {
                SettingsView()
            }
        }
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
        @Published var originalURL: URLComponents? = nil
        @Published var detectedFeeds: [Radar.DetectedFeed]
        @Published var queryItems: [URLQueryItem] = []
        @Published var isProcessing: Bool = false
        var cancelBag = Set<AnyCancellable>()
        
        init(detectedFeeds: [Radar.DetectedFeed] = []) {
            self.detectedFeeds = detectedFeeds
        }
        
        func process(originalURL: URLComponents) {
            //            guard self.originalURL != originalURL else { return }
            withAnimation {
                self.originalURL = originalURL
                self.isProcessing = true
            }
            
            let expandingURL = originalURL.expanding().share()
            
            expandingURL.receive(on: DispatchQueue.main)
                .sink { [weak self] url in
                    print("Original URL: \(url)")
                    withAnimation {
                        self?.originalURL = url
                    }
                }.store(in: &cancelBag)
            
            expandingURL
                .flatMap { url in
                    Radar.detecting(url: url)
                }.receive(on: DispatchQueue.main)
                .sink { [weak self] completion in
                    switch completion {
                    case .finished:
                        withAnimation {
                            self?.isProcessing = false
                        }
                    case .failure(let error):
                        print(error)
                        fatalError()
                    }
                } receiveValue: { [weak self] feeds in
                    withAnimation {
                        self?.detectedFeeds = feeds
                    }
                }.store(in: &cancelBag)
        }
        
    }
}

struct ContentView_Previews: PreviewProvider {
    
    static let viewModel = ContentView.ViewModel(detectedFeeds: [
        Radar.DetectedFeed(title: "当前视频评论", path: "/bilibili/video/reply/BV15z411v7zt"),
        Radar.DetectedFeed(title: "当前视频评论", path: "/bilibili/video/reply/BV15z411v7zt")
    ])
    
    static var previews: some View {
        ContentView(viewModel: viewModel)
    }
}
