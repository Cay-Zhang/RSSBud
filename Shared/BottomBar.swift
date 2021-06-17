//
//  BottomBar.swift
//  RSSBud
//
//  Created by Cay Zhang on 2021/6/17.
//

import SwiftUI
import Combine
import LinkPresentation

struct BottomBar: View {
    
    let parentViewModel: ContentView.ViewModel
    @ObservedObject var viewModel: Self.ViewModel
    
    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 8) {
                if isExpanded {
                    Cell { Text("Test") }.transition(Self.contentTransition)
                    Cell { Text("Test") }.transition(Self.contentTransition)
                    Cell { Text("Test") }.transition(Self.contentTransition)
                    Cell { Text("Test") }.transition(Self.contentTransition)
                    Cell { Text("Test") }.transition(Self.contentTransition)
                }
                
                if state != .focusedOnControls { mainCell }
                if state != .focusedOnLink {
                    HStack(spacing: 20) {
                        if parentViewModel.isProcessing {
                            ProgressView()
                        }
                        
                        WideButton("Read From Clipboard", systemImage: "arrow.up.doc.on.clipboard", backgroundColor: UIColor.secondarySystemBackground, action: readFromClipboard)
                    }
                }
            }
            .padding(isExpanded ? 8 : 0)
            .frame(maxWidth: .infinity)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .padding(.bottom, isExpanded ? 0 : 8)
        }.padding(.horizontal, 16)
    }
    
    @ViewBuilder var mainCell: some View {
        if let url = parentViewModel.originalURL {
            Cell(cornerRadius: isExpanded ? 8 : 16) {
                Text(detailedRepresentation(of: url))
            }
                .background(
                    viewModel.linkImage?
                        .resizable()
                        .aspectRatio(1, contentMode: .fill)
                        .opacity(isExpanded ? 0 : 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: isExpanded ? 8 : 16, style: .continuous))
                .onTapGesture {
                    withAnimation(BottomBar.transitionAnimation) {
                        state = (state == .expanded) ? .focusedOnLink : .expanded
                    }
                }
        }
    }
    
    struct Cell<Label: View>: View {
        
        var cornerRadius: CGFloat = 8
        @ViewBuilder var label: Label
       
        var body: some View {
            HStack { label }
                .font(Font.body.weight(.semibold))
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity)
                .background(.thinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        }
        
    }
}

extension BottomBar {
    class ViewModel: ObservableObject {
        @Published var state: ViewState = .focusedOnControls
        @Published var linkURL: URLComponents?
        @Published var linkTitle: String?
        @Published var linkIcon: Image?
        @Published var linkImage: Image?
    }
}

extension BottomBar {
    enum ViewState {
        case expanded, focusedOnControls, focusedOnLink
    }
    
    var state: ViewState {
        get { viewModel.state }
        nonmutating set { viewModel.state = newValue }
    }
    
    var isExpanded: Bool {
        state == .expanded
    }
    
    func detailedRepresentation(of url: URLComponents) -> AttributedString {
        let text = (url.host ?? "Untitled") + (isExpanded ? "" : url.path)
        var attributed = AttributedString(text)
        if let range = attributed.range(of: url.path) {
            attributed[range].foregroundColor = Color.secondary
        }
        return attributed
    }
}

extension BottomBar {
    func readFromClipboard() {
        if let url = UIPasteboard.general.url?.components {
            parentViewModel.process(url: url)
        } else if let url = UIPasteboard.general.string.flatMap(URLComponents.init(autoPercentEncoding:)) {
            parentViewModel.process(url: url)
        }
        withAnimation(BottomBar.transitionAnimation) {
            state = .focusedOnLink
        }
    }
}

extension BottomBar {
    static var transitionAnimation: Animation { Animation.interpolatingSpring(mass: 3, stiffness: 1000, damping: 500, initialVelocity: 0) }
    static var contentTransition: AnyTransition {
        AnyTransition.offset(y: 25).combined(with: AnyTransition.opacity).animation(BottomBar.transitionAnimation.speed(1.5))
    }
}

struct BottomBar_Previews: PreviewProvider {
    static var previews: some View {
        ContentView_Previews.previews
    }
}
