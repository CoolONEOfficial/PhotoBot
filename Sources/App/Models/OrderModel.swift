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
    
    @Field(key: "status")
    var status: OrderStatus
    
    @OptionalParent(key: "stylist_id")
    var stylist: StylistModel?
    
    var stylistId: UUID? {
        get { self.$stylist.id }
        set { self.$stylist.id = newValue }
    }
    
    @OptionalParent(key: "photographer_id")
    var photographer: PhotographerModel?
    
    var photographerId: UUID? {
        get { self.$photographer.id }
        set { self.$photographer.id = newValue }
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
    
    @Field(key: "hour_price")
    var hourPrice: Float

    @Siblings(through: OrderPromotion.self, from: \.$order, to: \.$promotion)
    var _promotions: [PromotionModel]

    var promotions: [PromotionModel] {
        get { _promotions }
        set { fatalError("Siblings must be attached manually") }
    }

    var promotionsSiblings: AttachablePromotionSiblings<OrderModel, OrderPromotion>? { $_promotions }
    
    @Siblings(through: AgreementModel.self, from: \.$order, to: \.$approver)
    var agreements: [UserModel]
    
    required init() { }
}

extension OrderModel {
    func fetchWatchers(app: Application) -> Future<[PlatformIdentifiable]> {
        [
            $makeuper.get(on: app.db).optionalMap { $0 as PlatformIdentifiable },
            $stylist.get(on: app.db).optionalMap { $0 as PlatformIdentifiable },
            $photographer.get(on: app.db).optionalMap { $0 as PlatformIdentifiable },
            $studio.get(on: app.db).optionalMap { $0 as PlatformIdentifiable },
        ].flatten(on: app.eventLoopGroup.next()).map { $0.compactMap { $0 } }
    }

    func fetchWatchersUsers(app: Application) -> Future<[UserModel]> {
        fetchWatchers(app: app)
            .throwingFlatMapEach(on: app.eventLoopGroup.next()) { try $0.getPlatformUser(app: app) }
            .map { $0.compactMap { $0 } }
//        [
//            $makeuper.get(on: app.db).optionalFlatMap { $0.getUser(app: app) },
//            $stylist.get(on: app.db).optionalFlatMap { $0.getUser(app: app) },
//            $photographer.get(on: app.db).optionalFlatMap { $0.getUser(app: app) },
//            $studio.get(on: app.db).optionalFlatMap { $0.getUser(app: app) },
//        ].flatten(on: app.eventLoopGroup.next()).map { $0.compactMap { $0 } }
    }
}
