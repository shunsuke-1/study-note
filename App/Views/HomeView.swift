import SwiftUI
import PhotosUI

struct HomeView: View {
    @EnvironmentObject private var repository: CardRepository
    @State private var showingPicker = false
    @State private var showingCamera = false
    @State private var showingSourceAction = false
    @State private var pickerItem: PhotosPickerItem?

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(repository.cards) { card in
                        NavigationLink(value: card.id) {
                            CardThumbnail(card: card)
                        }
                        .contextMenu {
                            Button(role: .destructive) {
                                delete(card: card)
                            } label {
                                Label("削除", systemImage: "trash")
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("暗記アルバム")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingSourceAction = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .navigationDestination(for: UUID.self) { id in
                if let card = repository.cards.first(where: { $0.id == id }) {
                    DetailView(card: card)
                }
            }
        }
        .confirmationDialog("写真を追加", isPresented: $showingSourceAction, titleVisibility: .visible) {
            Button("カメラ") { showingCamera = true }
            PhotosPicker(selection: $pickerItem, matching: .images) {
                Text("フォトライブラリ")
            }
            Button("キャンセル", role: .cancel) { }
        }
        .sheet(isPresented: $showingCamera) {
            CameraPicker { image in
                try? repository.addImage(image)
            }
        }
        .onChange(of: pickerItem) { newValue in
            guard let newValue else { return }
            Task {
                if let data = try? await newValue.loadTransferable(type: Data.self), let image = UIImage(data: data) {
                    try? repository.addImage(image)
                }
                pickerItem = nil
            }
        }
    }

    private func delete(card: PhotoCard) {
        repository.deleteCard(card)
    }
}

struct CardThumbnail: View {
    @EnvironmentObject private var repository: CardRepository
    let card: PhotoCard

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                if let image = repository.image(for: card) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    Color.gray.opacity(0.15)
                    Image(systemName: "photo")
                }
            }
            .frame(height: 140)
            .clipped()
            Text(card.title.isEmpty ? "無題" : card.title)
                .font(.headline)
                .lineLimit(1)
            Text(card.createdAt, style: .date)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(8)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}
