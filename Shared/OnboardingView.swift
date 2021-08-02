//
//  OnboardingView.swift
//  RSSBud
//
//  Created by Cay Zhang on 2020/10/24.
//

import SwiftUI

struct OnboardingView: View {
    
    @Environment(\.customOpenURLAction) var openURL
    @State var currentPage: Page = .welcome
    
    @Namespace var namespace
    
    @ViewBuilder var currentPageView: some View {
        switch currentPage {
        case .welcome:
            Welcome(currentPage: $currentPage)
                .transition(OnboardingView.transition)
                .zIndex(1)
        case .discover:
            Discover(currentPage: $currentPage)
                .transition(OnboardingView.transition)
                .zIndex(2)
        case .subscribe:
            Subscribe(currentPage: $currentPage)
                .transition(OnboardingView.transition)
                .zIndex(3)
        case .rssHubInstance:
            RSSHubInstance(currentPage: $currentPage)
                .transition(OnboardingView.transition)
                .zIndex(4)
        case .support:
            Support(currentPage: $currentPage)
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
        .transition(OnboardingView.transition)
        .buttonStyle(CayButtonStyle(wideContainerWithBackgroundColor: Color(uiColor: .tertiarySystemBackground)))
    }
}

extension OnboardingView {
    
    static let transition: AnyTransition = AnyTransition.asymmetric(
        insertion: AnyTransition.move(edge: .trailing),
        removal: AnyTransition.scale(scale: 0.7)
            .combined(with: AnyTransition.opacity)
    )
    
    static let transitionAnimation: Animation = Animation.spring(dampingFraction: 0.85)
    
    enum Page: CaseIterable {
        case welcome
        case discover
        case subscribe
        case rssHubInstance
        case support
    }
    
    struct Welcome: View {
        
        @Binding var currentPage: Page
        @Environment(\.customOpenURLAction) var openURL
        
        @Environment(\.namespace) var namespace
        
        var body: some View {
            VStack(spacing: 16) {
                Image("Icon")
                    .resizable()
                    .frame(width: 100, height: 100, alignment: .center)
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                
                Text("Onboarding Page 1 Title")
                    .font(.system(size: 24, weight: .semibold, design: .default))
                
                Text("Onboarding Page 1 Body")
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
                
                VStack(spacing: 8) {
                    Button("Learn More About RSSHub", systemImage: "info.circle.fill") {
                        openURL(URLComponents(string: "https://docs.rsshub.app/en/")!)
                    }
                    
                    Button("All About RSS", systemImage: "list.star") {
                        openURL(URLComponents(string: "https://github.com/AboutRSS/ALL-about-RSS")!)
                    }
                    
                    Button("Onboarding Next", systemImage: "arrow.right", withAnimation: OnboardingView.transitionAnimation) {
                        currentPage = .discover
                    }
                }
            }.padding(.top, 20)
            .padding(.bottom, 8)
        }
    }
    
    struct Discover: View {
        
        @Binding var currentPage: Page
        @Environment(\.customOpenURLAction) var openURL
        
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
                
                Text("Onboarding Page 2 Title")
                    .font(.system(size: 24, weight: .semibold, design: .default))
                
                Text("Onboarding Page 2 Body 1")
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
                
                Text("Onboarding Page 2 Body 2")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
                
                VStack(spacing: 8) {
                    Button("See What's Supported", systemImage: "text.book.closed.fill") {
                        openURL(URLComponents(string: "https://docs.rsshub.app/social-media.html")!)
                    }
                    
                    Button("Onboarding Next", systemImage: "arrow.right", withAnimation: OnboardingView.transitionAnimation) {
                        currentPage = .subscribe
                    }
                }
            }.padding(.top, 20)
            .padding(.bottom, 8)
        }
    }
    
    struct Subscribe: View {
        
        @Binding var currentPage: Page
        @Environment(\.customOpenURLAction) var openURL
        
        @Environment(\.namespace) var namespace
        
        var body: some View {
            VStack(spacing: 16) {
                Image(systemName: "arrowshape.turn.up.right.fill")
                    .font(.system(size: 24, weight: .semibold, design: .default))
                    .foregroundColor(.accentColor)
                    .frame(width: 70, height: 70)
                    .background(Color(UIColor.tertiarySystemBackground))
                    .clipShape(Circle())
                
                Text("Onboarding Page 3 Title")
                    .font(.system(size: 24, weight: .semibold, design: .default))
                
                Text("Onboarding Page 3 Body 1")
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
                
                Text("Onboarding Page 3 Body 2")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
                
                IntegrationSettingsView(
                    rowBackgroundColor: Color(UIColor.tertiarySystemBackground),
                    backgroundColor: Color(UIColor.tertiarySystemBackground)
                ).frame(height: 263)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Color.gray.opacity(0.5), lineWidth: 3)
                ).padding(.horizontal, 1.5)
                
                VStack(spacing: 8) {
                    Button("Onboarding Next", systemImage: "arrow.right", withAnimation: OnboardingView.transitionAnimation) {
                        currentPage = .rssHubInstance
                    }
                }
            }.padding(.top, 20)
            .padding(.bottom, 8)
        }
    }
    
    struct RSSHubInstance: View {
        @State var isEnteringRSSHubBaseURL: Bool = false
        @State var isUseOfficialDemoButtonShown: Bool = false
        @Binding var currentPage: Page
        @Environment(\.customOpenURLAction) var openURL
        
        @Environment(\.namespace) var namespace
        var rssHubBaseURL = RSSHub.BaseURL()
        
        var body: some View {
            VStack(spacing: 16) {
                Image("Icon")
                    .resizable()
                    .frame(width: 100, height: 100, alignment: .center)
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                
                Text("Onboarding Page 4 Title")
                    .font(.system(size: 24, weight: .semibold, design: .default))
                
                Text("Onboarding Page 4 Body")
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
                
                if isEnteringRSSHubBaseURL {
                    VStack(spacing: 16) {
                        Text("Onboarding Page 4 Prompt")
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 8)
                        
                        ValidatedTextField(
                            "RSSHub App URL",
                            text: rssHubBaseURL.$string,
                            validation: rssHubBaseURL.validate(string:)
                        ).foregroundColor(.primary)
                        .font(Font.body.weight(.semibold))
                        .keyboardType(.URL)
                        .disableAutocorrection(true)
                        .padding(10)
                        .frame(maxWidth: .infinity)
                        .background(Color(uiColor: .tertiarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        
                        Button("Onboarding Next", systemImage: "arrow.right", withAnimation: OnboardingView.transitionAnimation) {
                            currentPage = .support
                        }
                    }.transition(OnboardingView.transition)
                } else {
                    VStack(spacing: 8) {
                        Button("Learn More About Deployment", systemImage: "info.circle.fill") {
                            openURL(URLComponents(string: "https://docs.rsshub.app/en/")!)
                        }
                        
                        Button("Use My Own Instance", systemImage: "lock.shield.fill", withAnimation: OnboardingView.transitionAnimation) {
                            isEnteringRSSHubBaseURL = true
                        }
                        
                        if isUseOfficialDemoButtonShown {
                            Button("Use Official Demo", systemImage: "exclamationmark.shield.fill", withAnimation: OnboardingView.transitionAnimation) {
                                rssHubBaseURL.string = RSSHub.officialDemoBaseURLString
                                currentPage = .support
                            }.accentColor(.red)
                        }
                    }.transition(OnboardingView.transition)
                }
                
            }.padding(.top, 20)
            .padding(.bottom, 8)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    if currentPage == .rssHubInstance {
                        withAnimation(OnboardingView.transitionAnimation) { isUseOfficialDemoButtonShown = true }
                    }
                }
            }
        }
    }
    
    struct Support: View {
        
        @Binding var currentPage: Page
        @Environment(\.customOpenURLAction) var openURL
        
        @AppStorage("isOnboarding", store: RSSBud.userDefaults) var isOnboarding: Bool = true
        @Environment(\.namespace) var namespace
        
        var body: some View {
            VStack(spacing: 16) {
                Image("Icon")
                    .resizable()
                    .frame(width: 100, height: 100, alignment: .center)
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                
                Text("Onboarding Page 5 Title")
                    .font(.system(size: 24, weight: .semibold, design: .default))
                
                Text("Onboarding Page 5 Body")
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
                
                VStack(spacing: 8) {
                    Button("Star on GitHub", systemImage: "star.fill") {
                        openURL(URLComponents(string: "https://github.com/Cay-Zhang/RSSBud")!)
                    }.accentColor(.yellow)
                    
                    Button("Join Telegram Discussion", systemImage: "paperplane.fill") {
                        openURL(URLComponents(string: "https://t.me/RSSBud_Discussion")!)
                    }
                    
                    Button("Submit New Rules", systemImage: "link.badge.plus") {
                        openURL(URLComponents(string: "https://docs.rsshub.app/joinus/quick-start.html#ti-jiao-xin-de-rsshub-radar-gui-ze")!)
                    }
                    
                    Button("Donate to RSSBud", systemImage: "yensign.circle.fill") {
                        openURL(URLComponents(string: "https://docs.rsshub.app/joinus/#ti-jiao-xin-de-rsshub-radar-gui-ze")!)
                    }.environment(\.isEnabled, false)
                    
                    HStack(spacing: 8) {
                        Button("Onboarding Start Over", systemImage: "arrow.left", withAnimation: OnboardingView.transitionAnimation) {
                            currentPage = .welcome
                        }
                        
                        Button("Done", systemImage: "checkmark", withAnimation: OnboardingView.transitionAnimation) {
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
        ForEach(OnboardingView.Page.allCases, id: \.self) { page in
            OnboardingView(currentPage: page)
                .previewLayout(.sizeThatFits)
        }.colorScheme(.dark)
        .environment(\.locale, Locale(identifier: "zh-CN"))
    }
}
