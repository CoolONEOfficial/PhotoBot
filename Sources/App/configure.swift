import Fluent
import FluentPostgresDriver
import Vapor

// configures your application
public func configure(_ app: Application) throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    if let url = Environment.get("DATABASE_URL") {
        app.databases.use(try .postgres(url: url), as: .psql)
    } else {
      fatalError("Unable to find DATABASE_URL environment")
    }

    app.migrations.add(CreateTodo())

    // register routes
    try routes(app)
}
