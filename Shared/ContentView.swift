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
                        } else if viewModel.originalURL == nil {
                            #if !ACTION_EXTENSION
                            StartView()
                            #endif
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
                .environment(\.isEnabled, !viewModel.isFocusedOnBottomBar)
                .overlay(Color.black.opacity(viewModel.isFocusedOnBottomBar ? 0.5: 0.0))
                .safeAreaInset(edge: .bottom) {
                    BottomBar(viewModel: viewModel.bottomBarViewModel)
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
        }.symbolRenderingMode(.hierarchical)
    }
    
    @ViewBuilder var pageFeeds: some View {
        if let feeds = viewModel.rssFeeds, !feeds.isEmpty {
            ExpandableSection(viewModel: viewModel.pageFeedSectionViewModel) {
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
            ExpandableSection(viewModel: viewModel.rsshubFeedSectionViewModel) {
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
            ExpandableSection(viewModel: viewModel.rsshubParameterSectionViewModel) {
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

extension ContentView {
    class ViewModel: ObservableObject {
        @RSSHub.BaseURL var baseURL
        
        @Published var originalURL: URLComponents? = nil
        @Published var isProcessing: Bool = false
        
        @Published var rssFeeds: [RSSFeed]? = nil
        @Published var rsshubFeeds: [RSSHubFeed]? = nil
        @Published var queryItems: [URLQueryItem] = []
        
        @Published var alert: Alert? = nil
        
        @Published var isFocusedOnBottomBar: Bool = false
        
        let pageFeedSectionViewModel = ExpandableSection.ViewModel()
        let rsshubFeedSectionViewModel = ExpandableSection.ViewModel()
        let rsshubParameterSectionViewModel = ExpandableSection.ViewModel()
        
        let startViewStartSection = ExpandableSection.ViewModel()
        let startViewResourceSection = ExpandableSection.ViewModel()
        
        let bottomBarViewModel = BottomBar.ViewModel()
        
        var cancelBag = Set<AnyCancellable>()
        
        init(originalURL: URLComponents? = nil, rssFeeds: [RSSFeed]? = nil, rsshubFeeds: [RSSHubFeed]? = nil, queryItems: [URLQueryItem] = []) {
            self.originalURL = originalURL
            self.rssFeeds = rssFeeds
            self.rsshubFeeds = rsshubFeeds
            self.queryItems = queryItems
            
            self.$originalURL
                .map { $0?.url }
                .removeDuplicates()
                .map { (url: URL?) -> AnyPublisher<(metadata: LPLinkMetadata, icon: UIImage?, image: UIImage?)?, Never> in
                    if let url = url {
                        let placeholderMetadata = LPLinkMetadata()
                        placeholderMetadata.originalURL = url
                        placeholderMetadata.url = url
                        
                        return AsyncFuture<(metadata: LPLinkMetadata, icon: UIImage?, image: UIImage?)?> {
                            let provider = LPMetadataProvider()
                            if let metadata = await { @MainActor in try? await provider.startFetchingMetadata(for: url) }() {
                                async let icon = metadata.icon?.scaledDownIfNeeded(toFit: CGSize(width: 36, height: 36))
                                async let image = metadata.image
                                return await (metadata, icon, image)
                            } else {
                                return nil
                            }
                        }.prepend((placeholderMetadata, nil, nil))
                        .eraseToAnyPublisher()
                    } else {
                        return Just(nil).eraseToAnyPublisher()
                    }
                }.switchToLatest()
                .compactMap { $0 }
                .receive(on: DispatchQueue.main)
                .sink { [bottomBarViewModel] tuple in
                    let (metadata, icon, image) = tuple
                    withAnimation(BottomBar.transitionAnimation) {
                        bottomBarViewModel.linkURL = metadata.url?.components
                        bottomBarViewModel.linkTitle = metadata.title
                        bottomBarViewModel.linkIcon = icon.map(Image.init(uiImage:))
                        bottomBarViewModel.linkImage = image.map(Image.init(uiImage:))
                        if let icon = icon {
                            bottomBarViewModel.linkIconSize = (icon.size.width < 20) && (icon.size.height < 20) ? .small : .large
                        }
                    }
                }.store(in: &self.cancelBag)
            
            bottomBarViewModel.analyzeClipboardContent = { [unowned self] in
                if let url = UIPasteboard.general.url?.components {
                    process(url: url)
                } else if let url = UIPasteboard.general.string?.detect(types: .link).compactMap(\.url?.components).first {
                    process(url: url)
                }
            }
            
            bottomBarViewModel.dismiss = { [unowned self] in dismiss() }
            
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
                    self.bottomBarViewModel.state = .focusedOnLink
                    self.bottomBarViewModel.progress = 0.0
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
                                    self.bottomBarViewModel.progress = 1.0
                                }
                            case .failure(let error):
                                print(error)
                                withAnimation {
                                    self.isProcessing = false
                                    self.bottomBarViewModel.progress = 0.0
                                    self.rssFeeds = nil
                                    self.rsshubFeeds = nil
                                    self.alert = Alert(title: Text("An Error Occurred"), message: Text(verbatim: error.localizedDescription))
                                }
                            }
                        } receiveValue: { [unowned self] result in
                            withAnimation {
                                self.bottomBarViewModel.progress += 0.3
                                self.rssFeeds = result.rssFeeds
                                self.rsshubFeeds = result.rsshubFeeds
                            }
                        }.store(in: &self.cancelBag)
                }
            }
        }
        
        func dismiss() {
            withAnimation {
                originalURL = nil
                rssFeeds = nil
                rsshubFeeds = nil
                bottomBarViewModel.state = .focusedOnControls
                bottomBarViewModel.linkURL = nil
                bottomBarViewModel.linkIcon = nil
                bottomBarViewModel.linkImage = nil
                bottomBarViewModel.linkTitle = nil
            }
        }
        
        func analyzeClipboardContent() {
            if let url = UIPasteboard.general.url?.components {
                process(url: url)
            } else if let url = UIPasteboard.general.string?.detect(types: .link).compactMap(\.url?.components).first {
                process(url: url)
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
                Button("See What's Supported", systemImage: "text.book.closed.fill") {
                    openURL(URLComponents(string: "https://docs.rsshub.app/social-media.html")!)
                }
                
                Button("Submit New Rules", systemImage: "link.badge.plus") {
                    openURL(URLComponents(string: "https://docs.rsshub.app/joinus/quick-start.html#ti-jiao-xin-de-rsshub-radar-gui-ze")!)
                }
                
                if xCallbackContext.wrappedValue.cancel != nil {
                    Button(continueXCallbackText(), systemImage: "arrowtriangle.backward.fill", withAnimation: .default, action: continueXCallback)
                }
            }.buttonStyle(CayButtonStyle(wideContainerWithBackgroundColor: Color(uiColor: .tertiarySystemBackground)))
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

