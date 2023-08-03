//
//  StartView.swift
//  StartView
//
//  Created by Cay Zhang on 2021/8/3.
//

import SwiftUI

struct StartView: View {
    @State var isShortcutWorkshopPresented: Bool = false
    @Binding var isRuleManagerPresented: Bool
    
    @Environment(\.customOpenURLAction) var openURL
    @EnvironmentObject var viewModel: ContentView.ViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            ExpandableSection(viewModel: viewModel.startViewStartSection) {
                Button("Read From Clipboard", systemImage: "arrow.up.doc.on.clipboard", action: viewModel.analyzeClipboardContent)
                    .buttonStyle(CayButtonStyle(wideContainerWithFill: \.tertiary))
            } label: {
                Text("Start")
            }
            
            ExpandableSection(viewModel: viewModel.startViewResourceSection) {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150, maximum: .infinity), spacing: 10)], spacing: 10) {
                    Button("Rules", systemImage: "terminal.fill") {
                        isRuleManagerPresented = true
                    }
                    
                    Button("Shortcut Workshop", systemImage: "square.stack.3d.up.fill") {
                        isShortcutWorkshopPresented = true
                    }.sheet(isPresented: $isShortcutWorkshopPresented) {
                        NavigationView {
                            ShortcutWorkshopView()
                                .toolbar {
                                    ToolbarItem(placement: .navigationBarTrailing) {
                                        Button {
                                            isShortcutWorkshopPresented = false
                                        } label: {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                        }.modifier(CustomOpenURLModifier(openInSystem: openURL.openInSystem))
                    }

                    Button {
                        openURL("https://github.com/Cay-Zhang/RSSBud")
                    } label: {
                        Label {
                            Text("GitHub Repo Homepage")
                        } icon: {
                            Image("GitHub")
                                .font(.system(size: 28))
                                .offset(y: -1)
                        }
                    }
                    
                    Button("Telegram Group", systemImage: "paperplane.fill") {
                        openURL("https://t.me/RSSBud_Discussion")
                    }
                    
                    Button("All About RSS", systemImage: "list.star") {
                        openURL("https://github.com/AboutRSS/ALL-about-RSS")
                    }
                    
                    Button("RSSHub Documentation", systemImage: "text.book.closed.fill") {
                        openURL("https://docs.rsshub.app/")
                    }
                }.buttonStyle(CayButtonStyle(blockContainerWithFill: \.tertiary))
            } label: {
                Text("Resources")
            }
        }
    }
}

struct StartView_Previews: PreviewProvider {
    static let viewModel = ContentView.ViewModel()
    
    static var previews: some View {
        ContentView(viewModel: viewModel, isOnboarding: false)
    }
}
