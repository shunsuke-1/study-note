import SwiftUI

struct MarkerOverlayView: View {
    let marker: Marker
    let imageSize: CGSize
    let containerSize: CGSize
    let hidden: Bool
    let isSelected: Bool
    let editing: Bool
    let color: Color
    var onMoveStart: ((UUID) -> Void)?
    var onSelect: ((UUID) -> Void)?
    var onMove: ((UUID, CGSize) -> Void)?
    var onMoveEnd: ((UUID) -> Void)?
    var onResizeStart: ((UUID, DragHandle) -> Void)?
    var onResize: ((UUID, DragHandle, CGSize) -> Void)?
    var onResizeEnd: ((UUID, DragHandle) -> Void)?

    @State private var didStartMove = false
    @State private var resizingHandle: DragHandle?

    var body: some View {
        let frame = MarkerOverlayView.displayFrame(for: marker.rect, imageSize: imageSize, containerSize: containerSize)
        let shape = Rectangle()
            .path(in: frame)

        ZStack {
            if hidden {
                shape.fill(color.opacity(0.9))
            } else {
                shape.stroke(color, lineWidth: isSelected ? 3 : 2)
                    .background(shape.fill(color.opacity(0.15)))
            }
            if editing {
                shape.stroke(Color.accentColor, style: StrokeStyle(lineWidth: isSelected ? 3 : 2, dash: [6, 3]))
                handles(in: frame)
            }
        }
        .contentShape(Rectangle())
        .gesture(editing ? dragGesture(frame: frame) : tapGesture())
    }

    private func tapGesture() -> some Gesture {
        TapGesture().onEnded {
            onSelect?(marker.id)
        }
    }

    private func dragGesture(frame: CGRect) -> some Gesture {
        DragGesture()
            .onChanged { value in
                if !didStartMove {
                    didStartMove = true
                    onMoveStart?(marker.id)
                }
                onMove?(marker.id, value.translation)
            }
            .onEnded { value in
                onMove?(marker.id, value.translation)
                onMoveEnd?(marker.id)
                didStartMove = false
            }
    }

    private func handles(in frame: CGRect) -> some View {
        ForEach(DragHandle.allCases, id: \.self) { handle in
            let handleSize: CGFloat = 14
            Circle()
                .fill(Color.white)
                .overlay(Circle().stroke(Color.accentColor, lineWidth: 2))
                .frame(width: handleSize, height: handleSize)
                .position(handle.position(in: frame))
                .gesture(DragGesture()
                    .onChanged { value in
                        if resizingHandle == nil {
                            resizingHandle = handle
                            onResizeStart?(marker.id, handle)
                        }
                        onResize?(marker.id, handle, value.translation)
                    }
                    .onEnded { value in
                        onResize?(marker.id, handle, value.translation)
                        if let current = resizingHandle {
                            onResizeEnd?(marker.id, current)
                        }
                        resizingHandle = nil
                    })
        }
    }

    static func displayFrame(for rect: CGRect, imageSize: CGSize, containerSize: CGSize) -> CGRect {
        guard imageSize.width > 0 && imageSize.height > 0 else { return .zero }
        let scale = min(containerSize.width / imageSize.width, containerSize.height / imageSize.height)
        let displaySize = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
        let inset = CGPoint(x: (containerSize.width - displaySize.width) / 2, y: (containerSize.height - displaySize.height) / 2)
        let origin = CGPoint(x: inset.x + rect.origin.x * displaySize.width, y: inset.y + rect.origin.y * displaySize.height)
        let size = CGSize(width: rect.width * displaySize.width, height: rect.height * displaySize.height)
        return CGRect(origin: origin, size: size)
    }

    static func normalizedDelta(from translation: CGSize, imageSize: CGSize, containerSize: CGSize) -> CGSize {
        guard imageSize.width > 0 && imageSize.height > 0 else { return .zero }
        let scale = min(containerSize.width / imageSize.width, containerSize.height / imageSize.height)
        let displaySize = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
        guard displaySize.width > 0 && displaySize.height > 0 else { return .zero }
        return CGSize(width: translation.width / displaySize.width, height: translation.height / displaySize.height)
    }
}

enum DragHandle: CaseIterable {
    case topLeft, topRight, bottomLeft, bottomRight

    func position(in frame: CGRect) -> CGPoint {
        switch self {
        case .topLeft:
            return CGPoint(x: frame.minX, y: frame.minY)
        case .topRight:
            return CGPoint(x: frame.maxX, y: frame.minY)
        case .bottomLeft:
            return CGPoint(x: frame.minX, y: frame.maxY)
        case .bottomRight:
            return CGPoint(x: frame.maxX, y: frame.maxY)
        }
    }
}
