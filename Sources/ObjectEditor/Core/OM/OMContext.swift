 public final class OMContext {
     private(set) var objects: [String: OMObjectType] = [:]
     private(set) var modifications: [String: OMModificationType] = [:]

     public init() {}

     public func registerObjectType(_ obj: OMObjectType) throws {
         guard objects[obj.identifier] == nil else {
             throw OMError.message("already register")
         }
         objects[obj.identifier] = obj
     }

     public func registerModificationsType(_ obj: OMModificationType) throws {
         guard modifications[obj.identifier] == nil else {
             throw OMError.message("already register")
         }
         modifications[obj.identifier] = obj
     }

     public func addAllModification(_ node: IOMNode) throws {
         try modifications.values.filter({ $0.check(node) }).forEach { mod in
             let modification = try mod.maker()
             try modification.updateAnyModification(node)
             try modification.subscribeAnyObject(node)
             node.omModifications.append(modification)
         }
     }

     public func getAllObjectType() -> [OMObjectType] {
         Array(objects.values)
     }

     public func getAllModifications(for object: IOMNode) -> [OMModificationType] {
         return modifications
             .values
             .filter({ $0.check(object) })
     }
}

extension OMContext {
    public func registerObjects(_ array: [OMObjectType]) throws {
        try array.forEach {
            try registerObjectType($0)
        }
    }

    public func registerModifications(_ array: [OMModificationType]) throws {
        try array.forEach {
            try registerModificationsType($0)
        }
    }
}
