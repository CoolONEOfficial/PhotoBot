//
//  File.swift
//  
//
//  Created by Nickolay Truhin on 20.03.2021.
//

import Foundation
import Vapor
import Botter

public protocol PhotoBotContextProtocol: BotContextProtocol {
    var controllers: [NodeController] { get }
    var user: User { get set }
}

public struct PhotoBotContext: PhotoBotContextProtocol {
    public let app: Application
    public let bot: Botter.Bot
    public var user: User
    public let platform: AnyPlatform
    public let controllers: [NodeController]
}
