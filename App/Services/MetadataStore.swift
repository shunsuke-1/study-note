import Foundation

final class MetadataStore {
    private let defaults = UserDefaults.standard
    private let key = "cards_v1"

    func save(_ cards: [PhotoCard]) throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(cards)
        defaults.set(data, forKey: key)
    }

    func load() -> [PhotoCard] {
        guard let data = defaults.data(forKey: key) else { return [] }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return (try? decoder.decode([PhotoCard].self, from: data)) ?? []
    }
}
