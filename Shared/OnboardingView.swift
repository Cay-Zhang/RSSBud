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
                .transition(OnboardingView.transition)
                .zIndex(1)
        case .rssHubURL:
            RSSHubURL(currentPage: $currentPage)
                .transition(OnboardingView.transition)
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
    
    static let transition: AnyTransition = AnyTransition.asymmetric(
        insertion: AnyTransition.move(edge: .trailing),
        removal: AnyTransition.scale(scale: 0.7)
            .combined(with: AnyTransition.opacity)
    )
    
    static let transitionAnimation: Animation = .spring(dampingFraction: 0.85)
    
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
                
                Text(verbatim: "RSSBud is an open-source auxiliary app for RSSHub. He can help you quickly discover and subscribe to RSS feeds of different websites.")
                    .multilineTextAlignment(.center)
                    .lineSpacing(5)
                    .padding(.horizontal, 8)
                
                VStack(spacing: 8) {
                    WideButton("Learn more about RSSHub", systemImage: "info.circle.fill") {
                        openURL(URLComponents(string: "https://docs.rsshub.app/en/")!)
                    }
                    
                    WideButton("All about RSS", systemImage: "list.star") {
                        openURL(URLComponents(string: "https://github.com/AboutRSS/ALL-about-RSS")!)
                    }
                    
                    WideButton("Next", systemImage: "arrow.right", withAnimation: OnboardingView.transitionAnimation) {
                        currentPage = .rssHubURL
                    }
                }
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
                
                WideButton("Back", systemImage: "link.badge.plus", withAnimation: OnboardingView.transitionAnimation) {
                    currentPage = .welcome
                }
            }.padding(.top, 20)
            .padding(.bottom, 8)
        }
    }
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ScrollView {
                OnboardingView()
                    .padding(20)
                    .navigationTitle("Onboarding")
            }
        }
    }
}
