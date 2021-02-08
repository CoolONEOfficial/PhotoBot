//
//  File.swift
//  
//
//  Created by Nickolay Truhin on 05.02.2021.
//

import Foundation
import AnyCodable

extension Decodable {
    init(from dict: [String: Any]) throws {
        self = try JSONDecoder.snakeCased.decode(Self.self, from: try JSONSerialization.data(withJSONObject: dict, options: []))
    }
    
    init(from dict: [String: AnyCodable]) throws {
        try self.init(from: dict.unwrapped)
    }
}

extension Dictionary where Value == AnyCodable {
    var unwrapped: [Key: Any] {
        mapValues { wrapped in
            if let wrapped = wrapped.value as? Self {
                return wrapped.unwrapped
            } else {
                return wrapped.value
            }
        }
    }
}

extension Dictionary {
    var wrapped: [Key: AnyCodable] {
        mapValues { value -> AnyCodable in
            if let wrapped = value as? AnyCodable {
                if let childDict = wrapped.value as? [Key: Any] {
                    return .init(childDict.wrapped)
                }
                
                return wrapped
            }
            return .init(value)
        }
    }
}
