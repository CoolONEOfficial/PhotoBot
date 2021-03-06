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

final class OrderModel: Model, OrderProtocol {
    typealias TwinType = Order
    
    static let schema = "orders"
    
    @ID(key: .id)
    var id: UUID?
    
    @OptionalParent(key: "stylist_id")
    var stylist: StylistModel?
    
    var stylistId: UUID? {
        get { self.$stylist.id }
        set { self.$stylist.id = newValue }
    }
    
    @OptionalParent(key: "makeuper_id")
    var makeuper: MakeuperModel?
    
    var makeuperId: UUID? {
        get { self.$makeuper.id }
        set { self.$makeuper.id = newValue }
    }
    
    @OptionalParent(key: "studio_id")
    var studio: StudioModel?
    
    var studioId: UUID? {
        get { self.$studio.id }
        set { self.$studio.id = newValue }
    }
    
    @Field(key: "price")
    var price: Int
    
    required init() { }
    
}

