//
//  ViewModel.swift
//  chatOpenAi
//
//  Created by Oleksii Mykhalchuk on 2/24/24.
//

import Foundation
import Combine

protocol ViewModelProtocol: ObservableObject {

    func start()
}

final class ViewModel: ObservableObject, ViewModelProtocol {

    enum ViewModelError: Error {
        case requestBuilderFailure
    }

    private let userdefaults = UserDefaultsService()
    private let network = NetworkService()
    
    let logger = AppLogger()

    private var errorPublisher = PassthroughSubject<Int?, URLError>()

    func start() {
        //
    }

    func getPrompt(_ prompt: String) -> AnyPublisher<Data, Error> {
        guard let request: URLRequest = URLRequestBuilder(url: .chat)?
            .setValue(.json)
            .setValue(.auth)
            .setMethod(.post)
            .setBody(prompt)
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
