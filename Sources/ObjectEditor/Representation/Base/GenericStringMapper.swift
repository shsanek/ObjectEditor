#if canImport(SwiftUI)
import SwiftUI

public protocol IStringMapper {
    associatedtype ValueType

    var defaultValue: ValueType { get }

    func toValue(_ string: String) throws -> ValueType
    func toString(_ value: ValueType) -> String
}

extension IStringMapper {
    public func toString(_ value: ValueType) -> String {
        "\(value)"
    }
}

public protocol IStringMapperRepresentable: IValueEditorDefaultRepresentable {
    associatedtype Mapper: IStringMapper where Mapper.ValueType == Self
    static var mapper: Mapper { get }
}

extension IStringMapperRepresentable {
    public static var defaultRepresentation: StringMapperRepresentableView<Mapper>.Rep {
        .init(mapper: mapper)
    }
}

public struct StringMapperRepresentableView<Mapper: IStringMapper>: View {

    @ObservedObject var viewModel: ViewModel

    public var body: some View {
        HStack {
            HStack {
                Spacer()
                Text(viewModel.name)
            }
            .frame(width: 50)
            TextField(viewModel.name, text: $viewModel.value, onCommit: { viewModel.commit() })
        }
    }
}

extension StringMapperRepresentableView {
    public struct Rep: IValueEditorRepresentation {
        public let mapper: Mapper

        public init(mapper: Mapper) {
            self.mapper = mapper
        }

        public func makeSwiftUIView(_ info: RepresentationInfo <Mapper.ValueType>) throws -> AnyView {
            AnyView(StringMapperRepresentableView(viewModel: .init(mapper: mapper, info: info)))
        }
    }
}

extension StringMapperRepresentableView {
    public class ViewModel: GenericEditViewModel<Mapper.ValueType> {
        private let mapper: Mapper

        @Published var value: String = "" {
            didSet {
                if let obj = try? mapper.toValue(value) {
                    update(obj)
                } else {
                    if value.isEmpty {
                        update(mapper.defaultValue)
                    } else {
                        updateBlock {
                            value = mapper.toString(container.value)
                        }
                    }
                }
            }
        }

        public func commit() {
            DispatchQueue.main.async {
                self.updateBlock {
                    self.value = self.mapper.toString(self.container.value)
                }
            }
        }

        public init(mapper: Mapper, info: RepresentationInfo<Mapper.ValueType>) {
            self.mapper = mapper
            super.init(info: info)
        }

        public override func didUpdate(_ value: Mapper.ValueType) {
            self.value = mapper.toString(value)
        }
    }
}
#endif
