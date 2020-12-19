import Fluent
import FluentPostgresDriver
import Vapor
import TelegrammerMiddleware
import Telegrammer
import Vkontakter
import VkontakterMiddleware
import Botter

extension Application {
    static var databaseURL = URL(string: Environment.get("DATABASE_URL")!)!
    static var tgToken = Environment.get("TELEGRAM_BOT_TOKEN")!
    static var vkToken = Environment.get("VK_GROUP_TOKEN")!
    static var vkGroupId: UInt64? = {
        if let groupIdStr = Environment.get("VK_GROUP_ID"),
           let groupId = UInt64(groupIdStr) {
            return groupId
        }
        return nil
    }()
    static var serverName: String? = Environment.get("VK_NEW_SERVER_NAME")
    static var vkWebhooksUrl: String = Environment.get("WEBHOOKS_VK_URL")!
    static var tgWebhooksUrl: String = Environment.get("WEBHOOKS_TG_URL")!
    static var tgWebhooksPort: Int = Int(Environment.get("WEBHOOKS_TG_PORT")!)!
}

// configures your application
public func configure(_ app: Application) throws {
    //try configurePostgres(app)
    //try configureTelegram(app)
    //try configureVk(app)
    try configureBotter(app)

    //Todo(title: "Publish new article tomorrow").save(on: app.db)
    
    // register routes
    try routes(app)
}

private func configurePostgres(_ app: Application) throws {
    app.databases.use(try .postgres(url: Application.databaseURL), as: .psql)

    app.migrations.add(CreateTodo())
    if app.environment == .development {
        try app.autoMigrate().wait()
    }

}

//private func configureVk(_ app: Application) throws {
//    var settings: Vkontakter.Bot.Settings = .init(token: Application.vkToken, debugMode: !app.environment.isRelease)
//    settings.webhooksConfig = .init(ip: "0.0.0.0", url: Application.webhooksUrl, port: Application.webhooksPort, groupId: Application.vkGroupId)
//    let bot = try VkEchoBot(path: "vk", settings: settings)
//    try bot.setWebhooks(Application.serverName).whenFailure { err in
//        debugPrint("ERROR: \(err)")
//    }
//
//    app.middleware.use(bot)
//
//    let wh = Webhooks(bot: bot.bot, dispatcher: bot.dispatcher)
//    try wh.start()
//}

private func configureBotter(_ app: Application) throws {
    var tgSettings = Telegrammer.Bot.Settings(token: Application.tgToken, debugMode: !app.environment.isRelease)
    tgSettings.webhooksConfig = .init(ip: "0.0.0.0", baseUrl: Application.tgWebhooksUrl, port: Application.tgWebhooksPort)

    var vkSettings: Vkontakter.Bot.Settings = .init(token: Application.vkToken, debugMode: !app.environment.isRelease)
    vkSettings.webhooksConfig = .init(ip: "0.0.0.0", baseUrl: Application.vkWebhooksUrl, groupId: Application.vkGroupId)

    let settings: Botter.Bot.Settings = .init(
        vk: vkSettings,
        tg: tgSettings
    )
//    settings.webhooksConfig = .init(ip: "0.0.0.0", url: Application.webhooksUrl, port: Application.webhooksPort, groupId: Application.vkGroupId)
    let bot = try EchoBot(settings: settings)
    try bot.setWebhooks(Application.serverName, app.eventLoopGroup.next()).whenFailure { err in
        debugPrint("ERROR on set wh: \(err.localizedDescription)")
    }

    app.middleware.use(bot)

    let wh = Botter.Webhooks(bot: bot.bot, dispatcher: bot.dispatcher)
    try wh.start().whenFailure { err in
        debugPrint("ERROR on start wh: \(err.localizedDescription)")
    }
    
//    let wh = Telegrammer.Webhooks(bot: bot.bot.tg!, dispatcher: bot.dispatcher.tg!)
//    try wh.start()
}

private func configureTelegram(_ app: Application) throws {
    var settings: Telegrammer.Bot.Settings = .init(token: Application.tgToken, debugMode: !app.environment.isRelease)
    settings.webhooksConfig = .init(ip: "0.0.0.0", url: Application.tgWebhooksUrl + "/tg", port: Application.tgWebhooksPort)
    let bot = try TgEchoBot(path: "tg", settings: settings) // change to tg
    try bot.setWebhooks()

    app.middleware.use(bot)

    let wh = Webhooks(bot: bot.bot, dispatcher: bot.dispatcher)
    try wh.start()
}
