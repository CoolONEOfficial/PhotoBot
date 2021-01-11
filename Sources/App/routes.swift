import Fluent
import Vapor
import Telegrammer

func routes(_ app: Application) throws {
    app.get { req in
        return "Photo bot working.."
    }

    try app.register(collection: UserController())
}
