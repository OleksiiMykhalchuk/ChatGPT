//
//  SettingsView.swift
//  chatOpenAi
//
//  Created by Oleksii Mykhalchuk on 2/12/24.
//

import SwiftUI
import Security
import Combine

public struct SettingsView: View {

    @Environment(ViewModel.self) var viewModel: ViewModel

    private let keychainService = KeychainService()

    @State private var text: String = ""
    @State private var isExist: Bool = false

    @State private var error: Error?
    @State private var isError: Bool = false

    @State private var key: String?
    @State private var isSecure: Bool = true

    @Binding var isPresented: Bool

    @State var aiModel: AIModel = .gpt3

    @State private var subscriptions = Set<AnyCancellable>()
    private let logger = AppLogger()

    @State private var verifyMessage: String = ""
    @State private var isAnimating: Bool = false
    @State private var textSize: String = "\(ThemeManager.textSize)"

    public var body: some View {
        NavigationStack {
            VStack {
                Group {
                    if verifyMessage.isEmpty {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .scaleEffect(0.5)
                            .opacity(isAnimating ? 1 : 0)
                    } else {
                        Text("\(verifyMessage)")
                            .padding()
                    }
                }

                Picker(selection: $aiModel) {
                    Text("Gpt - 3").tag(AIModel.gpt3)
                    Text("Gpt - 4").tag(AIModel.gpt4)
                    Text("Dall-E").tag(AIModel.dalle)
                    Text("Dall-e-2").tag(AIModel.dalle2)
                } label: {
                    Text("Choose Model: ")
                }.padding()
                    .pickerStyle(.radioGroup)
                    .onChange(of: aiModel) { _, newValue in
                        viewModel.saveGPTModel(newValue.rawValue)
                    }
                HStack {
                    Text("Text Size: ")
                        .padding()
                    TextField("Message Text Size", text: $textSize)
                        .onChange(of: textSize) { _, newValue in
                            ThemeManager.textSize = Float(newValue)
                        }
                        .padding()
                }

                HStack {
                    Text("Open AI API Key: ")
                        .padding()
                    Group {
                        if isSecure {
                            SecureField("ApiKey", text: $text)
                                .padding()
                        } else {
                            TextField("ApiKey", text: $text)
                                .padding()
                        }
                    }
                }

                HStack {
                    Button("Save") {
                        saveKey()
                    }
                    .padding()
                    Button("Delete") {
                        deleteKey()
                    }
                    .padding()
                    Button("Verify") {
                        isAnimating = true
                        verifyMessage = ""
                        viewModel
                            .verifyAPIKey()
                            .sink { completion in
                                switch completion {
                                case .finished:
                                    logger.info("\(completion)")
                                case .failure(let error):
                                    logger.fault("\(error)")
                                }
                            } receiveValue: { value in
                                verifyMessage = "Response Code: \(value ?? 999)"
                                isAnimating = false
                            }.store(in: &subscriptions)
                    }
                    .padding()
                    Button("Update") {
                        updateApi()
                    }
                    .padding()
                    Button(isSecure ? "Show Password" : "Hide Password") {
                        isSecure.toggle()
                    }
                    .padding()
                    Button("Close") {
                        dismissAction()
                    }
                    .padding()
                }
                .padding()
            }
            .frame(minWidth: 800)
            .toolbarRole(.automatic)
            .navigationTitle("Add/Delete Api Key")
            .onAppear {
                aiModel = AIModel(rawValue: viewModel.getGPTModel() ?? "") ?? .gpt3
                viewModel.saveGPTModel(aiModel.rawValue)
                textSize = "\(ThemeManager.textSize ?? 12.0)"
            }
            .alert("Error", isPresented: $isError) {
                Button("OK") {

                }
            } message: {
                Text("\(error?.localizedDescription ?? "")")
            }

        }
    }

    private func throwing(_ action: @escaping () throws -> Void) {
        DispatchQueue.global().async {
            do {
                try action()
            } catch {
                self.error = error
                isError = true
            }
        }
    }

    private func saveKey() {

        throwing {
            try keychainService.storeValue(text)
        }
    }

    private func deleteKey() {

        throwing {
            try keychainService.deleteValue()
        }
    }

    private func verifyApi() {

        throwing {
            key = try keychainService.fetchValue()
        }

    }

    private func updateApi() {
        throwing {
            try keychainService.updateItem(text)
        }
    }

    private func dismissAction() {
        isPresented = false
    }
}

extension String {
    static let storeApiKey = "storeApiKey"
}
//
//#Preview {
//    SettingsView(isPresented: .init(get: {
//        true
//    }, set: { value in
//        //
//    }))
//}
