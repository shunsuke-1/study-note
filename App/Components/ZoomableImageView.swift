import SwiftUI

struct ZoomableImageView<Overlay: View>: View {
    let image: UIImage?
    let allowsOverlayHitTesting: Bool
    let allowZoom: Bool
    let overlay: (CGSize) -> Overlay

    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @GestureState private var gestureScale: CGFloat = 1.0
    @GestureState private var gestureOffset: CGSize = .zero

    init(image: UIImage?, allowsOverlayHitTesting: Bool = false, allowZoom: Bool = true, @ViewBuilder overlay: @escaping (CGSize) -> Overlay) {
        self.image = image
        self.allowsOverlayHitTesting = allowsOverlayHitTesting
        self.allowZoom = allowZoom
        self.overlay = overlay
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                if let image {
                    let combinedScale = allowZoom ? scale * gestureScale : 1.0
                    let combinedOffset = allowZoom ? CGSize(width: offset.width + gestureOffset.width, height: offset.height + gestureOffset.height) : .zero
                    var imageView = Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .scaleEffect(combinedScale)
                        .offset(combinedOffset)
                    if allowZoom {
                        imageView = imageView
                            .gesture(dragGesture().simultaneously(with: magnificationGesture()))
                            .onTapGesture(count: 2) {
                                withAnimation { resetView() }
                            }
                    }
                    imageView
                    overlay(proxy.size)
                        .scaleEffect(combinedScale)
                        .offset(combinedOffset)
                        .allowsHitTesting(allowsOverlayHitTesting)
                } else {
                    Color.gray.opacity(0.1)
                    Text("画像がありません")
                }
            }
        }
    }

    private func dragGesture() -> some Gesture {
        DragGesture()
            .updating($gestureOffset) { value, state, _ in
                state = value.translation
            }
            .onEnded { value in
                offset.width += value.translation.width
                offset.height += value.translation.height
            }
    }

    private func magnificationGesture() -> some Gesture {
        MagnificationGesture()
            .updating($gestureScale) { value, state, _ in
                state = value
            }
            .onEnded { value in
                scale = max(1.0, min(scale * value, 5.0))
            }
    }

    private func resetView() {
        scale = 1.0
        offset = .zero
    }
}
