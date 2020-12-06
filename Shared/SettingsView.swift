//
//  SettingsView.swift
//  RSSBud
//
//  Created by Cay Zhang on 2020/8/10.
//

import SwiftUI

struct SettingsView: View {
    var openURL: (URLComponents) -> Void = { _ in }
    var storedBaseURL = RSSHub.BaseURL()
    @State var baseURLString: String
    @State var isAlertPresented = false
    
    @ObservedObject var ruleManager = RuleManager.shared
    @AppStorage("lastRSSHubRadarRemoteRulesFetchDate", store: RSSBud.userDefaults) var _lastRemoteRulesFetchDate: Double?
    @AppStorage("isOnboarding", store: RSSBud.userDefaults) var isOnboarding: Bool = true
    @Environment(\.presentationMode) var presentationMode
    var rssHubAccessControl = RSSHub.AccessControl()
    
    var lastRemoteRulesFetchDate: Date? {
        get { _lastRemoteRulesFetchDate.map(Date.init(timeIntervalSinceReferenceDate:)) }
        set { _lastRemoteRulesFetchDate = newValue?.timeIntervalSinceReferenceDate }
    }
    
    init(openURL: @escaping (URLComponents) -> Void = { _ in }) {
        self.openURL = openURL
        self._baseURLString = State(wrappedValue: storedBaseURL.string)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Settings Section General")) {
                    HStack {
                        Text("RSSHub URL")
                        Spacer()
                        ValidatedTextField(
                            "RSSHub URL",
                            text: storedBaseURL.$string,
                            validation: storedBaseURL.validate(string:)
                        ).foregroundColor(.secondary)
                        .keyboardType(.URL)
                        .disableAutocorrection(true)
                        .multilineTextAlignment(.trailing)
                    }
                    
                    NavigationLink(
                        "Quick Subscriptions",
                        destination: IntegrationSettingsView(backgroundColor: Color(UIColor.systemGroupedBackground))
                            .navigationTitle("Quick Subscriptions")
                    )
                    
                    Toggle("Access Control", isOn: rssHubAccessControl.$isAccessControlEnabled.animation(.default))
                    
                    if rssHubAccessControl.isAccessControlEnabled {
                        HStack {
                            Text("Access Key")
                            Spacer()
                            SecureField("Access Key", text: rssHubAccessControl.$unwrappedAccessKey)
                        }
                    }
                    
                    NavigationLink(destination: RSSHub.Radar.RulesEditor()) {
                        HStack {
                            Text("Rules")
                            Spacer()
                            if let date = lastRemoteRulesFetchDate {
                                Text("Updated \(date, style: .relative) ago")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    HStack {
                        Button(
                            ruleManager.isFetchingRemoteRules ? "Updating Rules..." : "Update Rules Now",
                            systemImage: "arrow.clockwise"
                        ) {
                            ruleManager.fetchRemoteRules()
                            ruleManager.scheduleRemoteRulesFetchTask()
                        }.environment(\.isEnabled, !ruleManager.isFetchingRemoteRules)
                        
                        Spacer()
                        
                        if ruleManager.isFetchingRemoteRules {
                            ProgressView()
                        }
                    }
                }
                
                Section(header: Text("Settings Section About")) {
                    Button("GitHub Repo Homepage", systemImage: "star.fill") {
                        openURL(URLComponents(string: "https://github.com/Cay-Zhang/RSSBud")!)
                    }
                    
                    Button("Telegram Channel", systemImage: "paperplane.fill") {
                        openURL(URLComponents(string: "https://t.me/RSSBud")!)
                    }
                    
                    Button("Telegram Group", systemImage: "paperplane.fill") {
                        openURL(URLComponents(string: "https://t.me/RSSBud_Discussion")!)
                    }
                    
                    Button(
                        isOnboarding ? "Onboarding Skip" : "Onboarding Restart",
                        systemImage: "newspaper.fill"
                    ) {
                        withAnimation(OnboardingView.transitionAnimation) {
                            isOnboarding.toggle()
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                }
            }.navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: ToolbarItemPlacement.navigationBarTrailing) {
                    Button {
                        presentationMode.wrappedValue.dismiss()
                    } label: {
                        Image(systemName: "checkmark")
                    }
                }
            }.background(
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()
            )
        }.listStyle(InsetGroupedListStyle())
        .alert(isPresented: $isAlertPresented) {
            Alert(title: Text("Base URL is invalid."))
        }
    }
}

struct IntegrationSettingsView: View {
    var rowBackgroundColor: Color? = nil
    var backgroundColor: Color? = nil
    
    @Integration var integrations
    
    func validate(urlString: String) -> Bool {
        URLComponents(string: urlString)?.host != nil
    }
    
    var body: some View {
        List(selection: $integrations) {
            ForEach(Integration.Key.allCases) { key in
                switch key {
                case .tinyTinyRSS:
                    VStack(alignment: .leading, spacing: 2.0) {
                        Text(key.rawValue)
                        ValidatedTextField("App URL", text: _integrations.$ttrssBaseURLString, validation: validate(urlString:))
                            .foregroundColor(.secondary)
                            .keyboardType(.URL)
                            .disableAutocorrection(true)
                    }.tag(key)
                case .miniflux:
                    VStack(alignment: .leading, spacing: 2.0) {
                        Text(key.rawValue)
                        ValidatedTextField("App URL", text: _integrations.$minifluxBaseURLString, validation: validate(urlString:))
                            .foregroundColor(.secondary)
                            .keyboardType(.URL)
                            .disableAutocorrection(true)
                    }.tag(key)
                case .freshRSS:
                    VStack(alignment: .leading, spacing: 2.0) {
                        Text(key.rawValue)
                        ValidatedTextField("App URL", text: _integrations.$freshRSSBaseURLString, validation: validate(urlString:))
                            .foregroundColor(.secondary)
                            .keyboardType(.URL)
                            .disableAutocorrection(true)
                    }.tag(key)
                default:
                    Text(key.rawValue).tag(key)
                }
            }.listRowBackground(rowBackgroundColor)
        }.background(backgroundColor?.ignoresSafeArea())
        .environment(\.editMode, .constant(.active))
    }
}

extension RSSHub.Radar {
    struct RulesEditor: View {
        @State var rules: String = RSSHub.Radar.localRules.content
        
        var body: some View {
            TextEditor(text: $rules)
                .font(.system(size: 12, weight: .light, design: .monospaced))
                .disableAutocorrection(true)
                .navigationTitle("Rules")
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            SettingsView()
            
            NavigationView {
                IntegrationSettingsView()
            }
            
            NavigationView {
                RSSHub.Radar.RulesEditor()
            }
        }
    }
}
