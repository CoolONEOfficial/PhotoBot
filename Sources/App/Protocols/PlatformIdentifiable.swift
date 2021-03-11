//
//  File.swift
//  
//
//  Created by Nickolay Truhin on 11.03.2021.
//

import Foundation
import Botter

protocol PlatformIdentifiable {
    var platformIds: [TypedPlatform<UserPlatformId>] { get set }
}

extension PlatformIdentifiable {
    
    /// Returns mention like `@someone` if target platform is same and URL to profile if not
    func platformLink(for platform: AnyPlatform) -> String? {
        if let samePlatformId = platformIds.first(platform: platform) {
            return samePlatformId.mention
        } else {
            return platformIds.first?.link
        }
    }
}
