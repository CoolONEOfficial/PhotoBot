//
//  File.swift
//  
//
//  Created by Nickolay Truhin on 15.02.2021.
//

import Botter
import Vapor

extension Future where Value: Sequence {
    public func throwingFlatMapEach<Result>(
        on eventLoop: EventLoop,
        _ transform: @escaping (_ element: Value.Element) throws -> EventLoopFuture<Result>
    ) -> EventLoopFuture<[Result]> {
        self.throwingFlatMap { .reduce(into: [], try $0.map(transform), on: eventLoop) { $0.append($1) } }
    }
}

extension Future {
    public func throwingFlatMap<NewValue>(_ transform: @escaping (Value) throws -> Future<NewValue>) -> Future<NewValue> {
        flatMap { value in
            do {
                return try transform(value)
            } catch {
                return self.eventLoop.makeFailedFuture(error)
            }
        }
    }
    
    public func optionalThrowingFlatMap<Wrapped, Result>(
        _ closure: @escaping (_ unwrapped: Wrapped) throws -> Future<Result>
    ) -> Future<Result?> where Value == Optional<Wrapped> {
        return self.flatMap { optional in
            do {
                guard let future = try optional.map(closure) else {
                    return self.eventLoop.makeSucceededFuture(nil)
                }
                
                return future.map(Optional.init)
            } catch {
                return self.eventLoop.makeFailedFuture(error)
            }
        }
    }

    public func optionalThrowingFlatMap<Wrapped, Result>(
        _ closure: @escaping (_ unwrapped: Wrapped) throws -> Future<Result?>
    ) -> Future<Result?> where Value == Optional<Wrapped> {
        return self.flatMap { optional in
            do {
                return try optional.flatMap(closure)?.map { $0 } ?? self.eventLoop.makeSucceededFuture(nil)
            } catch {
                return self.eventLoop.makeFailedFuture(error)
            }
        }
    }
}
