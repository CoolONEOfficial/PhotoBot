//
//  File.swift
//  
//
//  Created by Nickolay Truhin on 10.01.2021.
//

import Foundation
import Fluent
import Botter

protocol ModelType {
    associatedtype _TypedModel: TypedModel
    
    init(from model: _TypedModel) throws
}

extension ModelType where _TypedModel._ModelType == Self {
    static func find(
        _ id: Self._TypedModel.IDValue,
        on database: Database
    ) -> Future<Self> {
        _TypedModel.find(id, on: database).flatMapThrowing { try $0!.toMyType() }
    }
}

extension Node: ModelType { typealias _TypedModel = NodeModel }

extension User: ModelType { typealias _TypedModel = UserModel }
