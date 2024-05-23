//
//  MainView.swift
//  chatOpenAi
//
//  Created by Oleksii Mykhalchuk on 2/12/24.
//

import SwiftUI
import Combine
import MarkdownUI
import SwiftData

public struct MainView: View {

    @Environment(\.modelContext) private var modelContext

    @State private var viewModel = ViewModel()

    @State private var message: String = ""
    @State private var isSettingPresent: Bool = false
    @State private var conversationList: [String] = ["\(Date())", "\(Date(timeIntervalSinceNow: 10))"]
    @State private var tempAlert: Bool = false
    @State private var subscriptions = Set<AnyCancellable>()
    @State private var isMessageLoading: Bool = false
    @Query private var dataModels: [DataModel]
    @State private var model: DataModel?

    public var body: some View {
        NavigationSplitView {
            List(dataModels, selection: $model) { model in
                NavigationLink("\(model.timeStamp)", value: model)
            }
            .navigationSplitViewColumnWidth(min: 300, ideal: 350)
            .toolbar(content: {
                ToolbarItem {
                    Button {
                        let dataModel = DataModel(aiModel: [])
                        modelContext.insert(dataModel)
                    } label: {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem {
                    Button {
                        if let model {
                            modelContext.delete(model)
                        } else {
                            tempAlert.toggle()
                        }
                    } label: {
                        Image(systemName: "trash")
                    }
                }
                ToolbarItem {
                    Button {

                    } label: {
                        Image(systemName: "square.and.pencil")
                    }
                }
            })
            .alert(isPresented: $tempAlert, content: {
                Alert(title: Text("Select Chat before delete!"))
            })
            .onChange(of: model) { oldValue, newValue in
                AppLogger().info("Model Selected")
                if let newValue {
                    viewModel.messages = newValue.aiModel
                }
            }
        } detail: {
            VStack {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack {
                            Image(systemName: "ellipsis")
                                .symbolEffect(.variableColor)
                                .font(.system(size: 30))
                                .opacity(isMessageLoading ? 1 : 0)
                            ForEach(viewModel.messages, id: \.id) { message in

                                if message.getRole() == "user" {

                                    ChatBubble(direction: .right) {
                                        Text(message.getContent())
                                            .textSelection(.enabled)
                                            .padding()
                                            .foregroundStyle(.white)
                                            .font(.system(size: CGFloat(ThemeManager.textSize ?? 12.0)))
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
                                        //                                        Markdown(MarkdownContent(message.getContent()))
                                        //                                            .markdownTextStyle(textStyle: {
                                        //                                                FontSize(.em(CGFloat(ThemeManager.textSize ?? 12.0)))
                                        //                                            })
                                        VStack {
                                            Text(message.getContent())
                                                .textSelection(.enabled)
                                                .font(.system(size: CGFloat(ThemeManager.textSize ?? 12.0)))
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
                                            if let image = message.imageURL {
                                                Text("\(image)")
                                                    .textSelection(.enabled)
                                                HStack {
                                                    Button {
                                                        let url = showSavePanel()
                                                        AppLogger().info("\(String(describing: url))")
                                                        let session = URLSession.shared
                                                        if let imageURL = URL(string: image) {
                                                            Task {
                                                                let data = try await session.data(for: URLRequest(url: imageURL))
                                                                if let path = url {
                                                                    try data.0.write(to: path)
                                                                }
                                                            }
                                                        }

                                                    } label: {
                                                        Label {
                                                            Text("Save")
                                                        } icon: {
                                                            Image(systemName: "square.and.arrow.down")
                                                        }

                                                    }
                                                    NavigationLink {
                                                        if let url = URL(string: image) {
                                                            ImageScreen(url: url)
                                                        }
                                                    } label: {
                                                        Label {
                                                            Text("Open")
                                                        } icon: {
                                                            Image(systemName: "square.and.arrow.up")
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }.flippedUpsideDown()
//                                    if let image = viewModel.imageModel?.data {
//                                        ChatBubble(direction: .left) {
//                                            List(image, id: \.url) { element in
//                                                AsyncImage(url: URL(string: element.url), content: { image in
//                                                    image
//                                                        .resizable()
//                                                        .aspectRatio(contentMode: .fit)
//                                                        .frame(width: 256, height: 256, alignment: .center)
//
//                                                }, placeholder: {
//                                                    ProgressView()
//                                                })
//                                            }
//                                        }
//                                        .flippedUpsideDown()
//                                        .frame(width: 356, height: 256, alignment: .leading)
//                                    }
                                }


                            }
                            .onAppear {
                                withAnimation {
                                    if let id = viewModel.messages.first?.id {
                                        proxy.scrollTo(id, anchor: .bottom)
                                    }
                                }
                            }
                            .onReceive(Just(viewModel.messages), perform: { _ in
                                withAnimation {
                                    if let id = viewModel.messages.first?.id {
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
                            if let model {
                                sendAction()
                                if let id = viewModel.messages.last?.id {
                                    proxy.scrollTo(id, anchor: .bottom)
                                }
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
            .environment(viewModel)
        }
    }

    private func showSavePanel() -> URL? {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.png, .jpeg]
        savePanel.canCreateDirectories = true
        savePanel.isExtensionHidden = false
        savePanel.allowsOtherFileTypes = false
        savePanel.title = "Save Image"
        savePanel.message = "Choose a Folder"
        savePanel.nameFieldLabel = "File name:"
        let response = savePanel.runModal()
        return response == .OK ? savePanel.url : nil
    }

    private func sendAction() {
        if !message.isEmpty {
            isMessageLoading = true
            viewModel.messages.insert(OpenAIResponseModel(id: UUID().uuidString, object: "", created: Int(Date().timeIntervalSince1970), model: viewModel.getGPTModel() ?? "unknown", choices: [ChoiceModel(index: 0, message: Message(role: "user", content: message))], usage: Usage(promptTokens: 0, completionTokens: 0, totalTokens: 0)), at: 0)
            model?.aiModel.insert(contentsOf: viewModel.messages, at: 0)

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
                        viewModel.messages.insert(OpenAIResponseModel(id: UUID().uuidString, object: "", created: Int(Date().timeIntervalSince1970), model: viewModel.getGPTModel() ?? "unknown", choices: [ChoiceModel(index: 0, message: Message(role: "assistant", content: value.data.map { $0.revizedPrompt }.joined(separator: "\n")))], usage: Usage(promptTokens: 0, completionTokens: 0, totalTokens: 0), imageURL: value.data.first?.url), at: 0)
                        viewModel.imageModel = value
                        model?.aiModel.insert(contentsOf: viewModel.messages, at: 0)
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
                        viewModel.messages.insert(value, at: 0)
                        model?.aiModel.insert(contentsOf: viewModel.messages, at: 0)
                    }.store(in: &subscriptions)

//                do {
//                    try viewModel
//                        .getTextGoogleCloud(message)
//                        .sink { completion in
//                            switch completion {
//                            case .finished:
//                                viewModel.logger.info("Google Cloud Finished")
//                            case .failure(let error):
//                                viewModel.logger.fault("\(error)")
//                            }
//                        } receiveValue: { data in
//                            viewModel.logger.info("\(data)")
//                        }.store(in: &subscriptions)
//                } catch {
//                    viewModel.logger.fault("\(error)")
//                }
            }
            message = ""
        }
    }

    private func settingsAction() {
        isSettingPresent = true
    }
}

//#Preview {
//    MainView()
//}

