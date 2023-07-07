import Foundation

public final class FileInfo {
    public enum FileType {
        case folder
        case file(_ extension: String)

        public var isFolder: Bool {
            switch self {
            case .folder:
                return true
            default:
                return false
            }
        }

        public var isFile: Bool {
            !isFolder
        }

        public var fileExtension: String? {
            switch self {
            case .file(let ext):
                return ext
            default:
                return nil
            }
        }
    }
    public let name: String
    public let fileType: FileType
    public let url: URL
    public let subnodes: [FileInfo]

    public init(name: String, fileType: FileType, url: URL, subnodes: [FileInfo]) {
        self.name = name
        self.fileType = fileType
        self.subnodes = subnodes
        self.url = url
    }
}

extension URL {
    public func getAllItems() throws -> [FileInfo] {
        let items = try FileManager
            .default
            .contentsOfDirectory(at: self, includingPropertiesForKeys: nil)
            .map({ item in
                FileInfo(
                    name: item.lastPathComponent,
                    fileType: item.isDirectory ? .folder : .file(item.pathExtension),
                    url: item,
                    subnodes: item.isDirectory ? ((try? item.getAllItems()) ?? []) : []
                )
            })
        return items
    }
}
