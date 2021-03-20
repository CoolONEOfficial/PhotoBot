//
//  File.swift
//  
//
//  Created by Nickolay Truhin on 20.03.2021.
//

import Foundation
import Vapor
import Botter

public protocol NodeController {
    func handleEventPayload(_ event: MessageEvent, _ eventPayload: EventPayload, _ replyText: inout String, context: PhotoBotContextProtocol) throws -> Future<[Botter.Message]>?
    func getSendMessages(platform: AnyPlatform, in node: Node, _ payload: NodePayload?, context: PhotoBotContextProtocol, group: SendMessageGroup) throws -> Future<[SendMessage]>?
    func getListSendMessages(platform: AnyPlatform, in node: Node, _ payload: NodePayload?, context: PhotoBotContextProtocol, listType: MessageListType, indexRange: Range<Int>) throws -> Future<([SendMessage], Int)>?
    func handleAction(_ action: NodeAction, _ message: Message, _ text: String, context: PhotoBotContextProtocol) throws -> EventLoopFuture<Result<Void, HandleActionError>>?
    func create(app: Application) throws -> Future<Node>
}

extension NodeController {
    func handleEventPayload(_ event: MessageEvent, _ eventPayload: EventPayload, _ replyText: inout String, context: PhotoBotContextProtocol) throws -> Future<[Botter.Message]>? { nil }
    func handleAction(_ action: NodeAction, _ message: Message, _ text: String, context: PhotoBotContextProtocol) throws -> EventLoopFuture<Result<Void, HandleActionError>>? { nil }
    func getSendMessages(platform: AnyPlatform, in node: Node, _ payload: NodePayload?, context: PhotoBotContextProtocol, group: SendMessageGroup) throws -> Future<[SendMessage]>? { nil }
    func getListSendMessages(platform: AnyPlatform, in node: Node, _ payload: NodePayload?, context: PhotoBotContextProtocol, listType: MessageListType, indexRange: Range<Int>) throws -> Future<([SendMessage], Int)>? { nil }
}
