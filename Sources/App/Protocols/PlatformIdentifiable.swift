//
//  File.swift
//  
//
//  Created by Nickolay Truhin on 11.03.2021.
//

import Foundation
import Botter
import Vapor

protocol PlatformIdentifiable {
    var platformIds: [TypedPlatform<UserPlatformId>] { get set }
    func getPlatformUser(app: Application) throws -> Future<UserModel?>
}

extension PlatformIdentifiable where Self == UserModel {
    func getPlatformUser(app: Application) throws -> Future<UserModel?> {
        app.eventLoopGroup.future(self)
    }
}

extension PlatformIdentifiable where Self == User {
    func getPlatformUser(app: Application) throws -> Future<UserModel?> {
        try self.toTwin(app: app).map { .init($0) }
    }
}

extension PlatformIdentifiable where Self: UsersProtocol {
    func getPlatformUser(app: Application) throws -> Future<UserModel?> {
        if let usersProperty = usersProperty {
            return usersProperty.get(on: app.db).map(\.first)
        }
        return app.eventLoopGroup.future(user)
    }
}

extension PlatformIdentifiable {
    /// Returns mention like `@someone` if target platform is same and URL to profile if not
    func platformLink(for platform: AnyPlatform) -> String? {
        if let samePlatformId = platformIds.first(platform: platform) {
            return samePlatformId.mention
        } else {
            return platformIds.first?.link
        }
    }
}
