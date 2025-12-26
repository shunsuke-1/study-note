import Foundation
import CoreGraphics

struct Marker: Identifiable, Codable, Equatable {
    let id: UUID
    var rect: CGRect // normalized (0...1)
    var createdAt: Date
    var updatedAt: Date

    init(id: UUID = UUID(), rect: CGRect, createdAt: Date = .now, updatedAt: Date = .now) {
        self.id = id
        self.rect = rect
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    private enum CodingKeys: String, CodingKey {
        case id, rectX, rectY, rectWidth, rectHeight, createdAt, updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        let x = try container.decode(CGFloat.self, forKey: .rectX)
        let y = try container.decode(CGFloat.self, forKey: .rectY)
        let w = try container.decode(CGFloat.self, forKey: .rectWidth)
        let h = try container.decode(CGFloat.self, forKey: .rectHeight)
        rect = CGRect(x: x, y: y, width: w, height: h)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(rect.origin.x, forKey: .rectX)
        try container.encode(rect.origin.y, forKey: .rectY)
        try container.encode(rect.size.width, forKey: .rectWidth)
        try container.encode(rect.size.height, forKey: .rectHeight)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
    }
}

struct PhotoCard: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var imagePath: String
    var createdAt: Date
    var markers: [Marker]

    init(id: UUID = UUID(), title: String = "", imagePath: String, createdAt: Date = .now, markers: [Marker] = []) {
        self.id = id
        self.title = title
        self.imagePath = imagePath
        self.createdAt = createdAt
        self.markers = markers
    }
}
