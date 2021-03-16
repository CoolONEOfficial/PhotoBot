//
//  PhotoBot.swift
//  
//
//  Created by Nickolay Truhin on 07.01.2021.
//

import Foundation
import Botter
import Vapor
import Fluent
import Vkontakter
import AnyCodable
import DateHelper

enum PhotoBotError: Error {
    case nodeByEntryPointNotFound(EntryPoint)
    case nodeByActionNotFound
    case nodeByIdNotFound
    case destinationNotFound
}

extension Array where Element == DictEntry {
    var nextEntry: Element? {
        for entry in self {
            if Optional.isNil(entry.value) {
               return entry
            } else if let childDict = entry.value as? [DictEntry] {
                if let nextChildEntry = childDict.nextEntry {
                    return nextChildEntry
                }
            } else if let childArrDict = entry.value as? [[DictEntry]] {
                for childDict in childArrDict {
                    if let nextChildEntry = childDict.nextEntry {
                        return nextChildEntry
                    }
                }
            }
        }
        return nil
    }
}

struct DictEntry {
    let key: String
    let value: Any
    
    enum DictEntryType {
        case array
    }
    
    var type: DictEntryType?
}

extension Buildable {

    var dict: [DictEntry] {
        let dict: [DictEntry] = Mirror(reflecting: self).children.compactMap { child in
            if let label = child.label {
                return .init(key: label, value: child.value)
            }
            return nil
        }
        
        let res: [DictEntry] = dict.reduce([]) { arr, entry in
            var arr = arr

            switch entry.value {
            case let child as OptionalProtocol:
                
                var shouldFallthrough: Bool = false
                
                switch child.myWrappedType {
                case let childType as Buildable.Type:
                    let val: Any
                    if let childWrappedInstance = child.myWrapped,
                        let childInstance = childWrappedInstance as? Buildable {
                        val = childInstance.dict
                    } else {
                        val = childType.init().dict
                    }
                    arr.append(.init(key: entry.key, value: val))
                    
                case let childType as ArrayProtocol.Type where childType.elementType is Buildable.Type:
                    let _entry: DictEntry
                    if let childWrappedInstance = child.myWrapped,
                       let childInstance = childWrappedInstance as? [Buildable] {
                        _entry = .init(key: entry.key, value: childInstance.map(\.dict), type: .array)
                    } else {
                        _entry = .init(key: entry.key, value: (childType.elementType as! Buildable.Type).init().dict, type: .array)
                    }
                    arr.append(_entry)
                    
                default:
                    shouldFallthrough = true
                }
                
                if shouldFallthrough {
                    fallthrough
                }
                
            default:
                arr.append(entry)
            }
            
            return arr
        }
        
        return res
    }
}

extension Optional {
    static func isNil(_ object: Wrapped) -> Bool {
        switch object as Any {
        case Optional<Any>.none:
            return true
        default:
            return false
        }
    }
}

class PhotoBot {
    public let dispatcher: Botter.Dispatcher
    public let bot: Botter.Bot
    public let updater: Botter.Updater
    public let app: Application
    
    public init(settings: Botter.Bot.Settings, app: Application) throws {
        self.bot = try .init(settings: settings)
        self.dispatcher = .init(bot: bot)
        self.updater = .init(bot: bot, dispatcher: dispatcher)
        self.app = app
        
        //dispatcher.add(handler: Botter.CommandHandler(commands: [ "start" ], callback: handleStart))
        
        dispatcher.add(handler: Botter.MessageHandler(filters: .text, callback: handleText))
        
        dispatcher.add(handler: Botter.MessageEventHandler(callback: handleEvent))
    }
    
//    func handleStart(_ update: Botter.Update, _ context: Botter.BotContext?) throws {
//        guard case let .message(message) = update.content, let command = message.command else { return }
//
//
//    }
    
    func handleError<T: Botter.Replyable & PlatformObject>(_ platformReplyable: T, err: Error) {
        try? platformReplyable.replyMessage(from: bot, params: .init(text: "Error: \(err)"), app: app)
        #if DEBUG
        print("Error: \(err)")
        #endif
    }
    
    func handleEventPayload(_ event: Botter.MessageEvent, _ user: User, _ eventPayload: EventPayload, _ replyText: inout String) throws -> Future<[Botter.Message]> {
        switch eventPayload {
        case let .editText(messageId):
            replyText = "Move"
            return Node.find(.action(.messageEdit), app: app).throwingFlatMap { [self] node in
                try user.push(node, payload: .editText(messageId: messageId), to: event, with: bot, app: app)
            }

        case let .createNode(type):
            replyText = "Move"
            return Node.find(.action(.createNode), app: app).throwingFlatMap { [self] node in
                try user.push(node, payload: .build(type: type), to: event, with: bot, app: app)
            }

        case let .selectStylist(stylistId):
            replyText = "Selected"
            return Node.find(.entryPoint(.orderBuilder), app: app).flatMap { [self] node in
                Stylist.find(stylistId, app: app).throwingFlatMap { stylist in
                    try user.push(node, payload: .orderBuilder(.init(with: user.history.last?.nodePayload, stylist: stylist)), to: event, with: bot, app: app, saveMove: false)
                }
                
            }
            
        case let .selectMakeuper(makeuperId):
            replyText = "Selected"
            return Node.find(.entryPoint(.orderBuilder), app: app).flatMap { [self] node in
                Makeuper.find(makeuperId, app: app).throwingFlatMap { makeuper in
                    try user.push(node, payload: .orderBuilder(.init(with: user.history.last?.nodePayload, makeuper: makeuper)), to: event, with: bot, app: app, saveMove: false)
                }
            }
            
        case let .selectStudio(studioId):
            replyText = "Selected"
            return Node.find(.entryPoint(.orderBuilder), app: app).flatMap { [self] node in
                Studio.find(studioId, app: app).throwingFlatMap { studio in
                    try user.push(node, payload: .orderBuilder(.init(with: user.history.last?.nodePayload, studio: studio)), to: event, with: bot, app: app, saveMove: false)
                }
            }
        
        case let .selectTime(time):
            guard case let .calendar(year, month, day, _, _) = user.nodePayload else { throw HandleActionError.nodePayloadInvalid }
            replyText = "Selected"
            return user.push(.entryPoint(.orderBuilderDate), payload: .calendar(year: year, month: month, day: day, time: time), to: event, with: bot, app: app, saveMove: false)
            
        case let .selectDay(date):
            replyText = "Selected"
            let comps = Calendar.current.dateComponents([.year, .month, .day], from: date)
            guard let (year, month, day) = (comps.year, comps.month, comps.day) as? (Int, Int, Int) else { throw HandleActionError.eventPayloadInvalid }
            return user.push(.entryPoint(.orderBuilderDate), payload: .calendar(year: year, month: month, day: day), to: event, with: bot, app: app, saveMove: false)
        
        case let .selectDuration(duration):
            replyText = "Selected"

            guard case let .calendar(year, month, day, time, _) = user.nodePayload,
                  let (hour, minute, _) = time?.components,
                  let date = DateComponents.create(year: year, month: month, day: day, hour: hour, minute: minute).date else { throw HandleActionError.nodePayloadInvalid }
            
            return try user.push(.entryPoint(.orderBuilder), payload: .orderBuilder(.init(with: user.history.last?.nodePayload, date: date, duration: duration)), to: event, with: bot, app: app, saveMove: false)

        case .back:
            replyText = "Pop"
            return try user.pop(to: event, with: bot, app: app)
            
        case let .push(target, nodePayload, saveMoveToHistory):
            replyText = "Move"
            return user.push(target, payload: nodePayload, to: event, with: bot, app: app, saveMove: saveMoveToHistory)
            
        case let .pushCheckout(state):
            replyText = "Move"
            
            return PromotionModel.query(on: app.db).filter(\.$autoApply == true).all().flatMap { [self] promotions in
                promotions.map { promo in
                    promo.condition.check(state: state, user: user, app: app).map { (check: $0, promo: promo) }
                }.flatten(on: app.eventLoopGroup.next()).flatMap { promotions in
                    let promotions = promotions.filter(\.check).compactMap(\.promo.id)
                    return user.push(.entryPoint(.orderCheckout), payload: .checkout(.init(order: state, promotions: promotions)), to: event, with: bot, app: app, saveMove: true)
                }
            }
            
        case .createOrder:
            replyText = "Move"
            
            guard case let .checkout(checkoutState) = user.nodePayload, let userId = user.id else { throw HandleActionError.nodePayloadInvalid }
            
            let platform = event.platform.any
            
            return try OrderModel.create(userId: userId, checkoutState: checkoutState, app: app).flatMap { [self] order in
                MessageFormatter.shared.format("Заказ успешно создан, в ближайшее время с Вами свяжется @" + .replacing(by: .admin), platform: platform, user: user, app: app)
                .throwingFlatMap { message in
                    try event.replyMessage(from: bot, params: .init(text: message), app: app)
                }.map { ($0, order) }
            }.throwingFlatMap { [self] (messages, order) in
                try User.find(
                    destination: .username(Application.adminNickname(for: platform)),
                    platform: platform,
                    app: app
                ).flatMap { user in
                    if let user = user, let id = user.platformIds.firstValue(platform: platform)?.id {

                        func getMessage(_ platform: AnyPlatform) -> Future<String> {
                            MessageFormatter.shared.format(
                                [
                                    "Новый заказ от @" + .replacing(by: .username) + " (" + .replacing(by: .userId) + "):",
                                    .replacing(by: .orderBlock),
                                    .replacing(by: .priceBlock),
                                ].joined(separator: "\n"),
                                platform: platform, user: user, app: app
                            )
                        }

                        return [
                            getMessage(platform).throwingFlatMap { text in
                                try bot.sendMessage(params: .init(
                                    destination: .init(platform: platform, id: id),
                                    text: text
                                ), platform: platform, app: app)
                            },
                            order.fetchWatchers(app: app).flatMap {
                                $0.map { watcher in
                                    let platformIds = watcher.platformIds
                                    
                                    let platformId = platformIds.first(for: platform) ?? platformIds.first!
                                    return getMessage(platformId.any).throwingFlatMap { text in
                                        try bot.sendMessage(params: .init(
                                            destination: platformId.sendDestination,
                                            text: text
                                        ), platform: platformId.any, app: app)
                                    }
                                }.flatten(on: app.eventLoopGroup.next()).map { messages + $0.reduce([], +) }
                            }
                        ].flatten(on: app.eventLoopGroup.next()).map { $0.reduce([], +) }
                    } else {
                        return app.eventLoopGroup.future(messages)
                    }
                }
            }.throwingFlatMap { [self] messages in
                try user.popToMain(to: event, with: bot, app: app).map { messages + $0 }
            }

        case .nextPage, .previousPage:
            var pageIndex: Int
            if case let .page(index) = user.nodePayload {
                pageIndex = index
            } else {
                pageIndex = 0
            }
            
            if case .nextPage = eventPayload {
                replyText = "👉 Следующая"
                pageIndex += 1
            } else {
                pageIndex -= 1
                replyText = "👈 Предыдущая"
            }

            return user.push(.id(user.nodeId!), payload: .page(at: pageIndex), to: event, with: bot, app: app, saveMove: false)
        }
    }
    
    func handleEvent(_ update: Botter.Update, _ context: Botter.BotContext?) throws {
        guard case let .event(event) = update.content else { return }
        
        let userFuture = try User.findOrCreate(from: event, bot: bot, app: app).throwingFlatMap { [self] user -> Future<[Botter.Message]> in
            
            var replyText: String = "Not handled"
            var nextFuture: Future<[Botter.Message]?>? = nil
            
            let eventData = event.data.value as? Data
            let eventStr = String(data: eventData ?? .init(), encoding: .utf8)
            
            if eventStr == "nope" {
                nextFuture = nil
            } else if let eventStr = eventStr,
                      let eventPayloadId = UUID(uuidString: eventStr) {
                nextFuture = EventPayloadModel.find(eventPayloadId, on: app.db)
                    .optionalFlatMapThrowing { model in try EventPayload(from: model.instance) }
                    .optionalThrowingFlatMap { eventPayload in try handleEventPayload(event, user, eventPayload, &replyText) }
            } else if let eventPayload: EventPayload = try? event.decodeData() {
                nextFuture = try handleEventPayload(event, user, eventPayload, &replyText).map { Optional($0) }
            }
            
            var futureArr: [EventLoopFuture<[Botter.Message]>] = update.platform.same(.vk) ? [] : [
                try event.reply(from: bot, params: .init(type: .notification(text: replyText)), app: app).map { _ in [] }
            ]
            
            if let nextFuture = nextFuture {
                futureArr.append(nextFuture.unwrap(orReplace: []))
            }
            
            return futureArr.flatten(on: app.eventLoopGroup.next()).map { $0.last ?? [] }
        }
        userFuture.whenFailure { [weak self] in self?.handleError(event, err: $0) }
    }

    func handleText(_ update: Botter.Update, _ context: Botter.BotContext?) throws {
        guard case let .message(message) = update.content, let text = message.text else { return }
        
        let userFuture = try User.findOrCreate(from: message, bot: bot, app: app)
            .throwingFlatMap { user -> Future<[Botter.Message]?> in
                if let nodeId = user.nodeId {
                    return NodeModel.find(nodeId, on: self.app.db)
                        .unwrap(or: PhotoBotError.nodeByIdNotFound)
                        .throwingFlatMap { [self] node -> Future<[Botter.Message]?> in
                            let nextFuture: Future<[Botter.Message]?>?
                            
                            if let action = node.action {
                                nextFuture = try handleAction(action, user, message, context).throwingFlatMap { result -> Future<[Botter.Message]?> in
                                    switch result {
                                    case .success:
                                        var future: Future<[Botter.Message]>?
                                    
                                        guard let successNodeId = action.action else { return self.app.eventLoopGroup.future(nil) }
                                        switch successNodeId {
                                        case let .push(target):
                                            future = user.push(target, to: message, with: bot, app: app)
                                            
                                        case .pop:
                                            future = try user.pop(to: message, with: bot, app: app)

                                        case .moveToBuilder(let builderType):
                                            future = try self.moveToBuilder(builderType, user: user, nodeId: nodeId, message: message, text: text)
                                        }
                                        
                                        return future?.map { Optional($0) } ?? (self.app.eventLoopGroup.future(nil))
                                        
                                    case let .failure(error):
                                        return try message.reply(from: bot, params: .init(text: error.errorDescription ?? "Некорректное сообщение, попробуй еще раз но с другим текстом."), app: app).map(\.first).optionalThrowingFlatMap { sentMessage in
                                            try user.pushToActualNode(to: message, with: bot, app: app).map { $0 + [sentMessage] }
                                        }
                                    }
                                }
                            } else {
                                nextFuture = try message.reply(from: bot, params: .init(text: "В этом месте не принимается текст. Попробуй нажать на подходящую кнопку."), app: app).map(\.first).optionalThrowingFlatMap { message in
                                    try user.pushToActualNode(to: message, with: bot, app: app).map { $0 + [message] }
                                }
                            }
                            
                            return nextFuture ?? self.app.eventLoopGroup.future(nil)
                        }
                } else {
                    return Node.find(.entryPoint(.welcomeGuest), app: self.app).throwingFlatMap { node in
                        try user.push(node, to: message, with: self.bot, app: self.app).map { Optional($0) }
                    }
                }
            }
        userFuture.whenFailure { [weak self] in self?.handleError(message, err: $0) }
    }
    
    enum UpdateNextValueResult {
        case success([String: AnyCodable])
        case checkFailed
        case notFound
    }
    
    func checkEntry(_ entry: DictEntry, _ payloadObject: [String: AnyCodable]?, _ text: String) -> UpdateNextValueResult {
        var payloadObject = payloadObject ?? [:]
        if Optional.isNil(entry.value),
           let fieldType = type(of: entry.value) as? BuildableField.Type {
            if fieldType.check(text) {
                payloadObject[entry.key] = fieldType.value(text)
                return .success(payloadObject)
            } else {
                return .checkFailed
            }
        } else if let childDict = entry.value as? [DictEntry] {
            if entry.type == .array {
                for entry in childDict {
                    switch checkEntry(entry, payloadObject[entry.key]?.value as? [String: AnyCodable], text) {
                    case let .success(obj):
                        payloadObject[entry.key] = .init(obj)
                        return .success(payloadObject)
                    case .checkFailed:
                        return .checkFailed
                    case .notFound:
                        break
                    }
                }
            } else {
                switch updatingNextValue(childDict, payloadObject[entry.key]?.value as? [String: AnyCodable], text) {
                case let .success(childPayloadObject):
                    payloadObject[entry.key] = .init(childPayloadObject)
                    return .success(payloadObject)

                case .checkFailed:
                    return .checkFailed

                case .notFound:
                    break
                }
            }
        }
        return .notFound
    }
    
    func updatingNextValue(_ dict: [DictEntry], _ payloadObject: [String: AnyCodable]?, _ text: String) -> UpdateNextValueResult {
        for entry in dict {
            let res = checkEntry(entry, payloadObject, text)
            guard case .notFound = res else {
                return res
            }
        }
        return .notFound
    }
    
    func moveToBuilder(_ builderType: BuildableType, user: User, nodeId: UUID, message: Botter.Message, text: String) throws -> Future<[Botter.Message]>? {
        var payloadObject: [String: AnyCodable]
        
        if case let .build(payloadType, actualPayloadObject) = user.nodePayload, builderType == payloadType {
            payloadObject = actualPayloadObject.wrapped
            
            let buildableInstance = try builderType.type.init(from: payloadObject)
            
            switch updatingNextValue(buildableInstance.dict, payloadObject, text) {
            case let .success(updatedPayloadObject):
                payloadObject = updatedPayloadObject
                
            case .notFound:
                let future: Future<Void>
                if let modelFuture = try? Node.create(other: NodeModel(from: NodeBuildable(from: payloadObject)), app: app).throwingFlatMap({ try $0.save(app: self.app).transform(to: $0) }) {
                    future = modelFuture.map { _ in () }
                } else {
                    future = try message.reply(from: self.bot, params: .init(text: "Failed to create model"), app: self.app).map { _ in () }
                }
                return future.throwingFlatMap { _ in try user.pop(to: message, with: self.bot, app: self.app)
                    { $0.nodeId != nodeId } }
                
            case .checkFailed:
                return try? message.reply(from: self.bot, params: .init(text: "Incorrect format, try again"), app: self.app)
            }
            
        } else {
            payloadObject = [:]
        }
        
        return user.push(.id(nodeId), payload: .build(type: builderType, object: payloadObject), to: message, with: self.bot, app: self.app)
    }

    enum HandleActionError: Error, LocalizedError {
        case textNotFound
        case textIncorrect
        case nodePayloadInvalid
        case eventPayloadInvalid
        case noAttachments
        case promoCondition
        case dateNotHandled
        case promoNotFound
        
        var errorDescription: String? {
            switch self {
            case .promoCondition:
                return "К сожалению в Вашем заказе не выполняются условия акции."
                
            case .dateNotHandled:
                return "Дата или время не было распознано."
                
            case .promoNotFound:
                return "По данному промокоду не найдено акций."
                
            default:
                return nil
            }
        }
    }

    func handleAction(_ action: NodeAction, _ user: User, _ message: Botter.Message, _ context: Botter.BotContext?) throws -> Future<Result<Void, HandleActionError>> {
        guard let text = message.text else { return app.eventLoopGroup.future(error: HandleActionError.textNotFound) }
        
        switch action.type {
        case .handleCalendar:
            if var date = Date(detectFromString: text) {
                while date.compare(.isInThePast) {
                    date = date.adjust(.year, offset: 1)
                }
                if user.nodePayload == nil {
                    if let year = date.component(.year),
                       let month = date.component(.month),
                       let day = date.component(.day) {
                        
                        return user.push(.entryPoint(.orderBuilderDate), payload: .calendar(
                            year: year, month: month, day: day,
                            needsConfirm: true
                        ), to: message, with: bot, app: app, saveMove: false).map { _ in .success }
                    }
                } else if case let .calendar(year, month, day, time, _) = user.nodePayload, time == nil {
                    
                    return user.push(.entryPoint(.orderBuilderDate), payload: .calendar(
                        year: year, month: month, day: day,
                        time: date.timeIntervalSince(date.dateFor(.startOfDay)),
                        needsConfirm: true
                    ), to: message, with: bot, app: app, saveMove: false).map { _ in .success }
                }
            }
            return app.eventLoopGroup.future(.failure(.dateNotHandled))
        
        case .messageEdit:
            return Node.find(.id(user.history.last!.nodeId), app: app).throwingFlatMap { node in
                
                guard let nodePayload = user.nodePayload,
                      case let .editText(messageId) = nodePayload else {
                    throw HandleActionError.nodePayloadInvalid
                }

                node.messagesGroup?.updateText(at: messageId, text: text)
                
                return try node.save(app: self.app).map { _ in .success }
            }

        case .setName:
            user.firstName = message.text
            return try user.save(app: app).throwingFlatMap { _ in
                try message.reply(from: self.bot, params: .init(text: "Good, \(user.firstName!)"), app: self.app)
            }.map { _ in .success }

        case .uploadPhoto:
            let availablePlatforms: [AnyPlatform] = .available(bot: bot)
            
            return try availablePlatforms.map { platform -> Future<PlatformFile.Entry> in
                let destination: SendDestination
                switch platform {
                case .tg:
                    destination = .chatId(Application.tgBufferUserId)
                case .vk:
                    destination = .userId(Application.vkBufferUserId)
                }
                return try self.bot.sendMessage(params: .init(
                    destination: destination,
                    text: "Загружаю вот эту фото",
                    attachments: [
                        .init(type: .photo, content: .url(text))
                    ]
                ), platform: platform, app: app).throwingFlatMap { res -> Future<PlatformFile.Entry> in
                    guard let attachment = res.first?.attachments.first else { throw HandleActionError.noAttachments }
                    var text = ""
                    switch platform {
                    case .tg:
                        text.append("tg id: ")
                        
                    case .vk:
                        text.append("vk id: ")
                    }
                    text.append(attachment.attachmentId)
                    return try message.reply(from: self.bot, params: .init(text: text), app: self.app)
                        .map { _ in platform.convert(to: attachment.attachmentId) }
                }
            }.flatten(on: app.eventLoopGroup.next()).flatMap { platformEntries in
                PlatformFile.create(platformEntries: platformEntries, type: .photo, app: self.app).throwingFlatMap { try $0.saveReturningId(app: self.app) }.throwingFlatMap { savedId in
                    try message.reply(from: self.bot, params: .init(text: "локальный id: \(savedId)"), app: self.app)
                        
                }
            }.map { _ in .success }
            
        case .applyPromocode:
            guard case var .checkout(checkoutState) = user.nodePayload else { throw HandleActionError.nodePayloadInvalid }
            
            return Promotion.find(promocode: text, app: app).flatMap { [self] promotion in
                guard let promotion = promotion else { return app.eventLoopGroup.future(.failure(.promoNotFound)) }
                
                return promotion.condition.check(state: checkoutState.order, user: user, app: app).flatMap { check in
                    guard check else { return app.eventLoopGroup.future(.failure(.promoCondition)) }

                    return checkoutState.promotions.map { Promotion.find($0, app: app) }.flatten(on: app.eventLoopGroup.next()).flatMap { promotions in
                        
                        for promo in promotions.compactMap({ $0 }) where !promo.autoApply {
                            if let promoId = promo.id {
                                if let index = checkoutState.promotions.firstIndex(of: promoId) {
                                    checkoutState.promotions.remove(at: index)
                                }
                            }
                        }
                        
                        checkoutState.promotions.append(promotion.id!)
                        
                        return user.push(.entryPoint(.orderCheckout), payload: .checkout(checkoutState), to: message, with: bot, app: app).map { _ in .success }
                    }
                    
                    
                }
            }

        case .buildType, .createNode:
            return app.eventLoopGroup.future(.success)
        }
    }

}
