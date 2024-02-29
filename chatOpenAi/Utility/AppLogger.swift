//
//  AppLogger.swift
//  chatOpenAi
//
//  Created by Oleksii Mykhalchuk on 2/12/24.
//

import Foundation
import OSLog

protocol LoggerProtocol {

    init(_ category: Category)
}

extension LoggerProtocol {

    func makeMessage(type: LogType, file: String, function: String, line: Int) -> String {
        let file = file.components(separatedBy: "/").last ?? "unknown file"
        return "\(type) [\(Date())] [\(file)] [\(function)] [\(line)] -> "
    }
}

enum Category: String {
    case defaultCategory
}

struct AppLogger: LoggerProtocol {

    private let logger: Logger

    private let subsystem = Bundle.main.bundleIdentifier

    init(_ category: Category = .defaultCategory) {
        logger = Logger(subsystem: subsystem ?? "unknown", category: category.rawValue)
    }

    func info(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        let string = "\(makeMessage(type: LogType(type: .info), file: file, function: function, line: line))-> \(message)"
        logger.info("\(string)")
    }

    func fault(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        let string = "\(makeMessage(type: LogType(type: .fault), file: file, function: function, line: line))-> \(message)"
        logger.fault("\(string)")
    }
}

struct LogType: CustomStringConvertible {

    var description: String {
        "\(type.emoji) \(type.name)"
    }

    private let type: LogType

    init(type: LogType) {
        self.type = type
    }
}

extension LogType {

    enum LogType {
        case info
        case fault

        var emoji: String {
            switch self {
            case .info:
                return "ℹ️"
            case .fault:
                return "🔴"
            }
        }

        var name: String {
            switch self {
            case .info:
                return "[INFO]"
            case .fault:
                return "[FAULT]"
            }
        }
    }
}
