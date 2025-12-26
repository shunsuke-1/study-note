import SwiftUI

@main
struct StudyNoteApp: App {
    @StateObject private var repository = CardRepository()
    @StateObject private var purchaseManager = PurchaseManager()

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(repository)
                .environmentObject(purchaseManager)
        }
    }
}
