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
    
    required init() {}

    init(_ instance: String) {
        self.instance = instance
    }
}
