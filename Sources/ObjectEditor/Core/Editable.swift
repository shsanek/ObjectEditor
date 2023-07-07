#if canImport(SwiftUI)
import SwiftUI
#endif

@propertyWrapper public final class Editable<ValueType> {
    public var wrappedValue: ValueType {
        set {
            container.value = newValue
        }
        get {
            container.value
        }
    }
    public let container: ValueContainer<ValueType>
    private let representation: IAnyValueEditorRepresentation
    private let name: String?

    public var updateObjectHandler: ((ValueType) -> Void)?

    public init<Rep: IValueEditorRepresentation, Mapper: IEditorMapper>(
        wrappedValue: ValueType,
        representation: Rep,
        mapper: Mapper.Type,
        key: StaticString = "",
        name: String? = nil
    ) where ValueType == Rep.ValueType, Mapper.Model == ValueType {
        self.representation = representation
        self.container = ValueContainer(value: wrappedValue)
        self.name = name
        listener = self.container.addListener({ [weak self] value in
            self?.updateObjectHandler?(value)
        })
    }

    public init<Rep: IValueEditorRepresentation>(
        wrappedValue: ValueType,
        representation: Rep,
        key: StaticString = "",
        name: String? = nil
    ) where ValueType == Rep.ValueType {
        self.representation = representation
        self.container = ValueContainer(value: wrappedValue)
        self.name = name
        listener = self.container.addListener({ [weak self] value in
            self?.updateObjectHandler?(value)
        })
    }

    private var listener: AnyObject? = nil

    deinit {
        self.container.removeListener(listener)
    }

    public init(
        wrappedValue: ValueType,
        key: StaticString = "",
        name: String? = nil
    ) {
        self.representation = (ValueType.self as? IAnyValueEditorDefaultRepresentable.Type)?.anyDefaultRepresentation ?? SimpleDescriptionRepresentation<ValueType>()
        self.container = ValueContainer(value: wrappedValue)
        self.name = name
        listener = self.container.addListener({ [weak self] value in
            self?.updateObjectHandler?(value)
        })
    }

    public init<Mapper: IEditorMapper>(
        wrappedValue: ValueType,
        mapper: Mapper.Type,
        key: StaticString = "",
        name: String? = nil
    ) where Mapper.Model == ValueType {
        self.representation = (ValueType.self as? IAnyValueEditorDefaultRepresentable.Type)?.anyDefaultRepresentation ?? SimpleDescriptionRepresentation<ValueType>()
        self.container = ValueContainer(value: wrappedValue)
        self.name = name
        listener = self.container.addListener({ [weak self] value in
            self?.updateObjectHandler?(value)
        })
    }

#if canImport(SwiftUI)
    public func createEditorSwiftUIView(with baseName: String) throws -> AnyView {
        try representation.makeSwiftUIView(RepresentationInfo(name: name ?? baseName, container: container))
    }
#endif
}
