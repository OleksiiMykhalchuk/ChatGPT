//
//  OpenAIResponseModel.swift
//  chatOpenAi
//
//  Created by Oleksii Mykhalchuk on 2/29/24.
//

import Foundation

struct OpenAIResponseModel: Codable, Hashable {

    static func == (lhs: OpenAIResponseModel, rhs: OpenAIResponseModel) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    var id: String
    var object: String
    var created: Int
    var model: String
    var choices: [ChoiceModel]
    var usage: Usage
    var imageURL: String?

    func getContent() -> String {
        choices
            .map { $0.message.content }
            .joined(separator: " / ")
    }

    func getRole() -> String {
        choices
            .map { $0.message.role }
            .first ?? "unknown"
    }
}

struct ChoiceModel: Codable {
    var index: Int
    var message: Message
}

struct Message: Codable {
    var role: String
    var content: String
}

struct Usage: Codable {
    let promptTokens: Int
    let completionTokens: Int
    let totalTokens: Int

    enum CodingKeys: String, CodingKey {
        case promptTokens = "prompt_tokens"
        case completionTokens = "completion_tokens"
        case totalTokens = "total_tokens"
    }
}

struct ImageGeneratedModel: Codable {
    var created: Int
    var data: [ImageData]
}

struct ImageData: Codable, Hashable {

    var revizedPrompt: String
    var url: String

    enum CodingKeys: String, CodingKey {
        case revizedPrompt = "revised_prompt"
        case url
    }
}
