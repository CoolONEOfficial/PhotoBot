import Fluent
import FluentPostgresDriver
import Vapor
import TelegrammerMiddleware
import Telegrammer
import Vkontakter
import VkontakterMiddleware
import Botter
import SwiftyChrono

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

    static let targetPlatform: String = Environment.get("TARGET_PLATFORM")!
    
    static let test: String = {
        
        debugPrint("Starting localhost process...")
        
        let port: Int
        
        switch targetPlatform{
        case "TG":
            port = tgWebhooksPort
        
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

        let res = matches(for: "\\S+(localhost.run)", in: output).last!

        return res
    }()
    
    static let vkWebhooksUrl: String = test
    static let tgWebhooksUrl: String = test
    
    #else
    
    static let vkWebhooksUrl: String = Environment.get("WEBHOOKS_VK_URL")!
    static let tgWebhooksUrl: String = Environment.get("WEBHOOKS_TG_URL")!
    
    #endif
    
    static let vkServerName: String? = Environment.get("VK_NEW_SERVER_NAME")
    
    #if DEBUG
    static let tgWebhooksPort: Int = Int(Environment.get("WEBHOOKS_TG_PORT")!)!
    #else
    static let tgWebhooksPort: Int = Int(Environment.get("PORT")!)!
    #endif
}

// configures your application
public func configure(_ app: Application) throws {
    Chrono.preferredLanguage = .russian
    
    let controllers = try configurePostgres(app)
    //try configureEchoTg(app)
    //try configureEchoVk(app)
    //try configureEchoBotter(app)
    try configurePhotoBot(app, controllers)
    
    // register routes
    try routes(app)
}

private func configurePostgres(_ app: Application) throws -> [NodeController] {
    var postgresConfig = PostgresConfiguration(url: Application.databaseURL)!
    postgresConfig.tlsConfiguration = .forClient(certificateVerification: .none)
    app.databases.use(.postgres(configuration: postgresConfig), as: .psql)
    
    app.migrations.add([
        CreateNodes(),
        CreatePlatformFiles(),
        CreateStylists(),
        CreateStylistPhotos(),
        CreateMakeupers(),
        CreateMakeuperPhotos(),
        CreatePhotographers(),
        CreatePhotographerPhotos(),
        CreateUsers(),
        CreateEventPayloads(),
        CreateStudios(),
        CreatePromotions(),
        CreateStudioPhotos(),
        CreateOrders(),
        CreateOrderPromotions(),
        CreateReviews(),
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
        
        let reviewPhotos: [PlatformFileModel] = [
            try PlatformFile.create(platformEntries: [
                .tg("AgACAgIAAxkBAAIdMGBpsjawdLtVu2FT22IWVBHb1rNrAAKIszEbMbpRS9e8uuCD16jMUS4lmy4AAwEAAwIAA3gAA-bbBQABHgQ"),
                .vk("photo-119092254_457239082")
            ], type: .photo, app: app).throwingFlatMap { try $0.save(app: app) }.wait(),
            try PlatformFile.create(platformEntries: [
                .tg("AgACAgIAAxkBAAIdL2BpsjbtHwj2a29Gdhk6WPvNPgvAAAKHszEbMbpRS7FEamIW-ryVFm9Yoi4AAwEAAwIAA3gAA863AAIeBA"),
                .vk("photo-119092254_457239081")
            ], type: .photo, app: app).throwingFlatMap { try $0.save(app: app) }.wait(),
            try PlatformFile.create(platformEntries: [
                .tg("AgACAgIAAxkBAAIdMWBpsjZoqvgM72INK3ymYHT3S6k4AAKJszEbMbpRS902COwTqrpYDk-poi4AAwEAAwIAA3gAA5KwAAIeBA"),
                .vk("photo-119092254_457239083")
            ], type: .photo, app: app).throwingFlatMap { try $0.save(app: app) }.wait(),
            try PlatformFile.create(platformEntries: [
                .tg("AgACAgIAAxkBAAIdMmBpsjZGg6Oy50xOp3ybEU5xRhDFAAKKszEbMbpRS5h1SO6J-3HzLF_9ni4AAwEAAwIAA3gAAwyiAgABHgQ"),
                .vk("photo-119092254_457239084")
            ], type: .photo, app: app).throwingFlatMap { try $0.save(app: app) }.wait(),
            try PlatformFile.create(platformEntries: [
                .tg("AgACAgIAAxkBAAIdM2BpsjYqTOyqKdf9GSV9-SESc1nCAAKLszEbMbpRS4rBPnQ4N4MeoZKboi4AAwEAAwIAA3gAA-KeAAIeBA"),
                .vk("photo-119092254_457239085")
            ], type: .photo, app: app).throwingFlatMap { try $0.save(app: app) }.wait(),
            try PlatformFile.create(platformEntries: [
                .tg("AgACAgIAAxkBAAIdNWBpsja0j9IW3lQi-wfQgGMU2usEAAKNszEbMbpRSwYswZ_hjzmuXl2Poi4AAwEAAwIAA3gAA2K9AAIeBA"),
                .vk("photo-119092254_457239086")
            ], type: .photo, app: app).throwingFlatMap { try $0.save(app: app) }.wait(),
        ]

        try reviewPhotos.map {
            try Review.create(screenshot: $0, app: app).throwingFlatMap { try $0.save(app: app) }.wait()
        }
        
        let coolonePlatformIds: [TypedPlatform<UserPlatformId>] = [.tg(.init(id: 356008384, username: "cooloneofficial"))]
        let nastyaPlatformIds: [TypedPlatform<UserPlatformId>] = [.tg(.init(id: 975594669, username: "nastyatsareva"))]
        
        var stylists: [StylistModel] = []
        for num in 1...20 {
            stylists.append(try Stylist.create(
                name: "Stylist \(num)", platformIds: coolonePlatformIds, photos: [testPhoto, testPhoto2], prices: [
                    .loveStory: Float(50 * num),
                    .content: Float(51 * num),
                    .family: Float(52 * num)
                ], app: app
            ).throwingFlatMap { try $0.save(app: app) }.wait())
        }
        
        var makeupers: [MakeuperModel] = []
        for num in 1...20 {
            makeupers.append(try Makeuper.create(
                name: "Makeuper \(num)", platformIds: coolonePlatformIds, photos: [testPhoto, testPhoto2], prices: [
                    .loveStory: Float(50 * num),
                    .content: Float(51 * num),
                    .family: Float(52 * num)
                ], app: app
            ).throwingFlatMap { try $0.save(app: app) }.wait())
        }

        let photographer = try Photographer.create(
            name: "Настя Царева", platformIds: nastyaPlatformIds, photos: [testPhoto, testPhoto2], prices: [
                .loveStory: Float(1000),
                .content: Float(800),
                .family: Float(2500)
            ], app: app
        ).throwingFlatMap { try $0.save(app: app) }.wait()
        
        try UserModel.create(history: [], nodeId: nil, nodePayload: nil, platformIds: coolonePlatformIds, isAdmin: true, firstName: "Николай", lastName: "Трухин", stylist: stylists.first, app: app).wait()
        
        try UserModel.create(history: [], nodeId: nil, nodePayload: nil, platformIds: nastyaPlatformIds, isAdmin: true, firstName: "Nastya", lastName: "Tsareva", makeuper: makeupers.first, photographer: photographer, app: app).wait()
        
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
                photos: [testPhoto], prices: [
                    .loveStory: Float(50 * num),
                    .content: Float(51 * num),
                    .family: Float(52 * num)
                ], app: app
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
