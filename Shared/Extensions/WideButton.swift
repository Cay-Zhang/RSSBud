//
//  WideButton.swift
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

struct CayButtonStyle<ContainerModifier: ViewModifier>: PrimitiveButtonStyle {
    var containerModifier: ContainerModifier
    
    @State private var isPressed: Bool = false
    
    init(containerModifier: ContainerModifier) {
        self.containerModifier = containerModifier
    }
    
    init(wideContainerWithBackgroundColor backgroundColor: Color) where ContainerModifier == WideButtonContainerModifier {
        self.init(containerModifier: WideButtonContainerModifier(backgroundColor: backgroundColor))
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .compositingGroup()
            .opacity(isPressed ? 0.5 : 1)
            .modifier(containerModifier)
            ._onButtonGesture { newValue in
                withAnimation(.easeOut(duration: newValue ? 0.1 : 0.4)) {
                    isPressed = newValue
                }
                if newValue {
                    UIImpactFeedbackGenerator.light.impactOccurred(intensity: 0.5)
                }
            } perform: {
                configuration.trigger()
            }.scaleEffect(isPressed ? 0.97 : 1)
    }
}

extension UIImpactFeedbackGenerator {
    static let light: UIImpactFeedbackGenerator = UIImpactFeedbackGenerator(style: .light)
}

struct WideButtonContainerModifier: ViewModifier {
    var backgroundColor: Color
    
    func body(content: Content) -> some View {
        content
            .font(Font.body.weight(.semibold))
            .foregroundColor(.accentColor)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

struct ButtonStyle_Previews: PreviewProvider {
    static var previews: some View {
        EmptyView()
    }
}
