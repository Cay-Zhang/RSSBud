//
//  Combine+Async.swift
//  RSSBud
//
//  Created by Cay Zhang on 2021/6/13.
//

import Combine

extension Publisher {
    func awaitable() async -> Output where Failure == Never {
        var cancellable: AnyCancellable?
        _ = cancellable
        return await withCheckedContinuation { continuation in
            cancellable = self.sink { output in
                continuation.resume(returning: output)
                cancellable = nil
            }
        }
    }
    
    func awaitable() async throws -> Output {
        var cancellable: AnyCancellable?
        _ = cancellable
        return try await withCheckedThrowingContinuation { continuation in
            cancellable = self.sink { completion in
                if case let .failure(error) = completion {
                    continuation.resume(throwing: error)
                }
            } receiveValue: { output in
                continuation.resume(returning: output)
                cancellable = nil
            }
        }
    }
}
