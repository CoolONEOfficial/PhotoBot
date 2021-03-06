//
//  File.swift
//  
//
//  Created by Nickolay Truhin on 22.02.2021.
//

import Foundation
import ValidatedPropertyKit
import Botter
import Vapor
import Fluent
import AnyCodable

final class Makeuper: MakeuperProtocol {
 
    typealias TwinType = MakeuperModel

    var id: UUID?

    @Validated(.isLetters && .greater(1) && .less(25))
    var name: String?

    var photos: [PlatformFileModel] = []
    
    var price: Int = 0

    required init() {}

}

extension Makeuper: PhotoModeledType {
    typealias PhotoModel = MakeuperPhoto
}

extension Makeuper: ModeledType {
    var isValid: Bool {
        _name.isValid //&& _photos.isValid
    }

    func save(app: Application) throws -> EventLoopFuture<TwinType> {
        guard isValid else {
            throw ModeledTypeError.validationError(self)
        }
        return TwinType.create(other: self, app: app)
    }
}
