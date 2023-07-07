import Foundation

public struct FileType {
    public let name: String
    public let ext: String
    public let systemImageName: String?
    public let template: () -> String

    public init(name: String, ext: String, systemImageName: String?, template: @escaping () -> String) {
        self.name = name
        self.ext = ext
        self.systemImageName = systemImageName
        self.template = template
    }
}

public protocol IFileTypeManager {
    var fileTypes: [FileType] { get }
}

extension FileType {
    public static func node(baseTypeIdentifier: String) -> Self {
        .init(
            name: "Empty Node",
            ext: "node",
            systemImageName: "square.3.layers.3d.down.forward",
            template: {
            """
            {
                "typeIdentifier": "\(baseTypeIdentifier)",
                "identifier": "Root",
                "modifications": [],
                "subnodes": []
            }
            """
            }
        )
    }
}
