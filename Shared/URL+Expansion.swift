//
//  URL+Expansion.swift
//  RSSBud
//
//  Created by Cay Zhang on 2020/7/5.
//

import Foundation
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
    static func + (url: URLComponents, queryItems: [URLQueryItem]) -> URLComponents {
        var result = url
        result.queryItems = result.queryItems ?? []
        result.queryItems!.append(contentsOf: queryItems)
        return result
    }
    
    init?(autoPercentEncoding string: String) {
        guard let encodedString = string.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed.union([" "])) else { return nil }
        self.init(string: encodedString)
    }
}

extension URL {
    var components: URLComponents? {
        URLComponents(url: self, resolvingAgainstBaseURL: false)
    }
}
