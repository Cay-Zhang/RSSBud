//
//  ExpandableSection.swift
//  RSSBud
//
//  Created by Cay Zhang on 2021/3/20.
//

import SwiftUI

struct ExpandableSection<Content: View, Label: View>: View {
    
    init(isExpanded: Bool = true, @ViewBuilder content: () -> Content, @ViewBuilder label: () -> Label) {
        self._useBinding = false
        self._isExpandedState = State(wrappedValue: isExpanded)
        self._isExpandedBinding = .constant(true)
        self.content = content()
        self.label = label()
    }
    
    init(isExpanded: Binding<Bool>, @ViewBuilder content: () -> Content, @ViewBuilder label: () -> Label) {
        self._useBinding = true
        self._isExpandedBinding = isExpanded
        self._isExpandedState = State(wrappedValue: true)
        self.content = content()
        self.label = label()
    }
    
    var isExpanded: Bool {
        get { _useBinding ? isExpandedBinding : isExpandedState }
        nonmutating set {
            if _useBinding {
                isExpandedBinding = newValue
            } else {
                isExpandedState = newValue
            }
        }
    }
    
    var content: Content
    var label: Label
    
    @State var isExpandedState: Bool
    @Binding var isExpandedBinding: Bool
    let _useBinding: Bool

    var body: some View {
        LazyVStack {
            Button(action: toggleExpanded) {
                HStack {
                    if !isExpanded {
                        Image(systemName: "plus")
                            .imageScale(.small)
                            .transition(AnyTransition.offset(x: -50))
                    }
                    label
                    Spacer()
                    Image(systemName: "chevron.down")
                        .imageScale(.small)
                        .rotationEffect(isExpanded ? .degrees(0) : .degrees(-90))
                }.padding(.horizontal, isExpanded ? 0 : 10)
                .padding(.top, 10)
                .padding(.bottom, isExpanded ? 0 : 10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    Color(UIColor.secondarySystemBackground)
                        .opacity(isExpanded ? 0.0 : 1.0)
                )
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .contentShape(Rectangle())
            }.buttonStyle(SquashableButtonStyle())
            .animatableFont(
                size: isExpanded ? 24 : 18,
                weight: .semibold,
                design: .default
            ).foregroundColor(.accentColor)
            .zIndex(1)
            
            if isExpanded {
                content
                    .transition(contentTransition)
                    .zIndex(0)
            }
        }
    }
    
    func toggleExpanded() {
        withAnimation(transitionAnimation) {
            isExpanded.toggle()
        }
    }
}

extension ExpandableSection {
    var transitionAnimation: Animation { Animation.spring(response: 0.5, dampingFraction: 1) }
    var contentTransition: AnyTransition {
        AnyTransition.offset(y: -25).combined(with: AnyTransition.opacity).animation(transitionAnimation.speed(1.5))
    }
}

struct DisclosureList_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ScrollView {
                ExpandableSection {
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
