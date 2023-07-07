#if canImport(SwiftUI)
import SwiftUI

public struct ShowPresentButton: View {
    @State private var showingSheet = false

    let makeView: () -> AnyView
    let label: () -> AnyView

    public init<MV: View, LV: View>(view: @escaping () -> MV, label: @escaping () -> LV) {
        self.makeView = { AnyView(view()) }
        self.label = { AnyView(label()) }
    }

    public var body: some View {
        Button {
            showingSheet.toggle()
        } label: {
            label()
        }
        .sheet(isPresented: $showingSheet) {
            makeView()
        }
    }
}
#endif
