import Fluent
import FluentPostgresDriver
import Vapor
import TelegrammerMiddleware
import Telegrammer
import Vkontakter
import VkontakterMiddleware
import Botter

extension Application {
    static var databaseURL: URL = URL(string: Environment.get("DATABASE_URL")!)!
    static var tgToken = Environment.get("TG_BOT_TOKEN")!
    static var tgBufferUserId = Int64(Environment.get("TG_BUFFER_USER_ID")!)!
    static var vkBufferUserId = Int64(Environment.get("VK_BUFFER_USER_ID")!)!
    static var vkToken = Environment.get("VK_GROUP_TOKEN")!
    static var vkGroupId: UInt64? = {
        if let groupIdStr = Environment.get("VK_GROUP_ID"),
           let groupId = UInt64(groupIdStr) {
            return groupId
        }
        return nil
    }()
    static var vkServerName: String? = Environment.get("VK_NEW_SERVER_NAME")
    static var vkWebhooksUrl: String = Environment.get("WEBHOOKS_VK_URL")!
    static var tgWebhooksUrl: String = Environment.get("WEBHOOKS_TG_URL")!
    static var tgWebhooksPort: Int = Int(Environment.get("WEBHOOKS_TG_PORT")!)!
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

        let test = try PlatformFile(platform: [
            .tg("AgACAgQAAxkDAAIHjGAyWdeuTYimywkuaJsCk6cnPBw_AAKIqDEb84k9Ulm1-biSJET0czAfGwAEAQADAgADbQADE8MBAAEeBA"),
            .vk("photo-119092254_457239065")
        ], type: .photo).toModel(app: app).wait()
        
        for num in 1...20 {
            try Stylist(
                name: "Stylist \(num)", photos: [try test.toMyType()]
            ).toModel(app: app).wait()
        }
        
        for num in 1...20 {
            try Makeuper(
                name: "Makeuper \(num)", photos: [try test.toMyType()]
            ).toModel(app: app).wait()
        }

        let showcaseNodeId = try Node(
            name: "Showcase node",
            messagesGroup: [
                .init(text: "Тут описание бота в деталях.", keyboard: [[
                    .init(text: "Перейти в главное меню", action: .callback, eventPayload: .toNode(welcomeNodeId))
                ]])
            ]
        ).toModelWithId(app: app).wait()
        
        try Node(
            name: "Welcome guest node",
            messagesGroup: [
                .init(text: "Привет, $USER! Похоже ты тут впервые) Хочешь узнать что делает этот бот?", keyboard: [[
                    .init(text: "Да", action: .callback, eventPayload: .toNode(showcaseNodeId)),
                    .init(text: "Нет", action: .callback, eventPayload: .toNode(welcomeNodeId))
                ]])
            ],
            //action: .init(.setName, success: .moveToNode(id: showcaseNodeId), failure: "Wrong name, please try again.")
            entryPoint: .welcomeGuest
        ).toModelWithId(app: app).wait()
        
        try Node(
            systemic: true,
            name: "Изменить текст сообщения",
            messagesGroup: [ .init(text: "Пришли мне новый текст") ],
            action: .init(.messageEdit, success: .pop)
        ).toModelWithId(app: app).wait()
        
    }
}

func mainGroup(_ app: Application) throws -> UUID {
    let uploadPhotoNodeId = try Node(
        name: "Upload photo node",
        messagesGroup: [
            .init(text: "Пришли мне прямую ссылку.")
        ],
        action: .init(.uploadPhoto)
    ).toModelWithId(app: app).wait()
    
    let aboutNodeId = try Node(
        name: "About node",
        messagesGroup: [
            .init(text: "Test message here."),
            .init(text: "And other message.")
        ]
    ).toModelWithId(app: app).wait()
    
    let portfolioNodeId = try Node(
        name: "Portfolio node",
        messagesGroup: [
            .init(text: "Test message here.")
        ]
    ).toModelWithId(app: app).wait()
    
    let orderMainNodeId = try orderBuilderGroup(app)
    
//        try Node(
//            systemic: true,
//            name: "Create node",
//            messagesGroup: .builder,
//            action: .init(.createNode, success: .moveToBuilder(of: .node), failure: "Wrong text, please try again.")
//        ).toModel().saveWithId(on: app.db).wait()
    
    return try Node(
        name: "Welcome node",
        messagesGroup: [
            .init(text: "Добро пожаловать, $USER! Выбери секцию чтобы в нее перейти.", keyboard: [
                [
                    .init(text: "Обо мне", action: .callback, eventPayload: .toNode(aboutNodeId)),
                    .init(text: "Мои работы", action: .callback, eventPayload: .toNode(portfolioNodeId)),
                ],
                [
                    .init(text: "Создание заявки", action: .callback, eventPayload: .toNode(orderMainNodeId)),
                    .init(text: "Выгрузить фотку", action: .callback, eventPayload: .toNode(uploadPhotoNodeId))
                ]
            ])
        ],
        entryPoint: .welcome
    ).toModelWithId(app: app).wait()
}

func orderBuilderGroup(_ app: Application) throws -> UUID {
    let stylistNodeId = try Node(
        name: "Order builder stylist node",
        messagesGroup: .list(.stylists)
    ).toModelWithId(app: app).wait()
    
    let makeuperNodeId = try Node(
        name: "Order builder makeuper node",
        messagesGroup: .list(.makeupers)
    ).toModelWithId(app: app).wait()
    
    return try Node(
        name: "Order builder main node",
        messagesGroup: .orderBuilder(stylistNodeId, makeuperNodeId),
        entryPoint: .orderBuilder
    ).toModelWithId(app: app).wait()
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
