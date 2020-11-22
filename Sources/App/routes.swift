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
        let event = try! req.content.decode(VkEvent.self)
        switch event.type {
        case .confirmation:
            if let key = Environment.get("VK_CONFIRM_KEY") {
                okResp.body = .init(string: key)
            }
            return okResp
        case .message_new:
            guard let message = event.object?.message else {
                debugPrint("not parsed vk handle!")
                return okResp
            }

            req.client.post(.vkMessage(message)).whenFailure { err in
                debugPrint("failed to reply \(err)")
            }

            return okResp
        }
        
    }

    try app.register(collection: TodoController())
}
