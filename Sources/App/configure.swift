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
    static var tgToken = Environment.get("TELEGRAM_BOT_TOKEN")!
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
    if app.environment == .development {
        try app.autoMigrate().wait()
    }

    if try NodeModel.query(on: app.db).count().wait() == 0 {
        let testNodeId = try createNode(app, NodeModel(
            name: "Test node",
            messages: [
                .init(message: "Test message here."),
                .init(message: "And other message.")
            ]
        ))
        
        let welcomeNodeId = try createNode(app, NodeModel(
            name: "Welcome node",
            messages: [
                .init(message: "Welcome to bot, $USER!", keyboard: .init(oneTime: false, buttons: [[
                    .init(text: "To test node", action: .callback, data: NavigationPayload.toNode(testNodeId))
                ]], inline: true))
            ],
            entryPoint: .welcome
        ))
        
        let welcomeGuestNodeId = try createNode(app, NodeModel(
            name: "Welcome guest node",
            messages: [
                .init(message: "Welcome to bot, newcomer! Please send your name.")
            ],
            entryPoint: .welcome_guest,
            action: .init(.set_name, success:.moveToNode(id: welcomeNodeId), failure: "Wrong name, please try again.")
        ))
        
        try createNode(app, NodeModel(
            systemic: true,
            name: "Change node text",
            messages: [ .init(message: "Send me new text") ],
            action: .init(.message_edit, success: .pop, failure: "Wrong text, please try again.")
        ))
        
    }
}

@discardableResult
private func createNode(_ app: Application, _ node: NodeModel) throws -> UUID {
    try node.save(on: app.db).map { node.id! }.wait()
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
