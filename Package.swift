// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "photobot",
    platforms: [
        .macOS(.v10_15)
    ],
    dependencies: [
        // 💧 A server-side Swift web framework.
        .package(url: "https://github.com/vapor/vapor.git", from: "4.77.1"),
        .package(url: "https://github.com/vapor/fluent.git", from: "4.8.0"),
        .package(url: "https://github.com/vapor/fluent-postgres-driver.git", from: "2.8.0"),
        .package(url: "https://github.com/CoolONEOfficial/Botter.git", .branch("main")),
        .package(url: "https://github.com/SvenTiigi/ValidatedPropertyKit.git", .exact("0.0.4")),
        .package(url: "https://github.com/CoolONEOfficial/SwiftyChrono.git", .branch("master")),
        .package(url: "https://github.com/CoolONEOfficial/DateHelper.git", .branch("master")),
    ],
    targets: [
        .target(
            name: "App",
            dependencies: [
                .product(name: "Fluent", package: "fluent"),
                .product(name: "FluentPostgresDriver", package: "fluent-postgres-driver"),
                .product(name: "Vapor", package: "vapor"),
                .product(name: "Botter", package: "Botter"),
                .product(name: "ValidatedPropertyKit", package: "ValidatedPropertyKit"),
                .product(name: "DateHelper", package: "DateHelper"),
                .product(name: "SwiftyChrono", package: "SwiftyChrono"),
            ],
            swiftSettings: [
                // Enable better optimizations when building in Release configuration. Despite the use of
                // the `.unsafeFlags` construct required by SwiftPM, this flag is recommended for Release
                // builds. See <https://github.com/swift-server/guides#building-for-production> for details.
                .unsafeFlags(["-cross-module-optimization"], .when(configuration: .release))
            ]
        ),
        .target(name: "Run", dependencies: [.target(name: "App")]),
        .testTarget(name: "AppTests", dependencies: [
            .target(name: "App"),
            .product(name: "XCTVapor", package: "vapor"),
        ])
    ]
)
