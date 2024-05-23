//
//  ViewModel.swift
//  chatOpenAi
//
//  Created by Oleksii Mykhalchuk on 2/24/24.
//

import Foundation
import Combine

protocol ViewModelProtocol {

    func start()
}

@Observable
final class ViewModel: ViewModelProtocol {

    enum ViewModelError: Error {
        case requestBuilderFailure
    }

    private let userdefaults = UserDefaultsService()
    private let network = NetworkService()
    
    let logger = AppLogger()

    var imageModel: ImageGeneratedModel?

    private var errorPublisher = PassthroughSubject<Int?, URLError>()
    private var model: String? {
        getGPTModel()
    }

    var messages: [OpenAIResponseModel] = []

    func start() {
        //
    }

    func generateImage(_ prompt: String) -> AnyPublisher<Data, Error> {
        let body = ImageGenerationBodyModel(
            model: model ?? AIModel.dalle.rawValue,
            prompt: prompt,
            count: 1,
            size: ImageSize.medium.rawValue)
        guard let request: URLRequest = URLRequestBuilder(url: .image)?
            .setValue(.json)
            .setValue(.auth)
            .setMethod(.post)
            .setBody(body)
            .build()
        else {
            logger.fault("URLRequest invalid")
            return Fail<Data, Error>(error: ViewModelError.requestBuilderFailure).eraseToAnyPublisher()
        }
        return network
            .getData(with: request)
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    func getPrompt(_ prompt: String) -> AnyPublisher<Data, Error> {
        let history = messages.compactMap { model -> Message in
            Message(role: model.getRole(), content: model.getContent())
        }
        var body = BodyModel(
            model: model ?? AIModel.gpt3.rawValue,
            messages: [
                Message(role: "system",
                        content: "You are helpfull assistant")
            ])
        body.messages.append(contentsOf: history.reversed())
        guard let request: URLRequest = URLRequestBuilder(url: .chat)?
            .setValue(.json)
            .setValue(.auth)
            .setMethod(.post)
            .setBody(body)
            .build()
        else {
            logger.fault("URLRequest invalid")
            return Fail<Data, Error>(error: ViewModelError.requestBuilderFailure).eraseToAnyPublisher()
        }
        return network
            .getData(with: request)
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    func getTextGoogleCloud(_ prompt: String) throws -> AnyPublisher<Data, Error> {
        let googleCloudService = GoogleCloudService()
        let request = try googleCloudService.userRoleRequest(prompt)
        return network
            .getData(with: request)
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    func verifyAPIKey() -> AnyPublisher<Int?, URLError> {
        guard let chatRequest: URLRequest = URLRequestBuilder(url: .chat)?
        .setValue(.json)
        .setValue(.auth)
        .setMethod(.post)
        .setBody("Test chat")
        .build() else {
            logger.fault("URLRequest invalid")
            return errorPublisher.eraseToAnyPublisher()
        }
        return network
            .verify(request: chatRequest)
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    func saveGPTModel(_ value: Any) {
        userdefaults.saveObject(value, .gptModel)
    }

    func getGPTModel() -> String? {
        userdefaults.getObject(.gptModel) as? String
    }
}
