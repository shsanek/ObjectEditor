//import EditorMacro

public struct CreateModel { }

@attached(member, names: arbitrary)
public macro EditorModification<Raw>(mutable: Bool = false) = #externalMacro(module: "EditorMacro", type: "EditorModification")

@attached(member, names: arbitrary)
public macro EditorRepresentation() = #externalMacro(module: "EditorMacro", type: "EditorRepresentation")

@attached(member, names: arbitrary)
public macro StorableExtension() = #externalMacro(module: "EditorMacro", type: "StorableExtension")


//@attached(member, names: arbitrary)
//public macro Storable() = #externalMacro(module: "EditorMacro", type: "EmptyMacro")
//
//@attached(member, names: arbitrary)
//public macro Updatable() = #externalMacro(module: "EditorMacro", type: "EmptyMacro")

#warning("fix this")

@propertyWrapper public final class Updatable<ValueType> {
    public var wrappedValue: ValueType

    public init(wrappedValue: ValueType) {
        self.wrappedValue = wrappedValue
    }
}

@propertyWrapper public final class Storable<ValueType> {
    public var wrappedValue: ValueType

    public init(wrappedValue: ValueType) {
        self.wrappedValue = wrappedValue
    }
}

@propertyWrapper public final class Ignorable<ValueType> {
    public var wrappedValue: ValueType

    public init(wrappedValue: ValueType) {
        self.wrappedValue = wrappedValue
    }
}
