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
    private func mapFunc(_ wrapped: Value) -> Any {
        switch wrapped.value {
        case let wrapped as Self:
            return wrapped.unwrapped

        default:
            switch wrapped.value {
            case let arr as [AnyCodable]:
                return arr.map(mapFunc)

            default:
                return wrapped.value
            }
        }
    }
    
    var unwrapped: [Key: Any] {
        mapValues(mapFunc)
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
