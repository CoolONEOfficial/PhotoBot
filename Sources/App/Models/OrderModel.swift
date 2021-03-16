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
    
    @Parent(key: "user_id")
    var user: UserModel

    var userId: UUID! {
        get { self.$user.id }
        set { self.$user.id = newValue }
    }
    
    @Field(key: "type")
    var type: OrderType!
    
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
    
    @Field(key: "start_date")
    var startDate: Date
    
    @Field(key: "end_date")
    var endDate: Date
    
    var interval: DateInterval {
        get {
            .init(start: startDate, end: endDate)
        }
        set {
            startDate = newValue.start
            endDate = newValue.end
        }
    }
    
    @Field(key: "price")
    var price: Int
    
    required init() { }
    
}

extension OrderModel {
    func fetchWatchers(app: Application) -> Future<[PlatformIdentifiable]> {
        [
            $makeuper.get(on: app.db).optionalMap { $0 as PlatformIdentifiable },
            $stylist.get(on: app.db).optionalMap { $0 as PlatformIdentifiable }
        ].flatten(on: app.eventLoopGroup.next()).map { $0.compactMap { $0 } }
    }
}
