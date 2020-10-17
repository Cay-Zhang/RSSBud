//
//  URL+Expansion.swift
//  RSSBud
//
//  Created by Cay Zhang on 2020/7/5.
//

import SwiftUI
import Combine

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
