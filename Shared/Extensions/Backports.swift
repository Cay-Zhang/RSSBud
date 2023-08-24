//
//  Backports.swift
//  RSSBud
//
//  Created by Cay Zhang on 2023/8/19.
//

import SwiftUI

#if os(iOS)
/// This shape style is appropriate for items situated on top of an existing background color.
/// It incorporates transparency to allow the background color to show through.
///
/// Use the primary version of this style to fill thin or small shapes, such as the track of a slider on iOS.
/// Use the secondary version of this style to fill medium-size shapes, such as the background of a switch on iOS.
/// Use the tertiary version of this style to fill large shapes, such as input fields, search bars, or buttons on iOS.
/// Use the quaternary version of this style to fill large areas that contain complex content, such as an expanded table cell on iOS.
struct FillShapeStyle: ShapeStyle {
    public typealias Resolved = Color
    
    public func resolve(in environment: EnvironmentValues) -> Resolved {
        resolve()
    }
    
    /// - Parameter level: secondary = 1, tertiary = 2, quaternary = 3, quinary = 4
    func resolve(at level: Int = 0) -> Resolved {
        let uiColor: UIColor = switch level {
        case 0: .systemFill
        case 1: .secondarySystemFill
        case 2: .tertiarySystemBackground
        case 3: .secondarySystemBackground
        case 4: .systemBackground
        default: .red
        }
        return Color(uiColor: uiColor)
    }
    
    public func _apply(to shape: inout _ShapeStyle_Shape) {
        resolve()._apply(to: &shape)
    }
    
    public static func _apply(to type: inout _ShapeStyle_ShapeType) {
        Resolved._apply(to: &type)
    }
}

extension ShapeStyle where Self == FillShapeStyle {
    static var fill: FillShapeStyle {
        get { .init() }
    }
}

struct HierarchicalShapeStyleModifier<Base>: ShapeStyle where Base: ShapeStyle {
    var base: Base
    
    /// secondary = 1, tertiary = 2, quaternary = 3, quinary = 4
    var level: Int
    
    init(base: Base, level: Int) {
        (self.base, self.level) = (base, level)
    }
    
    /// Making Resolved = Never would cause the app to crash on macOS 13.4 (built with Xcode 15 beta 7).
    typealias Resolved = Base
    
    func resolve(in environment: EnvironmentValues) -> Resolved { base }
    
    func _apply(to shape: inout _ShapeStyle_Shape) {
        if let fill = base as? FillShapeStyle {
            fill.resolve(at: level)._apply(to: &shape)
        } else {
            base._apply(to: &shape)
        }
    }
    
    static func _apply(to type: inout _ShapeStyle_ShapeType) {
        if let fill = Base.self as? FillShapeStyle.Type {
            fill.Resolved._apply(to: &type)
        } else {
            Base._apply(to: &type)
        }
    }
}

extension ShapeStyle {
    var secondary: some ShapeStyle {
        get {
            HierarchicalShapeStyleModifier(base: self, level: 1)
        }
    }
    
    var tertiary: some ShapeStyle {
        get {
            HierarchicalShapeStyleModifier(base: self, level: 2)
        }
    }
    
    var quaternary: some ShapeStyle {
        get {
            HierarchicalShapeStyleModifier(base: self, level: 3)
        }
    }
    
    var quinary: some ShapeStyle {
        get {
            HierarchicalShapeStyleModifier(base: self, level: 4)
        }
    }
}

extension EnvironmentValues {
    var backgroundStyle: AnyShapeStyle? {
        get { self[BackgroundStyleKey.self] }
        set { self[BackgroundStyleKey.self] = newValue }
    }
}

struct BackgroundStyleKey: EnvironmentKey {
    static let defaultValue: AnyShapeStyle? = nil
}

extension View {
    func backgroundStyle<S>(_ style: S) -> some View where S: ShapeStyle {
        self.environment(\.backgroundStyle, AnyShapeStyle(style))
    }
}
#endif
