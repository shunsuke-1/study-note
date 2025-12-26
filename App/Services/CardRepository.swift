import Foundation
import SwiftUI
import UIKit

@MainActor
final class CardRepository: ObservableObject {
    @Published private(set) var cards: [PhotoCard] = []

    let freeMarkerLimit = 5
    let premiumMarkerLimit = 1000

    private let imageStore = ImageStore()
    private let metadataStore = MetadataStore()

    init() {
        cards = metadataStore.load()
    }

    func addImage(_ image: UIImage, title: String = "") throws {
        let path = try imageStore.save(image: image)
        let card = PhotoCard(title: title, imagePath: path)
        cards.insert(card, at: 0)
        try persist()
    }

    func deleteCard(_ card: PhotoCard) {
        cards.removeAll { $0.id == card.id }
        imageStore.deleteImage(at: card.imagePath)
        try? persist()
    }

    func updateMarkers(for cardID: UUID, markers: [Marker]) {
        guard let index = cards.firstIndex(where: { $0.id == cardID }) else { return }
        cards[index].markers = markers
        try? persist()
    }

    func rename(cardID: UUID, title: String) {
        guard let index = cards.firstIndex(where: { $0.id == cardID }) else { return }
        cards[index].title = title
        try? persist()
    }

    func move(from source: IndexSet, to destination: Int) {
        cards.move(fromOffsets: source, toOffset: destination)
        try? persist()
    }

    func image(for card: PhotoCard) -> UIImage? {
        imageStore.loadImage(at: card.imagePath)
    }

    private func persist() throws {
        try metadataStore.save(cards)
    }
}
