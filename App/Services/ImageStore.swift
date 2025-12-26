import Foundation
import UIKit

struct ImageStore {
    private let fileManager = FileManager.default
    private let folderName = "Images"

    private var imagesDirectory: URL {
        let base = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first ?? URL(fileURLWithPath: NSTemporaryDirectory())
        let dir = base.appendingPathComponent(folderName, isDirectory: true)
        if !fileManager.fileExists(atPath: dir.path) {
            try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    func save(image: UIImage) throws -> String {
        let id = UUID().uuidString
        let url = imagesDirectory.appendingPathComponent("\(id).jpg")
        guard let data = image.jpegData(compressionQuality: 0.9) else {
            throw NSError(domain: "ImageStore", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to encode image"])
        }
        try data.write(to: url, options: .atomic)
        return url.path
    }

    func deleteImage(at path: String) {
        let url = URL(fileURLWithPath: path)
        try? fileManager.removeItem(at: url)
    }

    func loadImage(at path: String) -> UIImage? {
        UIImage(contentsOfFile: path)
    }
}
