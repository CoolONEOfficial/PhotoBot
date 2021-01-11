//
//  File.swift
//  
//
//  Created by Nickolay Truhin on 08.01.2021.
//

import Fluent
import Vapor

struct NodeController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let nodes = routes.grouped("nodes")
        nodes.get(use: index)
        nodes.post(use: create)
        nodes.group(":nodeID") { node in
            node.delete(use: delete)
        }
    }

    func index(req: Request) throws -> EventLoopFuture<[NodeModel]> {
        return NodeModel.query(on: req.db).all()
    }

    func create(req: Request) throws -> EventLoopFuture<NodeModel> {
        let nodeModel = try req.content.decode(NodeModel.self)
        return nodeModel.save(on: req.db).transform(to: nodeModel)
    }

    func delete(req: Request) throws -> EventLoopFuture<HTTPStatus> {
        return NodeModel.find(req.parameters.get("nodeID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { $0.delete(on: req.db) }
            .transform(to: .ok)
    }
}
