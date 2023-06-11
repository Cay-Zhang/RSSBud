//
//  Combine+Async.swift
//  RSSBud
//
//  Created by Cay Zhang on 2021/6/13.
//

import Combine

extension Publisher {
    func awaitable() async -> Output where Failure == Never {
        var iterator = self.values.makeAsyncIterator()
        return await iterator.next()!
    }
    
    func awaitable() async throws -> Output {
        var iterator = self.values.makeAsyncIterator()
        return try await iterator.next()!
    }
}

final class AsyncFuture<Output>: Publisher {
    
    typealias Failure = Never
    
    let priority: TaskPriority?
    let operation: @Sendable () async -> Output
    
    init(priority: TaskPriority? = nil, operation: @escaping @Sendable () async -> Output) {
        self.priority = priority
        self.operation = operation
    }
    
    func receive<S>(subscriber: S) where S: Subscriber, Failure == S.Failure, Output == S.Input {
        subscriber.receive(subscription: Subscription(subscriber: subscriber, priority: priority, operation: operation))
    }
    
    private class Subscription<Subscriber: Combine.Subscriber>: Combine.Subscription where Subscriber.Input == Output, Subscriber.Failure == Never {
        var taskHandle: Task<Void, Never>?
        
        init(subscriber: Subscriber, priority: TaskPriority? = nil, operation: @escaping @Sendable () async -> Output) {
            self.taskHandle = Task(priority: priority) {
                if Task.isCancelled { return }
                let result = await operation()
                _ = subscriber.receive(result)
                subscriber.receive(completion: .finished)
            }
        }
        
        func request(_ demand: Subscribers.Demand) { }
        
        func cancel() {
            taskHandle?.cancel()
            taskHandle = nil
        }
    }
}

final class AsyncThrowingFuture<Output>: Publisher {
    
    typealias Failure = Error
    
    let priority: TaskPriority?
    let operation: @Sendable () async throws -> Output
    
    init(priority: TaskPriority? = nil, operation: @escaping @Sendable () async throws -> Output) {
        self.priority = priority
        self.operation = operation
    }
    
    func receive<S>(subscriber: S) where S: Subscriber, Failure == S.Failure, Output == S.Input {
        subscriber.receive(subscription: Subscription(subscriber: subscriber, priority: priority, operation: operation))
    }
    
    private class Subscription<Subscriber: Combine.Subscriber>: Combine.Subscription where Subscriber.Input == Output, Subscriber.Failure == Error {
        var taskHandle: Task<Void, Never>?
        
        init(subscriber: Subscriber, priority: TaskPriority? = nil, operation: @escaping @Sendable () async throws -> Output) {
            self.taskHandle = Task(priority: priority) {
                do {
                    if Task.isCancelled { return }
                    let result = try await operation()
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
