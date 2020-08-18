//
//  FeedView.swift
//  RSSBud
//
//  Created by Cay Zhang on 2020/8/17.
//

import SwiftUI

struct FeedView: View {
    
    var feed: Radar.DetectedFeed
    var contentViewModel: ContentView.ViewModel
    var openURL: (URLComponents) -> Void = { _ in }
    @Integration var integrations
    @RSSBud.BaseURL var baseURL
    
    func rsshubURL() -> URLComponents {
        baseURL.replacing(path: feed.path).appending(queryItems: contentViewModel.queryItems)
    }
    
    func integrationURL(for integrationKey: Integration.Key) -> URLComponents? {
        Integration.url(forAdding: rsshubURL(), to: integrationKey)
    }
    
    var body: some View {
        VStack(spacing: 10.0) {
            Text(feed.title).fontWeight(.semibold)
                .padding(.horizontal, 15)
            Text(rsshubURL().string ?? "URL Conversion Failed")
                .padding(.horizontal, 15)
            
            HStack(spacing: 0) {
                Button {
                    rsshubURL().url.map { UIPasteboard.general.url = $0 }
                } label: {
                    Label("Copy", systemImage: "doc.on.doc.fill")
                }.buttonStyle(RoundedRectangleButtonStyle())
                
                integrationButton
            }.padding(.horizontal, 4)
        }.padding(.top, 15)
        .padding(.bottom, 4)
        .frame(maxWidth: .infinity)
        .background(Color(UIColor.secondarySystemFill))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
    
    @ViewBuilder var integrationButton: some View {
        if integrations.count == 1, let url = integrationURL(for: integrations[0]) {
            Button {
                openURL(url)
            } label: {
                Label(integrations[0].rawValue, systemImage: "arrowshape.turn.up.right.fill")
            }.buttonStyle(RoundedRectangleButtonStyle())
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
                Button { } label: {
                    Label("Integrations", systemImage: "ellipsis")
                }.buttonStyle(RoundedRectangleButtonStyle())
            }
        }
    }
    
}

struct FeedView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView_Previews.previews
    }
}
