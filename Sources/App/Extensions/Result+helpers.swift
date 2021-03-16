//
//  File.swift
//  
//
//  Created by Nickolay Truhin on 16.03.2021.
//

import Foundation

// MARK: - Result+Success

extension Result where Success == Void {
    
    /// The success Result case
    static var success: Result {
        return .success(())
    }
    
}
