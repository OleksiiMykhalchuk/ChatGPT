//
//  DataModel.swift
//  chatOpenAi
//
//  Created by Oleksii Mykhalchuk on 4/3/24.
//

import SwiftData
import Foundation

@Model
final class DataModel {

    let timeStamp: Date = Date()
    var name: String?
    var aiModel: [OpenAIResponseModel]

    init(timeStamp: Date = Date(), name: String? = nil, aiModel: [OpenAIResponseModel]) {
        self.timeStamp = timeStamp
        self.name = name
        self.aiModel = aiModel
    }
}
