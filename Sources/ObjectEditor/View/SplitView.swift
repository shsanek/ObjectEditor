#if canImport(SwiftUI)
import SwiftUI

public final class SplitViewModel: ObservableObject  {
    @Published public var contentA: AnyView
    @Published public var contentB: (() -> AnyView)?
    @Published var position: CGFloat = 150

    var size: CGSize = .zero {
        didSet {
            if !isDragging {
                self.position = aspect * size.width
            }
        }
    }
    var location: CGFloat = 150 {
        didSet {
            aspect = max(min(0.9, location / size.width), 0.1)
        }
    }
    var isDragging: Bool = false
    public private(set) var aspect: CGFloat = 0.5 {
        didSet {
            position = aspect * size.width
        }
    }

    public init(
        contentA: AnyView,
        aspect: CGFloat = 0.5
    ) {
        self.contentA = contentA
        self.contentB = nil
        self.aspect = aspect
    }
}

public struct SplitView: View {
    @ObservedObject var viewModel: SplitViewModel
    let uuidSpace = UUID().uuidString

    var simpleDrag: some Gesture {
        DragGesture(coordinateSpace: .named(uuidSpace))
            .onChanged { value in
                viewModel.isDragging = true
                viewModel.location = value.location.x
            }.onEnded { gesture in
                viewModel.isDragging = false
            }
    }

    public init(viewModel: SplitViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        GeometryReader { proxy in
            HStack {
                viewModel.contentA
                    .frame(width: viewModel.position)
                Color.black
                    .frame(width: 4)
                    .gesture(simpleDrag)
                if let view = viewModel.contentB?() {
                    view
                }
            }
            .coordinateSpace(name: uuidSpace)
            .preference(key: SizePreferenceKey.self, value: proxy.size)
        }.onPreferenceChange(SizePreferenceKey.self) { newSize in
            viewModel.size = newSize
        }
    }

    struct SizePreferenceKey: PreferenceKey {
        static var defaultValue: CGSize = .zero
        static func reduce(value: inout CGSize, nextValue: () -> CGSize) {}
    }
}
#endif
