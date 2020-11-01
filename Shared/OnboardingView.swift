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
        case .subscribe:
            Subscribe(currentPage: $currentPage, openURL: openURL)
                .transition(OnboardingView.transition)
                .zIndex(3)
        case .rssHubInstance:
            RSSHubInstance(currentPage: $currentPage, openURL: openURL)
                .transition(OnboardingView.transition)
                .zIndex(4)
        case .support:
            Support(currentPage: $currentPage, openURL: openURL)
                .transition(OnboardingView.transition)
                .zIndex(5)
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
        case subscribe
        case rssHubInstance
        case support
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
                        currentPage = .subscribe
                    }.matchedGeometryEffect(id: "Next", in: namespace)
                }
            }.padding(.top, 20)
            .padding(.bottom, 8)
        }
    }
    
    struct Subscribe: View {
        
        @Binding var currentPage: Page
        var openURL: (URLComponents) -> Void = { _ in }
        
        @Environment(\.namespace) var namespace
        
        var body: some View {
            VStack(spacing: 16) {
                Image(systemName: "arrowshape.turn.up.right.fill")
                    .font(.system(size: 24, weight: .semibold, design: .default))
                    .foregroundColor(.accentColor)
                    .frame(width: 70, height: 70)
                    .background(Color(UIColor.tertiarySystemBackground))
                    .clipShape(Circle())
                
                Text("Subscribe")
                    .font(.system(size: 24, weight: .semibold, design: .default))
                
                Text(verbatim: "RSSBud offers one-tap subscription to these RSS readers and services.")
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
                
                Text(verbatim: "Please select the ones you use.")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
                
                IntegrationSettingsView(backgroundColor: Color(UIColor.tertiarySystemBackground))
                    .frame(height: 263)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(Color.gray.opacity(0.5), lineWidth: 3)
                    ).padding(.horizontal, 1.5)
                
                VStack(spacing: 8) {
                    WideButton("Next", systemImage: "arrow.right", withAnimation: OnboardingView.transitionAnimation) {
                        currentPage = .rssHubInstance
                    }.matchedGeometryEffect(id: "Next", in: namespace)
                }
            }.padding(.top, 20)
            .padding(.bottom, 8)
        }
    }
    
    struct RSSHubInstance: View {
        @State var isEnteringRSSHubBaseURL: Bool = false
        @Binding var currentPage: Page
        var openURL: (URLComponents) -> Void = { _ in }
        
        @Environment(\.namespace) var namespace
        var rssHubBaseURL = RSSHub.BaseURL()
        
        var body: some View {
            VStack(spacing: 16) {
                Image("Icon")
                    .resizable()
                    .frame(width: 100, height: 100, alignment: .center)
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                
                Text("RSSHub Instance")
                    .font(.system(size: 24, weight: .semibold, design: .default))
                
                Text(verbatim: "You are encouraged to host your own RSSHub instance for better usability. The official demo instance may be unreliable due to anti-crawler policies of some websites.")
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
                
                if isEnteringRSSHubBaseURL {
                    VStack(spacing: 16) {
                        Text(verbatim: "Please enter the URL of the instance.")
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 8)
                        
                        ValidatedTextField(
                            "RSSHub App URL",
                            text: rssHubBaseURL.$string,
                            validation: rssHubBaseURL.validate(string:)
                        ).foregroundColor(.primary)
                        .keyboardType(.URL)
                        .disableAutocorrection(true)
                        .padding(.horizontal, 10)
                        .roundedRectangleBackground()
                        
                        WideButton("Next", systemImage: "arrow.right", withAnimation: OnboardingView.transitionAnimation) {
                            currentPage = .support
                        }.matchedGeometryEffect(id: "Next", in: namespace)
                    }.transition(OnboardingView.transition)
                } else {
                    VStack(spacing: 8) {
                        WideButton("Learn more about Deployment", systemImage: "info.circle.fill") {
                            openURL(URLComponents(string: "https://docs.rsshub.app/en/")!)
                        }
                        
                        WideButton("Use My Own Instance", systemImage: "lock.shield.fill", withAnimation: OnboardingView.transitionAnimation) {
                            isEnteringRSSHubBaseURL = true
                        }
                        
                        WideButton("Use Official Demo", systemImage: "exclamationmark.shield.fill", withAnimation: OnboardingView.transitionAnimation) {
                            rssHubBaseURL.string = RSSHub.officialDemoBaseURLString
                            currentPage = .support
                        }.accentColor(.red)
                    }.transition(OnboardingView.transition)
                }
                
            }.padding(.top, 20)
            .padding(.bottom, 8)
        }
    }
    
    struct Support: View {
        
        @Binding var currentPage: Page
        var openURL: (URLComponents) -> Void = { _ in }
        
        @AppStorage("isOnboarding", store: RSSBud.userDefaults) var isOnboarding: Bool = true
        @Environment(\.namespace) var namespace
        
        var body: some View {
            VStack(spacing: 16) {
                Image("Icon")
                    .resizable()
                    .frame(width: 100, height: 100, alignment: .center)
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                
                Text("Support RSSBud")
                    .font(.system(size: 24, weight: .semibold, design: .default))
                
                Text(verbatim: "RSSBud is open source and completely free under the MIT license. Your support is crucial to our development.")
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
                
                VStack(spacing: 8) {
                    WideButton("Star on GitHub!", systemImage: "star.fill") {
                        openURL(URLComponents(string: "https://github.com/Cay-Zhang/RSSBud")!)
                    }.accentColor(.yellow)
                    
                    WideButton("Join Telegram Discussion", systemImage: "paperplane.fill") {
                        openURL(URLComponents(string: "https://t.me/RSSBud_Discussion")!)
                    }
                    
                    WideButton("Submit New Rules", systemImage: "link.badge.plus") {
                        openURL(URLComponents(string: "https://docs.rsshub.app/joinus/#ti-jiao-xin-de-rsshub-radar-gui-ze")!)
                    }
                    
                    WideButton("Donate to RSSBud", systemImage: "yensign.circle.fill") {
                        openURL(URLComponents(string: "https://docs.rsshub.app/joinus/#ti-jiao-xin-de-rsshub-radar-gui-ze")!)
                    }.environment(\.isEnabled, false)
                    
                    HStack(spacing: 8) {
                        WideButton("Start Over", systemImage: "arrow.left", withAnimation: OnboardingView.transitionAnimation) {
                            currentPage = .welcome
                        }
                        
                        WideButton("Done", systemImage: "checkmark", withAnimation: OnboardingView.transitionAnimation) {
                            isOnboarding = false
                        }
                    }
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
                OnboardingView(currentPage: .support)
                    .padding(20)
                    .navigationTitle("Onboarding")
            }
        }.colorScheme(.dark)
    }
}
