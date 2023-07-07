#if canImport(SwiftUI)
import SwiftUI

public struct SimpleDescriptionView<ValueType>: View {
    class ViewModel: GenericEditViewModel<ValueType> {
        @Published var value: String = ""

        override func didUpdate(_ value: ValueType) {
            self.value = "\(value)"
        }
    }

    @ObservedObject var viewModel: ViewModel

    public var body: some View {
        if !viewModel.value.isEmpty {
            VStack {
                HStack {
                    Text(viewModel.name)
                    Spacer()
                }
                HStack {
                    Text(viewModel.value)
                    Spacer()
                }
            }
        }
    }
}
#endif

public struct SimpleDescriptionRepresentation<ValueType>: IValueEditorRepresentation {
    #if canImport(SwiftUI)
    public func makeSwiftUIView(_ info: RepresentationInfo <ValueType>) throws -> AnyView {
        AnyView(SimpleDescriptionView(viewModel: .init(info: info)))
    }
    #endif
}
