//
//  ExpandableSection.swift
//  RSSBud
//
//  Created by Cay Zhang on 2021/3/20.
//

import SwiftUI
import Combine

struct ExpandableSection<Content: View, Label: View>: View {
    @ObservedObject var viewModel: ExpandableSection<Never, Never>.ViewModel
    @ViewBuilder var content: () -> Content
    @ViewBuilder var label: Label

    var body: some View {
        LazyVStack {
            Button(action: toggleExpanded) {
                HStack {
                    if !viewModel.isExpanded {
                        Image(systemName: "plus")
                            .imageScale(.small)
                            .transition(AnyTransition.offset(x: -50))
                    }
                    label
                    Spacer()
                    Image(systemName: "chevron.down")
                        .imageScale(.small)
                        .rotationEffect(viewModel.isExpanded ? .degrees(0) : .degrees(-90))
                }.padding(.horizontal, viewModel.isExpanded ? 0 : 10)
                .padding(.top, 10)
                .padding(.bottom, viewModel.isExpanded ? 0 : 10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.fill.tertiary.opacity(viewModel.isExpanded ? 0.0 : 1.0))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .hoverEffect()
            }
            .buttonStyle(CayButtonStyle(containerModifier: EmptyModifier()).labelOpacityWhenPressed(0.75))
            .animatableFont(
                size: viewModel.isExpanded ? 24 : 18,
                weight: .semibold,
                design: .default
            )
#if os(xrOS)
            .foregroundStyle(.secondary)
#else
            .foregroundStyle(.tint)
#endif
            .zIndex(1)
            
            if viewModel.isExpanded {
                content()
                    .transition(contentTransition)
                    .zIndex(0)
            }
        }
    }
    
    func toggleExpanded() {
        withAnimation(transitionAnimation) {
            viewModel.isExpanded.toggle()
        }
    }
}

extension ExpandableSection {
    var transitionAnimation: Animation { Animation.spring(response: 0.5, dampingFraction: 1) }
    var contentTransition: AnyTransition {
        AnyTransition.offset(y: -25).combined(with: AnyTransition.opacity).animation(transitionAnimation.speed(1.5))
    }
}

extension ExpandableSection {
    class ViewModel: ObservableObject {
        @Published var isExpanded: Bool
        
        init(isExpanded: Bool = true) where Content == Never, Label == Never {
            self.isExpanded = isExpanded
        }
    }
}

struct DisclosureList_Previews: PreviewProvider {
    static let viewModel = ExpandableSection.ViewModel()
    
    static var previews: some View {
        NavigationView {
            ScrollView {
                ExpandableSection(viewModel: viewModel) {
                    ForEach(1..<21) { i in
                        Text("Text \(i)")
                            .font(.system(size: 27, weight: Font.Weight.semibold, design: Font.Design.default))
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity)
                            .background(Color(UIColor.secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                } label: {
                    Text("Section 1")
                        .foregroundColor(.accentColor)
                }.padding(16)
            }.navigationTitle("ExpandableSection")
        }.colorScheme(.dark)
    }
}
