//
//  File.swift
//  
//
//  Created by Nickolay Truhin on 22.03.2021.
//

import Foundation
import Vapor
import Fluent
import Botter

protocol UsersProtocol: class {
    associatedtype ImplementingModel: Model
    
    var user: UserModel! { get set }
    var usersProperty: ChildrenProperty<ImplementingModel, UserModel>? { get }
}

extension UsersProtocol where Self: Twinable, Self.TwinType == ImplementingModel {
    var usersProperty: ChildrenProperty<ImplementingModel, UserModel>? { nil }
}

extension UsersProtocol {
    func getUser(app: Application) -> Future<UserModel?> {
        usersProperty?.get(on: app.db).map(\.first) ?? app.eventLoopGroup.future(user)
    }

    func attachUser(_ user: UserModel, app: Application) throws -> Future<Void> {
        if let _ = self as? AnyModel {
            guard let property = self.usersProperty else { fatalError("Users property must be implemented") }
            return property.create(user, on: app.db)
        } else {
            self.user = user
            return app.eventLoopGroup.future()
        }
    }
}
