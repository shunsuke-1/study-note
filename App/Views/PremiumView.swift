import SwiftUI

struct PremiumView: View {
    @EnvironmentObject private var purchaseManager: PurchaseManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("Premium")
                    .font(.largeTitle).bold()
                Text("マーカー上限を解除して、好きなだけ追加できます。")
                    .multilineTextAlignment(.center)
                VStack(alignment: .leading, spacing: 12) {
                    Label("上限 \(purchaseManager.isPremium ? "無制限" : "Free 5個 → Unlimited")", systemImage: "checkmark.seal")
                    Label("広告なし", systemImage: "nosign")
                    Label("購入はApple IDに紐づきます", systemImage: "lock")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Spacer()
                if purchaseManager.isPremium {
                    Text("購入済み")
                        .font(.title2)
                        .foregroundColor(.green)
                } else {
                    Button(action: { Task { await purchaseManager.purchase() } }) {
                        Text("¥ Buy Premium")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    Button("購入を復元") {
                        Task { await purchaseManager.restore() }
                    }
                }
                Button("閉じる") { dismiss() }
                    .padding(.top)
            }
            .padding()
            .navigationTitle("プレミアム")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
