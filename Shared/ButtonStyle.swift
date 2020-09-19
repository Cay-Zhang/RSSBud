//
//  ButtonStyle.swift
//  RSSBud
//
//  Created by Cay Zhang on 2020/8/10.
//

import SwiftUI

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
