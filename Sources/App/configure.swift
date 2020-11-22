import Fluent
import FluentPostgresDriver
import Vapor

extension Application {
    static var databaseURL = URL(string: Environment.get("DATABASE_URL")!)!
}

// configures your application
public func configure(_ app: Application) throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    app.databases.use(try .postgres(url: Application.databaseURL), as: .psql)

    app.migrations.add(CreateTodo())
    if app.environment == .development {
        try app.autoMigrate().wait()
    }
    
    Todo(title: "Publish new article tomorrow").save(on: app.db)

    // register routes
    try routes(app)
}
