#if canImport(SwiftUI)
import SwiftUI
#endif

public protocol IAnyValueEditorRepresentation {
    #if canImport(SwiftUI)
    func makeSwiftUIView(_ container: Any) throws -> AnyView
    #endif
}

public struct RepresentationInfo<ValueType> {
    public let name: String
    public let container: ValueContainer<ValueType>
}

public protocol IValueEditorRepresentation: IAnyValueEditorRepresentation {
    associatedtype ValueType
    #if canImport(SwiftUI)
    func makeSwiftUIView(_ info: RepresentationInfo<ValueType>) throws -> AnyView
    #endif
}

#if canImport(SwiftUI)
extension IValueEditorRepresentation {
    public func makeSwiftUIView(_ container: Any) throws -> AnyView {
        guard let container = container as? RepresentationInfo<ValueType> else {
            throw EditorError.message("'\(container)' is not 'ValueContainer<ValueType>'")
        }
        return try makeSwiftUIView(container)
    }
}
#endif

public protocol IAnyValueEditorDefaultRepresentable {
    static var anyDefaultRepresentation: IAnyValueEditorRepresentation { get }
}

public protocol IValueEditorDefaultRepresentable: IAnyValueEditorDefaultRepresentable {
    associatedtype Rep: IValueEditorRepresentation where Rep.ValueType == Self
    static var defaultRepresentation: Rep { get }
}

extension IValueEditorDefaultRepresentable {
    public static var anyDefaultRepresentation: IAnyValueEditorRepresentation {
        defaultRepresentation
    }
}
