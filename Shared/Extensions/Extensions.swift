//
//  URL+Expansion.swift
//  RSSBud
//
//  Created by Cay Zhang on 2020/7/5.
//

import SwiftUI
import Combine
import CryptoKit

extension URLComponents {
    func expanding() -> Publishers.ReplaceError<Publishers.Map<URLSession.DataTaskPublisher, URLComponents>> {
        let originalURL = self.url!
        var req = URLRequest(url: originalURL)
        req.httpMethod = "HEAD"
        
        return URLSession.shared.dataTaskPublisher(for: req)
            .map { $0.response.url.flatMap { URLComponents(url: $0, resolvingAgainstBaseURL: false) } ?? self }
            .replaceError(with: self)
    }
}

extension URLComponents {
    
    init?(autoPercentEncoding string: String) {
        guard let encodedString = string.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed.union([" "])) else { return nil }
        self.init(string: encodedString)
    }
    
    func replacing(path: String) -> URLComponents {
        var copy = self
        copy.path = path
        return copy
    }
    
    func appending(path: String) -> URLComponents {
        var copy = self
        if let lastCharacter = copy.path.last, lastCharacter == "/" {
            copy.path.removeLast()
        }
        copy.path += path
        return copy
    }
    
    func prepending(_ prefix: String) -> URLComponents? {
        return self.string.flatMap { URLComponents(string: prefix + $0) }
    }
    
    func replacing(scheme: String) -> URLComponents {
        var copy = self
        copy.scheme = scheme
        return copy
    }
    
    func appending(queryItems: [URLQueryItem]) -> URLComponents {
        var copy = self
        copy.queryItems = self.queryItems ?? []
        copy.queryItems!.append(contentsOf: queryItems)
        return copy
    }
    
    mutating func omitEmptyQueryItems() {
        queryItems = (queryItems?.filter { !($0.value?.isEmpty ?? true) })
            .flatMap { $0.isEmpty ? nil : $0 }
    }
    
    func omittingEmptyQueryItems() -> URLComponents {
        var copy = self
        copy.omitEmptyQueryItems()
        return copy
    }
}

extension Array where Element == URLQueryItem {
    subscript(name: String) -> String? {
        get {
            self.first(where: { $0.name == name })?.value
        }
    }
}

extension URL {
    var components: URLComponents? {
        URLComponents(url: self, resolvingAgainstBaseURL: false)
    }
}

extension View {
    func foreground<Overlay: View>(_ overlay: Overlay) -> some View {
        self.opacity(0.0)
            .overlay(overlay)
            .mask(self)
    }
    
    func alert(_ _alert: Binding<Alert?>) -> some View {
        
        let _isPresented: Binding<Bool> = Binding(get: {
            _alert.wrappedValue != nil
        }, set: { newValue in
            if !newValue {
                _alert.wrappedValue = nil
            }
        })
        
        return self.alert(isPresented: _isPresented) {
            _alert.wrappedValue!
        }
    }
}

struct NamespaceEnvironmentKey: EnvironmentKey {
    static var defaultValue: Namespace.ID = Namespace().wrappedValue
}

extension EnvironmentValues {
    var namespace: Namespace.ID {
        get {
            self[NamespaceEnvironmentKey.self]
        }
        set {
            self[NamespaceEnvironmentKey.self] = newValue
        }
    }
}

extension Button {
    init(_ titleKey: LocalizedStringKey, systemImage iconName: String, action: @escaping () -> Void) where Label == SwiftUI.Label<Text, Image> {
        self.init(action: action, label: { Label(titleKey, systemImage: iconName) })
    }
}

extension DispatchSource.FileSystemEvent: CustomStringConvertible {
    public var description: String {
        var cases = [String]()
        if contains(.all)     { cases.append("all") }
        if contains(.attrib)  { cases.append("attrib") }
        if contains(.delete)  { cases.append("delete") }
        if contains(.extend)  { cases.append("extend") }
        if contains(.funlock) { cases.append("funlock") }
        if contains(.link)    { cases.append("link") }
        if contains(.rename)  { cases.append("rename") }
        if contains(.revoke)  { cases.append("revoke") }
        if contains(.write)   { cases.append("write") }
        return cases.joined(separator: ", ")
    }
}

extension String {
    public func md5() -> String {
        let digest = Insecure.MD5.hash(data: self.data(using: .utf8) ?? Data())
        return digest.lazy.map { String(format: "%02hhx", $0) }.joined()
    }
}

struct XCallbackContext: Equatable, ExpressibleByNilLiteral {
    var source: String?
    var success: URLComponents?
    var error: URLComponents?
    var cancel: URLComponents?
    
    init(queryItems: [URLQueryItem]) {
        source = queryItems["x-source"]
        success = queryItems["x-success"].flatMap(URLComponents.init(string:))
        error = queryItems["x-error"].flatMap(URLComponents.init(string:))
        cancel = queryItems["x-cancel"].flatMap(URLComponents.init(string:))
    }
    
    init(nilLiteral: ()) {
        source = nil
        success = nil
        error = nil
        cancel = nil
    }
}

struct XCallbackContextEnvironmentKey: EnvironmentKey {
    static var defaultValue: Binding<XCallbackContext> = .constant(nil)
}

extension EnvironmentValues {
    var xCallbackContext: Binding<XCallbackContext> {
        get {
            self[XCallbackContextEnvironmentKey.self]
        }
        set {
            self[XCallbackContextEnvironmentKey.self] = newValue
        }
    }
}

struct AnimatableFontModifier: AnimatableModifier {
    var size: CGFloat
    var weight: Font.Weight = .regular
    var design: Font.Design = .default
    
    var animatableData: CGFloat {
        get { size }
        set { size = newValue }
    }
    
    func body(content: Content) -> some View {
        content
            .font(.system(size: size, weight: weight, design: design))
    }
}

extension View {
    func animatableFont(size: CGFloat, weight: Font.Weight = .regular, design: Font.Design = .default) -> some View {
        self.modifier(AnimatableFontModifier(size: size, weight: weight, design: design))
    }
}

@propertyWrapper
struct URLString: Codable {
    var string: String
    var wrappedValue: URLComponents
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.string = try container.decode(String.self)
        if let url = URLComponents(string: self.string) {
            self.wrappedValue = url
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "shit")
        }
    }
    
    func encode(to encoder: Encoder) throws {
        try string.encode(to: encoder)
    }
}
