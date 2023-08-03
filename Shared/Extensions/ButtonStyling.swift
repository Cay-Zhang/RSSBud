//
//  ButtonStyling.swift
//  RSSBud
//
//  Created by Cay Zhang on 2020/8/10.
//

import SwiftUI

struct CayButtonStyle<ContainerModifier: ViewModifier, BackgroundStyle: ShapeStyle>: PrimitiveButtonStyle {
    var containerModifier: ContainerModifier
    var backgroundStyle: BackgroundStyle
    var labelOpacityWhenPressed: Double = 0.5
    
    @State private var isPressed: Bool = false
    
    init(containerModifier: ContainerModifier, backgroundStyle: BackgroundStyle = Color.clear) {
        self.containerModifier = containerModifier
        self.backgroundStyle = backgroundStyle
    }
    
    init(wideContainerWithFill keyPath: KeyPath<FillShapeStyle, BackgroundStyle>) where ContainerModifier == WideButtonContainerModifier {
        self.init(containerModifier: WideButtonContainerModifier(), backgroundStyle: FillShapeStyle()[keyPath: keyPath])
    }
    
    init(blockContainerWithFill keyPath: KeyPath<FillShapeStyle, BackgroundStyle>) where ContainerModifier == BlockButtonContainerModifier {
        self.init(containerModifier: BlockButtonContainerModifier(), backgroundStyle: FillShapeStyle()[keyPath: keyPath])
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .compositingGroup()
            .opacity(isPressed ? labelOpacityWhenPressed : 1)
            .modifier(containerModifier)
            .backgroundStyle(backgroundStyle)
            ._onButtonGesture { newValue in
                withAnimation(.easeOut(duration: newValue ? 0.1 : 0.4)) {
                    isPressed = newValue
                }
                if newValue {
                    playButtonSensoryFeedback()
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
                playButtonSensoryFeedback()
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

//extension UIImpactFeedbackGenerator {
//    static let light: UIImpactFeedbackGenerator = UIImpactFeedbackGenerator(style: .light)
//}

fileprivate func playButtonSensoryFeedback() {
//    UIImpactFeedbackGenerator.light.impactOccurred(intensity: 0.5)
}

struct WideButtonContainerModifier: ViewModifier {
    @ScaledMetric var height: CGFloat = 42
    
    func body(content: Content) -> some View {
        content
            .font(Font.body.weight(.semibold))
#if os(xrOS)
            .foregroundStyle(.secondary)
#else
            .foregroundStyle(.tint)
#endif
            .frame(maxWidth: .infinity, minHeight: height, idealHeight: height, maxHeight: height)
            .background(.background)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .hoverEffect()
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
    @ScaledMetric(relativeTo: Font.TextStyle.body) var height: CGFloat = 120
    
    func body(content: Content) -> some View {
        content
            .labelStyle(BlockLabelStyle())
#if os(xrOS)
            .foregroundStyle(.secondary)
#else
            .foregroundStyle(.tint)
#endif
            .padding(.leading, 12)
            .padding(.trailing, 16)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, idealHeight: height, alignment: .leading)
            .background(.background)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .hoverEffect()
    }
}

struct ButtonStyle_Previews: PreviewProvider {
    static var previews: some View {
        Button("Test") { }
            .padding(20)
            .buttonStyle(CayButtonStyle(wideContainerWithFill: \.quaternary))
    }
}
