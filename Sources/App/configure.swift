import Fluent
import FluentPostgresDriver
import Vapor
import TelegrammerMiddleware
import Telegrammer
import Vkontakter
import VkontakterMiddleware
import Botter

extension Application {
    static let databaseURL: URL = URL(string: Environment.get("DATABASE_URL")!)!
    static let tgToken = Environment.get("TG_BOT_TOKEN")!
    static let tgBufferUserId = Int64(Environment.get("TG_BUFFER_USER_ID")!)!
    static let vkBufferUserId = Int64(Environment.get("VK_BUFFER_USER_ID")!)!
    static let vkAdminNickname: String = Environment.get("VK_ADMIN_NICKNAME")!
    static let tgAdminNickname: String = Environment.get("TG_ADMIN_NICKNAME")!
    static let vkToken = Environment.get("VK_GROUP_TOKEN")!
    static let vkGroupId: UInt64? = {
        if let groupIdStr = Environment.get("VK_GROUP_ID"),
           let groupId = UInt64(groupIdStr) {
            return groupId
        }
        return nil
    }()
    static let vkServerName: String? = Environment.get("VK_NEW_SERVER_NAME")
    static let vkWebhooksUrl: String = Environment.get("WEBHOOKS_VK_URL")!
    static let tgWebhooksUrl: String = Environment.get("WEBHOOKS_TG_URL")!
    static let tgWebhooksPort: Int = Int(Environment.get("WEBHOOKS_TG_PORT")!)!
}

// configures your application
public func configure(_ app: Application) throws {
    try configurePostgres(app)
    //try configureEchoTg(app)
    //try configureEchoVk(app)
    //try configureEchoBotter(app)
    try configurePhotoBot(app)
    
    // register routes
    try routes(app)
}

private func configurePostgres(_ app: Application) throws {
    app.databases.use(try .postgres(url: Application.databaseURL), as: .psql)

    app.migrations.add(CreateNodes())
    app.migrations.add(CreateUsers())
    app.migrations.add(CreatePlatformFiles())
    app.migrations.add(CreateStylists())
    app.migrations.add(CreateStylistPhotos())
    app.migrations.add(CreateMakeupers())
    app.migrations.add(CreateMakeuperPhotos())
    app.migrations.add(CreateStudios())
    app.migrations.add(CreatePromotions())
    app.migrations.add(CreateStudioPhotos())
    if app.environment == .development {
        try app.autoMigrate().wait()
    }
    
    //print("Drop all tables? (y or n)") TODO: drop tables on restart
    
//    if let name = readLine(), name.contains("y") {
//        print("Dropping tables...")
//
//        try app.db.execute(enum: <#T##DatabaseEnum#>)(query: DatabaseQuery(schema: "DROP TABLE nodes, users, _fluent_migrations CASCADE"), onOutput: {_ in}).wait()
//        fatalError()
//    } else {
//        print("Ok, just start with previous db state")
//    }
    
    
    
    if try NodeModel.query(on: app.db).count().wait() == 0 {
        
        let welcomeNodeId = try mainGroup(app)

        let test = try PlatformFile.create(platformEntries: [
            .tg("AgACAgQAAxkDAAIHjGAyWdeuTYimywkuaJsCk6cnPBw_AAKIqDEb84k9Ulm1-biSJET0czAfGwAEAQADAgADbQADE8MBAAEeBA"),
            .vk("photo-119092254_457239065")
        ], type: .photo, app: app).throwingFlatMap { try $0.save(app: app) }.wait()
        
        for num in 1...20 {
            try Stylist.create(
                name: "Stylist \(num)", photos: [test], app: app
            ).throwingFlatMap { try $0.save(app: app) }.wait()
        }
        
        for num in 1...20 {
            try Makeuper.create(
                name: "Makeuper \(num)", photos: [test], app: app
            ).throwingFlatMap { try $0.save(app: app) }.wait()
        }
        
        for num in 1...3 {
            try Promotion.create(
                name: "Promo \(num)",
                description: "Promo desc",
                app: app
            ).throwingFlatMap { try $0.save(app: app) }.wait()
        }
        
        for num in 1...3 {
            try Studio.create(
                name: "Studio \(num)",
                description: "Studio desc",
                address: "adsdsad",
                coords: .init(lat: 0, long: 0),
                photos: [test], app: app
            ).throwingFlatMap { try $0.save(app: app) }.wait()
        }

        let showcaseNodeId = try Node.create(
            name: "Showcase node",
            messagesGroup: [
                .init(text: "Тут описание бота в деталях.", keyboard: [[
                    .init(text: "Перейти в главное меню", action: .callback, eventPayload: .push(.entryPoint(.welcome)))
                ]])
            ], app: app
        ).throwingFlatMap { try $0.saveReturningId(app: app) }.wait()
        
        try Node.create(
            name: "Welcome guest node",
            messagesGroup: [
                .init(text: "Привет, $USER! Похоже ты тут впервые) Хочешь узнать что делает этот бот?", keyboard: [[
                    .init(text: "Да", action: .callback, eventPayload: .push(.id(showcaseNodeId))),
                    .init(text: "Нет", action: .callback, eventPayload: .push(.entryPoint(.welcome)))
                ]])
            ],
            //action: .init(.setName, success: .push(id: showcaseNodeId), failure: "Wrong name, please try again.")
            entryPoint: .welcomeGuest, app: app
        ).throwingFlatMap { try $0.saveReturningId(app: app) }.wait()
        
        try Node.create(
            systemic: true,
            name: "Change static node text node",
            messagesGroup: [ .init(text: "Пришли мне новый текст") ],
            action: .init(.messageEdit, success: .pop), app: app
        ).throwingFlatMap { try $0.saveReturningId(app: app) }.wait()
        
    }
}

func mainGroup(_ app: Application) throws -> UUID {
    let uploadPhotoNodeId = try Node.create(
        name: "Upload photo node",
        messagesGroup: [
            .init(text: "Пришли мне прямую ссылку.")
        ],
        action: .init(.uploadPhoto), app: app
    ).throwingFlatMap { try $0.saveReturningId(app: app) }.wait()
    
    let aboutNodeId = try Node.create(
        name: "About node",
        messagesGroup: [
            .init(text: "Test message here."),
            .init(text: "And other message.")
        ], app: app
    ).throwingFlatMap { try $0.saveReturningId(app: app) }.wait()
    
    let portfolioNodeId = try Node.create(
        name: "Portfolio node",
        messagesGroup: [
            .init(text: "Test message here.")
        ], app: app
    ).throwingFlatMap { try $0.saveReturningId(app: app) }.wait()
    
    let orderMainNodeId = try orderBuilderGroup(app)

    return try Node.create(
        name: "Welcome node",
        messagesGroup: [
            .init(text: "Добро пожаловать, $USER! Выбери секцию чтобы в нее перейти.", keyboard: [
                [
                    .init(text: "Обо мне", action: .callback, eventPayload: .push(.id(aboutNodeId))),
                    .init(text: "Мои работы", action: .callback, eventPayload: .push(.id(portfolioNodeId))),
                ],
                [
                    .init(text: "Заказ фотосессии", action: .callback, eventPayload: .push(.id(orderMainNodeId))),
                    .init(text: "Выгрузить фотку", action: .callback, eventPayload: .push(.id(uploadPhotoNodeId)))
                ]
            ])
        ],
        entryPoint: .welcome, app: app
    ).throwingFlatMap { try $0.saveReturningId(app: app) }.wait()
}

func orderBuilderGroup(_ app: Application) throws -> UUID {
    let stylistNodeId = try Node.create(
        name: "Order builder stylist node",
        messagesGroup: .list(.stylists),
        entryPoint: .orderBuilderStylist, app: app
    ).throwingFlatMap { try $0.saveReturningId(app: app) }.wait()
    
    let makeuperNodeId = try Node.create(
        name: "Order builder makeuper node",
        messagesGroup: .list(.makeupers),
        entryPoint: .orderBuilderMakeuper, app: app
    ).throwingFlatMap { try $0.saveReturningId(app: app) }.wait()
    
    let studioNodeId = try Node.create(
        name: "Order builder studio node",
        messagesGroup: .list(.studios),
        entryPoint: .orderBuilderStudio, app: app
    ).throwingFlatMap { try $0.saveReturningId(app: app) }.wait()
    
    let finishNodeId = try Node.create(
        name: "Order finish node",
        messagesGroup: [
            .init(text: "Заказ успешно создан, в ближайшее время с Вами свяжется @$ADMIN")
        ],
        entryPoint: .orderFinish, app: app
    ).throwingFlatMap { try $0.saveReturningId(app: app) }.wait()

    try Node.create(
        name: "Order checkout node",
        messagesGroup: .orderCheckout,
        entryPoint: .orderCheckout, app: app
    ).throwingFlatMap { try $0.saveReturningId(app: app) }.wait()
    
    return try Node.create(
        name: "Order builder main node",
        messagesGroup: .orderBuilder,
        entryPoint: .orderBuilder, app: app
    ).throwingFlatMap { try $0.saveReturningId(app: app) }.wait()
}

func tgSettings(_ app: Application) -> Telegrammer.Bot.Settings {
    var tgSettings = Telegrammer.Bot.Settings(token: Application.tgToken, debugMode: !app.environment.isRelease)
    tgSettings.webhooksConfig = .init(ip: "0.0.0.0", baseUrl: Application.tgWebhooksUrl, port: Application.tgWebhooksPort)
    return tgSettings
}

func vkSettings(_ app: Application) -> Vkontakter.Bot.Settings {
    var vkSettings: Vkontakter.Bot.Settings = .init(token: Application.vkToken, debugMode: !app.environment.isRelease)
    vkSettings.webhooksConfig = .init(ip: "0.0.0.0", baseUrl: Application.vkWebhooksUrl, groupId: Application.vkGroupId)
    return vkSettings
}

func botterSettings(_ app: Application) -> Botter.Bot.Settings {
    .init(
        vk: vkSettings(app),
        tg: tgSettings(app)
    )
}

private func configureEchoVk(_ app: Application) throws {
    let bot = try VkEchoBot(settings: vkSettings(app))
    try bot.updater.startWebhooks(serverName: Application.vkServerName).wait()
}

private func configureEchoBotter(_ app: Application) throws {
    let bot = try EchoBot(settings: botterSettings(app), app: app)
    try bot.updater.startWebhooks(vkServerName: Application.vkServerName).wait()
}

private func configureEchoTg(_ app: Application) throws {
    let bot = try TgEchoBot(settings: tgSettings(app))
    try bot.updater.startWebhooks().wait()
}

private func configurePhotoBot(_ app: Application) throws {
    let bot = try PhotoBot(settings: botterSettings(app), app: app)
    try bot.updater.startWebhooks(vkServerName: Application.vkServerName).wait()
}
