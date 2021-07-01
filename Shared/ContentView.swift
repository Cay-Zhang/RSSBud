//
//  ContentView.swift
//  Shared
//
//  Created by Cay Zhang on 2020/7/5.
//

import SwiftUI
import Combine
import LinkPresentation

struct ContentView: View {
    
    @Environment(\.customOpenURLAction) var openURL
    var done: (() -> Void)? = nil
    @ObservedObject var viewModel = ViewModel()
    @State var isSettingsViewPresented = false
    
    @AppStorage("isOnboarding", store: RSSBud.userDefaults) var isOnboarding: Bool = true
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    var body: some View {
        HStack(spacing: 0) {
            NavigationView {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        if isOnboarding {
                            OnboardingView()
                        } else {
                            pageFeeds
                            
                            rsshubFeeds
                            
                            if (viewModel.rssFeeds?.isEmpty ?? false) && (viewModel.rsshubFeeds?.isEmpty ?? false) && !viewModel.isProcessing {
                                NothingFoundView(url: viewModel.originalURL)
                            }
                            
                            if horizontalSizeClass != .regular {
                                rsshubParameters
                            }
                        }
                    }.padding(16)
                }.navigationTitle("RSSBud")
                .toolbar(content: toolbarContent)
                .safeAreaInset(edge: .bottom) {
                    BottomBar(parentViewModel: viewModel)
                }
            }
            
            if horizontalSizeClass == .regular {
                Divider().ignoresSafeArea(.keyboard, edges: .vertical)
                
                NavigationView {
                    ScrollView {
                        rsshubParameters
                            .padding(16)
                            .navigationTitle(Text("Parameters"))
                    }
                }
            }
        }.navigationViewStyle(StackNavigationViewStyle())
        .environmentObject(viewModel)
        .alert($viewModel.alert)
        .sheet(isPresented: $isSettingsViewPresented) {
            SettingsView()
                .modifier(CustomOpenURLModifier(openInSystem: openURL.openInSystem))
        }
    }
    
    @ViewBuilder var pageFeeds: some View {
        if let feeds = viewModel.rssFeeds, !feeds.isEmpty {
            ExpandableSection(isExpanded: true) {
                LazyVStack(spacing: 16) {
                    ForEach(feeds, id: \.title) { feed in
                        RSSFeedView(feed: feed, contentViewModel: viewModel)
                    }
                }
            } label: {
                Text("Content Section RSS Feeds")
            }
        }
    }
    
    @ViewBuilder var rsshubFeeds: some View {
        if let feeds = viewModel.rsshubFeeds, !feeds.isEmpty {
            ExpandableSection(isExpanded: true) {
                LazyVStack(spacing: 16) {
                    ForEach(feeds, id: \.title) { feed in
                        RSSHubFeedView(feed: feed, contentViewModel: viewModel)
                    }
                }
            } label: {
                Text("Content Section RSSHub Feeds")
            }
        }
    }
    
    @ViewBuilder var rsshubParameters: some View {
        if let feeds = viewModel.rsshubFeeds, !feeds.isEmpty {
            ExpandableSection(isExpanded: true) {
                QueryEditor(queryItems: $viewModel.queryItems)
            } label: {
                Text("Content Section RSSHub Parameters")
            }
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
        
        ToolbarItemGroup(placement: ToolbarItemPlacement.navigationBarTrailing) {
            #if DEBUG
            Menu {
                Button("Analyze") {
                    viewModel.process(url: URLComponents(string: "https://github.com/Cay-Zhang/RSSBud")!)
                }
                Button("Error") {
                    viewModel.process(url: URLComponents(string: "example.com")!)
                }
                Button("Nothing Found") {
                    viewModel.process(url: URLComponents(string: "https://www.baidu.com/")!)
                }
                Button("Toggle Onboarding") {
                    withAnimation(OnboardingView.transitionAnimation) { isOnboarding.toggle() }
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

// MARK: - Methods
extension ContentView {
    func readFromClipboard() {
        if let url = UIPasteboard.general.url?.components {
            viewModel.process(url: url)
        } else if let url = UIPasteboard.general.string.flatMap(URLComponents.init(autoPercentEncoding:)) {
            viewModel.process(url: url)
        }
    }
}

extension ContentView {
    class ViewModel: ObservableObject {
        @RSSHub.BaseURL var baseURL
        
        @Published var originalURL: URLComponents? = nil
        @Published var linkPresentationMetadata: LPLinkMetadata? = nil
        @Published var isProcessing: Bool = false
        
//        @Published var isPageFeedSectionExpanded: Bool = false
//
//        @Published var isRSSHubFeedSectionExpanded: Bool = true
        @Published var rssFeeds: [RSSFeed]? = nil
        @Published var rsshubFeeds: [RSSHubFeed]? = nil
        @Published var queryItems: [URLQueryItem] = []
        
        @Published var alert: Alert? = nil
        
        var cancelBag = Set<AnyCancellable>()
        
        init(originalURL: URLComponents? = nil, rssFeeds: [RSSFeed]? = nil, rsshubFeeds: [RSSHubFeed]? = nil, queryItems: [URLQueryItem] = []) {
            self.originalURL = originalURL
            self.rssFeeds = rssFeeds
            self.rsshubFeeds = rsshubFeeds
            self.queryItems = queryItems
            
            self.$originalURL
                .map { $0?.url }
                .removeDuplicates()
                .map { (url: URL?) -> AnyPublisher<LPLinkMetadata?, Never> in
                    if let url = url {
                        let placeholderMetadata = LPLinkMetadata()
                        placeholderMetadata.originalURL = url
                        placeholderMetadata.url = url
                        
                        return Future<LPLinkMetadata?, Never> { promise in
                            let provider = LPMetadataProvider()
                            provider.startFetchingMetadata(for: url) { (result, error) in
                                if let metadata = result {
                                    promise(.success(metadata))
                                } else if let _ = error {
                                    promise(.success(placeholderMetadata))
                                }
                            }
                        }.prepend(placeholderMetadata)
                        .eraseToAnyPublisher()
                    } else {
                        return Just(nil).eraseToAnyPublisher()
                    }
                }.switchToLatest()
                .receive(on: DispatchQueue.main)
                .sink { [weak self] metadata in
                    withAnimation { self?.linkPresentationMetadata = metadata }
                }.store(in: &self.cancelBag)
            
            Core.onFinishReloadingRules
                .sink { [weak self] in
                    self?.originalURL.map { self?.process(url: $0) }
                }.store(in: &cancelBag)
        }
        
        func process(url: URLComponents, html: String? = nil) {
            if baseURL.host == url.host {
                let items = url.queryItems?.map { item in
                    URLQueryItem(name: item.name, value: item.value?.removingPercentEncoding)
                }
                withAnimation {
                    rsshubFeeds = [RSSHubFeed(title: "Current URL", path: url.path)]
                    queryItems = items ?? []
                }
            } else {
                withAnimation {
                    self.originalURL = url
                    self.isProcessing = true
                }
                
                DispatchQueue.global(qos: .userInitiated).async {
                    let analysisPipeline: AnyPublisher<Core.AnalysisResult, Error>
                    if let html = html {
                        analysisPipeline = Core.analyzing(url: url, html: html)
                    } else {
                        analysisPipeline = Core.analyzing(contentsOf: url)
                    }
                    
                    analysisPipeline
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
                                    self.rssFeeds = nil
                                    self.rsshubFeeds = nil
                                    self.alert = Alert(title: Text("An Error Occurred"), message: Text(verbatim: error.localizedDescription))
                                }
                            }
                        } receiveValue: { [unowned self] result in
                            withAnimation {
                                self.rssFeeds = result.rssFeeds
                                self.rsshubFeeds = result.rsshubFeeds
                            }
                        }.store(in: &self.cancelBag)
                }
            }
        }
        
    }
}

struct NothingFoundView: View {
    
    var url: URLComponents?
    @Environment(\.customOpenURLAction) var openURL
    
    @Environment(\.xCallbackContext) var xCallbackContext: Binding<XCallbackContext>
    
    func continueXCallbackText() -> LocalizedStringKey {
        if let source = xCallbackContext.wrappedValue.source {
            return LocalizedStringKey("Continue in \(source)")
        } else {
            return LocalizedStringKey("Continue")
        }
    }
    
    func continueXCallback() {
        let url = xCallbackContext
            .wrappedValue
            .cancel
        url.map(openURL.callAsFunction(_:))
        xCallbackContext.wrappedValue = nil
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "bookmark.slash.fill")
                .font(.system(size: 24, weight: .semibold, design: .default))
                .foregroundColor(.accentColor)
                .frame(width: 70, height: 70)
                .background(Color(UIColor.tertiarySystemBackground))
                .clipShape(Circle())
            
            Text("Nothing Found")
                .font(.system(size: 24, weight: .semibold, design: .default))
            
            if let urlString = url?.string?.removingPercentEncoding {
                Menu {
                    Button("Copy", systemImage: "doc.on.doc.fill") {
                        UIPasteboard.general.url = url?.url
                    }
                } label: {
                    Text(verbatim: urlString)
                        .foregroundColor(.secondary)
                }
            }
            
            VStack(spacing: 8) {
                WideButton("See What's Supported", systemImage: "text.book.closed.fill") {
                    openURL(URLComponents(string: "https://docs.rsshub.app/social-media.html")!)
                }
                
                WideButton("Submit New Rules", systemImage: "link.badge.plus") {
                    openURL(URLComponents(string: "https://docs.rsshub.app/joinus/#ti-jiao-xin-de-rsshub-radar-gui-ze")!)
                }
                
                if xCallbackContext.wrappedValue.cancel != nil {
                    WideButton(continueXCallbackText(), systemImage: "arrowtriangle.backward.fill", withAnimation: .default, action: continueXCallback)
                }
            }
        }.padding(.horizontal, 8)
        .padding(.top, 20)
        .padding(.bottom, 8)
        .frame(maxWidth: .infinity)
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

struct ContentView_Previews: PreviewProvider {
    
    static let viewModel = ContentView.ViewModel(
        originalURL: URLComponents(string: "https://space.bilibili.com/17404347"),
        rsshubFeeds: [
            RSSHubFeed(title: "UP 主动态", path: "/bilibili/user/dynamic/17404347"),
            RSSHubFeed(title: "UP 主投稿", path: "/bilibili/user/video/17404347")
        ]
    )
    
    static var previews: some View {
        Group {
            ContentView(viewModel: viewModel, isOnboarding: false)
            
            NothingFoundView(url: URLComponents(autoPercentEncoding: "https://www.baidu.com/s?word=你好")!)
                .padding(.horizontal, 20)
        }
    }
}

