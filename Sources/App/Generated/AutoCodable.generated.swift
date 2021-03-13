// Generated using Sourcery 1.0.2 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT

import Vapor
import AnyCodable

extension ReplacingKey {

    enum CodingKeys: String, CodingKey {
        case username
        case userId
        case userFirstName
        case userLastName
        case stylist
        case makeuper
        case studio
        case price
        case totalPrice
        case admin
        case orderDate
        case promoBlock
        case priceBlock
        case orderBlock
        case showLinks
    }

    internal init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        if container.allKeys.contains(.username), try container.decodeNil(forKey: .username) == false {
            self = .username
            return
        }
        if container.allKeys.contains(.userId), try container.decodeNil(forKey: .userId) == false {
            self = .userId
            return
        }
        if container.allKeys.contains(.userFirstName), try container.decodeNil(forKey: .userFirstName) == false {
            self = .userFirstName
            return
        }
        if container.allKeys.contains(.userLastName), try container.decodeNil(forKey: .userLastName) == false {
            self = .userLastName
            return
        }
        if container.allKeys.contains(.stylist), try container.decodeNil(forKey: .stylist) == false {
            self = .stylist
            return
        }
        if container.allKeys.contains(.makeuper), try container.decodeNil(forKey: .makeuper) == false {
            self = .makeuper
            return
        }
        if container.allKeys.contains(.studio), try container.decodeNil(forKey: .studio) == false {
            self = .studio
            return
        }
        if container.allKeys.contains(.price), try container.decodeNil(forKey: .price) == false {
            self = .price
            return
        }
        if container.allKeys.contains(.totalPrice), try container.decodeNil(forKey: .totalPrice) == false {
            self = .totalPrice
            return
        }
        if container.allKeys.contains(.admin), try container.decodeNil(forKey: .admin) == false {
            self = .admin
            return
        }
        if container.allKeys.contains(.orderDate), try container.decodeNil(forKey: .orderDate) == false {
            self = .orderDate
            return
        }
        if container.allKeys.contains(.promoBlock), try container.decodeNil(forKey: .promoBlock) == false {
            self = .promoBlock
            return
        }
        if container.allKeys.contains(.priceBlock), try container.decodeNil(forKey: .priceBlock) == false {
            self = .priceBlock
            return
        }
        if container.allKeys.contains(.orderBlock), try container.decodeNil(forKey: .orderBlock) == false {
            let associatedValues = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: .orderBlock)
            let showLinks = try associatedValues.decode(Bool.self, forKey: .showLinks)
            self = .orderBlock(showLinks: showLinks)
            return
        }
        throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "Unknown enum case"))
    }

    internal func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .username:
            _ = container.nestedContainer(keyedBy: CodingKeys.self, forKey: .username)
        case .userId:
            _ = container.nestedContainer(keyedBy: CodingKeys.self, forKey: .userId)
        case .userFirstName:
            _ = container.nestedContainer(keyedBy: CodingKeys.self, forKey: .userFirstName)
        case .userLastName:
            _ = container.nestedContainer(keyedBy: CodingKeys.self, forKey: .userLastName)
        case .stylist:
            _ = container.nestedContainer(keyedBy: CodingKeys.self, forKey: .stylist)
        case .makeuper:
            _ = container.nestedContainer(keyedBy: CodingKeys.self, forKey: .makeuper)
        case .studio:
            _ = container.nestedContainer(keyedBy: CodingKeys.self, forKey: .studio)
        case .price:
            _ = container.nestedContainer(keyedBy: CodingKeys.self, forKey: .price)
        case .totalPrice:
            _ = container.nestedContainer(keyedBy: CodingKeys.self, forKey: .totalPrice)
        case .admin:
            _ = container.nestedContainer(keyedBy: CodingKeys.self, forKey: .admin)
        case .orderDate:
            _ = container.nestedContainer(keyedBy: CodingKeys.self, forKey: .orderDate)
        case .promoBlock:
            _ = container.nestedContainer(keyedBy: CodingKeys.self, forKey: .promoBlock)
        case .priceBlock:
            _ = container.nestedContainer(keyedBy: CodingKeys.self, forKey: .priceBlock)
        case let .orderBlock(showLinks):
            var associatedValues = container.nestedContainer(keyedBy: CodingKeys.self, forKey: .orderBlock)
            try associatedValues.encode(showLinks, forKey: .showLinks)
        }
    }

}

extension NodeAction.Action {

    enum CodingKeys: String, CodingKey {
        case push
        case moveToBuilder
        case pop
        case target
        case of
    }

    internal init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        if container.allKeys.contains(.push), try container.decodeNil(forKey: .push) == false {
            let associatedValues = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: .push)
            let target = try associatedValues.decode(PushTarget.self, forKey: .target)
            self = .push(target: target)
            return
        }
        if container.allKeys.contains(.moveToBuilder), try container.decodeNil(forKey: .moveToBuilder) == false {
            let associatedValues = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: .moveToBuilder)
            let of = try associatedValues.decode(BuildableType.self, forKey: .of)
            self = .moveToBuilder(of: of)
            return
        }
        if container.allKeys.contains(.pop), try container.decodeNil(forKey: .pop) == false {
            self = .pop
            return
        }
        throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "Unknown enum case"))
    }

    internal func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case let .push(target):
            var associatedValues = container.nestedContainer(keyedBy: CodingKeys.self, forKey: .push)
            try associatedValues.encode(target, forKey: .target)
        case let .moveToBuilder(of):
            var associatedValues = container.nestedContainer(keyedBy: CodingKeys.self, forKey: .moveToBuilder)
            try associatedValues.encode(of, forKey: .of)
        case .pop:
            _ = container.nestedContainer(keyedBy: CodingKeys.self, forKey: .pop)
        }
    }

}
