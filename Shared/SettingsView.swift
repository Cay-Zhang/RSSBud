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
                    
                    NavigationLink(destination: Core.RuleManagerView()) {
                        Text("Rules")
                    }
                    
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
                        Text(LocalizedStringKey(key.rawValue))
                        ValidatedTextField("App URL", text: _integrations.$ttrssBaseURLString, validation: validate(urlString:))
                            .foregroundColor(.secondary)
                            .keyboardType(.URL)
                            .disableAutocorrection(true)
                    }.tag(key)
                case .miniflux:
                    VStack(alignment: .leading, spacing: 2.0) {
                        Text(LocalizedStringKey(key.rawValue))
                        ValidatedTextField("App URL", text: _integrations.$minifluxBaseURLString, validation: validate(urlString:))
                            .foregroundColor(.secondary)
                            .keyboardType(.URL)
                            .disableAutocorrection(true)
                    }.tag(key)
                case .freshRSS:
                    VStack(alignment: .leading, spacing: 2.0) {
                        Text(LocalizedStringKey(key.rawValue))
                        ValidatedTextField("App URL", text: _integrations.$freshRSSBaseURLString, validation: validate(urlString:))
                            .foregroundColor(.secondary)
                            .keyboardType(.URL)
                            .disableAutocorrection(true)
                    }.tag(key)
                default:
                    Text(LocalizedStringKey(key.rawValue)).tag(key)
                }
            }.listRowBackground(rowBackgroundColor)
        }.background(backgroundColor?.ignoresSafeArea())
        .environment(\.editMode, .constant(.active))
    }
}

extension Core {
    struct RuleManagerView: View {
        @AppStorage("isAdvancedRuleConfigurationEnabled", store: RSSBud.userDefaults) var isAdvancedRuleConfigurationEnabled: Bool = false
        @Environment(\.customOpenURLAction) var openURL
        
        var body: some View {
            Form {
                if !isAdvancedRuleConfigurationEnabled {
                    Section {
                        VStack(alignment: .leading, spacing: 8.0) {
                            Image(systemName: "info.circle.fill")
                                .font(Font.system(size: 24.0, weight: .medium, design: .default))
                            
                            Text("Rules Overview")
                                .fontWeight(.medium)
                        }.padding(.vertical, 4)
                        .foregroundColor(.secondary)
                    }
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 10) {
                        Image("RSSHub")
                            .resizable()
                            .frame(width: 32, height: 32)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            .font(Font.system(size: 24.0, weight: .medium, design: .default))
                        
                        Text("RSSHub Radar Rules Overview")
                            .fontWeight(.medium)
                    }.padding(.vertical, 4)
                    .foregroundColor(.secondary)
                    
                    Button("See What's Supported", systemImage: "arrow.up.forward.app.fill") {
                        openURL("https://docs.rsshub.app/social-media.html")
                    }
                    
                    Button("Submit New Rules", systemImage: "arrow.up.forward.app.fill") {
                        openURL("https://docs.rsshub.app/joinus/quick-start.html#ti-jiao-xin-de-rsshub-radar-gui-ze")
                    }
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 10) {
                        Image("Icon")
                            .resizable()
                            .frame(width: 32, height: 32)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            .font(Font.system(size: 24.0, weight: .medium, design: .default))
                        
                        Text("RSSBud Rules Overview")
                            .fontWeight(.medium)
                    }.padding(.vertical, 4)
                    .foregroundColor(.secondary)
                    
                    Button("Submit New Rules", systemImage: "arrow.up.forward.app.fill") {
                        openURL("https://github.com/Cay-Zhang/RSSBudRules")
                    }
                }
                
                if !isAdvancedRuleConfigurationEnabled {
                    BasicRuleConfigurationView()
                } else {
                    AdvancedRuleConfigurationView()
                }
            }.navigationTitle("Rules")
        }
    }
}

extension Core.RuleManagerView {
    private struct BasicRuleConfigurationView: View {
        @ObservedObject var ruleManager = RuleManager.shared
        @AppStorage("isAdvancedRuleConfigurationEnabled", store: RSSBud.userDefaults) var isAdvancedRuleConfigurationEnabled: Bool = false
        @AppStorage("rules", store: RSSBud.userDefaults) @CodableAdaptor private var _ruleFilesInfo: [RuleFileInfo] = RuleManager.defaultRuleFilesInfo  // subscribing to changes, do not set
        @AppStorage("lastRSSHubRadarRemoteRulesFetchDate", store: RSSBud.userDefaults) private var _lastRemoteRulesFetchDate: Double?
        @Environment(\.customOpenURLAction) private var openURL
        
        private var lastRemoteRulesFetchDate: Date? {
            get { _lastRemoteRulesFetchDate.map(Date.init(timeIntervalSinceReferenceDate:)) }
            set { _lastRemoteRulesFetchDate = newValue?.timeIntervalSinceReferenceDate }
        }
        
        private var ruleLanguageBinding: Binding<String> {
            .init {
                RuleManager.defaultRuleFileLanguages.first { RuleManager.defaultRuleFilesInfo(for: $0).withStableID == RuleManager.shared.ruleFilesInfo.withStableID } ?? {
                    assertionFailure()
                    return RuleManager.defaultRuleFileLanguages[0]
                }()
            } set: { newValue in
                RuleManager.shared.updateRuleFilesInfo(RuleManager.defaultRuleFilesInfo(for: newValue))
                RuleManager.shared.fetchRemoteRules()
            }
        }
        
        var body: some View {
            Section {
                VStack(alignment: .leading, spacing: 8.0) {
                    Image(systemName: "character.book.closed.fill")
                        .font(Font.system(size: 24.0, weight: .medium, design: .default))
                    
                    Text("Rule Language Overview")
                        .fontWeight(.medium)
                }.padding(.vertical, 4)
                .foregroundColor(.secondary)
                
                Picker("Rule Language", selection: ruleLanguageBinding) {
                    ForEach(RuleManager.defaultRuleFileLanguages, id: \.self) { language in
                        Text(verbatim: Locale.current.localizedString(forLanguageCode: language) ?? language)
                    }
                }
                
                Button("Contribute To Rule Translations", systemImage: "arrow.up.forward.app.fill") {
                    openURL("https://github.com/Cay-Zhang/RSSBudRules")
                }
            }
            
            Section {
                VStack(alignment: .leading, spacing: 8.0) {
                    Image(systemName: "externaldrive.fill.badge.icloud")
                        .font(Font.system(size: 24.0, weight: .medium, design: .default))
                    
                    Text("Rule Update Overview")
                        .fontWeight(.medium)
                }.padding(.vertical, 4)
                .foregroundColor(.secondary)
                
                if let date = lastRemoteRulesFetchDate {
                    HStack {
                        Text("Last Update")
                        
                        Spacer()
                        
                        Text("\(date, style: .relative) ago")
                            .foregroundColor(.secondary)
                    }
                }
                
                HStack {
                    Button(
                        ruleManager.isFetchingRemoteRules ? "Updating Rules..." : "Update Rules Now",
                        systemImage: "arrow.down.square.fill"
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
            
            Section {
                VStack(alignment: .leading, spacing: 8.0) {
                    Image(systemName: "hammer.fill")
                        .font(Font.system(size: 24.0, weight: .medium, design: .default))
                    
                    Text("Advanced Mode Overview")
                        .fontWeight(.medium)
                }.padding(.vertical, 4)
                .foregroundColor(.secondary)
                
                Button("Switch To Advanced Mode", systemImage: "exclamationmark.square.fill", withAnimation: .default) {
                    isAdvancedRuleConfigurationEnabled = true
                }.foregroundColor(.red)
            }
        }
    }
    
    private struct AdvancedRuleConfigurationView: View {
        @ObservedObject var ruleManager = RuleManager.shared
        @State private var ruleFilesInfo: [RuleFileInfo] = RuleManager.shared.ruleFilesInfo
        @AppStorage("isAdvancedRuleConfigurationEnabled", store: RSSBud.userDefaults) var isAdvancedRuleConfigurationEnabled: Bool = false
        @AppStorage("lastRSSHubRadarRemoteRulesFetchDate", store: RSSBud.userDefaults) private var _lastRemoteRulesFetchDate: Double?
        
        private var lastRemoteRulesFetchDate: Date? {
            get { _lastRemoteRulesFetchDate.map(Date.init(timeIntervalSinceReferenceDate:)) }
            set { _lastRemoteRulesFetchDate = newValue?.timeIntervalSinceReferenceDate }
        }
        
        var body: some View {
            Section {
                if let date = lastRemoteRulesFetchDate {
                    HStack {
                        Text("Last Update")
                        
                        Spacer()
                        
                        Text("\(date, style: .relative) ago")
                            .foregroundColor(.secondary)
                    }
                }
                
                HStack {
                    Button(
                        ruleManager.isFetchingRemoteRules ? "Updating Rules..." : "Save and update",
                        systemImage: "arrow.down.square.fill"
                    ) {
                        ruleManager.updateRuleFilesInfo(ruleFilesInfo)
                        ruleManager.fetchRemoteRules()
                        ruleManager.scheduleRemoteRulesFetchTask()
                    }.environment(\.isEnabled, ruleFilesInfo.isValid && !ruleManager.isFetchingRemoteRules)
                    
                    Spacer()
                    
                    if ruleManager.isFetchingRemoteRules {
                        ProgressView()
                    }
                }
                
                Button("Add new rule file", systemImage: "plus.square.fill", withAnimation: .default) {
                    ruleFilesInfo.insert(.init(filename: "", remoteURL: ""), at: 0)
                }
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
                Button("Switch To Basic Mode", systemImage: "arrow.uturn.left.square.fill", withAnimation: .default) {
                    RuleManager.shared.updateRuleFilesInfo(RuleManager.defaultRuleFilesInfo)
                    RuleManager.shared.fetchRemoteRules()
                    isAdvancedRuleConfigurationEnabled = false
                }.foregroundColor(.red)
            } footer: {
                Text("Switch To Basic Mode Warning")
            }
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
        }.symbolRenderingMode(.hierarchical)
    }
}
