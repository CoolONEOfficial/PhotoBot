import Fluent
import FluentPostgresDriver
import Vapor
import TelegrammerMiddleware
import Telegrammer
import Vkontakter
import VkontakterMiddleware
import Botter
import SwiftyChrono

enum TargetPlatform: String {
    case tg = "TG"
    case vk = "VK"
}

extension Application {
    static let targetPlatform = TargetPlatform(rawValue: Environment.get("TARGET_PLATFORM") ?? .init())
    
    static let databaseURL = URL(string: Environment.get("DATABASE_URL")!)!
    static let tgToken = Environment.get("TG_BOT_TOKEN")!
    static let tgBufferUserId = Int64(Environment.get("TG_BUFFER_USER_ID")!)!
    static let vkBufferUserId = Int64(Environment.get("VK_BUFFER_USER_ID")!)!
    static let vkAdminNickname = Environment.get("VK_ADMIN_NICKNAME")!
    static let tgAdminNickname = Environment.get("TG_ADMIN_NICKNAME")!
    
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
    
    static let herokuName = Environment.get("HEROKU_APP_NAME")
    static let herokuServerPort = Int(Environment.get("PORT") ?? .init())

    static var isHeroku: Bool {
        herokuName != nil || herokuServerPort != nil
    }
    
    func webhooksPort(for platform: AnyPlatform) -> Int {
        if Self.isHeroku {
            return 443
        }
        switch platform {
        case .tg:
            return Application.tgWebhooksPort ?? Application.webhooksPort ?? (environment == .development ? 443 : 1314)
            
        case .vk:
            return Application.vkWebhooksPort ?? Application.webhooksPort ?? (environment == .development ? 443 : 1313)
        }
    }
    
    func serverPort(for platform: AnyPlatform) -> Int {
        let port: Int?
        switch platform {
        case .tg:
            port = Application.tgServerPort
            
        case .vk:
            port = Application.vkServerPort
        }
        return Self.herokuServerPort ?? port ?? webhooksPort(for: platform)
    }
    
    func webhooksUrl(for platform: AnyPlatform) -> String {
        let url: URL

        if let urlStr = Enviroment.get("WEBHOOKS_URL"), let _url = URL(string: urlStr) {
            url = _url
        } else if environment == .production {
            if let herokuName = Self.herokuName, let _url = URL(string: "https://\(herokuName).herokuapp.com") {
                url = _url
            } else {
                fatalError("You should specify HEROKU_APP_NAME or WEBHOOKS_URL")
            }
            debugPrint("WEBHOOKS_URL is \(url)")
        } else {
            debugPrint("Starting localhost process...")
            
            let port = serverPort(for: platform)
            
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

            url = URL(string: matches(for: "\\S+(localhost.run)", in: output).last!)!
        }
        
        let port = self.webhooksPort(for: platform)
        if (port != 80 && url.scheme == "http") || (port != 443 && url.scheme == "https") {
            return "\(url):\(port)"
        }
        
        return url.absoluteString
    }

    static let vkServerName = Environment.get("VK_NEW_SERVER_NAME")

    static let webhooksPort = Int(Environment.get("WH_PORT") ?? .init())
    static let vkWebhooksPort = Int(Environment.get("VK_WH_PORT") ?? .init())
    static let tgWebhooksPort = Int(Environment.get("TG_WH_PORT") ?? .init())
    static let vkServerPort = Int(Environment.get("VK_SERVER_PORT") ?? .init())
    static let tgServerPort = Int(Environment.get("TG_SERVER_PORT") ?? .init())
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

    if Application.isHeroku {
        postgresConfig.tlsConfiguration = .forClient(certificateVerification: .none)
    }
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
        CreateStudios(),
        CreateStudioPhotos(),
        CreateUsers(),
        CreateEventPayloads(),
        CreatePromotions(),
        CreateOrders(),
        CreateOrderPromotions(),
        CreateReviews(),
        CreateAgreements(),
    ])

    if app.environment == .development {
        try app.autoMigrate().wait()
    }

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
        OrderBuilderPhotographerNodeController(),
        OrderBuilderStudioNodeController(),
        OrderBuilderStylistNodeController(),
        ChangeTextNodeController(),
        OrderAgreementNodeController(),
        OrderReplacementNodeController(),
        ShowcaseNodeController(),
        WelcomeNodeController(),
    ]
    
    if try NodeModel.query(on: app.db).count().wait() == 0 {
        
        for controller in controllers {
            try controller.create(app: app).throwingFlatMap { try $0.saveReturningId(app: app) }.wait()
        }

        let testPhoto = try PlatformFile.create(platformEntries: [
            .tg("AgACAgIAAxkBAAN2YLIvRKdBuPchyfcsMpZpJLh9gcAAAv2zMRuHOJFJINW0txSyW6DgxiakLgADAQADAgADeQADBK0BAAEfBA"),
            .vk("photo-119092254_457239065")
        ], type: .photo, app: app).throwingFlatMap { try $0.save(app: app) }.wait()
        
        let testPhoto2 = try PlatformFile.create(platformEntries: [
            .tg("AgACAgIAAxkBAAN2YLIvRKdBuPchyfcsMpZpJLh9gcAAAv2zMRuHOJFJINW0txSyW6DgxiakLgADAQADAgADeQADBK0BAAEfBA"),
            .vk("photo-119092254_457239065")
        ], type: .photo, app: app).throwingFlatMap { try $0.save(app: app) }.wait()
        
        let reviewPhotos: [PlatformFileModel] = [
            try PlatformFile.create(platformEntries: [
                .tg("AgACAgIAAxkBAAN2YLIvRKdBuPchyfcsMpZpJLh9gcAAAv2zMRuHOJFJINW0txSyW6DgxiakLgADAQADAgADeQADBK0BAAEfBA"),
                .vk("photo-119092254_457239082")
            ], type: .photo, app: app).throwingFlatMap { try $0.save(app: app) }.wait(),
            try PlatformFile.create(platformEntries: [
                .tg("AgACAgIAAxkBAAN2YLIvRKdBuPchyfcsMpZpJLh9gcAAAv2zMRuHOJFJINW0txSyW6DgxiakLgADAQADAgADeQADBK0BAAEfBA"),
                .vk("photo-119092254_457239081")
            ], type: .photo, app: app).throwingFlatMap { try $0.save(app: app) }.wait(),
            try PlatformFile.create(platformEntries: [
                .tg("AgACAgIAAxkBAAN2YLIvRKdBuPchyfcsMpZpJLh9gcAAAv2zMRuHOJFJINW0txSyW6DgxiakLgADAQADAgADeQADBK0BAAEfBA"),
                .vk("photo-119092254_457239083")
            ], type: .photo, app: app).throwingFlatMap { try $0.save(app: app) }.wait(),
            try PlatformFile.create(platformEntries: [
                .tg("AgACAgIAAxkBAAN2YLIvRKdBuPchyfcsMpZpJLh9gcAAAv2zMRuHOJFJINW0txSyW6DgxiakLgADAQADAgADeQADBK0BAAEfBA"),
                .vk("photo-119092254_457239084")
            ], type: .photo, app: app).throwingFlatMap { try $0.save(app: app) }.wait(),
            try PlatformFile.create(platformEntries: [
                .tg("AgACAgIAAxkBAAN2YLIvRKdBuPchyfcsMpZpJLh9gcAAAv2zMRuHOJFJINW0txSyW6DgxiakLgADAQADAgADeQADBK0BAAEfBA"),
                .vk("photo-119092254_457239085")
            ], type: .photo, app: app).throwingFlatMap { try $0.save(app: app) }.wait(),
            try PlatformFile.create(platformEntries: [
                .tg("AgACAgIAAxkBAAN2YLIvRKdBuPchyfcsMpZpJLh9gcAAAv2zMRuHOJFJINW0txSyW6DgxiakLgADAQADAgADeQADBK0BAAEfBA"),
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
                platformIds: coolonePlatformIds, photos: [testPhoto], prices: [
                    .loveStory: Float(50 * num),
                    .content: Float(51 * num),
                    .family: Float(52 * num)
                ], app: app
            ).throwingFlatMap { try $0.save(app: app) }.wait()
        }
    }
    
    for entryPoint in EntryPoint.allCases {        
        let future = NodeModel.query(on: app.db).filter(\.$entryPoint == .enumCase(entryPoint.rawValue)).first()
            .unwrap(or: PhotoBotError.nodeByEntryPointNotFound(entryPoint))
        future.whenSuccess { node in
            Node.entryPointIds[entryPoint] = node.id
        }
        try future.wait()
    }

    return controllers
}

func tgSettings(_ app: Application) -> Telegrammer.Bot.Settings {
    var tgSettings = Telegrammer.Bot.Settings(token: Application.tgToken, debugMode: !app.environment.isRelease)
    tgSettings.webhooksConfig = .init(ip: "0.0.0.0", baseUrl: app.webhooksUrl(for: .tg), port: app.serverPort(for: .tg))
    debugPrint("Starting webhooks tg\non url \(tgSettings.webhooksConfig?.url ?? "nope") port \(tgSettings.webhooksConfig?.port)")
    return tgSettings
}

func vkSettings(_ app: Application) -> Vkontakter.Bot.Settings {
    var vkSettings: Vkontakter.Bot.Settings = .init(token: Application.vkToken, debugMode: !app.environment.isRelease)
    vkSettings.webhooksConfig = .init(ip: "0.0.0.0", baseUrl: app.webhooksUrl(for: .vk), port: app.serverPort(for: .vk), groupId: Application.vkGroupId)
    debugPrint("Starting webhooks vk on url \(vkSettings.webhooksConfig?.url ?? "nope") port \(vkSettings.webhooksConfig?.port)")
    return vkSettings
}

func botterSettings(_ app: Application) -> Botter.Bot.Settings {
    .init(
        vk: Application.targetPlatform ?? .vk == .vk ? vkSettings(app) : nil,
        tg: Application.targetPlatform ?? .tg == .tg ? tgSettings(app) : nil
    )
}

//private func configureEchoVk(_ app: Application) throws {
//    let bot = try VkEchoBot(settings: vkSettings(app))
//    try bot.updater.startWebhooks(serverName: Application.vkServerName).wait()
//}

//private func configureEchoBotter(_ app: Application) throws {
//    let bot = try EchoBot(settings: botterSettings(app), app: app)
//    try bot.updater.startWebhooks(vkServerName: Application.vkServerName).wait()
//}

//private func configureEchoTg(_ app: Application) throws {
//    let bot = try TgEchoBot(settings: tgSettings(app))
//    try bot.updater.startWebhooks().wait()
//}

private func configurePhotoBot(_ app: Application, _ controllers: [NodeController]) throws {
    let bot = try PhotoBot(settings: botterSettings(app), app: app, controllers: controllers)
    try bot.updater.startWebhooks(vkServerName: Application.vkServerName).wait()
}
