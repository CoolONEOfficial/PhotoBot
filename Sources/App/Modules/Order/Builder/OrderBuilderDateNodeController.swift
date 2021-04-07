//
//  File.swift
//  
//
//  Created by Nickolay Truhin on 20.03.2021.
//

import Foundation
import Botter
import Vapor
import SwiftyChrono

class OrderBuilderDateNodeController: NodeController {
    func create(app: Application) throws -> EventLoopFuture<Node> {
        Node.create(
            name: "Order builder date node",
            messagesGroup: .calendar,
            entryPoint: .orderBuilderDate,
            action: .init(.handleCalendar), app: app
        )
    }
    
    func getSendMessages(platform: AnyPlatform, in node: Node, _ payload: NodePayload?, context: PhotoBotContextProtocol, group: SendMessageGroup) throws -> EventLoopFuture<[SendMessage]>? {
        guard case .calendar = group else { return nil }
        
        let app = context.app
        
        let calendar = Calendar.current
        let currentDate = Date()
        var (year, month) = (currentDate.component(.year)!, currentDate.component(.month)!)
        var day: Int?
        var time: TimeInterval?
        var needsConfirm = false
        
        if case let .calendar(payloadYear, payloadMonth, payloadDay, payloadTime, payloadNeedsConfirm) = payload {
            year = payloadYear
            month = payloadMonth
            day = payloadDay
            time = payloadTime
            needsConfirm = payloadNeedsConfirm
        }
        
        var date = DateComponents.create(year: year, month: month, day: day).date!
        if let time = time {
            date.addTimeInterval(time)
        }

        if needsConfirm {
            if let time = time {
                return app.eventLoopGroup.future([
                    .init(text: "Было считано время \(date.toString(dateStyle: .none, timeStyle: .short)). Все верно?", keyboard: [[
                        try .init(text: "Да", action: .callback, eventPayload: .selectTime(time: time))
                    ]]),
                ])
            } else {
                return app.eventLoopGroup.future([
                    .init(text: "Была считана дата \(date.toString(dateStyle: .long, timeStyle: .none)) Все верно?", keyboard: [[
                        try .init(text: "Да", action: .callback, eventPayload: .selectDay(date: date))
                    ]]),
                ])
            }
        } else if time != nil {
            return app.eventLoopGroup.future([
                .init(text: "Выберите продолжительность для \(date.toString(style: .short)):", keyboard: [[
                    try .init(text: "30 минут", action: .callback, eventPayload: .selectDuration(duration: 60*30)),
                    try .init(text: "1 час", action: .callback, eventPayload: .selectDuration(duration: 60*60)),
                    try .init(text: "2 часа", action: .callback, eventPayload: .selectDuration(duration: 60*60*2))
                ]])//,
//                .init(text: "Полчаса\nза полчаса можно тото", keyboard: [[
//                    try .init(text: "Выбрать", action: .callback, eventPayload: .selectDuration(duration: 60*30))
//                ]]),
//                .init(text: "Час\nза час можно тото", keyboard: [[
//                    try .init(text: "Выбрать", action: .callback, eventPayload: .selectDuration(duration: 60*60))
//                ]]),
//                .init(text: "Два часа\nза два часа можно тото", keyboard: [[
//                    try .init(text: "Выбрать", action: .callback, eventPayload: .selectDuration(duration: 60*60*2))
//                ]])
            ])
        
        } else if day != nil {
            
            switch platform {
            case .vk:
                return app.eventLoopGroup.future([.init(text: "Пришли желаемое время")])

            case .tg:
                let startOfDay = Date().dateFor(.startOfDay)
                let availableInterval = startOfDay.adjust(.hour, offset: 8)...startOfDay.adjust(.hour, offset: 24)
                let timesMessages = try availableInterval.intervalDates(.minute, 30)
                    .map { ($0, $0.timeIntervalSince(startOfDay)) }
                    .map { (date, time) in
                    try Button(
                        text: date.toString(dateStyle: .none, timeStyle: .short),
                        action: .callback,
                        eventPayload: .selectTime(time: time)
                    )
                }.chunked(into: 6)
                
                let headers = [ "Утро", "День", "Вечер" ]
                
                let groupsMessages = timesMessages.chunked(into: timesMessages.count / 3).enumerated()
                    .map { (Button(text: headers[$0.0]), $0.1) }
                    .map { [[$0.0]] + $0.1 }
                    .reduce([], +)

                return app.eventLoopGroup.future([
                    .init(text: "Выбери или пришли время для \(date.toString(dateStyle: .long, timeStyle: .none))", keyboard: .init(buttons: groupsMessages))
                ])
            }
        }
        
        switch platform {
        case .vk:
            return app.eventLoopGroup.future([.init(text: "Пришли желаемую дату")])
            
        case .tg:
            
            let startMonth = date.dateFor(.startOfMonth)
            let startTable = startMonth.adjust(.day, offset: -calendar.weekday(date: startMonth))

            let endMonth = startMonth.adjust(.month, offset: 1).adjust(.day, offset: -1)
            let endTable = endMonth.adjust(.day, offset: 6 - calendar.weekday(date: endMonth))
            
            let formatter = DateFormatter()
            let weekdayMessages = formatter.veryShortWeekdaySymbols
                .shift(withDistance: calendar.firstWeekday - 1).compactMap { weekday in
                Button(text: weekday)
            }
            let daysMessages = try (startTable...endTable).intervalDates(.day, 1).map { date in
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
                .init(text: "Выбери или пришли дату", keyboard: .init(buttons: [
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
    
    func handleAction(_ action: NodeAction, _ message: Message, context: PhotoBotContextProtocol) throws -> EventLoopFuture<Result<Void, HandleActionError>>? {
        guard case .handleCalendar = action.type, let text = message.text else { return nil }
        let (user, app) = (context.user, context.app)

        if var date = Chrono().parseDate(text: text) {
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
                    ), to: message, saveMove: false, context: context).map { _ in .success }
                }
            } else if case let .calendar(year, month, day, time, _) = user.nodePayload, time == nil {
                
                return user.push(.entryPoint(.orderBuilderDate), payload: .calendar(
                    year: year, month: month, day: day,
                    time: date.timeIntervalSince(date.dateFor(.startOfDay)),
                    needsConfirm: true
                ), to: message, saveMove: false, context: context).map { _ in .success }
            }
        }
        return app.eventLoopGroup.future(.failure(.dateNotHandled))
    }
    
    func handleEventPayload(_ event: MessageEvent, _ eventPayload: EventPayload, _ replyText: inout String, context: PhotoBotContextProtocol) throws -> EventLoopFuture<[Message]>? {
        let user = context.user
        
        switch eventPayload {
        case let .selectTime(time):
            guard case let .calendar(year, month, day, _, _) = user.nodePayload else { throw HandleActionError.nodePayloadInvalid }
            replyText = "Selected"
            return user.push(.entryPoint(.orderBuilderDate), payload: .calendar(year: year, month: month, day: day, time: time), to: event, saveMove: false, context: context)
            
        case let .selectDay(date):
            replyText = "Selected"
            let comps = Calendar.current.dateComponents([.year, .month, .day], from: date)
            guard let (year, month, day) = (comps.year, comps.month, comps.day) as? (Int, Int, Int) else { throw HandleActionError.eventPayloadInvalid }
            return user.push(.entryPoint(.orderBuilderDate), payload: .calendar(year: year, month: month, day: day), to: event, saveMove: false, context: context)
        
        case let .selectDuration(duration):
            replyText = "Selected"

            guard case let .calendar(year, month, day, time, _) = user.nodePayload,
                  let (hour, minute, _) = time?.components,
                  let date = DateComponents.create(year: year, month: month, day: day, hour: hour, minute: minute).date else { throw HandleActionError.nodePayloadInvalid }
            
            return user.push(.entryPoint(.orderBuilder), payload: .orderBuilder(.init(with: user.history.last?.nodePayload, date: date, duration: duration)), to: event, saveMove: false, context: context)
            
        default:
            return nil
        }
    }
}
