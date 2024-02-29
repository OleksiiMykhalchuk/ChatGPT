//
//  UserDefaultsService.swift
//  chatOpenAi
//
//  Created by Oleksii Mykhalchuk on 2/26/24.
//

import Foundation

final class UserDefaultsService {

    private let defaults = UserDefaults.standard

    enum Keys: String {
        case gptModel
        case asistant
    }

    func saveObject(_ object: Any, _ forKey: Keys) {
        defaults.setValue(object, forKey: forKey.rawValue)
    }

    func getObject(_ forKey: Keys) -> Any? {
        defaults.object(forKey: forKey.rawValue)
    }
}
