//
//  ShortcutWorkshop.swift
//  RSSBud
//
//  Created by Cay Zhang on 2020/12/18.
//

import SwiftUI
import Combine

final class ShortcutWorkshopManager: ObservableObject {
    
    var file: PersistentFile
    
    @Published var workshop: ShortcutWorkshop!
    var cancelBag = Set<AnyCancellable>()
    
    init() {
        let preferredLocalization = Bundle.main.preferredLocalizations.first ?? "en"
        
        let url = FileManager
            .default
            .containerURL(forSecurityApplicationGroupIdentifier: RSSBud.appGroupIdentifier)!
            .appendingPathComponent(preferredLocalization + ".lproj", isDirectory: true)
            .appendingPathComponent("shortcut-workshop.json", isDirectory: false)
        
        // Debug
        if FileManager.default.fileExists(atPath: url.path) {
            try! FileManager.default.removeItem(at: url)
        }
        
        let defaultContentURL = Bundle.main.url(forResource: "shortcut-workshop", withExtension: "json")!
        
        file = try! PersistentFile(url: url, defaultContentURL: defaultContentURL)
        
        let decoder = JSONDecoder()
        
        file.contentPublisher
            .compactMap { $0.data(using: .utf8) }
            .map { data in
                Result { try decoder.decode(ShortcutWorkshop.self, from: data) }
            }.sink { [weak self] result in
                switch result {
                case .success(let workshop):
                    self?.workshop = workshop
                case .failure(let error):
                    fatalError(error.localizedDescription)
                }
            }.store(in: &cancelBag)
    }
}

struct ShortcutWorkshop: Codable {
    var shortcuts: [Shortcut]
}

extension ShortcutWorkshop {
    struct Shortcut: Codable, Identifiable {
        var name: String
        var iconSystemName: String
        var isTemplate: Bool
        var author: String
        var description: String
        var url: URLComponents
        
        var id: String { name }
    }
}

struct ShortcutWorkshopView: View {
    
    @Environment(\.customOpenURLAction) var openURL
    
    @StateObject var manager = ShortcutWorkshopManager()
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                introduction
                
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 300, maximum: .infinity))], spacing: 10) {
                    ForEach(manager.workshop.shortcuts) { shortcut in
                        Button {
                            openURL(shortcut.url)
                        } label: {
                            ShortcutView(shortcut: shortcut)
                        }
                    }
                }.buttonStyle(CayButtonStyle(containerModifier: EmptyModifier()).labelOpacityWhenPressed(0.75))
            }.padding(.horizontal, 16)
        }.navigationTitle("Shortcut Workshop")
        .background(
            Color(UIColor.systemGroupedBackground).ignoresSafeArea()
        )
    }
    
    var introduction: some View {
        ZStack(alignment: .leading) {
#if os(visionOS)
            Rectangle().fill(.regularMaterial)
#else
            Color(uiColor: .secondarySystemGroupedBackground)
#endif
            
            VStack(alignment: .leading, spacing: 8.0) {
                Image(systemName: "ellipsis.bubble.fill")
                    .font(Font.system(size: 24.0, weight: .medium, design: .default))
                
                Text("Shortcut Workshop Introduction")
                    .fontWeight(.medium)
            }.padding(.horizontal)
            .padding(.top, 12)
            .padding(.bottom, 15)
        }.foregroundColor(.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 18.0, style: .continuous))
        .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0.0, y: 2.0)
    }
    
}

struct ShortcutView: View {
    
    var shortcut: ShortcutWorkshop.Shortcut
    
    var body: some View {
        ZStack(alignment: Alignment(horizontal: .leading, vertical: .center)) {
#if os(visionOS)
            Rectangle().fill(.regularMaterial)
#else
            Color(uiColor: .secondarySystemGroupedBackground)
#endif
            
            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 0) {
                    Image(systemName: shortcut.iconSystemName)
                        .font(Font.system(size: 24.0, weight: .medium, design: .default))
                    
                    Spacer()
                    
                    
                    
                    (Text(verbatim: "\(shortcut.name)")
                    + Text(verbatim: " by \(shortcut.author)").foregroundColor(.secondary))
                        .font(Font.system(size: 17.0, weight: .medium, design: .default))
                        .minimumScaleFactor(0.7)
                }.foregroundColor(.accentColor)
                .padding(.horizontal)
                .padding(.top, 12)
                .padding(.bottom, 15)
                .frame(maxWidth: 175)
                .overlay(
                    shortcut.isTemplate ?
                    Text("Template")
                        .font(Font.system(size: 15, weight: .medium, design: .default))
                        .foregroundColor(.secondary)
                        .padding()
                    : nil
                    , alignment: .topTrailing
                )
                
                Divider()
                    .padding(.vertical)
                
                Text(verbatim: shortcut.description)
                    .foregroundColor(.secondary)
                    .font(Font.system(size: 15.0, weight: .regular, design: .default))
                    .multilineTextAlignment(.leading)
                    .padding(.horizontal)
                    .padding(.top, 12)
                    .padding(.bottom, 15)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
        }.clipShape(RoundedRectangle(cornerRadius: 18.0, style: .continuous))
        .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0.0, y: 2.0)
    }
}

struct ShortcutWorkshopView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ShortcutWorkshopView()
        }.preferredColorScheme(.dark)
        .navigationViewStyle(StackNavigationViewStyle())
    }
}
