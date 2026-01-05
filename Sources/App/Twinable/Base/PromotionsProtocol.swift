//
//  File.swift
//  
//
//  Created by Nickolay Truhin on 21.03.2021.
//

import Foundation
import Vapor
import Fluent
import Botter

protocol PromotionsProtocol: class {
    
    associatedtype ImplementingModel: Model
    associatedtype SiblingModel: Model
    
    var promotions: [PromotionModel] { get set }
    var promotionsSiblings: AttachablePromotionSiblings<ImplementingModel, SiblingModel>? { get }
}

extension PromotionsProtocol {
    func getPromotions(app: Application) -> Future<[PromotionModel]> {
        promotionsSiblings?.get(on: app.db) ?? app.eventLoopGroup.future(promotions)
    }

    var promotionsSiblings: AttachablePromotionSiblings<ImplementingModel, SiblingModel>? { nil }
    
    func attachPromotions(_ promotions: [PromotionModel]?, app: Application) throws -> Future<Void> {
        guard let promotions = promotions else { return app.eventLoopGroup.future() }

        if let _ = self as? AnyModel {
            guard let siblings = self.promotionsSiblings else { fatalError("Promotions siblings must be implemented") }
            return try promotions.attach(to: siblings, app: app)
        } else {
            self.promotions = promotions
            return app.eventLoopGroup.future()
        }
    }
}
