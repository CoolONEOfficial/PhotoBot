//
//  File.swift
//  
//
//  Created by Nickolay Truhin on 10.01.2021.
//

import Foundation
import Fluent

protocol TypedModel: Model {
    associatedtype MyType: ModeledType
    
    func toMyType() throws -> MyType
}

extension TypedModel where MyType.Model == Self {
    func toMyType() throws -> MyType { try .init(from: self) }
}
