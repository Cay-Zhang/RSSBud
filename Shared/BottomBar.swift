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
    @ObservedObject var viewModel: Self.ViewModel
    @FocusState var isTextFieldFocused: Bool
    
    var body: some View {
        let url = viewModel.linkURL ?? URLComponents()
        ZStack {
            viewModel.linkImage?
                .resizable()
                .aspectRatio(1, contentMode: .fill)
                .opacity((!viewModel.isEditing && viewModel.progress == 1.0) ? 0.5 : 0.0)
                .allowsHitTesting(false)
            
            Rectangle().fill(.thinMaterial).transition(.identity)
            
            AutoAdvancingProgressView(viewModel: viewModel.progressViewModel)
                .progressViewStyle(BarProgressViewStyle())
                .tint(!viewModel.isFailed ? nil : .red)
                .opacity((viewModel.progress != 1.0) ? 0.1 : 0.0)
            
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    linkTitleView
                        .font(.system(size: 15, weight: .semibold, design: .default))
                        .transition(.offset(y: -25).combined(with: .opacity))
                    
                    linkURLView(url: url)
                        .environment(\.backgroundMaterial, .thin)
                }
                Spacer()
                if !viewModel.isEditing && viewModel.linkIconSize == .large {
                    viewModel.linkIcon?
                        .clipShape(RoundedRectangle(cornerRadius: 3, style: .continuous))
                        .transition(.offset(x: 60).combined(with: .opacity))
                }
            }.padding(16)
            .font(Font.body.weight(.semibold))
            .layoutPriority(1)
            .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .contextMenu(menuItems: linkViewContextMenuItems)
        }.clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color(.sRGBLinear, white: 0, opacity: 0.15), radius: 12, y: 3)
        .transition(.offset(y: 50).combined(with: .scale(scale: 0.5)).combined(with: .opacity))
        .gesture(dragGesture, including: .all)
        .offset(viewModel.offset)
        .animation(Self.transitionAnimation, value: viewModel.linkTitle)
        .animation(Self.transitionAnimation, value: viewModel.isEditing)
    }
    
    var dragGesture: some Gesture {
        DragGesture(minimumDistance: 5, coordinateSpace: .global)
            .onChanged { value in
                let translation = CGSize(width: value.translation.width, height: value.translation.height + viewModel.dragTranslationYDelta)
                let offsetHeight = decay(translation.height, positiveThreshold: 0, negativeThreshold: 0)
                withAnimation(Self.transitionAnimation) {
                    viewModel.offset.height = offsetHeight
                    if isTextFieldFocused {
                        if translation.height > 30 {
                            if viewModel.linkURL != nil {
                                viewModel.isEditing = false
                            }
                            isTextFieldFocused = false
                            assert(viewModel.dragTranslationYDelta == 0, "dragTranslationYDelta should not accumulate.")
                            viewModel.dragTranslationYDelta = -value.translation.height - 45
                            Self.feedbackGenerator.selectionChanged()
                        }
                    } else if translation.height < -50 {
                        if !viewModel.isEditing {
                            viewModel.isEditing = true
                            Self.feedbackGenerator.selectionChanged()
                        }
                    } else if translation.height > 15 {
                        if !viewModel.isEditing {
                            viewModel._isEditing = true
                            viewModel.editingText = ""
                            Self.feedbackGenerator.selectionChanged()
                        }
                    } else if viewModel.isEditing && viewModel.linkURL != nil {
                        viewModel.isEditing = false
                        Self.feedbackGenerator.selectionChanged()
                    }
                }
            }.onEnded { value in
                let translation = CGSize(width: value.translation.width, height: value.translation.height + viewModel.dragTranslationYDelta)
                withAnimation(.spring()) {
                    if translation.height < -50 {
                        isTextFieldFocused = true
                    } else if translation.height > 15 {
                        viewModel.dismiss()
                    }
                    viewModel.offset.height = 0
                    viewModel.dragTranslationYDelta = 0
                }
            }
    }
    
    @ViewBuilder func linkViewContextMenuItems() -> some View {
        Button {
            viewModel.linkURL?.url.map { UIPasteboard.general.url = $0 }
        } label: {
            Label("Copy Link", systemImage: "doc.on.doc.fill")
        }
        
        Button(action: viewModel.dismiss) {
            Label("Dismiss Current Analysis", systemImage: "clear.fill")
        }
    }
    
    @ViewBuilder var linkTitleView: some View {
        if !viewModel.isEditing, let title = viewModel.linkTitle {
            if let icon = viewModel.linkIcon, viewModel.linkIconSize == .small {
                Label { Text(title).lineLimit(1) } icon: { icon }
            } else {
                Text(title).lineLimit(2)
            }
        }
    }
    
    @ViewBuilder func linkURLView(url: URLComponents) -> some View {
        ZStack(alignment: .leading) {
            ValidatedTextField("Bottom Bar Start Prompt", text: $viewModel.editingText) { $0.isEmpty || URLComponents(string: $0)?.host != nil }
                .keyboardType(.URL)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
                .animatableFont(size: (viewModel.linkTitle != nil && !viewModel.isEditing) ? 13 : 15, weight: .semibold)
                .opacity(viewModel.isEditing ? 1 : 0)
                .offset(x: viewModel.isEditing ? 0 : -30)
                .focused($isTextFieldFocused)
                .onSubmit {
                    if !viewModel.editingText.isEmpty, let url = URLComponents(autoPercentEncoding: viewModel.editingText) {
                        viewModel.onSubmit(url)
                    }
                }
            Text((viewModel.linkTitle != nil) ? conciseRepresentation(of: url) : detailedRepresentation(of: url))
                .foregroundStyle(.secondary)
                .animatableFont(size: (viewModel.linkTitle != nil && !viewModel.isEditing) ? 13 : 15, weight: (viewModel.linkTitle != nil && !viewModel.isEditing) ? .regular : .semibold)
                .opacity(!viewModel.isEditing ? 1 : 0)
                .offset(x: viewModel.isEditing ? 30 : 0)
        }
    }
}

extension BottomBar {
    class ViewModel: ObservableObject {
        @Published var linkURL: URLComponents?
        @Published var linkTitle: String?
        @Published var linkIcon: Image?
        @Published var linkImage: Image?
        @Published var linkIconSize: LinkIconSize = .large
        
        @Published var isFailed: Bool = false
        @Published var _isEditing: Bool = true
        @Published var editingText: String = ""
        
        @Published var progress: Double = 1.0
        let progressViewModel = AutoAdvancingProgressView.ViewModel()
        
        @Published var offset: CGSize = .zero
        var dragTranslationYDelta: CGFloat = 0
        
        var dismiss: () -> Void = { }
        var onSubmit: (URLComponents) -> Void = { _ in }
        
        var cancelBag = Set<AnyCancellable>()
        
        init() {
            $progress
                .assign(to: \.progress, on: progressViewModel)
                .store(in: &cancelBag)
        }
        
        var isEditing: Bool {
            get { _isEditing }
            set {
                _isEditing = newValue
                if newValue {
                    editingText = linkURL?.string ?? ""
                }
            }
        }
    }
}

extension BottomBar {
    enum LinkIconSize {
        case small, large
    }
    
    func conciseRepresentation(of url: URLComponents) -> AttributedString {
        AttributedString(url.host ?? url.string ?? "")
    }
    
    func detailedRepresentation(of url: URLComponents) -> AttributedString {
        guard let rangeOfHost = url.rangeOfHost,
              let startingIndexOfPath = url.rangeOfPath?.lowerBound,
              let hostString = url.string?[rangeOfHost],
              let afterHostString = url.string?[startingIndexOfPath...]
        else {
            return AttributedString(url.string ?? "")
        }
        var host = AttributedString(hostString)
        host.foregroundColor = Color.primary
        let afterHost = AttributedString(afterHostString)
        return host + afterHost
    }
    
    func decay(_ value: CGFloat, positiveThreshold: CGFloat, negativeThreshold: CGFloat, k: CGFloat = 20) -> CGFloat {
        return (value >= 0) ? _decay(value, threshold: positiveThreshold, k: k) : -_decay(-value, threshold: -negativeThreshold, k: k)
    }
    
    private func _decay(_ value: CGFloat, threshold: CGFloat, k: CGFloat) -> CGFloat {
        assert(value >= 0 && threshold >= 0)
        if value > threshold {
            let x = value - threshold
            return threshold + sqrt(k * (x + 0.25 * k)) - 0.5 * k
        } else {
            return value
        }
    }
}

extension BottomBar {
    static let feedbackGenerator: UISelectionFeedbackGenerator = UISelectionFeedbackGenerator()
    static var transitionAnimation: Animation { Animation.interpolatingSpring(mass: 3, stiffness: 1000, damping: 500, initialVelocity: 0) }
    static var contentTransition: AnyTransition {
        AnyTransition.offset(y: 25).combined(with: AnyTransition.opacity)
    }
}

struct BottomBar_Previews: PreviewProvider {
    static var contentViewModels = [ContentView.ViewModel]()
    
    static func bottomBar(for url: URLComponents) -> BottomBar {
        let model = ContentView.ViewModel()
        contentViewModels.append(model)
        model.originalURL = url
        return BottomBar(viewModel: model.bottomBarViewModel)
    }
    
    static var previews: some View {
        Group {
            bottomBar(for: "https://space.bilibili.com/17404347")
            bottomBar(for: "https://www.youtube.com/watch?v=7A5-eRfDQ0M")
        }
    }
}
