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
    
    @ViewBuilder var bar: some View {
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
        .transition(.offset(y: 100).combined(with: .opacity))
        .gesture(dragGesture, including: .all)
        .gesture(tapGesture, including: !viewModel.isEditing ? .all : .subviews)
        .scaleEffect(x: viewModel.scale, y: viewModel.scale)
    }
    
    var body: some View {
        bar.overlay(alignment: .top) {
            Text("Bottom Bar Hint Swipe Down")
                .fontWeight(.semibold)
                .shadow(color: Color(.sRGBLinear, white: 0, opacity: 1), radius: 25)
                .opacity(viewModel.currentHint == .swipeDown ? 1 : 0)
                .offset(y: viewModel.currentHint == .swipeDown ? 0 : -10)
                .alignmentGuide(.top) { context in context[.bottom] + 8 }
        }.overlay(alignment: .bottom) {
            Text("Bottom Bar Hint Swipe Up")
                .fontWeight(.semibold)
                .shadow(color: Color(.sRGBLinear, white: 0, opacity: 1), radius: 25)
                .opacity(viewModel.currentHint == .swipeUp ? 1 : 0)
                .offset(y: viewModel.currentHint == .swipeUp ? 0 : 10)
                .alignmentGuide(.bottom) { context in context[.top] - 5 }
        }.offset(viewModel.offset)
    }
    
    var dragGesture: some Gesture {
        DragGesture(minimumDistance: 5, coordinateSpace: .global)
            .onChanged { value in
                withAnimation(Self.transitionAnimation) {
                    onDragChanged(rawTranslation: value.translation)
                    viewModel.currentHint = nil
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
                    viewModel.scale = 1
                    viewModel.dragTranslationYDelta = 0
                }
            }
    }
    
    var tapGesture: some Gesture {
        TapGesture().onEnded {
            Task {
                withAnimation(.spring(response: 0.8, dampingFraction: 1.05)) {
                    onDragChanged(rawTranslation: .init(width: 0, height: 120))
                    viewModel.currentHint = .swipeDown
                }
                try await Task.sleep(nanoseconds: 1_500_000_000)
                guard viewModel.currentHint == .swipeDown else { throw CancellationError() }
                withAnimation(.spring(response: 0.8, dampingFraction: 1.05)) {
                    onDragChanged(rawTranslation: .zero)
                    onDragChanged(rawTranslation: .init(width: 0, height: -200))
                    viewModel.currentHint = .swipeUp
                }
                try await Task.sleep(nanoseconds: 1_500_000_000)
                guard viewModel.currentHint == .swipeUp else { throw CancellationError() }
                withAnimation(.spring(response: 0.8, dampingFraction: 1.05)) {
                    onDragChanged(rawTranslation: .zero)
                    viewModel.scale = 1
                    viewModel.currentHint = nil
                }
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
                .onChange(of: isTextFieldFocused) { focused in
                    if focused {
                        viewModel.offset = .zero
                        viewModel.dragTranslationYDelta = 0
                        viewModel.scale = 1
                        viewModel.currentHint = nil
                    }
                }.onSubmit {
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
    
    func onDragChanged(rawTranslation: CGSize) {
        let translation = CGSize(width: rawTranslation.width, height: rawTranslation.height + viewModel.dragTranslationYDelta)
        let offsetHeight = decay(translation.height, positiveThreshold: 0, negativeThreshold: 0)
        viewModel.offset.height = offsetHeight
        viewModel.scale = 1.01
        if isTextFieldFocused {
            if translation.height > 30 {
                if viewModel.linkURL != nil {
                    viewModel.isEditing = false
                }
                isTextFieldFocused = false
                assert(viewModel.dragTranslationYDelta == 0, "dragTranslationYDelta should not accumulate.")
                viewModel.dragTranslationYDelta = -rawTranslation.height - 45
//                Self.feedbackGenerator.selectionChanged()
            }
        } else if translation.height < -50 {
            if !viewModel.isEditing {
                viewModel.isEditing = true
//                Self.feedbackGenerator.selectionChanged()
            }
        } else if translation.height > 15 {
            if !viewModel.isEditing {
                viewModel._isEditing = true
                viewModel.editingText = ""
//                Self.feedbackGenerator.selectionChanged()
            }
        } else if viewModel.isEditing && viewModel.linkURL != nil {
            viewModel.isEditing = false
//            Self.feedbackGenerator.selectionChanged()
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
        @Published var scale: CGFloat = 1
        var dragTranslationYDelta: CGFloat = 0
        
        @Published var currentHint: Hint? = nil
        
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
    
    enum Hint {
        case swipeDown, swipeUp
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
//    static let feedbackGenerator: UISelectionFeedbackGenerator = UISelectionFeedbackGenerator()
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
