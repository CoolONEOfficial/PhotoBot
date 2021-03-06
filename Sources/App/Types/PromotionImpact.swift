//
//  File.swift
//  
//
//  Created by Nickolay Truhin on 04.03.2021.
//

import Foundation

enum PromotionImpact {
    case fixed(Int)
    case percents(Int)
}

extension PromotionImpact {
    func apply(to num: inout Int) {
        switch self {
        case let .fixed(fixed):
            num -= fixed
        case let .percents(percents):
            num -= num / 100 * percents
        }
    }
}

extension PromotionImpact: Codable {

    enum CodingKeys: String, CodingKey {
        case fixed
        case percents
    }

    internal init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        if container.allKeys.contains(.fixed), try container.decodeNil(forKey: .fixed) == false {
            let associatedValue0 = try container.decode(Int.self, forKey: .fixed)
            self = .fixed(associatedValue0)
            return
        }
        if container.allKeys.contains(.percents), try container.decodeNil(forKey: .percents) == false {
            let associatedValue0 = try container.decode(Int.self, forKey: .percents)
            self = .percents(associatedValue0)
            return
        }
        throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "Unknown enum case"))
    }

    internal func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case let .fixed(associatedValue0):
            try container.encode(associatedValue0, forKey: .fixed)
        case let .percents(associatedValue0):
            try container.encode(associatedValue0, forKey: .percents)
        }
    }

}
