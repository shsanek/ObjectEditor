#if canImport(SwiftUI)
import SwiftUI

public struct EditorModificationView: View {
    public struct ViewContainer: Identifiable {
        public let id: String
        public let view: AnyView
        public init(id: String, view: AnyView) {
            self.id = id
            self.view = view
        }
    }

    public let views: [ViewContainer]

    public var body: some View {
        VStack {
            ForEach(views) {
                $0.view
            }
        }
    }

    public init(views: [ViewContainer]) {
        self.views = views
    }
}
#endif
