import Fluent
import FluentPostgresDriver
import Vapor
import TelegrammerMiddleware
import Telegrammer

extension Application {
    static var databaseURL = URL(string: Environment.get("DATABASE_URL")!)!
    static var tgToken = Environment.get("TELEGRAM_BOT_TOKEN")!
    static var vkToken = Enviroment.get("VK_GROUP_TOKEN")!
}

// configures your application
public func configure(_ app: Application) throws {
    //try configurePostgres(app)
    try configureTelegram(app)

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

private func configureTelegram(_ app: Application) throws {
    var settings = Bot.Settings(token: Application.tgToken)
    settings.webhooksConfig = .init(ip: "0.0.0.0", url: "https://65b5824069b4.ngrok.io", port: 8443)
    let bot = try DemoEchoBot(path: "bot", settings: settings)
    try bot.setWebhooks()

    app.middleware.use(bot)
    
    let wh = Webhooks(bot: bot.bot, dispatcher: bot.dispatcher)
    try wh.start()
}
