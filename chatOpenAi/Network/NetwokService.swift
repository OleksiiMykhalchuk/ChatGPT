//
//  NetwokService.swift
//  chatOpenAi
//
//  Created by Oleksii Mykhalchuk on 2/12/24.
//

import Foundation
import Combine

protocol NetworkProvider {

    init(session: URLSession, logger: AppLogger)

    func getData(with request: URLRequest) -> AnyPublisher<Data, Error>
}

enum HTTPMethod: String {
    case post = "POST"
}

enum BaseURL {
    case chat

    var url: URL? {
        switch self {
        case .chat:
            return .init(string: "https://api.openai.com/v1/chat/completions")
        }
    }
}

enum AIModel: String, CaseIterable {
    case gpt4 = "gpt-4"
    case gpt3 = "gpt-3.5-turbo"
}

final class NetworkService: NetworkProvider {

    private let session: URLSession

    private let logger: AppLogger

    required init(session: URLSession = .shared,
                  logger: AppLogger = .init()) {
        self.session = session
        self.logger = logger
    }

    func getData(with request: URLRequest) -> AnyPublisher<Data, Error> {
        session
            .dataTaskPublisher(for: request)
            .tryMap({ [weak self] element -> Data in
                self?.logger.info("\(element.response)")
                self?.logger.info("\(try JSONSerialization.jsonObject(with: element.data))")
                guard let response = element.response as? HTTPURLResponse,
                      (200...299).contains(response.statusCode)
                else {
                    throw NetworkServiceError.badNetworkResponse
                }
                return element.data
            })
            .eraseToAnyPublisher()
    }

    func verify(request: URLRequest) -> AnyPublisher<Int?, URLError> {
        session
            .dataTaskPublisher(for: request)
            .compactMap {
                ($0.response as? HTTPURLResponse)?.statusCode
            }
            .eraseToAnyPublisher()
    }
}

// MARK: - Error Handling

extension NetworkService {
    enum NetworkServiceError: Error {
        case badNetworkResponse
    }
}

final class URLRequestBuilder {

    enum Value {
        case json
        case auth

        var value: String {
            switch self {
            case .json:
                return "application/json"
            case .auth:
                return "Bearer \(URLRequestBuilder.apiKey ?? "")"
            }
        }

        var forHTTP: String {
            switch self {
            case .json:
                return "Content-Type"
            case .auth:
                return "Authorization"
            }
        }
    }

    private var request: URLRequest

    private let logger = AppLogger()

    static private var apiKey: String? {
        do {
            return try KeychainService().fetchValue()
        } catch {
            return nil
        }
    }

    private var aiModel: AIModel? {
        AIModel(rawValue: UserDefaultsService().getObject(.gptModel) as? String ?? "")
    }

    init?(url: BaseURL) {
        guard let url = url.url else { return nil }
        self.request = .init(url: url)
    }

    func setValue(_ value: Value) -> Self {
        request.setValue(value.value, forHTTPHeaderField: value.forHTTP)
        return self
    }

    func setMethod(_ method: HTTPMethod) -> Self {
        request.httpMethod = method.rawValue
        return self
    }

    func setBody(_ prompt: String) -> Self {
        let body = [
            "model": aiModel?.rawValue ?? AIModel.gpt3.rawValue,
            "messages": [
                [
                    "role": "system",
                    "content": "You are a helpful assistant."
                ],
                [
                    "role": "user",
                    "content": prompt
                ]
            ]
        ] as [String : Any]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        return self
    }

    func build() -> URLRequest {
        request
    }
}

