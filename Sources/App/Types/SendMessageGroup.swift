//
//  SendMessageGroup.swift
//  
//
//  Created by Nickolay Truhin on 01.02.2021.
//

import Foundation
import Botter
import Vapor
import Fluent
//
enum SendMessageGroupError: Error {
    case invalidPayload
    case nodesNotFound
}

extension NSObject {
    func propertyNames() -> [String] {
        let mirror = Mirror(reflecting: self)
        return mirror.children.compactMap{ $0.label }
    }
}


extension Optional {
    var wrappedType: Any.Type {
        Wrapped.self
    }
}

enum MessageListType: String, Codable {
    case portfolio
    case stylists
    case makeupers
    case studios
}

enum SendMessageGroup {
    case array(_ elements: [SendMessage])
    case builder
    case list(_ content: MessageListType)
    case orderBuilder
    case orderCheckout
    case welcome
    case calendar
    
    mutating func getSendMessages(platform: AnyPlatform, in node: Node, app: Application, _ user: User, _ payload: NodePayload?) throws -> Future<[SendMessage]> {
        let result: Future<[SendMessage]>
        
        switch self {
        case var .array(arr):
            
            if !(node.systemic ?? false), user.isValid, user.isAdmin {
                for (index, params) in arr.enumerated() {
                    params.keyboard.buttons.insert([
                        try! Button(
                            text: "Редактировать текст",
                            action: .callback,
                            eventPayload: .editText(messageId: index)
                        )
//                        try! Button( TODO: node creation
//                            text: "Add node",
//                            action: .callback,
//                            eventPayload: .createNode(type: .node)
//                        )
                    ], at: 0)
                    arr[index] = params
                }
            }
            result = app.eventLoopGroup.future(arr)

        case let .list(type):
            
            var pageNumber: Int
            if case let .page(num) = payload {
                pageNumber = num
            } else {
                pageNumber = 0
            }
            
            let itemsPerPage = 3
            let startIndex = pageNumber * itemsPerPage
            let endIndex = startIndex + itemsPerPage
            
            switch type {
            case .portfolio:
                result = app.eventLoopGroup.future([])
                
            case .makeupers:
                result = MakeuperModel.query(on: app.db).count().flatMap { count in
                    MakeuperModel.query(on: app.db).range(startIndex ..< endIndex).all().flatMap { humans in
                        humans.enumerated().map { (index, human) -> Future<SendMessage> in
                            human.$_photos.get(on: app.db).throwingFlatMap { photos -> Future<SendMessage> in
                                try photos.map { try PlatformFile.create(other: $0, app: app) }
                                    .flatten(on: app.eventLoopGroup.next())
                                    .flatMapThrowing { attachments -> SendMessage in
                                        SendMessage(
                                            text: "\(human.name ?? "")\n\(human.price) ₽ / час\n\(human.platformLink(for: platform) ?? "")",
                                            keyboard: [ [
                                                try Button(
                                                    text: "Выбрать",
                                                    action: .callback,
                                                    eventPayload: .selectMakeuper(id: try human.requireID())
                                                )
                                            ] ],
                                            attachments: attachments.compactMap { $0.fileInfo }
                                        )

                                    }
                            }
                        }
                        .flatten(on: app.eventLoopGroup.next())
                        .map { Self.addPageButtons($0, startIndex, endIndex, count) }
                    }
                }
                
            case .stylists:
                let model = StylistModel.self
                result = model.query(on: app.db).count().flatMap { count in
                    model.query(on: app.db).range(startIndex ..< endIndex).all().flatMap { humans in
                        humans.enumerated().map { (index, human) -> Future<SendMessage> in
                            human.$_photos.get(on: app.db).throwingFlatMap { photos -> Future<SendMessage> in
                                try photos.map { try PlatformFile.create(other: $0, app: app) }
                                    .flatten(on: app.eventLoopGroup.next())
                                    .flatMapThrowing { attachments -> SendMessage in
                                        SendMessage(
                                            text: "\(human.name ?? "")\n\(human.price) ₽ / час\n\(human.platformLink(for: platform) ?? "")",
                                            keyboard: [ [
                                                try Button(
                                                    text: "Выбрать",
                                                    action: .callback,
                                                    eventPayload: .selectStylist(id: try human.requireID())
                                                )
                                            ] ],
                                            attachments: attachments.compactMap { $0.fileInfo }
                                        )

                                    }
                            }
                        }
                        .flatten(on: app.eventLoopGroup.next())
                        .map { Self.addPageButtons($0, startIndex, endIndex, count) }
                    }
                }
                
            case .studios:
                let model = StudioModel.self
                result = model.query(on: app.db).count().flatMap { count in
                    model.query(on: app.db).range(startIndex ..< endIndex).all().flatMap { studios in
                        studios.enumerated().map { (index, studio) -> Future<SendMessage> in
                            studio.$_photos.get(on: app.db).throwingFlatMap { photos -> Future<SendMessage> in
                                try photos.map { try PlatformFile.create(other: $0, app: app) }
                                    .flatten(on: app.eventLoopGroup.next())
                                    .flatMapThrowing { attachments -> SendMessage in
                                        SendMessage(
                                            text: "\(studio.name ?? "")\n\(studio.price) ₽ / час",
                                            keyboard: [ [
                                                try Button(
                                                    text: "Выбрать",
                                                    action: .callback,
                                                    eventPayload: .selectStudio(id: try studio.requireID())
                                                )
                                            ] ],
                                            attachments: attachments.compactMap { $0.fileInfo }
                                        )

                                    }
                            }
                        }
                        .flatten(on: app.eventLoopGroup.next())
                        .map { Self.addPageButtons($0, startIndex, endIndex, count) }
                    }
                }
            }
            
        case .builder:
            guard let payload = payload, case let .build(payloadTypeWrapper, payloadObject) = payload else {
                return app.eventLoopGroup.future(error: SendMessageGroupError.invalidPayload)
            }
            let buildableInstance = try! payloadTypeWrapper.type.init(from: payloadObject)
            
            let arr: [SendMessage]
            let statusStr = buildableInstance.statusStr()
            if let nextKey = buildableInstance.dict.nextEntry?.key {
                arr = [ .init(text: "Builder status" + statusStr), .init(text: "Send \(nextKey)") ]
            } else {
                arr = [ .init(text: "Builded obj" + statusStr) ]
            }
            
            result = app.eventLoopGroup.future(arr)

        case .orderBuilder:
            
            var keyboard: Keyboard = [[
                try .init(text: "Стилист", action: .callback, eventPayload: .push(.entryPoint(.orderBuilderStylist))),
                try .init(text: "Визажист", action: .callback, eventPayload: .push(.entryPoint(.orderBuilderMakeuper))),
                try .init(text: "Студия", action: .callback, eventPayload: .push(.entryPoint(.orderBuilderStudio))),
                try .init(text: "Время", action: .callback, eventPayload: .push(.entryPoint(.orderBuilderDate)))
            ]]
            
            if case let .orderBuilder(state) = payload,
               state.stylistId != nil,
               state.makeuperId != nil,
               state.studioId != nil,
               state.date != nil {
                keyboard.buttons.safeAppend([
                    try .init(text: "👌 К завершению", action: .callback, eventPayload: .push(.entryPoint(.orderCheckout), payload: .checkout(.init(order: state))))
                ])
            }
            
            result = app.eventLoopGroup.future([ .init(
                text: [
                    "Ваш заказ:",
                    .replacing(by: .orderBlock),
                    "Сумма: " + .replacing(by: .price) + " ₽"
                ].joined(separator: "\n"),
                keyboard: keyboard
            ) ])
            
        case .orderCheckout:
            result = app.eventLoopGroup.future([ .init(
                text: [
                    "Оформление заказа",
                    .replacing(by: .orderBlock),
                    .replacing(by: .priceBlock),
                    .replacing(by: .promoBlock),
                ].joined(separator: "\n"),
                keyboard: [[
                    try .init(text: "✅ Отправить", action: .callback, eventPayload: .createOrder)
                ]]
            ) ])

        case .welcome:
            
            result = app.eventLoopGroup.future([
                .init(text: "Добро пожаловать, " + .replacing(by: .userFirstName) + "! Выбери секцию чтобы в нее перейти.", keyboard: [
                    [
                        try .init(text: "👧 Обо мне", action: .callback, eventPayload: .push(.entryPoint(.about))),
                        try .init(text: "🖼️ Мои работы", action: .callback, eventPayload: .push(.entryPoint(.portfolio))),
                    ],
                    [
                        try .init(text: "📷 Заказ фотосессии", action: .callback, eventPayload: .push(.entryPoint(.orderBuilder)))
                    ] + (user.isAdmin ? [
                        try .init(text: "Выгрузить фотку", action: .callback, eventPayload: .push(.entryPoint(.uploadPhoto)))
                    ] : [])
                ])
            ])
            
        case .calendar:
            result = try calendarMessages(app: app, payload)
        }

        return result
            .map { Self.addNavigationButtons($0, user) }
            .flatMapEach(on: app.eventLoopGroup.next()) { Self.formatMessage(platform: platform, $0, user, app: app) }
    }
    
    func calendarMessages(app: Application, _ payload: NodePayload?) throws -> Future<[SendMessage]> {
        
        let calendar = Calendar.current
        let currentDate = Date()
        let comps = calendar.dateComponents([.year, .month], from: currentDate)
        var (year, month) = (comps.year!, comps.month!)
        var day: Int?
        var time: TimeInterval?
        
        if case let .calendar(payloadYear, payloadMonth, payloadDay, payloadTime) = payload {
            year = payloadYear
            month = payloadMonth
            day = payloadDay
            time = payloadTime
        }
        
        let formatter = DateFormatter()
        if let _ = time {
            return app.eventLoopGroup.future([
                .init(text: "Выберите продолжительность:"),
                .init(text: "Полчаса\nза полчаса можно тото", keyboard: [[
                    try .init(text: "Выбрать", action: .callback, eventPayload: .selectDuration(duration: 60*30))
                ]]),
                .init(text: "Час\nза час можно тото", keyboard: [[
                    try .init(text: "Выбрать", action: .callback, eventPayload: .selectDuration(duration: 60*60))
                ]]),
                .init(text: "Два часа\nза два часа можно тото", keyboard: [[
                    try .init(text: "Выбрать", action: .callback, eventPayload: .selectDuration(duration: 60*60*2))
                ]])
            ])
        } else if let selectedDay = day {
            let date = calendar.date(from: .init(year: year, month: month, day: selectedDay))!
            let hour: TimeInterval = 60 * 60
            let availableInterval = date.addingTimeInterval(hour * 8)...date
                .addingTimeInterval(hour * 24)
            let timesMessages = try availableInterval.intervalDates(with: hour / 2).map { date in
                try Button(
                    text: DateFormatter.localizedString(from: date, dateStyle: .none, timeStyle: .short),
                    action: .callback,
                    eventPayload: .selectTime(date: date)
                )
            }.chunked(into: 6)
            
            let headers = [ "Утро", "День", "Вечер" ]
            
            let groupsMessages = timesMessages.chunked(into: timesMessages.count / 3).enumerated()
                .map { (Button(text: headers[$0.0]), $0.1) }
                .map { [[$0.0]] + $0.1 }
                .reduce([], +)

            return app.eventLoopGroup.future([
                .init(text: "Выбери время:", keyboard: .init(buttons: groupsMessages))
            ])
        } else {
            let dayInSeconds: TimeInterval = 60 * 60 * 24
            let startMonth = calendar.date(from: .init(year: year, month: month))!
            let startTable = startMonth.addingTimeInterval(-dayInSeconds * .init(calendar.weekday(date: startMonth)))

            let endMonth = calendar.date(byAdding: .init(month: 1, day: -1), to: startMonth)!
            let endTable = endMonth.addingTimeInterval(dayInSeconds * .init(6 - calendar.weekday(date: endMonth)))
            
            
            let weekdayMessages = formatter.veryShortWeekdaySymbols
                .shift(withDistance: calendar.firstWeekday - 1).compactMap { weekday in
                Button(text: weekday)
            }
            let daysMessages = try (startTable...endTable).intervalDates().map { date in
                try Button(
                    text: String(calendar.component(.day, from: date)),
                    action: .callback,
                    eventPayload: .selectDay(date: date)
                )
            }.chunked(into: 7)
            
            func eventPayload(appending comps: DateComponents) -> EventPayload {
                let date = calendar.date(from: .init(year: year, month: month))!
                let newDate = calendar.date(byAdding: comps, to: date)!
                let newComps = calendar.dateComponents([.year, .month], from: newDate)
                let (newYear, newMonth) = (newComps.year!, newComps.month!)
                return .push(.entryPoint(.orderBuilderDate), payload: .calendar(year: newYear, month: newMonth), saveToHistory: false)
            }
            
            return app.eventLoopGroup.future([
                .init(text: "Выбери дату:", keyboard: .init(buttons: [
                    [
                        try .init(text: "👈", action: .callback, eventPayload: eventPayload(appending: .init(month: -1))),
                        .init(text: formatter.shortMonthSymbols[month - 1]),
                        try .init(text: "👉", action: .callback, eventPayload: eventPayload(appending: .init(month: 1))),
                        try .init(text: "👈", action: .callback, eventPayload: eventPayload(appending: .init(year: -1))),
                        .init(text: .init(year)),
                        try .init(text: "👉", action: .callback, eventPayload: eventPayload(appending: .init(year: 1)))
                    ],
                    weekdayMessages
                ] + daysMessages))
            ])
        }
    }

    static private func addPageButtons(_ messages: [SendMessage], _ startIndex: Int, _ endIndex: Int, _ count: Int) -> [SendMessage] {
        if let lastMessage = messages.last {
            var buttons = [Button]()
            if startIndex > 0, let prevButton = try? Button(text: "Предыдущая стр", action: .callback, eventPayload: .previousPage) {
                buttons.append(prevButton)
            }
            if endIndex < count, let nextButton = try? Button(text: "Следующая стр", action: .callback, eventPayload: .nextPage) {
                buttons.append(nextButton)
            }
            
            lastMessage.keyboard.buttons.append(buttons)
        }
        return messages
    }
    
    static private func addNavigationButtons(_ messages: [SendMessage], _ user: User) -> [SendMessage] {
        if !user.history.isEmpty, let lastMessage = messages.last {
            lastMessage.keyboard.buttons.safeAppend([ try! .init(
                text: user.history.last?.nodeId == user.nodeId ? "❌ Отмена" : "👈 Назад",
                action: .callback, eventPayload: .back
            ) ])
        }
        return messages
    }
    
    static private func formatMessage(platform: AnyPlatform, _ message: SendMessage, _ user: User, app: Application) -> Future<SendMessage> {
        if let text = message.text {
            return MessageFormatter.shared.format(text, platform: platform, user: user, app: app).map { text in
                message.text = text
                return message
            }
        } else {
            return app.eventLoopGroup.future(message)
        }
    }
    
    mutating func updateText(at index: Int, text: String) {
        guard case let .array(arr) = self else { return }
        arr[index].text = text
        self = .array(arr)
    }
}

extension Buildable {
    func statusStr(_ keyPrefix: String = "", _ entries: [DictEntry]? = nil) -> String {
        (entries ?? dict).map { entry in
            var value = entry.value
            
            if let valueOptional = value as? OptionalProtocol,
               let valueUnwrapped = valueOptional.myWrapped {
                value = valueUnwrapped
            }
            let statusVal: String
            switch value {
            case let subEntries as [[DictEntry]]:
                statusVal = "\n---" + subEntries.map { statusStr("\t" + keyPrefix + entry.key + " -> ", $0) }.joined(separator: "\n\n---\n\n") + "\n---"
            
            case let subEntries as [DictEntry]:
                statusVal = statusStr("\t" + keyPrefix + entry.key + " -> ", subEntries)

            case let strConv as CustomStringConvertible:
                statusVal = strConv.description

            default:
                statusVal = String(describing: value)
            }
            
            let typeStr: String
            if let optionalType = value as? OptionalProtocol {
                typeStr = ": \(optionalType.myWrappedType)"
            } else {
                typeStr = .init()
            }
            
            return "\n\t\(keyPrefix)\(entry.key)\(typeStr) = \(statusVal)"
        }.reduce("", +)
    }
}

extension SendMessageGroup: Codable {

    enum CodingKeys: String, CodingKey {
        case builder
        case elements
        case listType
        case orderBuilder
        case orderCheckout
        case welcome
        case calendar
    }

    internal init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        if container.allKeys.contains(.elements), try container.decodeNil(forKey: .elements) == false {
            let elements = try container.decode([SendMessage].self, forKey: .elements)
            self = .array(elements)
            return
        }
        if container.allKeys.contains(.builder), try container.decodeNil(forKey: .builder) == false {
            self = .builder
            return
        }
        if container.allKeys.contains(.listType), try container.decodeNil(forKey: .listType) == false {
            let type = try container.decode(MessageListType.self, forKey: .listType)
            self = .list(type)
            return
        }
        if container.allKeys.contains(.orderBuilder), try container.decodeNil(forKey: .orderBuilder) == false {
            self = .orderBuilder
            return
        }
        if container.allKeys.contains(.orderCheckout), try container.decodeNil(forKey: .orderCheckout) == false {
            self = .orderCheckout
            return
        }
        if container.allKeys.contains(.welcome), try container.decodeNil(forKey: .welcome) == false {
            self = .welcome
            return
        }
        if container.allKeys.contains(.calendar), try container.decodeNil(forKey: .calendar) == false {
            self = .calendar
            return
        }
        throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "Unknown enum case"))
    }

    internal func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case let .array(elements):
            try container.encode(elements, forKey: .elements)
        case .builder:
            try container.encode("builder", forKey: .builder)
        case let .list(type):
            try container.encode(type, forKey: .listType)
        case .orderBuilder:
            try container.encode(true, forKey: .orderBuilder)
        case .orderCheckout:
            try container.encode(true, forKey: .orderCheckout)
        case .welcome:
            try container.encode(true, forKey: .welcome)
        case .calendar:
            try container.encode(true, forKey: .calendar)
        }
    }

}

extension SendMessageGroup: ExpressibleByArrayLiteral {
    typealias ArrayLiteralElement = SendMessage

    init(arrayLiteral elements: SendMessage...) {
        self = .array(elements)
    }
}
