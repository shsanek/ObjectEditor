#if canImport(SwiftUI)
import SwiftUI
#endif

public struct AutocompletionInputTextRepresenter: IValueEditorRepresentation {
    private let helper: IStringInputHelper
    private let autoSelectFirst: Bool

    public init(helper: IStringInputHelper, autoSelectFirst: Bool = true) {
        self.helper = helper
        self.autoSelectFirst = autoSelectFirst
    }

#if canImport(SwiftUI)
    public func makeSwiftUIView(_ info: RepresentationInfo<String>) throws -> AnyView {
        AnyView(
            AutocompletionInputTextView(
                viewModel: .init(
                    info: info,
                    autoSelectFirst: autoSelectFirst,
                    helper: helper
                )
            )
        )
    }
#endif
}
