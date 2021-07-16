//
//  FeedView.swift
//  RSSBud
//
//  Created by Cay Zhang on 2020/8/17.
//

import SwiftUI

struct RSSFeedView: View {
    
    var feed: RSSFeed
    var contentViewModel: ContentView.ViewModel
    @Environment(\.customOpenURLAction) var openURL
    @Integration var integrations
    @Environment(\.xCallbackContext) var xCallbackContext: Binding<XCallbackContext>
    
    func integrationURL(for integrationKey: Integration.Key) -> URLComponents? {
        _integrations.url(forAdding: feed.url, to: integrationKey)
    }
    
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
            .success?
            .appending(queryItems: [
                URLQueryItem(name: "feed_title", value: feed.title),
                URLQueryItem(name: "feed_url", value: feed.url.string)
            ])
        url.map(openURL.callAsFunction(_:))
        xCallbackContext.wrappedValue = nil
    }
    
    var body: some View {
        VStack(spacing: 10.0) {
            Text(feed.title)
                .fontWeight(.semibold)
                .padding(.horizontal, 15)
            
//            Text(rsshubURL().string ?? "URL Conversion Failed")
//                .padding(.horizontal, 15)
            
            if xCallbackContext.wrappedValue.success != nil {
                Button(continueXCallbackText(), systemImage: "arrowtriangle.backward.fill", withAnimation: .default, action: continueXCallback)
                    .padding(.horizontal, 8)
            } else {
                HStack(spacing: 8) {
                    Button("Copy", systemImage: "doc.on.doc.fill") {
                        feed.url.url.map { UIPasteboard.general.url = $0 }
                    }
                    
                    integrationButton
                }.padding(.horizontal, 8)
            }
            
        }.padding(.top, 15)
        .padding(.bottom, 8)
        .frame(maxWidth: .infinity)
        .buttonStyle(CayButtonStyle(wideContainerWithBackgroundColor: Color(uiColor: .tertiarySystemBackground)))
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
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

struct RSSHubFeedView: View {
    
    var feed: RSSHubFeed
    var contentViewModel: ContentView.ViewModel
    @Environment(\.customOpenURLAction) var openURL
    @Integration var integrations
    @RSSHub.BaseURL var baseURL
    var rssHubAccessControl = RSSHub.AccessControl()
    @Environment(\.xCallbackContext) var xCallbackContext: Binding<XCallbackContext>
    
    func rsshubURL() -> URLComponents {
        baseURL
            .appending(path: feed.path)
            .appending(queryItems: contentViewModel.queryItems + rssHubAccessControl.accessCodeQueryItem(for: feed.path))
            .omittingEmptyQueryItems()
    }
    
    func integrationURL(for integrationKey: Integration.Key) -> URLComponents? {
        _integrations.url(forAdding: rsshubURL(), to: integrationKey)
    }
    
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
            .success?
            .appending(queryItems: [
                URLQueryItem(name: "feed_title", value: feed.title),
                URLQueryItem(name: "feed_url", value: rsshubURL().string)
            ])
        url.map(openURL.callAsFunction(_:))
        xCallbackContext.wrappedValue = nil
    }
    
    var body: some View {
        VStack(spacing: 10.0) {
            Text(feed.title)
                .fontWeight(.semibold)
                .padding(.horizontal, 15)
            
//            Text(rsshubURL().string ?? "URL Conversion Failed")
//                .padding(.horizontal, 15)
            
            if xCallbackContext.wrappedValue.success != nil {
                Button(continueXCallbackText(), systemImage: "arrowtriangle.backward.fill", withAnimation: .default, action: continueXCallback)
                    .padding(.horizontal, 8)
            } else {
                HStack(spacing: 8) {
                    Button("Copy", systemImage: "doc.on.doc.fill") {
                        rsshubURL().url.map { UIPasteboard.general.url = $0 }
                    }
                    
                    integrationButton
                }.padding(.horizontal, 8)
            }
            
        }.padding(.top, 15)
        .padding(.bottom, 8)
        .frame(maxWidth: .infinity)
        .buttonStyle(CayButtonStyle(wideContainerWithBackgroundColor: Color(uiColor: .tertiarySystemBackground)))
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
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

struct FeedView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView_Previews.previews
    }
}
