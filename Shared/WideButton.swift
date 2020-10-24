//
//  WideButton.swift
//  RSSBud
//
//  Created by Cay Zhang on 2020/8/10.
//

import SwiftUI

struct WideButton: View {
    
    var action: () -> Void
    var label: Label<Text, Image>
    var backgroundColor: UIColor
    
    init(_ label: Label<Text, Image>, backgroundColor: UIColor = .tertiarySystemBackground, action: @escaping () -> Void) {
        self.action = action
        self.label = label
        self.backgroundColor = backgroundColor
    }
    
    init(_ label: Label<Text, Image>, backgroundColor: UIColor = .tertiarySystemBackground, withAnimation animation: Animation?, action: @escaping () -> Void) {
        self.action = { withAnimation(animation, action) }
        self.label = label
        self.backgroundColor = backgroundColor
    }
    
    var body: some View {
        Button {
            action()
        } label: {
            label.roundedRectangleBackground(color: backgroundColor)
        }.buttonStyle(SquashableButtonStyle())
    }
}

extension WideButton {
    init(_ titleKey: LocalizedStringKey, systemImage iconName: String, backgroundColor: UIColor = .tertiarySystemBackground, action: @escaping () -> Void) {
        self.action = action
        self.label = Label(titleKey, systemImage: iconName)
        self.backgroundColor = backgroundColor
    }
    
    init(_ titleKey: LocalizedStringKey, systemImage iconName: String, backgroundColor: UIColor = .tertiarySystemBackground, withAnimation animation: Animation?, action: @escaping () -> Void) {
        self.action = { withAnimation(animation, action) }
        self.label = Label(titleKey, systemImage: iconName)
        self.backgroundColor = backgroundColor
    }
}

struct SquashableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.75 : 1)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
    }
}

extension View {
    func roundedRectangleBackground(color uiColor: UIColor = .tertiarySystemBackground) -> some View {
        self.font(Font.body.weight(.semibold))
            .foregroundColor(.accentColor)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(Color(uiColor))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

struct ButtonStyle_Previews: PreviewProvider {
    static var previews: some View {
        EmptyView()
    }
}
