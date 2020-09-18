//
//  ContentView.swift
//  Shared
//
//  Created by Cay Zhang on 2020/7/5.
//

import SwiftUI
import Combine

struct ContentView: View {
    
    var openURL: (URLComponents) -> Void = { _ in }
    var done: (() -> Void)? = nil
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
                        }
                        
                        HStack(spacing: 20) {
                            if viewModel.isProcessing {
                                ProgressView()
                            }
                            Button {
                                if let url = UIPasteboard.general.url?.components {
                                    viewModel.process(url: url)
                                } else if let url = UIPasteboard.general.string.flatMap(URLComponents.init(autoPercentEncoding:)) {
                                    viewModel.process(url: url)
                                }
                            } label: {
                                Label("Read from Clipboard", systemImage: "arrow.up.doc.on.clipboard")
                                    .roundedRectangleBackground()
                            }.buttonStyle(SquashableButtonStyle())
                        }
                    }
                    
                    // Derived URL
                    LazyVStack(spacing: 16) {
                        ForEach(viewModel.detectedFeeds, id: \.title) { feed in
                            FeedView(feed: feed, contentViewModel: viewModel, openURL: openURL)
                        }
                    }
                    
                    QueryEditor(queryItems: $viewModel.queryItems)
                }.padding(20)
            }.navigationTitle("RSSBud")
            .toolbar {
                ToolbarItem(placement: ToolbarItemPlacement.navigationBarLeading) {
                    if let done = done {
                        Button(action: done) {
                            Text("Done").fontWeight(.semibold)
                        }
                    }
                }
                
                ToolbarItem(placement: ToolbarItemPlacement.navigationBarTrailing) {
                    HStack {
                        #if DEBUG
                        Menu {
                            Button("Analyze") {
                                viewModel.process(url: URLComponents(string: "https://space.bilibili.com/17404347/")!)
                            }
                            Button("Error") {
                                viewModel.process(url: URLComponents(string: "example.com")!)
                            }
                        } label: {
                            Image(systemName: "hammer.fill")
                        }
                        #endif
                        Button {
                            isSettingsViewPresented.toggle()
                        } label: {
                            Image(systemName: "gearshape.fill")
                        }
                    }
                }
            }.sheet(isPresented: $isSettingsViewPresented) {
                SettingsView()
            }
        }.environmentObject(viewModel)
        .alert($viewModel.alert)
    }
}

extension ContentView {
    class ViewModel: ObservableObject {
        @RSSHub.BaseURL var baseURL
        
        @Published var originalURL: URLComponents? = nil
        @Published var detectedFeeds: [RSSHub.Radar.DetectedFeed]
        @Published var queryItems: [URLQueryItem] = []
        @Published var isProcessing: Bool = false
        @Published var alert: Alert? = nil
        
        var cancelBag = Set<AnyCancellable>()
        
        init(detectedFeeds: [RSSHub.Radar.DetectedFeed] = []) {
            self.detectedFeeds = detectedFeeds
        }
        
        func process(url: URLComponents) {
            if baseURL.host == url.host {
                let items = url.queryItems?.map { item in
                    URLQueryItem(name: item.name, value: item.value?.removingPercentEncoding)
                }
                withAnimation {
                    detectedFeeds = [RSSHub.Radar.DetectedFeed(title: "Current URL", path: url.path)]
                    queryItems = items ?? []
                }
            } else {
                withAnimation {
                    self.originalURL = url
                    self.isProcessing = true
                    self.detectedFeeds = []
                }
                
                url.expanding()
                    .prepend(url)
                    .flatMap { url in
                        RSSHub.Radar.detecting(url: url)
                    }.first { feeds in !feeds.isEmpty }
                    .receive(on: DispatchQueue.main)
                    .sink { [unowned self] completion in
                        switch completion {
                        case .finished:
                            withAnimation {
                                self.isProcessing = false
                            }
                        case .failure(let error):
                            print(error)
                            withAnimation {
                                self.isProcessing = false
                                self.alert = Alert(title: Text("An Error Occurred"), message: Text(verbatim: error.localizedDescription))
                            }
                        }
                    } receiveValue: { [unowned self] feeds in
                        withAnimation {
                            self.detectedFeeds = feeds
                        }
                    }.store(in: &cancelBag)
            }
        }
        
    }
}

struct ContentView_Previews: PreviewProvider {
    
    static let viewModel = ContentView.ViewModel(detectedFeeds: [
        RSSHub.Radar.DetectedFeed(title: "当前视频评论", path: "/bilibili/video/reply/BV15z411v7zt"),
        RSSHub.Radar.DetectedFeed(title: "当前视频评论", path: "/bilibili/video/reply/BV15z411v7zt")
    ])
    
    static var previews: some View {
        ContentView(viewModel: viewModel)
    }
}

