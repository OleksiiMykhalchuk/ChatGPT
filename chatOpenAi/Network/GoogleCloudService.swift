//
//  GoogleCloudService.swift
//  chatOpenAi
//
//  Created by Oleksii Mykhalchuk on 4/26/24.
//

import Foundation

extension GoogleCloudService {
    enum GoogleCloudServiceError: Error {
        case badURL
    }
}

struct GoogleCloudService {

    private let projectNumber = "304542692433"
    private let region = "europe-west8"

    private let streamGenerateContent = "streamGenerateContent"
    private let generateContent = "generateContent"
    private let model = "gemini-1.5-pro"

    private let baseURL = "https://-aiplatform.googleapis.com"

    private let endpoint = "https://europe-west8-aiplatform.googleapis.com/v1/projects/304542692433/locations/europe-west8/publishers/google/models/gemini-1.5-pro:streamGenerateContent"
    private let accessToken = "ya29.a0Ad52N3-rdXr9STf2f8GGQQSbMYm35-RMMBwxYGPViZslt5ypQ-f3mPDVtbIEMiLZV5Sz1wx11PzO8SnE8-ab46pTDkelwzDRmbY8GaqSFdSfbTZhVJZBeGMRBq0akUi-eZZBO4J_fHvIEn-Hp_1Orv0upD3s165Gs6OD_1j-ZSEaCgYKAUoSARMSFQHGX2MihunoNOOZI0ziFvXM0VJz0w0178"

    private func buildURLRequest(_ body: Encodable) throws -> URLRequest {
        guard let url = URL(string: endpoint) else {
            throw GoogleCloudServiceError.badURL
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authentication")
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"

        request.httpBody = try JSONEncoder().encode(body)

        return request
    }

    func userRoleRequest(_ text: String) throws -> URLRequest {
        let requestBody = RequestBody(
            contents: RequestBody.Contents(
                role: "user",
                parts: RequestBody.Contents.Part(
                    text: text
                )
            ),
            safety_settings: RequestBody.SafetySettings(
                category: "HARM_CATEGORY_SEXUALLY_EXPLICIT",
                threshold: "BLOCK_LOW_AND_ABOVE"
            ),
            generation_config: RequestBody.GenerationConfig(
                temperature: 0.2,
                topP: 0.8,
                topK: 40
            )
        )
        return try buildURLRequest(requestBody)
    }
}

// MARK: - Body Model

extension GoogleCloudService {
    struct RequestBody: Encodable {

        let contents: Contents
        let safety_settings: SafetySettings
        let generation_config: GenerationConfig

        struct Contents: Encodable {
            let role: String
            let parts: Part

            struct Part: Encodable {
                let text: String
            }

        }

        struct SafetySettings: Encodable {
            let category: String
            let threshold: String
        }

        struct GenerationConfig: Encodable {
            let temperature: Double
            let topP: Double
            let topK: Double
        }

    }
}
