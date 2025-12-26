import SwiftUI

struct MarkerEditorView: View {
    @EnvironmentObject private var repository: CardRepository
    @EnvironmentObject private var purchaseManager: PurchaseManager
    @Environment(\.dismiss) private var dismiss

    let card: PhotoCard
    let image: UIImage

    @State private var markers: [Marker]
    @State private var selectedID: UUID?
    @State private var showPremium = false
    @State private var containerSize: CGSize = .zero
    @State private var moveStartRect: CGRect?
    @State private var resizeStartRect: CGRect?
    @State private var activeHandle: DragHandle?

    private var markerLimit: Int {
        purchaseManager.isPremium ? repository.premiumMarkerLimit : repository.freeMarkerLimit
    }

    init(card: PhotoCard, image: UIImage) {
        self.card = card
        self.image = image
        _markers = State(initialValue: card.markers)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                editorToolbar
                Divider()
                GeometryReader { proxy in
                    Color.clear
                        .overlay(editorCanvas(size: proxy.size))
                        .onAppear { containerSize = proxy.size }
                        .onChange(of: proxy.size) { newSize in containerSize = newSize }
                }
            }
            .navigationTitle("マーカー編集")
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $showPremium) {
            PremiumView()
                .environmentObject(purchaseManager)
        }
    }

    private var editorToolbar: some View {
        HStack {
            Button("完了") { saveAndDismiss() }
                .fontWeight(.semibold)
            Spacer()
            Text("\(markers.count) / \(markerLimit)")
                .font(.subheadline)
                .padding(.trailing)
            Button(action: addMarker) {
                Image(systemName: "plus")
            }
            .disabled(markers.count >= markerLimit)
            Button(role: .destructive, action: deleteSelected) {
                Image(systemName: "trash")
            }
            .disabled(selectedID == nil)
        }
        .padding()
    }

    private func editorCanvas(size: CGSize) -> some View {
        ZoomableImageView(image: image, allowsOverlayHitTesting: true, allowZoom: false) { container in
            ZStack {
                ForEach(markers) { marker in
                    MarkerOverlayView(marker: marker,
                                     imageSize: image.size,
                                     containerSize: container,
                                     hidden: false,
                                     isSelected: marker.id == selectedID,
                                     editing: true,
                                     color: .black,
                                     onMoveStart: { id in beginMove(id: id) },
                                     onSelect: { id in selectedID = id },
                                     onMove: { id, translation in moveMarker(id: id, translation: translation, container: container) },
                                     onMoveEnd: { _ in moveStartRect = nil },
                                     onResizeStart: { id, _ in beginResize(id: id) },
                                     onResize: { id, handle, translation in resizeMarker(id: id, handle: handle, translation: translation, container: container) },
                                     onResizeEnd: { _, _ in resizeStartRect = nil; activeHandle = nil })
                }
            }
        }
    }

    private func beginMove(id: UUID) {
        moveStartRect = markers.first(where: { $0.id == id })?.rect
        selectedID = id
    }

    private func moveMarker(id: UUID, translation: CGSize, container: CGSize) {
        guard let start = moveStartRect, let index = markers.firstIndex(where: { $0.id == id }) else { return }
        let delta = MarkerOverlayView.normalizedDelta(from: translation, imageSize: image.size, containerSize: container)
        var newRect = start
        newRect.origin.x += delta.width
        newRect.origin.y += delta.height
        markers[index].rect = clamp(rect: newRect)
        markers[index].updatedAt = .now
    }

    private func beginResize(id: UUID) {
        resizeStartRect = markers.first(where: { $0.id == id })?.rect
        selectedID = id
    }

    private func resizeMarker(id: UUID, handle: DragHandle, translation: CGSize, container: CGSize) {
        guard let start = resizeStartRect, let index = markers.firstIndex(where: { $0.id == id }) else { return }
        let delta = MarkerOverlayView.normalizedDelta(from: translation, imageSize: image.size, containerSize: container)
        var rect = start
        switch handle {
        case .topLeft:
            rect.origin.x += delta.width
            rect.origin.y += delta.height
            rect.size.width -= delta.width
            rect.size.height -= delta.height
        case .topRight:
            rect.origin.y += delta.height
            rect.size.width += delta.width
            rect.size.height -= delta.height
        case .bottomLeft:
            rect.origin.x += delta.width
            rect.size.width -= delta.width
            rect.size.height += delta.height
        case .bottomRight:
            rect.size.width += delta.width
            rect.size.height += delta.height
        }
        markers[index].rect = clamp(rect: rect)
        markers[index].updatedAt = .now
    }

    private func clamp(rect: CGRect) -> CGRect {
        var x = rect.origin.x
        var y = rect.origin.y
        var width = rect.width
        var height = rect.height
        let minSize: CGFloat = 0.05

        width = max(width, minSize)
        height = max(height, minSize)

        x = min(max(0, x), 1 - width)
        y = min(max(0, y), 1 - height)

        return CGRect(x: x, y: y, width: min(width, 1), height: min(height, 1))
    }

    private func addMarker() {
        guard markers.count < markerLimit else {
            showPremium = true
            return
        }
        let size = CGSize(width: 0.3, height: 0.2)
        let origin = CGPoint(x: (1 - size.width) / 2, y: (1 - size.height) / 2)
        let marker = Marker(rect: CGRect(origin: origin, size: size))
        markers.append(marker)
        selectedID = marker.id
    }

    private func deleteSelected() {
        guard let id = selectedID else { return }
        markers.removeAll { $0.id == id }
        selectedID = nil
    }

    private func saveAndDismiss() {
        repository.updateMarkers(for: card.id, markers: markers)
        dismiss()
    }
}
