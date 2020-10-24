//
//  OnboardingView.swift
//  RSSBud
//
//  Created by Cay Zhang on 2020/10/24.
//

import SwiftUI

struct OnboardingView: View {
    
    var openURL: (URLComponents) -> Void = { _ in }
    
    @State var currentPage: Page = .welcome
    
    @ViewBuilder var currentPageView: some View {
        switch currentPage {
        case .welcome:
            Welcome(currentPage: $currentPage, openURL: openURL)
                .transition(AnyTransition.opacity)
                .zIndex(1)
        case .rssHubURL:
            RSSHubURL(currentPage: $currentPage)
                .transition(AnyTransition.opacity)
                .zIndex(2)
        }
    }
    
    var body: some View {
        ZStack {
            Color(UIColor.secondarySystemBackground)
                .zIndex(0)
            
            currentPageView
                .padding(.horizontal, 8)
                .frame(maxWidth: .infinity)
        }.clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

extension OnboardingView {
    
    enum Page {
        case welcome
        case rssHubURL
    }
    
    struct Welcome: View {
        
        @Binding var currentPage: Page
        var openURL: (URLComponents) -> Void = { _ in }
        
        var body: some View {
            VStack(spacing: 16) {
                Image("Icon")
                    .resizable()
                    .frame(width: 100, height: 100, alignment: .center)
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                Text("Welcome!")
                    .font(.system(size: 24, weight: .semibold, design: .default))
                
                Button {
                    openURL(URLComponents(string: "https://docs.rsshub.app/social-media.html")!)
                } label: {
                    Label("Learn more about RSSHub", systemImage: "info.circle.fill")
                        .roundedRectangleBackground()
                }.buttonStyle(SquashableButtonStyle())
                
                Button {
                    openURL(URLComponents(string: "https://docs.rsshub.app/joinus/#ti-jiao-xin-de-rsshub-radar-gui-ze")!)
                } label: {
                    Label("Submit New Rules", systemImage: "link.badge.plus")
                        .roundedRectangleBackground()
                }.buttonStyle(SquashableButtonStyle())
                
                Button {
                    withAnimation { currentPage = .rssHubURL }
                } label: {
                    Label("Next", systemImage: "link.badge.plus")
                        .roundedRectangleBackground()
                }.buttonStyle(SquashableButtonStyle())
            }.padding(.top, 20)
            .padding(.bottom, 8)
        }
    }
    
    struct RSSHubURL: View {
        
        @Binding var currentPage: Page
        
        var body: some View {
            VStack(spacing: 16) {
                Image("Icon")
                    .resizable()
                    .frame(width: 100, height: 100, alignment: .center)
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                Text("Page 2")
                    .font(.system(size: 24, weight: .semibold, design: .default))
                
                Button {
//                    openURL(URLComponents(string: "https://docs.rsshub.app/social-media.html")!)
                } label: {
                    Label("Learn more about RSSHub", systemImage: "info.circle.fill")
                        .roundedRectangleBackground()
                }.buttonStyle(SquashableButtonStyle())
                Button {
//                    openURL(URLComponents(string: "https://docs.rsshub.app/joinus/#ti-jiao-xin-de-rsshub-radar-gui-ze")!)
                } label: {
                    Label("Submit New Rules", systemImage: "link.badge.plus")
                        .roundedRectangleBackground()
                }.buttonStyle(SquashableButtonStyle())
                
                Divider()
            }.padding(.top, 20)
            .padding(.bottom, 8)
        }
    }
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            OnboardingView()
                .navigationTitle("Test")
        }
    }
}
