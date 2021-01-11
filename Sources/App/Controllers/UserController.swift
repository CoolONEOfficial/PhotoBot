//
//  File.swift
//
//
//  Created by Nickolay Truhin on 08.01.2021.
//

import Fluent
import Vapor

struct UserController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let users = routes.grouped("users")
        users.get(use: index)
        users.post(use: create)
        users.group(":userID") { user in
            user.delete(use: delete)
        }
    }

    func index(req: Request) throws -> EventLoopFuture<[UserModel]> {
        return UserModel.query(on: req.db).all()
    }

    func create(req: Request) throws -> EventLoopFuture<UserModel> {
        let userModel = try req.content.decode(UserModel.self)
        return userModel.save(on: req.db).transform(to: userModel)
    }

    func delete(req: Request) throws -> EventLoopFuture<HTTPStatus> {
        return UserModel.find(req.parameters.get("userID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { $0.delete(on: req.db) }
            .transform(to: .ok)
    }
}
