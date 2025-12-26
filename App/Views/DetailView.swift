import SwiftUI

struct DetailView: View {
    @EnvironmentObject private var repository: CardRepository
    @EnvironmentObject private var purchaseManager: PurchaseManager
    @Environment(\.dismiss) private var dismiss

    let card: PhotoCard
    @State private var currentCard: PhotoCard
    @State private var hideMode = true
    @State private var showingEditor = false
    @GestureState private var pressReveal = false

    init(card: PhotoCard) {
        self.card = card
        _currentCard = State(initialValue: card)
    }

    var body: some View {
        VStack(spacing: 0) {
            toolbar
            Divider()
            content
            footerNav
        }
        .navigationBarBackButtonHidden()
        .onReceive(repository.$cards) { cards in
            if let updated = cards.first(where: { $0.id == currentCard.id }) {
                currentCard = updated
            }
        }
        .sheet(isPresented: $showingEditor) {
            if let image = repository.image(for: currentCard) {
                MarkerEditorView(card: currentCard, image: image)
                    .environmentObject(repository)
                    .environmentObject(purchaseManager)
            }
        }
    }

    private var toolbar: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.backward")
                Text("戻る")
            }
            Spacer()
            Toggle(isOn: $hideMode) {
                Text(hideMode ? "隠す" : "表示")
                    .fontWeight(.semibold)
            }
            .toggleStyle(.switch)
            Spacer()
            Button(action: { showingEditor = true }) {
                Label("編集", systemImage: "pencil")
            }
        }
        .padding()
    }

    private var content: some View {
        GeometryReader { proxy in
            if let image = repository.image(for: currentCard) {
                let hideMarkers = hideMode && !pressReveal
                ZoomableImageView(image: image) { size in
                    ZStack {
                        ForEach(currentCard.markers) { marker in
                            MarkerOverlayView(marker: marker,
                                             imageSize: image.size,
                                             containerSize: size,
                                             hidden: hideMarkers,
                                             isSelected: false,
                                             editing: false,
                                             color: .black)
                        }
                    }
                }
                .gesture(LongPressGesture(minimumDuration: 0.2).updating($pressReveal) { value, state, _ in
                    state = value
                })
            } else {
                Color.gray.opacity(0.1)
                Text("画像が見つかりません")
            }
        }
    }

    private var footerNav: some View {
        HStack {
            Button(action: previousCard) {
                Label("前へ", systemImage: "chevron.left")
            }
            .disabled(previousCardID == nil)
            Spacer()
            Button(action: nextCard) {
                Label("次へ", systemImage: "chevron.right")
            }
            .disabled(nextCardID == nil)
        }
        .padding()
    }

    private var previousCardID: UUID? {
        guard let index = repository.cards.firstIndex(where: { $0.id == currentCard.id }), index > 0 else { return nil }
        return repository.cards[repository.cards.index(before: index)].id
    }

    private var nextCardID: UUID? {
        guard let index = repository.cards.firstIndex(where: { $0.id == currentCard.id }), repository.cards.index(after: index) < repository.cards.endIndex else { return nil }
        return repository.cards[repository.cards.index(after: index)].id
    }

    private func previousCard() {
        guard let id = previousCardID, let card = repository.cards.first(where: { $0.id == id }) else { return }
        currentCard = card
    }

    private func nextCard() {
        guard let id = nextCardID, let card = repository.cards.first(where: { $0.id == id }) else { return }
        currentCard = card
    }
}
