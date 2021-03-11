//
//  File.swift
//  
//
//  Created by Nickolay Truhin on 14.02.2021.
//

import Foundation
import ValidatedPropertyKit
import Botter
import Vapor
import Fluent
import AnyCodable

final class Stylist: StylistProtocol {

    typealias TwinType = StylistModel
    
    var id: UUID?

    @Validated(.greater(1))
    var name: String?
    
    var platformIds: [TypedPlatform<UserPlatformId>] = []

    var photos: [PlatformFileModel] = []
    
    var price: Int = 0

    required init() {}

    // TODO: contact info (vk or tg id/username)

}

extension Stylist: ModeledType {
    var isValid: Bool {
        _name.isValid// && _photos.isValid
    }

    func save(app: Application) throws -> EventLoopFuture<TwinType> {
        guard isValid else {
            throw ModeledTypeError.validationError(self)
        }
        return try TwinType.create(other: self, app: app)
    }
}

