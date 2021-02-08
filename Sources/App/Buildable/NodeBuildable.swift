//
//  File.swift
//  
//
//  Created by Nickolay Truhin on 01.02.2021.
//

import Foundation

extension NodeModel: BuildableModel {}
extension SendMessage: BuildableModel {}

struct NodeBuildable: Buildable {
    var modelType: BuildableModel.Type { NodeModel.self }

    var name: String? = nil
    var systemic: Bool? = nil
    var test: SendMessageBuildable? = nil
}

struct SendMessageBuildable: Buildable {
    var modelType: BuildableModel.Type { SendMessage.self }
    
    var innertest: String? = nil
    var innertest2: String? = nil
    var innertest3: String? = nil
    var innertestBool: Bool? = nil
}
