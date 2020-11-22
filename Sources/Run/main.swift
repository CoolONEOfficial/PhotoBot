import App
import Vapor
import TelegrammerMiddleware

var env = try Environment.detect()
try LoggingSystem.bootstrap(from: &env)
let app = Application(env)

defer { app.shutdown() }
try configure(app)
try app.run()
