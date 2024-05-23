//
//  ImageScreen.swift
//  chatOpenAi
//
//  Created by Oleksii Mykhalchuk on 4/4/24.
//

import SwiftUI

struct ImageScreen: View {

    let url: URL

    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            AsyncImage(url: url) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } placeholder: {
                ProgressView()
            }
            .navigationTitle("Image")
            .toolbar {
                ToolbarItem {
                    Button {
                        dismiss()
                    } label: {
                        Text("Dismiss")
                    }
                }
                ToolbarItem {
                    Button {
                        let url = showSavePanel()
                        AppLogger().info("\(String(describing: url))")
                        let session = URLSession.shared
                        if let imageURL = url {
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
                }
            }
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
}
