//
//  ChatView.swift
//  chatOpenAIMobile
//
//  Created by Oleksii Mykhalchuk on 3/12/24.
//

import SwiftUI

struct ChatView: View {
    @State private var column = NavigationSplitViewColumn.detail
    static private var chats: [String] = ["Chat 1", "Chat 2"]
    @State private var selectedChat: String? = chats.first
    var body: some View {
        NavigationSplitView(preferredCompactColumn: $column) {
            List(selection: $selectedChat, content: {
                ForEach(ChatView.chats, id: \.self) { chat in
                    NavigationLink(value: chat) {
                        Text(chat)
                    }
                }
            })

        } detail: {
            Text(selectedChat ?? "default chat")
                .navigationBarBackButtonHidden()
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            // TODO: -
                        } label: {
                            Image(systemName: "line.3.horizontal.decrease")
                        }

                    }
                }

        }
    }
}
