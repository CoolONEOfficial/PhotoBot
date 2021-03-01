import Fluent
import Vapor
import Telegrammer

func routes(_ app: Application) throws {
    app.get { _ in
        "Photo bot working.."
    }
}
