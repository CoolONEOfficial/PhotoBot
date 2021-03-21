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
    
    static func adminNickname(for platform: AnyPlatform) -> String {
        switch platform {
        case .vk:
            return Self.vkAdminNickname
            
        case .tg:
            return Self.tgAdminNickname
        }
    }
    
    static let vkToken = Environment.get("VK_GROUP_TOKEN")!
    static let vkGroupId: UInt64? = {
        if let groupIdStr = Environment.get("VK_GROUP_ID"),
           let groupId = UInt64(groupIdStr) {
            return groupId
        }
        return nil
    }()
    
    #if DEBUG

    static let targetPlatform = Environment.get("TARGET_PLATFORM")!
    
    static let test: String = {
        
        let port: Int
        
        switch targetPlatform{
        case "TG":
            port = 8443
        
        case "VK":
            port = 80
    
        default:
            fatalError("Where is test platform env vars?")
        }
        
        let command = "ssh -R 80:localhost:\(port) localhost.run"
        
        let task = Process()
        let pipe = Pipe()
        task.standardOutput = pipe
        task.arguments = ["-c", command]
        task.launchPath = "/bin/zsh"
        task.launch()
        sleep(5)
        task.interrupt()
        
        let bgTask = Process()
        bgTask.arguments = ["-c", command]
        bgTask.launchPath = "/bin/zsh"
        bgTask.launch()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)!
        
        func matches(for regex: String, in text: String) -> [String] {

            do {
                let regex = try NSRegularExpression(pattern: regex)
                let results = regex.matches(in: text,
                                            range: NSRange(text.startIndex..., in: text))
                return results.map {
                    String(text[Range($0.range, in: text)!])
                }
            } catch let error {
                print("invalid regex: \(error.localizedDescription)")
                return []
            }
        }

        let res = matches(for: "\\S+(localhost.run)", in: output).first!

        return res
    }()
    
    static let vkWebhooksUrl: String = test
    static let tgWebhooksUrl: String = test
    
    #else
    
    static let vkWebhooksUrl: String = Environment.get("WEBHOOKS_VK_URL")!
    static let tgWebhooksUrl: String = Environment.get("WEBHOOKS_TG_URL")!
    
    #endif
    
    static let vkServerName: String? = Environment.get("VK_NEW_SERVER_NAME")
    
    static let tgWebhooksPort: Int = Int(Environment.get("WEBHOOKS_TG_PORT")!)!
}

// configures your application
public func configure(_ app: Application) throws {
    let controllers = try configurePostgres(app)
    //try configureEchoTg(app)
    //try configureEchoVk(app)
    //try configureEchoBotter(app)
    try configurePhotoBot(app, controllers)
    
    // register routes
    try routes(app)
}

private func configurePostgres(_ app: Application) throws -> [NodeController] {
    app.databases.use(try .postgres(url: Application.databaseURL), as: .psql)
    
    app.migrations.add([
        CreateEventPayloads(),
        CreateNodes(),
        CreateUsers(),
        CreatePlatformFiles(),
        CreateStylists(),
        CreateStylistPhotos(),
        CreateMakeupers(),
        CreateMakeuperPhotos(),
        CreateStudios(),
        CreatePromotions(),
        CreateStudioPhotos(),
        CreateOrders()
    ])

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
    
    let controllers: [NodeController] = [
        MainNodeController(),
        AboutNodeController(),
        ReviewsNodeController(),
        OrdersNodeController(),
        PortfolioNodeController(),
        UploadPhotoNodeController(),
        OrderCheckoutNodeController(),
        OrderTypesNodeController(),
        OrderBuilderDateNodeController(),
        OrderBuilderMainNodeController(),
        OrderBuilderMakeuperNodeController(),
        OrderBuilderStudioNodeController(),
        OrderBuilderStylistNodeController(),
        ChangeTextNodeController(),
        ShowcaseNodeController(),
        WelcomeNodeController(),
    ]
    
    if try NodeModel.query(on: app.db).count().wait() == 0 {
        
        for controller in controllers {
            try controller.create(app: app).throwingFlatMap { try $0.saveReturningId(app: app) }.wait()
        }

        let testPhoto = try PlatformFile.create(platformEntries: [
            .tg("AgACAgQAAxkDAAIHjGAyWdeuTYimywkuaJsCk6cnPBw_AAKIqDEb84k9Ulm1-biSJET0czAfGwAEAQADAgADbQADE8MBAAEeBA"),
            .vk("photo-119092254_457239065")
        ], type: .photo, app: app).throwingFlatMap { try $0.save(app: app) }.wait()
        
        let testPhoto2 = try PlatformFile.create(platformEntries: [
            .tg("AgACAgQAAxkDAAIHjGAyWdeuTYimywkuaJsCk6cnPBw_AAKIqDEb84k9Ulm1-biSJET0czAfGwAEAQADAgADbQADE8MBAAEeBA"),
            .vk("photo-119092254_457239065")
        ], type: .photo, app: app).throwingFlatMap { try $0.save(app: app) }.wait()
        
        for num in 1...20 {
            try Stylist.create(
                name: "Stylist \(num)", platformIds: [.tg(.init(id: 356008384, username: "cooloneofficial"))], photos: [testPhoto, testPhoto2], price: 123, app: app
            ).throwingFlatMap { try $0.save(app: app) }.wait()
        }
        
        for num in 1...20 {
            try Makeuper.create(
                name: "Makeuper \(num)", platformIds: [.tg(.init(id: 356008384, username: "cooloneofficial"))], photos: [testPhoto, testPhoto2], price: 123, app: app
            ).throwingFlatMap { try $0.save(app: app) }.wait()
        }
        
        for num in 1...3 {
            try Promotion.create(
                name: "Promo \(num)",
                description: "Promo desc",
                promocode: "PROMO\(num)",
                impact: .fixed(100),
                condition: .and([ .numeric(.price, .more, 500) ]),
                app: app
            ).throwingFlatMap { try $0.save(app: app) }.wait()
        }
        
        try Promotion.create(
            autoApply: true,
            name: "Скидка за второй заказ",
            description: "Promo desc",
            impact: .percents(5),
            condition: .numeric(.orderCount, .equals, 1),
            app: app
        ).throwingFlatMap { try $0.save(app: app) }.wait()
        
        try Promotion.create(
            autoApply: true,
            name: "Скидка за третий заказ",
            description: "Promo desc",
            impact: .percents(10),
            condition: .numeric(.orderCount, .equals, 2),
            app: app
        ).throwingFlatMap { try $0.save(app: app) }.wait()
        
        for num in 1...3 {
            try Studio.create(
                name: "Studio \(num)",
                description: "Studio desc",
                address: "adsdsad",
                coords: .init(lat: 0, long: 0),
                photos: [testPhoto], price: 123, app: app
            ).throwingFlatMap { try $0.save(app: app) }.wait()
        }
    }
    
    return controllers
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

//private func configureEchoBotter(_ app: Application) throws {
//    let bot = try EchoBot(settings: botterSettings(app), app: app)
//    try bot.updater.startWebhooks(vkServerName: Application.vkServerName).wait()
//}

private func configureEchoTg(_ app: Application) throws {
    let bot = try TgEchoBot(settings: tgSettings(app))
    try bot.updater.startWebhooks().wait()
}

private func configurePhotoBot(_ app: Application, _ controllers: [NodeController]) throws {
    let bot = try PhotoBot(settings: botterSettings(app), app: app, controllers: controllers)
    try bot.updater.startWebhooks(vkServerName: Application.vkServerName).wait()
}
