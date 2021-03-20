//
//  File.swift
//  
//
//  Created by Nickolay Truhin on 01.02.2021.
//

import Foundation

public enum BuildableType: String, Codable {
    case node
    
    var type: Buildable.Type {
        switch self {
        case .node:
            return NodeBuildable.self
        }
    }
}

enum BuildableTypeError: Error {
    case unknownClass
}

extension BuildableType: Equatable {
    public static func == (lhs: BuildableType, rhs: BuildableType) -> Bool {
        lhs.type == rhs.type
    }
}
