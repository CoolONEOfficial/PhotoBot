//
//  File.swift
//  
//
//  Created by Nickolay Truhin on 15.02.2021.
//

import Botter

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
}
