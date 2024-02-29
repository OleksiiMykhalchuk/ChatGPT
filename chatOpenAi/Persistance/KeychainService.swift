//
//  KeychainService.swift
//  chatOpenAi
//
//  Created by Oleksii Mykhalchuk on 2/24/24.
//

import Foundation
import Security

struct KeychainService {

    enum KeychainServiceError: Error {
        case addItemFailure
        case fetchItemFailure
        case deleteItemFailure
        case invalidData
        case updateFailed
    }

    private let tag = "dev.oleksi.chatOpenAi.apiKey".data(using: .utf8) ?? Data()
    private let logger: AppLogger = AppLogger()
    private let queue = DispatchQueue(label: "keychain")
    private let account = "com.oleksi.chatOpenAi.apiKey"

    func storeValue(_ value: String) throws {

        let addquery: [String: Any] = [
            kSecClass as String:              kSecClassGenericPassword,
            kSecAttrAccount as String:        account,
            kSecValueData as String:          value.data(using: .utf8) as Any
        ]

        let status = SecItemAdd(addquery as CFDictionary, nil)

        logger.info("Status: \(status.description)")

        guard status == errSecSuccess else {
            throw KeychainServiceError.addItemFailure
        }

    }

    func fetchValue() throws -> String? {

        let getquery: [String: Any] = [
            kSecClass as String:              kSecClassGenericPassword,
            kSecAttrAccount as String:        account,
            kSecMatchLimitOne as String:      true,
            kSecReturnData as String:         true
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(getquery as CFDictionary, &item)

        logger.info("Status: \(status.description)")

        guard status == errSecSuccess else {
            throw KeychainServiceError.fetchItemFailure
        }

        guard let data = item as? Data else {
            throw KeychainServiceError.invalidData
        }

        return String(data: data, encoding: .utf8)
    }

    func updateItem(_ value: String) throws {

        let query: CFDictionary = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrAccount as String: account
        ] as CFDictionary

        let attribute = [
            kSecValueData as String:    value.data(using: .utf8) as Any
        ]

        let status = SecItemUpdate(query, attribute as CFDictionary)

        logger.info("Status: \(status.description)")

        guard status == errSecSuccess else {
            throw KeychainServiceError.updateFailed
        }
    }

    func deleteValue() throws {
        let status = SecItemDelete([
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrAccount as String: account
        ] as CFDictionary)

        logger.info("Status: \(status.description)")

        guard status == errSecSuccess else {
            throw KeychainServiceError.deleteItemFailure
        }
    }
}
