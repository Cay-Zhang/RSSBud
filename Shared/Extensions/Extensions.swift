//
//  URL+Expansion.swift
//  RSSBud
//
//  Created by Cay Zhang on 2020/7/5.
//

import SwiftUI
import Combine
import CryptoKit
import LinkPresentation
import UniformTypeIdentifiers

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
        if let url = URLComponents(string: string) {
            self = url
        } else if let encodedString = string.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed.union([" "])),
                  let url = URLComponents(string: encodedString) {
            self = url
        } else {
            return nil
        }
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

extension URLComponents: ExpressibleByStringLiteral {
    public init(stringLiteral value: StaticString) {
        self.init(autoPercentEncoding: "\(value)")!
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

extension Button where Label == SwiftUI.Label<Text, Image> {
    init(_ titleKey: LocalizedStringKey, systemImage iconName: String, action: @escaping () -> Void) {
        self.init(action: action) { Label(titleKey, systemImage: iconName) }
    }
    
    @_disfavoredOverload
    init<S>(_ title: S, systemImage iconName: String, action: @escaping () -> Void) where S : StringProtocol {
        self.init(action: action) { Label(title, systemImage: iconName) }
    }
    
    init(_ titleKey: LocalizedStringKey, systemImage iconName: String, withAnimation animation: Animation?, action: @escaping () -> Void) {
        self.init {
            withAnimation(animation, action)
        } label: {
            Label(titleKey, systemImage: iconName)
        }
    }
    
    @_disfavoredOverload
    init<S>(_ title: S, systemImage iconName: String, withAnimation animation: Animation?, action: @escaping () -> Void) where S : StringProtocol {
        self.init {
            withAnimation(animation, action)
        } label: {
            Label(title, systemImage: iconName)
        }
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
    
    public func detect(types: NSTextCheckingResult.CheckingType) -> [NSTextCheckingResult] {
        let detector = try! NSDataDetector(types: types.rawValue)
        return detector.matches(in: self, range: NSRange(self.startIndex..., in: self))
    }
    
    public var isValidFilename: Bool {
        guard !isEmpty else { return false }
        
        let invalidCharacters = CharacterSet(charactersIn: ":/")
            .union(.newlines)
            .union(.illegalCharacters)
            .union(.controlCharacters)

        return rangeOfCharacter(from: invalidCharacters) == nil
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
    var wrappedValue: URLComponents
    
    init(wrappedValue: URLComponents) {
        self.wrappedValue = wrappedValue
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)
        if let url = URLComponents(autoPercentEncoding: string) {
            self.wrappedValue = url
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "\"\(string)\" is not a valid URL.")
        }
    }
    
    func encode(to encoder: Encoder) throws {
        try wrappedValue.string.encode(to: encoder)
    }
}

extension NSItemProvider {
    func loadObject<T: NSItemProviderReading>(ofClass aClass: T.Type) async throws -> T {
        return try await withCheckedThrowingContinuation { continuation in
            _ = self.loadObject(ofClass: T.self) { (object: NSItemProviderReading?, error: Error?) in
                if let object = object as? T {
                    continuation.resume(returning: object)
                } else if let error = error {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func loadObject<T: _ObjectiveCBridgeable>(ofClass: T.Type) async throws -> T where T._ObjectiveCType: NSItemProviderReading {
        return try await withCheckedThrowingContinuation { continuation in
            _ = self.loadObject(ofClass: T.self) { (object: T?, error: Error?) in
                if let object = object {
                    continuation.resume(returning: object)
                } else if let error = error {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func loadDataRepresentation(forTypeIdentifier typeIdentifier: String) async throws -> Data {
        return try await withCheckedThrowingContinuation { continuation in
            _ = self.loadDataRepresentation(forTypeIdentifier: typeIdentifier) { data, error in
                if let data = data {
                    continuation.resume(returning: data)
                } else if let error = error {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}

extension UIImage {
    func scaled(by ratio: CGFloat) -> UIImage {
        let newSize = CGSize(width: self.size.width * ratio, height: self.size.height * ratio)
        let renderFormat = UIGraphicsImageRendererFormat.default()
        renderFormat.opaque = false
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: newSize.width, height: newSize.height), format: renderFormat)
        return renderer.image { context in
            self.draw(in: CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height))
        }
    }
    
    func scaledDownIfNeeded(toFit size: CGSize) -> UIImage {
        let horizontalRatio = min(size.width / self.size.width, 1.0)
        let verticalRatio = min(size.height / self.size.height, 1.0)
        let ratio = min(horizontalRatio, verticalRatio)
        return self.scaled(by: ratio)
    }
}

extension LPLinkMetadata {
    var image: UIImage? {
        get async {
            if let provider = self.imageProvider {
                return try? await provider.loadObject(ofClass: UIImage.self)
            } else {
                return nil
            }
        }
    }
    
    var icon: UIImage? {
        get async {
            if let provider = self.iconProvider {
                var data = try? await provider.loadDataRepresentation(forTypeIdentifier: UTType.image.identifier)
                if data == nil { data = try? await provider.loadDataRepresentation(forTypeIdentifier: "dyn.agq80w5pbq7ww88brrfv085u") }
                let scale = await UIScreen.main.scale
                return data
                    .flatMap { UIImage(data: $0, scale: scale) }
            } else {
                return nil
            }
        }
    }
}

struct BarProgressViewStyle: ProgressViewStyle {
    func makeBody(configuration: Configuration) -> some View {
        let progress = configuration.fractionCompleted ?? 0.5
        return Rectangle()
            .fill(.tint)
            .scaleEffect(x: progress, y: 1, anchor: .leading)
    }
}

public struct Version: Comparable, CustomStringConvertible {
    public var major: Int
    public var minor: Int
    public var patch: Int
    
    public init(major: Int, minor: Int, patch: Int) {
        precondition(major >= 0 && minor >= 0 && patch >= 0)
        self.major = major
        self.minor = minor
        self.patch = patch
    }
    
    public init<S: StringProtocol>(string: S) {
        var numbers = string.split(separator: ".").prefix(3).compactMap { Int($0) }
        if numbers.count < 3 { numbers += [Int](repeating: 0, count: 3 - numbers.count) }
        self.init(major: numbers[0], minor: numbers[1], patch: numbers[2])
    }
    
    public var tuple: (Int, Int, Int) { (major, minor, patch) }
    
    public static func < (lhs: Version, rhs: Version) -> Bool {
        lhs.tuple < rhs.tuple
    }
    
    public var description: String {
        "\(major).\(minor)" + (patch != 0 ? ".\(patch)" : "")
    }
    
    static let marketing: Version = Version(string: Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String)
    
    static let build: Version = Version(string: Bundle.main.infoDictionary!["CFBundleVersion"] as! String)
}

extension Version: Codable {
    public init(from decoder: Decoder) throws {
        self.init(string: try decoder.singleValueContainer().decode(String.self))
    }
    
    public func encode(to encoder: Encoder) throws {
        try description.encode(to: encoder)
    }
}

@propertyWrapper
public struct CodableAdaptor<Value: Codable>: RawRepresentable {
    public var wrappedValue: Value
    
    public init(wrappedValue: Value) {
        self.wrappedValue = wrappedValue
    }
    
    public init?(rawValue: String) {
        if let value = rawValue.data(using: .utf8).flatMap({ try? JSONDecoder().decode(Value.self, from: $0) }) {
            wrappedValue = value
        } else {
            return nil
        }
    }
    
    public var rawValue: String {
        (try? JSONEncoder().encode(wrappedValue)).flatMap { String(data: $0, encoding: .utf8) } ?? ""
    }
}

extension Sequence where Element: Hashable {
    public func isUnique() -> Bool {
        var set = Set<Element>()
        for element in self {
            let (inserted, _) = set.insert(element)
            if !inserted {
                return false
            }
        }
        return true
    }
}
