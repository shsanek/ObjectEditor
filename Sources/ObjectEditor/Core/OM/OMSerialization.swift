import Foundation

public final class OMSerialization {
    let omContext: OMContext
    let resourcesPool: IResourcesPool

    public init(omContext: OMContext, resourcesPool: IResourcesPool) {
        self.omContext = omContext
        self.resourcesPool = resourcesPool
    }

    public func saveNode(_ node: IOMNode) throws -> Data {
        guard let dictionary = try encodeNode(node) else {
            throw EditorError.message("incorrect root objects")
        }
        return try JSONSerialization.data(withJSONObject: dictionary)
    }

    public func loadNode(_ data: Data) throws -> IOMNode {
        let dictionary = try JSONSerialization.jsonObject(with: data, options: .mutableContainers)
        return try loadNode(with: dictionary)
    }

    private func encodeNode(_ node: IOMNode) throws -> Any? {
        var dictionary = [String: Any?]()
        if !omContext.objects.contains(where: { $0.key == node.omTypeIdentifier }) {
            return nil
        }
        dictionary[OMBaseKey.typeIdentifier] = node.omTypeIdentifier
        dictionary[OMBaseKey.identifier] = node.omIdentifier
        dictionary[OMBaseKey.modifications] = try node.omModifications.map { try encodeModification($0) }
        dictionary[OMBaseKey.subnodes] = try node.omSubnodes.filter({ !$0.omIgnore }).compactMap { try encodeNode($0) }
        return dictionary
    }

    private func encodeModification(_ modification: IAnyOMModification) throws -> Any {
        var dictionary = [String: Any?]()
        dictionary[OMBaseKey.typeIdentifier] = modification.typeIdentifier
        dictionary[OMBaseKey.body] = try objectToDictionary(modification)
        return dictionary
    }

    private func objectToDictionary<T: Encodable>(_ obj: T) throws -> Any {
        let data = try JSONEncoder().encode(obj)
        return try JSONSerialization.jsonObject(with: data, options: .mutableContainers)
    }

    private func loadNode(with dictionary: Any) throws -> IOMNode {
        guard let dictionary = dictionary as? [String: Any] else {
            throw OMError.message("\(dictionary) is not dictionary")
        }
        guard let typeIdentifier = dictionary[OMBaseKey.typeIdentifier] as? String else {
            throw OMError.message("typeIdentifier not found")
        }
        guard let object = omContext.objects[typeIdentifier] else {
            throw OMError.message("object for '\(typeIdentifier)' not found")
        }
        let node = try object.maker()
        guard let modifications = dictionary[OMBaseKey.modifications] as? [Any] else {
            throw OMError.message("modifications not found")
        }
        guard let subnodes = dictionary[OMBaseKey.subnodes] as? [Any] else {
            throw OMError.message("subnodes not found")
        }
        let identifier = dictionary[OMBaseKey.identifier] as? String
        node.omSubnodes.forEach { $0.omIgnore = true }
        node.omIdentifier = identifier
        try subnodes
            .map({ try self.loadNode(with: $0) })
            .forEach { child in
                try node.omAddSubnode(child)
            }
        try modifications
            .map({ try self.loadModification(with: $0) })
            .forEach { modification in
                node.omModifications.append(modification)
                try modification.updateAnyObject(node)
                try modification.subscribeAnyObject(node)
            }
        return node
    }

    private func getTemplate(from typeIdentifier: String) -> Resource? {
        guard typeIdentifier.hasPrefix(OMBaseKey.templatePrefix) else {
            return nil
        }
        return Resource(String(typeIdentifier.dropFirst(OMBaseKey.templatePrefix.count)))
    }

    private func loadModification(with dictionary: Any) throws -> IAnyOMModification {
        guard let dictionary = dictionary as? [String: Any] else {
            throw OMError.message("\(dictionary) is not dictionary")
        }
        guard let typeIdentifier = dictionary[OMBaseKey.typeIdentifier] as? String else {
            throw OMError.message("typeIdentifier not found")
        }
        guard let modification = omContext.modifications[typeIdentifier] else {
            throw OMError.message("modification for '\(typeIdentifier)' not found")
        }
        guard let body = dictionary[OMBaseKey.body] else {
            throw OMError.message("body not found")
        }
        let data = try JSONSerialization.data(withJSONObject: body)
        return try modification.loader(data)
    }
}
