#if canImport(SwiftUI)
import SwiftUI
#endif

@EditorRepresentation
extension String: IValueEditorDefaultRepresentable, IEmptyInit {
    struct EditView: View {
        class ViewModel: GenericEditViewModel<String> {
            @Published var value: String = "" {
                didSet {
                    update(value)
                }
            }

            override func didUpdate(_ value: String) {
                self.value = value
            }
        }

        @ObservedObject var viewModel: ViewModel

        var body: some View {
            HStack {
                HStack {
                    Spacer()
                    Text(viewModel.name)
                }
                .frame(width: 50)
                TextField(viewModel.name, text: $viewModel.value)
            }
        }
    }
}
