//
//  ThemeManager.swift
//  chatOpenAi
//
//  Created by Oleksii Mykhalchuk on 3/29/24.
//

import Foundation

enum ThemeManager {
    static var textSize: Float? {
        get {
            UserDefaultsService().getObject(.textSize) as? Float
        }
        set {
            UserDefaultsService().saveObject(newValue ?? 12.0, .textSize)
        }
    }
}
