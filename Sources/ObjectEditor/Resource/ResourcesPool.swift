import Foundation

public protocol IResourcesPool {
    func path(_ resources: IResource) -> String?
    func getData(_ resource: IResource) throws -> Data
}
public protocol IResource {
    var containerName: String { get }
    var path: String { get }
}

public struct Resource: Codable, IEmptyInit {
    public var fullPath: String

    public init() {
        self.fullPath = ""
    }

    public init(_ fullPath: String) {
        self.fullPath = fullPath
    }
}

extension Resource: IResource {
    public var containerName: String {
        guard fullPath.contains(":") else {
            return ResourcesPool.defaultContainerName
        }
        return fullPath.components(separatedBy: ":").first ?? ""
    }

    public var path: String {
        guard fullPath.contains(":") else {
            return fullPath
        }
        return fullPath.components(separatedBy: ":").last ?? ""
    }
}

public protocol IResourcesContainer {
    var path: String { get }
    func path(forResource path: String) -> String?
}

extension Bundle: IResourcesContainer {
    public var path: String {
        self.resourcePath ?? self.bundlePath
    }

    public func path(forResource path: String) -> String? {
        self.path(forResource: path, ofType: "")
    }
}

public struct FolderResourcesContainer: IResourcesContainer {
    public let path: String

    public init(path: String) {
        self.path = path.hasSuffix("/") ? String(path.dropLast()) : path
    }

    public func path(forResource path: String) -> String? {
        let path = path.hasPrefix("/") ? String(path.dropFirst()) : path
        return self.path + "/" + path
    }
}

extension ResourcesPool {
    public static let `default` = ResourcesPool()

    public static let defaultContainerName: String = "default"
}

public final class ResourcesPool: IResourcesPool, IStringInputHelper {
    public private(set) var containers: [String: IResourcesContainer] = [:]

    public init() {
    }

    public func addContainer(_ container: IResourcesContainer, with name: String) {
        containers[name] = container
    }

    public func path(_ resources: IResource) -> String? {
        guard !resources.containerName.isEmpty else {
            return nil
        }
        guard !resources.path.isEmpty else {
            return nil
        }
        guard let container = containers[resources.containerName] else {
            return nil
        }
        guard let path = container.path(forResource: resources.path) else {
            return nil
        }
        guard FileManager.default.fileExists(atPath: path) else {
            return nil
        }
        return path
    }

    public func getData(_ resource: IResource) throws -> Data {
        guard let path = path(resource) else {
            throw EditorError.message("file not found")
        }
        guard let data = try? Data(contentsOf: URL(filePath: path)) else {
            throw EditorError.message("not load file")
        }
        return data
    }

    public func getAutocompletionVariations(_ input: String, completion: @escaping (_ variations: [String]) -> Void) {
        let fullInput = input.lowercased()
        let input = input.components(separatedBy: "/").dropLast().joined(separator: "/")
        let containerName: String = input.contains(":") ? input.components(separatedBy: ":")[0] : ResourcesPool.defaultContainerName
        let path = input.hasPrefix("\(containerName):") ? String(input.dropFirst(containerName.count + 1)) : input
        let containers = self.containers

        DispatchQueue.global().async {
            let containerNameList = Array(containers.keys.map({ "\($0):" })
                .sorted())
                .filter({ $0 != ResourcesPool.defaultContainerName + ":" })
                .filter({ $0.lowercased().hasPrefix(fullInput) })
            guard let containerPath = containers[containerName]?.path else {
                DispatchQueue.main.async {
                    completion(containerNameList)
                }
                return
            }
            let url = URL(filePath: containerPath).appending(path: path)
            let items = ((try? FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)) ?? [])
                .map({ (input.isEmpty ? "" : (input + "/")) + $0.lastPathComponent + ($0.isDirectory ? "/" : "") })
                .filter({ $0.lowercased().hasPrefix(fullInput) })
            DispatchQueue.main.async {
                completion(containerNameList + items)
            }
        }
    }
}

extension URL {
    var isDirectory: Bool {
       (try? resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true
    }

    var updateDate: Date? {
       (try? resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate
    }
}
