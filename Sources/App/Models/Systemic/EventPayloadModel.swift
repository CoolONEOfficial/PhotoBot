//
//  File.swift
//  
//
//  Created by Nickolay Truhin on 06.03.2021.
//

import Foundation
import Fluent
import Vapor
import Botter
import ValidatedPropertyKit

final class EventPayloadModel: Model {

    static var schema: String  = "event_payloads"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "instance")
    var instance: String
    
    @Parent(key: "owner_id")
    var owner: UserModel

    required init() {}

    init<T: UserProtocol>(instance: String, owner: T) {
        self.instance = instance
        self.$owner.id = owner.id!
    }
}
