import Foundation
#if canImport(SwiftUI)
import SwiftUI
#endif

public protocol IAnyEditorModification: IAnyOMModification {
    #if canImport(SwiftUI)
    func makeAnyEditSwiftUIView() throws -> AnyView
    #endif
}

extension IAnyEditorModification {
    public var typeIdentifier: String {
        "\(Self.self)"
    }
}

public protocol IEditorModification: Codable, IAnyEditorModification
{
    associatedtype ObjectType

    init(_ object: ObjectType)

    #if canImport(SwiftUI)
    func _makeEditSwiftUIView() throws -> AnyView
    func makeEditSwiftUIView() throws -> AnyView
    #endif
    func _subscribeObject(_ object: ObjectType)
    func _updateObject(_ object: ObjectType)
    func _updateModification(_ object: ObjectType)

    func subscribeObject(_ object: ObjectType)
    func updateObject(_ object: ObjectType)
    func updateModification(_ object: ObjectType)
}


extension IEditorModification {
    public func _subscribeObject(_ object: ObjectType) { }
    public func _updateObject(_ object: ObjectType) { }
    public func _updateModification(_ object: ObjectType) { }

    #if canImport(SwiftUI)
    public func _makeEditSwiftUIView() throws -> AnyView {
        throw EditorError.message("not implementation")
    }
    public func makeEditSwiftUIView() throws -> AnyView {
        try _makeEditSwiftUIView()
    }
    public func makeAnyEditSwiftUIView() throws -> AnyView {
        try makeEditSwiftUIView()
    }
    #endif

    public func subscribeObject(_ object: ObjectType) {
        _subscribeObject(object)
    }
    public func updateObject(_ object: ObjectType) {
        _updateObject(object)
    }

    public func updateModification(_ object: ObjectType) {
        _updateModification(object)
    }

    public func subscribeAnyObject(_ object: Any) throws {
        guard let obj = object as? ObjectType else {
            throw EditorError.message("'\(object)' is not '\(ObjectType.self)'")
        }
        subscribeObject(obj)
    }

    public func updateAnyObject(_ object: Any) throws {
        guard let obj = object as? ObjectType else {
            throw EditorError.message("'\(object)' is not '\(ObjectType.self)'")
        }
        updateObject(obj)
    }

    public func updateAnyModification(_ object: Any) throws {
        guard let obj = object as? ObjectType else {
            throw EditorError.message("'\(object)' is not '\(ObjectType.self)'")
        }
        updateModification(obj)
    }
}
