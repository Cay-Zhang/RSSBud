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
    
    @AppStorage("isOnboarding", store: RSSBud.userDefaults) var isOnboarding: Bool = true
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    var body: some View {
        HStack(spacing: 0) {
            NavigationView {
                ScrollView {
                    VStack(spacing: 30) {
                        if isOnboarding {
                            OnboardingView(openURL: openURL)
                        } else {
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
                                            .roundedRectangleBackground(color: .secondarySystemBackground)
                                    }.buttonStyle(SquashableButtonStyle())
                                }
                            }
                            
                            if let feeds = viewModel.detectedFeeds {
                                if !feeds.isEmpty {
                                    LazyVStack(spacing: 16) {
                                        ForEach(feeds, id: \.title) { feed in
                                            FeedView(feed: feed, contentViewModel: viewModel, openURL: openURL)
                                        }
                                    }
                                } else {
                                    NothingFoundView(url: viewModel.originalURL, openURL: openURL)
                                }
                            }
                            
                            if horizontalSizeClass != .regular {
                                QueryEditor(queryItems: $viewModel.queryItems)
                            }
                        }
                    }.padding(20)
                }.navigationTitle("RSSBud")
                .toolbar(content: toolbarContent)
            }
            
            if horizontalSizeClass == .regular {
                Divider()
                
                NavigationView {
                    ScrollView {
                        QueryEditor(queryItems: $viewModel.queryItems)
                            .padding(20)
                            .navigationTitle(Text("Parameters"))
                    }
                }
            }
        }.navigationViewStyle(StackNavigationViewStyle())
        .environmentObject(viewModel)
        .alert($viewModel.alert)
        .sheet(isPresented: $isSettingsViewPresented) {
            SettingsView()
        }
    }
    
    @ToolbarContentBuilder func toolbarContent() -> some ToolbarContent {
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
                    Button("Nothing Found") {
                        viewModel.process(url: URLComponents(string: "https://www.baidu.com/")!)
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
    }
}

extension ContentView {
    class ViewModel: ObservableObject {
        @RSSHub.BaseURL var baseURL
        
        @Published var originalURL: URLComponents? = nil
        @Published var detectedFeeds: [RSSHub.Radar.DetectedFeed]? = nil
        @Published var queryItems: [URLQueryItem] = []
        @Published var isProcessing: Bool = false
        @Published var alert: Alert? = nil
        
        var cancelBag = Set<AnyCancellable>()
        
        init(detectedFeeds: [RSSHub.Radar.DetectedFeed]? = nil) {
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
                }
                
                url.expanding()
                    .prepend(url)
                    .flatMap { url in
                        RSSHub.Radar.detecting(url: url)
                    }.first { feeds in !feeds.isEmpty }
                    .replaceEmpty(with: [])
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
                                self.detectedFeeds = nil
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

struct NothingFoundView: View {
    
    var url: URLComponents?
    var openURL: (URLComponents) -> Void = { _ in }
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "bookmark.slash.fill")
                .imageScale(.large)
                .font(.system(size: 24, weight: .semibold, design: .default))
                .foregroundColor(.accentColor)
            Text("Nothing Found")
                .font(.system(size: 24, weight: .semibold, design: .default))
            if let urlString = url?.string {
                Text(verbatim: urlString)
                    .foregroundColor(.secondary)
            }
            Button {
                openURL(URLComponents(string: "https://docs.rsshub.app/social-media.html")!)
            } label: {
                Label("See What's Supported", systemImage: "text.book.closed.fill")
                    .roundedRectangleBackground()
            }.buttonStyle(SquashableButtonStyle())
            Button {
                openURL(URLComponents(string: "https://docs.rsshub.app/joinus/#ti-jiao-xin-de-rsshub-radar-gui-ze")!)
            } label: {
                Label("Submit New Rules", systemImage: "link.badge.plus")
                    .roundedRectangleBackground()
            }.buttonStyle(SquashableButtonStyle())
            
            
            Divider()
            
            Text("Can be detected by RSSHub Radar?").fontWeight(.semibold)
            Button {
                openURL(URLComponents(string: "https://t.me/RSSBud_Discussion")!)
            } label: {
                Label("Contact Developer", systemImage: "hammer.fill")
                    .roundedRectangleBackground()
            }.buttonStyle(SquashableButtonStyle())
        }.padding(.horizontal, 8)
        .padding(.top, 20)
        .padding(.bottom, 8)
        .frame(maxWidth: .infinity, idealHeight: 200)
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
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

