import Foundation

public protocol IEditorMapper {
    associatedtype Model
    associatedtype Object

    static func fillObject(_ object: inout Object, from model: Model)
    static func objectToModel(_ object: Object) -> Model
}

public struct ModificationMapper<Modification: IEditorModification>: IEditorMapper {
    public static func objectToModel(_ object: Modification.ObjectType) -> Modification {
        Modification(object)
    }

    public static func fillObject(_ object: inout Modification.ObjectType, from model: Modification) {
        model.updateObject(object)
    }
}

extension IEditorDirectMapper where Model: IDefaultValue {
    public static var directOptional: DirectOptionalMapper<Self>.Type {
        DirectOptionalMapper<Self>.self
    }
}

extension IEditorMapper where Model: IDefaultValue {
    public static var optional: OptionalMapper<Self>.Type {
        OptionalMapper<Self>.self
    }
}

public struct OptionalMapper<Mapper: IEditorMapper>: IEditorMapper where Mapper.Model: IDefaultValue {
    public static func fillObject(_ object: inout Mapper.Object?, from model: Mapper.Model) {
        guard var obj = object else {
            return
        }
        Mapper.fillObject(&obj, from: model)
        object = obj
    }

    public static func objectToModel(_ object: Mapper.Object?) -> Mapper.Model {
        guard let obj = object else {
            return Mapper.Model.defaultValue
        }
        return Mapper.objectToModel(obj)
    }
}


public struct DirectOptionalMapper<Mapper: IEditorDirectMapper>: IEditorMapper where Mapper.Model: IDefaultValue {
    public static func fillObject(_ object: inout Mapper.Object?, from model: Mapper.Model) {
        guard var obj = object else {
            object = Mapper.modelToObject(model)
            return
        }
        Mapper.fillObject(&obj, from: model)
        object = obj
    }

    public static func objectToModel(_ object: Mapper.Object?) -> Mapper.Model {
        guard let obj = object else {
            return Mapper.Model.defaultValue
        }
        return Mapper.objectToModel(obj)
    }
}

public protocol IEditorDirectMapper: IEditorMapper {
    static func modelToObject(_ model: Model) -> Object?
}

extension IEditorDirectMapper {
    public static func fillObject(_ object: inout Object, from model: Model) {
        if let obj = modelToObject(model) {
            object = obj
        }
    }
}
