#if canImport(SwiftUI)
import SwiftUI
#endif

@EditorRepresentation
extension Bool: IValueEditorDefaultRepresentable {
    struct EditView: View {
        class ViewModel: GenericEditViewModel<Bool> {
            @Published var value: Bool = true {
                didSet {
                    update(value)
                }
            }

            override func didUpdate(_ value: Bool) {
                self.value = value
            }
        }

        @ObservedObject var viewModel: ViewModel

        var body: some View {
            HStack {
                Toggle(isOn: $viewModel.value, label: {
                    Text(viewModel.name)
                })
                Spacer()
            }
        }
    }
}
