//
//  StartView.swift
//  StartView
//
//  Created by Cay Zhang on 2021/8/3.
//

import SwiftUI

struct StartView: View {
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
                VStack(spacing: 16) {
                    Color.clear.frame(height: 100)
                        .overlay { Text("Todo") }
                }.padding(.horizontal, 8)
                .padding(.top, 20)
                .padding(.bottom, 8)
                .frame(maxWidth: .infinity)
                .background(Color(uiColor: .secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
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
