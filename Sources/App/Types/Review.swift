//
//  File.swift
//  
//
//  Created by Nickolay Truhin on 03.04.2021.
//

import Foundation
import ValidatedPropertyKit
import Botter
import Vapor
import Fluent

final class Review: ReviewProtocol {

    typealias TwinType = ReviewModel
    
    var id: UUID?
    
    var screenshot: PlatformFileModel!
    
    required init() {}
    
}

extension Review: ModeledType {
    var isValid: Bool {
        true
    }
    
    func save(app: Application) throws -> EventLoopFuture<TwinType> {
        guard isValid else {
            throw ModeledTypeError.validationError(self)
        }
        return TwinType.create(other: self, app: app)
    }
}
