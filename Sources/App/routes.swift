import Fluent
import Vapor

struct VkEvent: Content {
    struct Object: Content {
        struct Message: Content {
            let date: Int64
            let from_id: Int64
            let id: Int64
            let peer_id: Int64
            let text: String
            let conversation_message_id: Int64
            let important: Bool
            let random_id: Int64
        }

        let message: Message?
    }
    
    var type: String?
    var object: Object
}

var randomIds = [Int64: Int64]()

func routes(_ app: Application) throws {
    app.get { req in
        return "667acee3"
    }

    app.get("hello") { req -> String in
        return "Hello, world!"
    }

    app.post("vk") { req -> Response in
        let okResp = Response(status: .ok, version: req.version, headers: req.headers, body: "04726fa0")
        let event = try! req.content.decode(VkEvent.self)
        guard
              let message = event.object.message
              //!randomIds.keys.contains(message.random_id)
        else {
            debugPrint("not parsed vk handle!")
            return okResp
        }

        let randomId = Int64.random()
        //randomIds[message.random_id] = randomId
        
        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.vk.com"
        components.path = "/method/messages.send"
        components.queryItems = [
            .init(name: "v", value: "5.126"),
            .init(name: "access_token", value: Application.vkToken),
            .init(name: "random_id", value: String(randomId)),
            .init(name: "peer_id", value: String(message.peer_id)),
            .init(name: "message", value: message.text),
        ]

        req.client.post(.init(string: components.string!))
        
        return okResp
    }

    try app.register(collection: TodoController())
}
