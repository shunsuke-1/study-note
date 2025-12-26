import Foundation
import StoreKit

@MainActor
final class PurchaseManager: ObservableObject {
    @Published var isPremium: Bool = false
    @Published var products: [Product] = []
    @Published var purchaseState: PurchaseState = .idle

    enum PurchaseState {
        case idle
        case purchasing
        case purchased
        case failed(Error)
    }

    let productIDs: Set<String> = ["premium_unlock"]

    init() {
        Task {
            await load()
            await listenForTransactions()
        }
    }

    func load() async {
        do {
            products = try await Product.products(for: Array(productIDs))
            await updateEntitlements()
        } catch {
            print("Failed to load products: \(error)")
        }
    }

    func purchase() async {
        guard let product = products.first else { return }
        purchaseState = .purchasing
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                if case .verified(let transaction) = verification {
                    await transaction.finish()
                    purchaseState = .purchased
                    await updateEntitlements()
                } else {
                    purchaseState = .failed(PurchaseError.verificationFailed)
                }
            case .userCancelled:
                purchaseState = .idle
            default:
                purchaseState = .idle
            }
        } catch {
            purchaseState = .failed(error)
        }
    }

    func restore() async {
        do {
            try await AppStore.sync()
            await updateEntitlements()
        } catch {
            purchaseState = .failed(error)
        }
    }

    private func listenForTransactions() async {
        for await result in Transaction.updates {
            if case .verified(let transaction) = result {
                await transaction.finish()
                await updateEntitlements()
            }
        }
    }

    private func updateEntitlements() async {
        for await entitlement in Transaction.currentEntitlements {
            if case .verified(let transaction) = entitlement, productIDs.contains(transaction.productID) {
                isPremium = true
                return
            }
        }
        isPremium = false
    }

    enum PurchaseError: Error {
        case verificationFailed
    }
}
