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

final class AsyncFuture<Output>: Publisher {
    
    typealias Failure = Error
    
    let priority: Task.Priority?
    let task: @Sendable () async throws -> Output
    
    init(priority: Task.Priority? = nil, task: @escaping @Sendable () async throws -> Output) {
        self.priority = priority
        self.task = task
    }
    
    func receive<S>(subscriber: S) where S: Subscriber, Failure == S.Failure, Output == S.Input {
        subscriber.receive(subscription: Subscription(subscriber: subscriber, priority: priority, task: task))
    }
    
    private class Subscription<Subscriber: Combine.Subscriber>: Combine.Subscription where Subscriber.Input == Output, Subscriber.Failure == Error {
        var taskHandle: Task.Handle<Void, Never>?
        
        init(subscriber: Subscriber, priority: Task.Priority? = nil, task: @escaping @Sendable () async throws -> Output) {
            self.taskHandle = async(priority: priority) {
                do {
                    if Task.isCancelled { return }
                    let result = try await task()
                    _ = subscriber.receive(result)
                    subscriber.receive(completion: .finished)
                } catch {
                    subscriber.receive(completion: .failure(error))
                }
            }
        }
        
        func request(_ demand: Subscribers.Demand) { }
        
        func cancel() {
            taskHandle?.cancel()
            taskHandle = nil
        }
    }
}
