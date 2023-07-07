#if canImport(SwiftUI)
import SwiftUI
#endif

public struct OptionalRepresentation<Wrapped>: IValueEditorRepresentation {
    private let defaultValue: Wrapped
    private let representation: IAnyValueEditorRepresentation

    public init<Rep: IValueEditorRepresentation>(
        _ defaultValue: Wrapped,
        _ representation: Rep
    ) where Rep.ValueType == Wrapped {
        self.defaultValue = defaultValue
        self.representation = representation
    }

    #if canImport(SwiftUI)
    public func makeSwiftUIView(_ info: RepresentationInfo<Wrapped?>) throws -> AnyView {
        let value = info.container.value ?? defaultValue
        let wrappedContainer = ValueContainer(value: value)
        let wrappedInfo = RepresentationInfo(name: "value", container: wrappedContainer)
        let wrappedView = try representation.makeSwiftUIView(wrappedInfo)
        return AnyView(
            Optional<Wrapped>.EditView(
                viewModel: .init(container: wrappedContainer, info: info),
                wrappedView: wrappedView
            )
        )
    }
    #endif
}

extension OptionalRepresentation where Wrapped: IValueEditorDefaultRepresentable {
    public init(
        _ defaultValue: Wrapped
    ) {
        self.defaultValue = defaultValue
        self.representation = Wrapped.defaultRepresentation
    }
}

extension Optional: IValueEditorDefaultRepresentable, IAnyValueEditorDefaultRepresentable where Wrapped: (IDefaultValue&IValueEditorDefaultRepresentable) {
    public static var defaultRepresentation: OptionalRepresentation<Wrapped> {
        OptionalRepresentation(Wrapped.defaultValue)
    }
}

extension Optional {
    struct EditView: View {
        class ViewModel: GenericEditViewModel<Wrapped?> {
            @Published var isNull: Bool {
                didSet {
                    if isNull {
                        update(nil)
                    } else {
                        update(value)
                    }
                }
            }

            var value: Wrapped {
                didSet {
                    if !isNull {
                        update(value)
                    }
                }
            }

            override func didUpdate(_ value: Wrapped?) {
                if let value = value {
                    self.wrappedContainer.value = value
                    self.isNull = false
                    self.value = value
                } else {
                    self.isNull = true
                }
            }

            private let wrappedContainer: ValueContainer<Wrapped>
            private var listener: AnyObject?

            init(
                container: ValueContainer<Wrapped>,
                info: RepresentationInfo<Wrapped?>
            ) {
                self.isNull = info.container.value == nil
                self.wrappedContainer = container
                self.value = container.value
                super.init(info: info)
                listener = container.addListener({ [weak self] value in
                    self?.value = value
                })
            }

            deinit {
                self.wrappedContainer.removeListener(listener)
            }
        }

        @ObservedObject var viewModel: ViewModel
        let wrappedView: AnyView

        var body: some View {
            VStack {
                HStack {
                    Text(viewModel.name)
                    Spacer()
                    Toggle(isOn: $viewModel.isNull, label: {
                        Text("null")
                    })
                }
                if !viewModel.isNull {
                    wrappedView
                }
            }
        }
    }
}
