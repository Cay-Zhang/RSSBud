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
    
    @Namespace var namespace
    
    @ViewBuilder var currentPageView: some View {
        switch currentPage {
        case .welcome:
            Welcome(currentPage: $currentPage, openURL: openURL)
                .transition(OnboardingView.transition)
                .zIndex(1)
        case .discover:
            Discover(currentPage: $currentPage, openURL: openURL)
                .transition(OnboardingView.transition)
                .zIndex(2)
        case .userInfo:
            UserInfo(currentPage: $currentPage)
                .transition(OnboardingView.transition)
                .zIndex(3)
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
        .environment(\.namespace, namespace)
    }
}

extension OnboardingView {
    
    static let transition: AnyTransition = AnyTransition.asymmetric(
        insertion: AnyTransition.move(edge: .trailing),
        removal: AnyTransition.scale(scale: 0.7)
            .combined(with: AnyTransition.opacity)
    )
    
    static let transitionAnimation: Animation = Animation.spring(dampingFraction: 0.85)
    
    enum Page {
        case welcome
        case discover
        case userInfo
    }
    
    struct Welcome: View {
        
        @Binding var currentPage: Page
        var openURL: (URLComponents) -> Void = { _ in }
        
        @Environment(\.namespace) var namespace
        
        var body: some View {
            VStack(spacing: 16) {
                Image("Icon")
                    .resizable()
                    .frame(width: 100, height: 100, alignment: .center)
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                
                Text("Welcome!")
                    .font(.system(size: 24, weight: .semibold, design: .default))
                
                Text(verbatim: "RSSBud can help you quickly discover and subscribe to RSS feeds of different websites, especially those provided by RSSHub.")
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
                
                VStack(spacing: 8) {
                    WideButton("Learn more about RSSHub", systemImage: "info.circle.fill") {
                        openURL(URLComponents(string: "https://docs.rsshub.app/en/")!)
                    }
                    
                    WideButton("All about RSS", systemImage: "list.star") {
                        openURL(URLComponents(string: "https://github.com/AboutRSS/ALL-about-RSS")!)
                    }
                    
                    WideButton("Next", systemImage: "arrow.right", withAnimation: OnboardingView.transitionAnimation) {
                        currentPage = .discover
                    }.matchedGeometryEffect(id: "Next", in: namespace)
                }
            }.padding(.top, 20)
            .padding(.bottom, 8)
        }
    }
    
    struct Discover: View {
        
        @Binding var currentPage: Page
        var openURL: (URLComponents) -> Void = { _ in }
        
        @Environment(\.namespace) var namespace
        
        var body: some View {
            VStack(spacing: 16) {
                
                
                HStack(spacing: -10) {
                    let sideLength: CGFloat = 70
                    Image(systemName: "square.and.arrow.up.fill")
                        .font(.system(size: 24, weight: .semibold, design: .default))
                        .foregroundColor(.accentColor)
                        .frame(width: sideLength, height: sideLength)
                        .background(Color(UIColor.tertiarySystemBackground))
                        .clipShape(Circle())
                    Image(systemName: "doc.on.clipboard.fill")
                        .font(.system(size: 24, weight: .semibold, design: .default))
                        .foregroundColor(.accentColor)
                        .frame(width: sideLength, height: sideLength)
                        .background(Color(UIColor.tertiarySystemBackground))
                        .clipShape(Circle())
                }
                
                Text("Discover")
                    .font(.system(size: 24, weight: .semibold, design: .default))
                
                Text(verbatim: "RSSBud discovers RSS feeds by analyzing a website link according to a set of rules.")
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
                
                Text(verbatim: "Preferably you would share the link to RSSBud using the system share sheet. But in case you only have the option to copy the link, you can also have him read your clipboard for it.")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
                
                VStack(spacing: 8) {
                    WideButton("See What's Supported", systemImage: "text.book.closed.fill") {
                        openURL(URLComponents(string: "https://docs.rsshub.app/social-media.html")!)
                    }
                    
                    WideButton("Next", systemImage: "arrow.right", withAnimation: OnboardingView.transitionAnimation) {
                        currentPage = .userInfo
                    }.matchedGeometryEffect(id: "Next", in: namespace)
                }
            }.padding(.top, 20)
            .padding(.bottom, 8)
        }
    }
    
    struct UserInfo: View {
        
        @Binding var currentPage: Page
        
        @Environment(\.namespace) var namespace
        var rssHubBaseURL = RSSHub.BaseURL()
        
        var body: some View {
            VStack(spacing: 16) {
                
                WideButton("Next", systemImage: "arrow.right", withAnimation: OnboardingView.transitionAnimation) {
                    currentPage = .userInfo
                }.matchedGeometryEffect(id: "Next", in: namespace)
                
                Text("RSSHub App URL")
                    .fontWeight(.semibold)
                
                ValidatedTextField(
                    "RSSHub App URL",
                    text: rssHubBaseURL.$string,
                    validation: rssHubBaseURL.validate(string:)
                ).foregroundColor(.primary)
                .keyboardType(.URL)
                .disableAutocorrection(true)
                .padding(.horizontal, 10)
                .roundedRectangleBackground()
                
                Divider()
                
                Text("Quick Subscription")
                    .fontWeight(.semibold)
                
                IntegrationSettingsView()
                    .frame(height: 564)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                
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
                OnboardingView(currentPage: .discover)
                    .padding(20)
                    .navigationTitle("Onboarding")
            }
        }.colorScheme(.dark)
    }
}
