import Foundation

public protocol IAnyOMModification: Encodable {
    var typeIdentifier: String { get }

    func subscribeAnyObject(_ object: Any) throws
    func updateAnyObject(_ object: Any) throws
    func updateAnyModification(_ object: Any) throws
}

public protocol IOMNode: AnyObject {
    var omTypeIdentifier: String { get }
    var omIdentifier: String? { get set }
    var omIgnore: Bool { get set }
    var omModifications: [IAnyOMModification] { get set }
    var omSubnodes: [IOMNode] { get }

    func omAddSubnode(_ node: IOMNode) throws
    func omRemoveFromSupernode() throws
}

extension IOMNode {
    public var omTypeIdentifier: String {
        "\(Self.self)"
    }
}

public struct OMModificationType {
    public let name: String
    public let maker: () throws -> IAnyOMModification

    let identifier: String
    let loader: (Data) throws -> IAnyOMModification
    let check: (Any) -> Bool
    let isOnly: Bool

    public init(
        name: String,
        identifier: String,
        isOnly: Bool = true,
        maker: @escaping () throws -> IAnyOMModification,
        loader: @escaping (Data) throws -> IAnyOMModification,
        check: @escaping (Any) -> Bool
    ) {
        self.isOnly = isOnly
        self.name = name
        self.maker = maker
        self.loader = loader
        self.identifier = identifier
        self.check = check
    }
}

public struct OMObjectType {
    public let name: String
    public let maker: () throws -> IOMNode

    let identifier: String

    public init(
        name: String,
        identifier: String,
        maker: @escaping () throws -> IOMNode
    ) {
        self.name = name
        self.maker = maker
        self.identifier = identifier
    }
}

extension OMModificationType {
    public static func make<ModificationType: IEditorModification>(
        isOnly: Bool = true,
        name: String? = nil,
        _ maker: @escaping () throws -> ModificationType
    ) -> OMModificationType {
        OMModificationType(
            name: name ?? "\(ModificationType.self)",
            identifier: "\(ModificationType.self)",
            isOnly: isOnly,
            maker: { try maker() },
            loader: {
                try JSONDecoder().decode(ModificationType.self, from: $0)
            },
            check: {
                $0 is ModificationType.ObjectType
            }
        )
    }
}

extension OMObjectType {
    public static func make<NodeType: IOMNode>(
        name: String? = nil,
        _ maker: @escaping () throws -> NodeType
    ) -> OMObjectType {
        .init(
            name: name ?? "\(NodeType.self)",
            identifier: "\(NodeType.self)",
            maker: {
                let node = try maker()
                node.omSubnodes.forEach { $0.omIgnore = true }
                return node
            }
        )
    }
}
