//
//  ButtonStyling.swift
//  RSSBud
//
//  Created by Cay Zhang on 2020/8/10.
//

import SwiftUI

struct CayButtonStyle<ContainerModifier: ViewModifier>: PrimitiveButtonStyle {
    var containerModifier: ContainerModifier
    var labelOpacityWhenPressed: Double = 0.5
    
    @State private var isPressed: Bool = false
    
    init(containerModifier: ContainerModifier) {
        self.containerModifier = containerModifier
    }
    
    init(wideContainerWithBackgroundColor backgroundColor: Color) where ContainerModifier == WideButtonContainerModifier {
        self.init(containerModifier: WideButtonContainerModifier(backgroundColor: backgroundColor))
    }
    
    init(blockContainerWithBackgroundColor backgroundColor: Color) where ContainerModifier == BlockButtonContainerModifier {
        self.init(containerModifier: BlockButtonContainerModifier(backgroundColor: backgroundColor))
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .compositingGroup()
            .opacity(isPressed ? labelOpacityWhenPressed : 1)
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
    
    func labelOpacityWhenPressed(_ newValue: Double) -> Self {
        var copy = self
        copy.labelOpacityWhenPressed = newValue
        return copy
    }
}

struct CayMenuStyle: MenuStyle {
    var labelOpacityWhenPressed: Double = 0.5
    
    @State private var isPressed: Bool = false
    
    var buttonGesture: some Gesture {
        _ButtonGesture { } pressing: { newValue in
            withAnimation(.easeOut(duration: newValue ? 0.1 : 0.4)) {
                isPressed = newValue
            }
            if newValue {
                UIImpactFeedbackGenerator.light.impactOccurred(intensity: 0.5)
            }
        }
    }
    
    func makeBody(configuration: Configuration) -> some View {
        Menu(configuration)
            .simultaneousGesture(buttonGesture)
            .scaleEffect(isPressed ? 0.97 : 1)
    }
    
    func labelOpacityWhenPressed(_ newValue: Double) -> Self {
        var copy = self
        copy.labelOpacityWhenPressed = newValue
        return copy
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

struct BlockLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            configuration.icon
                .font(Font.system(size: 24.0, weight: .medium, design: .default))
            
            Spacer()
            
            configuration.title
                .font(Font.system(size: 17.0, weight: .medium, design: .default))
                .minimumScaleFactor(0.7)
        }
    }
}

struct BlockButtonContainerModifier: ViewModifier {
    var backgroundColor: Color
    @ScaledMetric(relativeTo: Font.TextStyle.body) var height: CGFloat = 120
    
    func body(content: Content) -> some View {
        content
            .labelStyle(BlockLabelStyle())
            .foregroundColor(.accentColor)
            .padding(.leading, 12)
            .padding(.trailing, 16)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, idealHeight: height, alignment: .leading)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

struct ButtonStyle_Previews: PreviewProvider {
    static var previews: some View {
        Button("Test") { }
            .padding(20)
            .buttonStyle(CayButtonStyle(wideContainerWithBackgroundColor: Color(uiColor: .secondarySystemBackground)))
    }
}
