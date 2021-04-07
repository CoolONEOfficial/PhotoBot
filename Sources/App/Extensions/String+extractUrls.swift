//
//  File.swift
//  
//
//  Created by Nickolay Truhin on 04.04.2021.
//

import Foundation

extension String {
    var extractUrls: [URL] {
        #if os(Linux)
        // Regex pattern from http://daringfireball.net/2010/07/improved_regex_for_matching_urls
        let pattern = "(?i)\\b((?:[a-z][\\w-]+:(?:/{1,3}|[a-z0-9%])|www\\d{0,3}[.]|[a-z0-9.\\-]+[.][a-z]{2,4}/)" +
            "(?:[^\\s()<>]+|\\(([^\\s()<>]+|(\\([^\\s()<>]+\\)))*\\))+(?:\\(([^\\s()<>]+|(\\([^\\s()<>]+\\)))*" +
            "\\)|[^\\s`!()\\[\\]{};:'\".,<>?«»“”‘’]))"
        return matches(for: pattern).compactMap { URL(string: $0) }
        #else
        let types: NSTextCheckingResult.CheckingType = .link

        guard let detect = try? NSDataDetector(types: types.rawValue) else {
            return []
        }

        let matches = detect.matches(in: self, options: .reportCompletion, range: NSMakeRange(0, count))

        return matches.compactMap(\.url)
        #endif
    }

    #if os(Linux)
    func matches(for regex: String) -> [String] {

        do {
            let regex = try NSRegularExpression(pattern: regex)
            let results = regex.matches(in: self,
                                        range: NSRange(startIndex..., in: self))
            return results.map {
                String(self[Range($0.range, in: self)!])
            }
        } catch let error {
            print("invalid regex: \(error.localizedDescription)")
            return []
        }
    }
    #endif
}
