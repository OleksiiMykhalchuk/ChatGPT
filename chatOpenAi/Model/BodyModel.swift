//
//  BodyModel.swift
//  chatOpenAi
//
//  Created by Oleksii Mykhalchuk on 4/16/24.
//

import Foundation

struct BodyModel: Codable {
    let model: String
    var messages: [Message]
}

struct ImageGenerationBodyModel: Codable {
    let model: String
    let prompt: String
    let count: Int
    let size: String

    enum CodingKeys: String, CodingKey {
        case model, prompt, size
        case count = "n"
    }
}
