//
//  File.swift
//  
//
//  Created by Nickolay Truhin on 10.01.2021.
//

import Foundation
import Fluent

protocol TypedModel: Model {
    associatedtype _ModelType: ModelType
    
    func toMyType() throws -> _ModelType
}

extension TypedModel where _ModelType._TypedModel == Self {
    func toMyType() throws -> _ModelType { try .init(from: self) }
}

extension NodeModel: TypedModel { typealias _ModelType = Node }

extension UserModel: TypedModel { typealias _ModelType = User }
