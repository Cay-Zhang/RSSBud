//
//  FeedView.swift
//  RSSBud
//
//  Created by Cay Zhang on 2020/8/17.
//

import SwiftUI

protocol FeedView: View {
    var feedTitle: String { get }
    var feedURL: URLComponents { get }
    var pathComponents: [Substring] { get }
    var docsURL: URLComponents? { get }
    
    var openURL: CustomOpenURLAction { get }
    var xCallbackContext: XCallbackContext { get nonmutating set }
    
    var _integrations: Integration { get }
}

extension FeedView {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(feedTitle)
                        .font(Font.system(size: 20.0, weight: .semibold, design: .default))
                        .minimumScaleFactor(0.7)
                    
                    pathComponentsView
                }
               
                Spacer()
                
                if let docsURL = docsURL {
                    Button {
                        openURL(docsURL)
                    } label: {
                        Image(systemName: "text.book.closed.fill")
                            .font(Font.system(size: 20.0, weight: .semibold, design: .default))
#if os(visionOS)
                            .foregroundStyle(.secondary)
#else
                            .foregroundStyle(.tint)
#endif
                    }.buttonStyle(CayButtonStyle(containerModifier: EmptyModifier()))
                }
            }
            
            if xCallbackContext.success != nil {
                Button(continueXCallbackText(), systemImage: "arrowtriangle.backward.fill", withAnimation: .default, action: continueXCallback)
            } else {
                HStack(spacing: 8) {
                    Button("Copy", systemImage: "doc.on.doc.fill") {
                        feedURL.url.map { UIPasteboard.general.url = $0 }
                    }
                    
                    integrationButton
                }
            }
        }.padding(.top, 12)
        .padding(.bottom, 9)
        .padding(.horizontal, 9)
        .frame(maxWidth: .infinity)
        .buttonStyle(CayButtonStyle(wideContainerWithFill: \.tertiary))
        .menuStyle(CayMenuStyle())
        .background {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .foregroundStyle(.fill.quaternary)
        }
    }
    
    @ViewBuilder var pathComponentsView: some View {
        if #available(iOS 16.0, *) {
            ScrollView(.horizontal) {
                HStack(spacing: 4) {
                    ForEach(pathComponents, id: \.self) { component in
                        Text(component)
                            .lineLimit(1)
                            .foregroundStyle(.secondary)
                            .font(Font.system(size: 13.0, weight: .regular, design: .rounded))
                            .padding(4)
                            .background(.fill.tertiary, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                    }
                }
            }.scrollIndicators(.hidden)
        } else {
            HStack(spacing: 4) {
                ForEach(pathComponents, id: \.self) { component in
                    Text(component)
                        .lineLimit(1)
                        .foregroundStyle(.secondary)
                        .font(Font.system(size: 13.0, weight: .regular, design: .rounded))
                        .padding(4)
                        .background(.fill.tertiary, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                }
            }
        }
    }
    
    var integrations: [Integration.Key] { _integrations.wrappedValue }
    
    func continueXCallbackText() -> LocalizedStringKey {
        if let source = xCallbackContext.source {
            return LocalizedStringKey("Continue in \(source)")
        } else {
            return LocalizedStringKey("Continue")
        }
    }
    
    func continueXCallback() {
        let url = xCallbackContext
            .success?
            .appending(queryItems: [
                URLQueryItem(name: "feed_title", value: feedTitle),
                URLQueryItem(name: "feed_url", value: feedURL.string)
            ])
        url.map(openURL.callAsFunction(_:))
        xCallbackContext = nil
    }
    
    func integrationURL(for integrationKey: Integration.Key) -> URLComponents? {
        _integrations.url(forAdding: feedURL, to: integrationKey)
    }
    
    @ViewBuilder var integrationButton: some View {
        if integrations.count == 1, let url = integrationURL(for: integrations[0]) {
            let label = LocalizedStringKey(integrations[0] == .systemDefaultReader ? "Subscribe" : integrations[0].rawValue)
            Button(label, systemImage: "arrowshape.turn.up.right.fill") {
                openURL(url)
            }
        } else {
            Menu {
                ForEach(integrations) { key in
                    if let url = integrationURL(for: key) {
                        Button(LocalizedStringKey(key.rawValue)) {
                            openURL(url)
                        }
                    }
                }
            } label: {
                Label("Subscribe", systemImage: "arrowshape.turn.up.right.fill")
                    .modifier(WideButtonContainerModifier())
                    .backgroundStyle(.fill.tertiary)
            }
        }
    }
}

struct RSSFeedView: FeedView {
    var feed: RSSFeed
    var contentViewModel: ContentView.ViewModel
    
    @Environment(\.customOpenURLAction) var openURL
    @Environment(\.xCallbackContext) @Binding var xCallbackContext: XCallbackContext
    var _integrations = Integration()
    
    var feedTitle: String { feed.title }
    var feedURL: URLComponents { feed.url }
    var pathComponents: [Substring] {
        feed.url.path.split(separator: "/", omittingEmptySubsequences: true)
    }
    var docsURL: URLComponents? { feed.docsURL?.wrappedValue }
}

struct RSSHubFeedView: FeedView {
    var feed: RSSHubFeed
    var contentViewModel: ContentView.ViewModel
    
    @Environment(\.customOpenURLAction) var openURL
    @Environment(\.xCallbackContext) @Binding var xCallbackContext: XCallbackContext
    @RSSHub.BaseURL var baseURL
    var rssHubAccessControl = RSSHub.AccessControl()
    var _integrations = Integration()
    
    var feedTitle: String { feed.title }
    
    var feedURL: URLComponents {
        baseURL
            .appending(path: feed.path)
            .appending(queryItems: contentViewModel.queryItems + rssHubAccessControl.accessCodeQueryItem(for: feed.path))
            .omittingEmptyQueryItems()
    }
    
    var pathComponents: [Substring] {
        return feed.path.split(separator: "/", omittingEmptySubsequences: true)
    }
    
    var docsURL: URLComponents? { feed.docsURL }
}

struct FeedView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView_Previews.previews
        
        VStack(spacing: 16) {
            ForEach(Integration.Key.allCases.dropFirst()) { key in
                HStack(spacing: 8) {
                    Button(LocalizedStringKey(key.rawValue), systemImage: "arrowshape.turn.up.right.fill") { }
                    
                    Button(LocalizedStringKey(key.rawValue), systemImage: "arrowshape.turn.up.right.fill") { }
                        .environment(\.locale, Locale(identifier: "zh-CN"))
                }
            }
            
            HStack(spacing: 8) {
                Button("Subscribe", systemImage: "arrowshape.turn.up.right.fill") { }
                
                Button("Subscribe", systemImage: "arrowshape.turn.up.right.fill") { }
                    .environment(\.locale, Locale(identifier: "zh-CN"))
            }
        }.padding(.horizontal, 25)
        .buttonStyle(CayButtonStyle(wideContainerWithFill: \.quaternary))
        .previewDisplayName("Subscribe Buttons")
    }
}
