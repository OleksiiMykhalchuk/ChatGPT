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

    let id: String
    let object: String
    let created: Int
    let model: String
    let choices: [ChoiceModel]
    let usage: Usage

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
    let index: Int
    let message: Message
}

struct Message: Codable {
    let role: String
    let content: String
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
