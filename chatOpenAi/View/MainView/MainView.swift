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
                                    if let image = viewModel.imageModel?.data {
                                        ChatBubble(direction: .left) {
                                            List(image, id: \.url) { element in
                                                AsyncImage(url: URL(string: element.url), content: { image in
                                                    image
                                                        .resizable()
                                                        .aspectRatio(contentMode: .fit)
                                                        .frame(width: 256, height: 256, alignment: .center)

                                                }, placeholder: {
                                                    ProgressView()
                                                })
                                            }
                                        }
                                        .flippedUpsideDown()
                                        .frame(width: 356, height: 256, alignment: .center)
                                    }
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
            if viewModel.getGPTModel() == AIModel.dalle.rawValue {
                viewModel
                    .generateImage(message)
                    .decode(type: ImageGeneratedModel.self, decoder: JSONDecoder())
                    .sink { completion in
                        switch completion {
                        case .finished:
                            viewModel.logger.info("getPrompt Finished")
                            isMessageLoading = false
                        case .failure(let error):
                            viewModel.logger.fault("\(error)")
                        }
                    } receiveValue: { value in
                        messages.insert(OpenAIResponseModel(id: UUID().uuidString, object: "", created: Int(Date().timeIntervalSince1970), model: viewModel.getGPTModel() ?? "unknown", choices: [ChoiceModel(index: 0, message: Message(role: "assistant", content: value.data.map { $0.revizedPrompt }.joined(separator: "\n")))], usage: Usage(promptTokens: 0, completionTokens: 0, totalTokens: 0)), at: 0)
                        viewModel.imageModel = value
                    }.store(in: &subscriptions)
//                messages.insert(OpenAIResponseModel(id: UUID().uuidString, object: "", created: Int(Date().timeIntervalSince1970), model: viewModel.getGPTModel() ?? "unknown", choices: [ChoiceModel(index: 0, message: Message(role: "assistant", content: "Picture"))], usage: Usage(promptTokens: 0, completionTokens: 0, totalTokens: 0)), at: 0)
//                viewModel.imageModel = ImageGeneratedModel(created: 1, data: [ImageData(revizedPrompt: "Prompt", url: "https://oaidalleapiprodscus.blob.core.windows.net/private/org-RvgT4ucvKmPdvU8dSTJrnUcd/user-hwjgy67dlklvojD1c7r3NKnF/img-PzLbVjFzrC2nFXm34f3arj1l.png?st=2024-03-10T11%3A10%3A50Z&se=2024-03-10T13%3A10%3A50Z&sp=r&sv=2021-08-06&sr=b&rscd=inline&rsct=image/png&skoid=6aaadede-4fb3-4698-a8f6-684d7786b067&sktid=a48cca56-e6da-484e-a814-9c849652bcb3&skt=2024-03-09T18%3A23%3A05Z&ske=2024-03-10T18%3A23%3A05Z&sks=b&skv=2021-08-06&sig=EfSTDCBPUF/2nld78ZX5RCqhPf/bBQC6OjQeRjnc1vQ%3D")])
//                isMessageLoading = false
            } else {
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

            }
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

