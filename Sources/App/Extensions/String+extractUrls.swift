//
//  File.swift
//  
//
//  Created by Nickolay Truhin on 04.04.2021.
//

import Foundation

extension String {
    var extractUrls: [URL] {
        let types: NSTextCheckingResult.CheckingType = .link

        guard let detect = try? NSDataDetector(types: types.rawValue) else {
            return []
        }

        let matches = detect.matches(in: self, options: .reportCompletion, range: NSMakeRange(0, count))

        return matches.compactMap(\.url)
    }
}
