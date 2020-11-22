import Fluent
import Vapor
import Telegrammer

func routes(_ app: Application) throws {
    app.get { req in
        return "Photo bot working.."
    }

    app.post("vk") { req -> Response in
        let okResp = Response(
            status: .ok,
            version: req.version,
            headers: req.headers,
            body: "ok"
        )
        if let event = try? req.content.decode(VkEvent.self),
           let message = event.object?.message {

            req.client.post(.vkMessage(message)).whenFailure { err in
                debugPrint("failed to reply \(err)")
            }

            return okResp
        } else {
            if let key = Environment.get("VK_CONFIRM_KEY") {
                debugPrint("cannot parse event, return VK_CONFIRM_KEY")
                okResp.body = .init(string: key)
            } else {
                debugPrint("cannot parse event")
            }
            return okResp
        }
    }

    try app.register(collection: TodoController())
}
