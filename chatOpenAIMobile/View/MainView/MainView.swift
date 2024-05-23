//
//  MainView.swift
//  chatOpenAIMobile
//
//  Created by Oleksii Mykhalchuk on 3/12/24.
//

import SwiftUI

struct MainView: View {

    var body: some View {
        TabView {
            ChatView()
                .tabItem {
                    Label(
                        title: { Text("Chat") },
                        icon: { Image(systemName: "ellipsis.bubble") }
                    )
                }
            SettingsView()
                .tabItem {
                    Label(
                        title: { Text("Settings") },
                        icon: { Image(systemName: "gear") }
                    )
                }
        }
    }
}
