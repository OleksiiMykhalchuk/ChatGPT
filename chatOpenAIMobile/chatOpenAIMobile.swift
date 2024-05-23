//
//  AppDelegate.swift
//  chatOpenAIMobile
//
//  Created by Oleksii Mykhalchuk on 3/12/24.
//

import SwiftUI

@main
struct chatOpenAIMobile: App {

    var body: some Scene {
        WindowGroup {
            if NSClassFromString("XCTestCase") != nil {
                EmptyView()
            } else {
                MainView()
            }
        }
    }
}

