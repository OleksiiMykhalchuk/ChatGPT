//
//  MainView.swift
//  chatOpenAi
//
//  Created by Oleksii Mykhalchuk on 2/12/24.
//

import SwiftUI
import Combine
import AppKit
import MarkdownUI

struct MainView: View {

    @ObservedObject var viewModel = ViewModel()

    @State private var message: String = ""

    @State private var isSettingPresent: Bool = false

    @State private var messages: [OpenAIResponseModel] = []

    @State private var conversationList: [String] = ["\(Date())", "\(Date(timeIntervalSinceNow: 10))"]

    @State private var tempAlert: Bool = false

    @State private var subscriptions = Set<AnyCancellable>()

    @State private var isMessageLoading: Bool = false

    var body: some View {
        NavigationSplitView {
            List(conversationList, id: \.self) { conversation in
                Text("\(conversation)")
            }
            .navigationSplitViewColumnWidth(min: 230, ideal: 250)
            .toolbar(content: {
                ToolbarItem {
                    Button {
                        tempAlert.toggle()
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            })
            .alert(isPresented: $tempAlert, content: {
                Alert(title: Text("Add Conversation is unavailabel now."))
            })
        } detail: {
            VStack {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack {
                            Image(systemName: "ellipsis")
                                .symbolEffect(.pulse)
                                .font(.system(size: 30))
                                .opacity(isMessageLoading ? 1 : 0)
                            ForEach(messages, id: \.id) { message in

                                if message.getRole() == "user" {

                                    ChatBubble(direction: .right) {
                                        Text(message.getContent())
                                            .padding()
                                            .foregroundStyle(.white)
                                            .background(.blue)
                                            .contextMenu(menuItems: {
                                                Button {
                                                    NSPasteboard.general.clearContents()
                                                    NSPasteboard.general.setString(message.getContent(), forType: .string)
                                                } label: {
                                                    Text("Copy")
                                                }
                                            })
                                    }.flippedUpsideDown()
                                } else {
                                    ChatBubble(direction: .left) {
                                        Markdown(MarkdownContent(message.getContent()))
                                            .padding()
                                            .background(.gray.opacity(0.1))
                                            .contextMenu(menuItems: {
                                                Button {
                                                    NSPasteboard.general.clearContents()
                                                    NSPasteboard.general.setString(message.getContent(), forType: .string)
                                                } label: {
                                                    Text("Copy")
                                                }
                                            })
                                    }.flippedUpsideDown()
                                }

                            }
                            .onAppear {
                                withAnimation {
                                    if let id = messages.first?.id {
                                        proxy.scrollTo(id, anchor: .bottom)
                                    }
                                }
                            }
                            .onReceive(Just(messages), perform: { _ in
                                withAnimation {
                                    if let id = messages.first?.id {
                                        proxy.scrollTo(id, anchor: .bottom)
                                    }
                                }
                            })
                        }
                    }.flippedUpsideDown()

                    HStack(spacing: nil) {
                        TextEditor(text: $message)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .circular))
                            .padding([.leading, .trailing], 10)
                            .font(.system(size: 20))
                            .frame(minHeight: 20, maxHeight: 100)
                            .fixedSize(horizontal: false, vertical: true)
                            .overlay {
                                if !message.isEmpty {
                                    VStack {
                                        HStack(alignment: .top) {
                                            Spacer()
                                            Button(action: {
                                                message = ""
                                            }, label: {
                                                Image(systemName: "multiply.circle.fill")
                                            })
                                            .foregroundStyle(.secondary)
                                            .clipShape(Circle())
                                            .padding([.trailing, .top], 10)
                                        }
                                        Spacer()
                                    }
                                }
                            }


                        Button {
                            sendAction()
                            if let id = messages.last?.id {
                                proxy.scrollTo(id, anchor: .bottom)
                            }
                        } label: {
                            Image(systemName: "paperplane")
                        }
                        .padding(.trailing, 10)

                    }
                    .padding(.bottom, 20)
                }
            }
            .toolbar(content: {
                Button(action: {
                    settingsAction()
                }, label: {
                    Image(systemName: "gear")
                })
            })
            .sheet(isPresented: $isSettingPresent, content: {
                SettingsView(isPresented: $isSettingPresent)
            })
            .environmentObject(viewModel)
        }
    }

    private func sendAction() {
        if !message.isEmpty {
            isMessageLoading = true
            messages.insert(OpenAIResponseModel(id: UUID().uuidString, object: "", created: Int(Date().timeIntervalSince1970), model: viewModel.getGPTModel() ?? "unknown", choices: [ChoiceModel(index: 0, message: Message(role: "user", content: message))], usage: Usage(promptTokens: 0, completionTokens: 0, totalTokens: 0)), at: 0)
            viewModel
                .getPrompt(message)
                .decode(type: OpenAIResponseModel.self, decoder: JSONDecoder())
                .sink { completion in
                    switch completion {
                    case .finished:
                        viewModel.logger.info("getPrompt Finished")
                        isMessageLoading = false
                    case .failure(let error):
                        viewModel.logger.fault("\(error)")
                    }
                } receiveValue: { value in
                    messages.insert(value, at: 0)
                }.store(in: &subscriptions)
            message = ""
        }
    }

    private func settingsAction() {
        isSettingPresent = true
    }
}

#Preview {
    MainView()
}

