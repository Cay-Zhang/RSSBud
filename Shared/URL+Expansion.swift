//
//  URL+Expansion.swift
//  RSSBud
//
//  Created by Cay Zhang on 2020/7/5.
//

import Foundation
import Combine

extension URL {
    func resolveWithCompletionHandler(completion: @escaping (URL) -> Void) {
        let originalURL = self
        var req = URLRequest(url: originalURL)
        req.httpMethod = "HEAD"
        
        URLSession.shared.dataTask(with: req) { body, response, error in
            completion(response?.url ?? originalURL)
        }.resume()
    }
    
    func expanding() -> Publishers.ReplaceError<Publishers.Map<URLSession.DataTaskPublisher, URL>> {
        let originalURL = self
        var req = URLRequest(url: originalURL)
        req.httpMethod = "HEAD"
        
        return URLSession.shared.dataTaskPublisher(for: req)
            .map { $0.response.url ?? originalURL }
            .replaceError(with: originalURL)
    }
}

extension URLComponents {
    static func + (url: URLComponents, queryItems: [URLQueryItem]) -> URLComponents {
        var result = url
        result.queryItems = result.queryItems ?? []
        result.queryItems!.append(contentsOf: queryItems)
        return result
    }
}
