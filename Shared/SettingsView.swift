//
//  SettingsView.swift
//  RSSBud
//
//  Created by Cay Zhang on 2020/8/10.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.customOpenURLAction) var openURL
    var storedBaseURL = RSSHub.BaseURL()
    @State var baseURLString: String
    @State var isAlertPresented = false
    
    @ObservedObject var ruleManager = RuleManager.shared
    @AppStorage("lastRSSHubRadarRemoteRulesFetchDate", store: RSSBud.userDefaults) var _lastRemoteRulesFetchDate: Double?
    @AppStorage("isOnboarding", store: RSSBud.userDefaults) var isOnboarding: Bool = true
    @Environment(\.presentationMode) var presentationMode
    var rssHubAccessControl = RSSHub.AccessControl()
    @AppStorage("defaultOpenURLMode", store: RSSBud.userDefaults) var defaultOpenURLMode: CustomOpenURLAction.Mode = .inApp
    
    var _isOpenURLInAppPreferred: Binding<Bool> {
        Binding<Bool>(
            get: {
                defaultOpenURLMode == .inApp
            }, set: { newValue in
                defaultOpenURLMode = newValue ? .inApp : .system
            }
        )
    }
    
    var lastRemoteRulesFetchDate: Date? {
        get { _lastRemoteRulesFetchDate.map(Date.init(timeIntervalSinceReferenceDate:)) }
        set { _lastRemoteRulesFetchDate = newValue?.timeIntervalSinceReferenceDate }
    }
    
    init() {
        self._baseURLString = State(wrappedValue: storedBaseURL.string)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Settings Section RSSBud")) {
                    NavigationLink(
                        "Quick Subscriptions",
                        destination: IntegrationSettingsView(backgroundColor: Color(UIColor.systemGroupedBackground))
                            .navigationTitle("Quick Subscriptions")
                    )
                    
                    NavigationLink(
                        "Shortcut Workshop",
                        destination: ShortcutWorkshopView()
                    )
                    
                    Toggle("Prefer Opening URL In App", isOn: _isOpenURLInAppPreferred.animation(.default))
                }
                
                Section(header: Text("Settings Section RSSHub")) {
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
                    
                    Toggle("Access Control", isOn: rssHubAccessControl.$isAccessControlEnabled.animation(.default))
                    
                    if rssHubAccessControl.isAccessControlEnabled {
                        HStack {
                            Text("Access Key")
                            Spacer()
                            SecureField("Access Key", text: rssHubAccessControl.$accessKey)
                                .foregroundColor(.secondary)
                                .disableAutocorrection(true)
                                .multilineTextAlignment(.trailing)
                        }
                    }
                    
                    NavigationLink(destination: Core.RuleManagerView()) {
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

extension Core {
    struct RuleManagerView: View {
        @State var ruleFilesInfo: [RuleFileInfo] = RuleManager.shared.ruleFilesInfo
        
        var body: some View {
            Form {
                Section {
                    Button("Save and update", systemImage: "arrow.clockwise", withAnimation: .default) {
                        RuleManager.shared.updateRuleFilesInfo(ruleFilesInfo)
                        RuleManager.shared.fetchRemoteRules()
                    }.environment(\.isEnabled, ruleFilesInfo != RuleManager.shared.ruleFilesInfo && ruleFilesInfo.isValid)
                }
                
                ForEach($ruleFilesInfo) { $info in
                    Section {
                        HStack {
                            Text("Filename")
                            Spacer()
                            ValidatedTextField(
                                "Filename",
                                text: $info.filename,
                                validation: \.isValidFilename
                            ).foregroundColor(.secondary)
                            .disableAutocorrection(true)
                            .textInputAutocapitalization(.never)
                            .multilineTextAlignment(.trailing)
                        }
                        
                        HStack {
                            Text("Remote URL")
                            Spacer()
                            ValidatedTextField(
                                "Remote URL",
                                text: $info.remoteURL.validatedString,
                                validation: { URLComponents(autoPercentEncoding: $0) != nil }
                            ).foregroundColor(.secondary)
                            .keyboardType(.URL)
                            .disableAutocorrection(true)
                            .multilineTextAlignment(.trailing)
                        }
                        
                        Button("Delete", role: .destructive) {
                            withAnimation {
                                _ = ruleFilesInfo.firstIndex {
                                    $0.id == info.id
                                }.map {
                                    ruleFilesInfo.remove(at: $0)
                                }
                            }
                        }
                    }
                }
                
                Section {
                    Button("Add new rule file", systemImage: "plus", withAnimation: .default) {
                        ruleFilesInfo.append(.init(filename: "", remoteURL: ""))
                    }
                }
            }.navigationTitle("Rules")
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
                Core.RuleManagerView()
            }
        }
    }
}
