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
                            .foregroundStyle(.tint)
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
        .buttonStyle(CayButtonStyle(wideContainerWithBackgroundColor: Color(uiColor: .tertiarySystemBackground)))
        .menuStyle(CayMenuStyle())
        .background {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(uiColor: .secondarySystemBackground))
        }
    }
    
    var pathComponentsView: some View {
        HStack(spacing: 4) {
            ForEach(pathComponents, id: \.self) { component in
                Text(component)
                    .foregroundStyle(.secondary)
                    .font(Font.system(size: 13.0, weight: .regular, design: .rounded))
                    .padding(4)
                    .background(Color(uiColor: UIColor.tertiarySystemBackground), in: RoundedRectangle(cornerRadius: 6, style: .continuous))
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
            Button(integrations[0].rawValue, systemImage: "arrowshape.turn.up.right.fill") {
                openURL(url)
            }
        } else {
            Menu {
                ForEach(integrations) { key in
                    if let url = integrationURL(for: key) {
                        Button(key.rawValue) {
                            openURL(url)
                        }
                    }
                }
            } label: {
                Label("Subscribe", systemImage: "arrowshape.turn.up.right.fill")
                    .modifier(WideButtonContainerModifier(backgroundColor: Color(uiColor: .tertiarySystemBackground)))
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
    var docsURL: URLComponents? { nil }
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
    }
}
