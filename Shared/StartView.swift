//
//  StartView.swift
//  StartView
//
//  Created by Cay Zhang on 2021/8/3.
//

import SwiftUI

struct StartView: View {
    @Binding var isRuleManagerPresented: Bool
    
    @Environment(\.customOpenURLAction) var openURL
    @EnvironmentObject var viewModel: ContentView.ViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            ExpandableSection(viewModel: viewModel.startViewStartSection) {
                Button("Read From Clipboard", systemImage: "arrow.up.doc.on.clipboard", action: viewModel.analyzeClipboardContent)
                    .buttonStyle(CayButtonStyle(wideContainerWithBackgroundColor: Color(uiColor: .secondarySystemBackground)))
            } label: {
                Text("Start")
            }
            
            ExpandableSection(viewModel: viewModel.startViewResourceSection) {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150, maximum: .infinity), spacing: 10)], spacing: 10) {
                    Button("GitHub Repo Homepage", systemImage: "star.fill") {
                        openURL("https://github.com/Cay-Zhang/RSSBud")
                    }
                    
                    Button("Telegram Group", systemImage: "paperplane.fill") {
                        openURL("https://t.me/RSSBud_Discussion")
                    }
                    
                    Button("Rules", systemImage: "checklist") {
                        isRuleManagerPresented = true
                    }
                    
                    
                    Button("All About RSS", systemImage: "list.star") {
                        openURL("https://github.com/AboutRSS/ALL-about-RSS")
                    }
                    
                    Button("RSSHub Documentation", systemImage: "text.book.closed.fill") {
                        openURL("https://docs.rsshub.app/")
                    }
                }.buttonStyle(CayButtonStyle(blockContainerWithBackgroundColor: Color(uiColor: .secondarySystemBackground)))
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
