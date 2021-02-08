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
        let testNodeId = try Node(
            name: "Test node",
            messagesGroup: [
                .init(text: "Test message here."),
                .init(text: "And other message.")
            ]
            //action: .init(.buildType, success: .moveToBuilder(of: .init(type: NodeBuildable.self), object: <#[String : AnyCodable]#>))
        ).toModel!.saveWithId(on: app.db).wait()
        
        let createNodeId = try Node(
            systemic: true,
            name: "Create node",
            messagesGroup: .builder,
            action: .init(.createNode, success: .moveToBuilder(of: .node), failure: "Wrong text, please try again.")
        ).toModel!.saveWithId(on: app.db).wait()
        
        let welcomeNodeId = try Node(
            name: "Welcome node",
            messagesGroup: [
                .init(text: "Welcome to bot, $USER!", keyboard: .init([[
                    .init(text: "To test node", action: .callback, data: NavigationPayload.toNode(testNodeId))
                ]]))
            ],
            entryPoint: .welcome
        ).toModel!.saveWithId(on: app.db).wait()
        
        try Node(
            name: "Welcome guest node",
            messagesGroup: [
                .init(text: "Welcome to bot, newcomer! Please send your name.")
            ],
            entryPoint: .welcome_guest,
            action: .init(.setName, success: .moveToNode(id: welcomeNodeId), failure: "Wrong name, please try again.")
        ).toModel!.saveWithId(on: app.db).wait()
        
        try Node(
            systemic: true,
            name: "Change node text",
            messagesGroup: [ .init(text: "Send me new text") ],
            action: .init(.messageEdit, success: .pop, failure: "Wrong text, please try again.")
        ).toModel!.saveWithId(on: app.db).wait()

        //try BuilderTypeKind.configureNodeIds(app: app).wait()
        
    }
}

//@discardableResult
//private func createNode(_ app: Application, _ nodeModel: NodeModel) throws -> UUID {
//    try nodeModel.save(on: app.db).map { node.id! }.wait()
//}

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
