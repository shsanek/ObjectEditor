#if canImport(SwiftUI)
import SwiftUI

public struct FolderFilesView: View {
    @ObservedObject var viewModel: FolderFilesViewModel
    @FocusState var focusedField: Bool
    private let space: Float

    public init(
        viewModel: FolderFilesViewModel,
        space: Float = 0
    ) {
        self.viewModel = viewModel
        self.space = space
    }

    public var body: some View {
        VStack {
            HStack {
                Spacer()
                    .frame(width: CGFloat(space))
                if viewModel.node.fileType.isFolder {
                    Group {
                        if viewModel.isOpen {
                            Image(systemName: "chevron.down")
                                .frame(width: 25, height: 25)
                        } else {
                            Image(systemName: "chevron.right")
                                .frame(width: 25, height: 25)
                        }
                    }.onTapGesture {
                        viewModel.isOpen.toggle()
                    }
                } else {
                    Spacer().frame(width: 25)
                }
                Image(systemName: viewModel.imageSystemName)
                    .frame(width: 25, height: 25)
                if viewModel.isEditName {
                    TextField("name", text: $viewModel.name) {
                        viewModel.saveName()
                    }
                    .focused($focusedField, equals: true)
                    .background(.clear)
                    .onAppear(perform: {
                        focusedField = true
                    })
                } else {
                    Text(viewModel.name).onAppear(perform: {
                        focusedField = false
                    }).lineLimit(1)
                }
                Spacer()
            }.onTapGesture {
                viewModel.select()
            }
            .background(viewModel.isSelected ? .blue : .clear)
            .clipShape(RoundedRectangle(cornerRadius: 8.0, style: .continuous))
            if !viewModel.subnodes.isEmpty && viewModel.isOpen {
                HStack {
                    VStack {
                        ForEach(viewModel.subnodes, id: \.node.url) { viewModel in
                            FolderFilesView(viewModel: viewModel, space: space + 20)
                        }
                    }
                }
            }
        }
    }
}

public struct ProjectState: Codable {
    static var resource: Resource = .init("project.json")
    public var openedFolders: [String]
    public var selectFile: String?
}

public class FolderFilesViewModel: ObservableObject {
    @Published var name: String
    @Published var isSelected: Bool = false {
        didSet {
            if !self.isSelected {
                self.isEditName = false
            }
        }
    }
    @Published var subnodes: [FolderFilesViewModel] = []
    @Published var isOpen: Bool = false
    @Published var isEditName: Bool = false
    @Published var imageSystemName: String = "list.bullet.rectangle.portrait.fill"

    weak var parent: FolderFilesViewModel?

    let fileTypeManager: IFileTypeManager
    let isEnable: Bool
    let selectHandler: (FolderFilesViewModel) -> Void
    let renameFileHandler: ((FileInfo, FileInfo) -> Void)
    private(set) var node: FileInfo

    public init(
        node: FileInfo,
        isEnable: Bool = true,
        fileTypeManager: IFileTypeManager,
        renameFileHandler: @escaping ((FileInfo, FileInfo) -> Void),
        selectHandler: @escaping (FolderFilesViewModel) -> Void,
        parent: FolderFilesViewModel? = nil
    ) {
        self.node = node
        self.name = node.name
        self.fileTypeManager = fileTypeManager
        self.isEnable = isEnable
        self.selectHandler = selectHandler
        self.renameFileHandler = renameFileHandler
        self.parent = parent
        reloadNode()
    }

    public func loadState(_ state: ProjectState, rootPath: String) {
        let path = node.url.path()
        let localPath = path.hasSuffix(rootPath) ? String(path.dropFirst(rootPath.count)) : path

        if state.openedFolders.contains(localPath) {
            self.isOpen = true
        }
        if state.selectFile == localPath {
            select()
        }
        for node in subnodes {
            node.loadState(state, rootPath: rootPath)
        }
    }

    public func saveState(_ rootPath: String) -> ProjectState {
        var state = ProjectState(openedFolders: [])
        for node in subnodes {
            let subState = node.saveState(rootPath)
            state.openedFolders.append(contentsOf: subState.openedFolders)
            state.selectFile = state.selectFile ?? subState.selectFile
        }
        let path = node.url.path()
        let localPath = path.hasSuffix(rootPath) ? String(path.dropFirst(rootPath.count)) : path
        if isOpen {
            state.openedFolders.append(localPath)
        }
        if isSelected {
            state.selectFile = localPath
        }
        return state
    }

    func reloadNode() {
        self.node = .init(name: name, fileType: node.fileType, url: node.url, subnodes: (try? node.url.getAllItems()) ?? [])
        self.subnodes = node.subnodes.map({ node in
            .init(node: node, fileTypeManager: fileTypeManager, renameFileHandler: renameFileHandler, selectHandler: selectHandler, parent: self)
        }).sorted(by: { a, b in
            if a.node.fileType.isFolder && !b.node.fileType.isFolder {
                return true
            }
            if b.node.fileType.isFolder && !a.node.fileType.isFolder {
                return false
            }
            return a.node.name < b.node.name
        })
        if node.fileType.isFolder {
            imageSystemName = "folder.fill"
        } else if let name = fileTypeManager.fileTypes.first(where: { $0.ext == node.url.pathExtension })?.systemImageName {
            imageSystemName = name
        } else {
            imageSystemName = "list.bullet.rectangle.portrait.fill"
        }
    }


    func saveName() {
        isEditName = false
        let newURL = node.url.deletingLastPathComponent().appendingPathComponent(name)
        do {
            try FileManager.default.moveItem(at: node.url, to: newURL)
            let old = node
            self.node = .init(name: name, fileType: node.fileType, url: newURL, subnodes: (try? node.url.getAllItems()) ?? [])
            reloadNode()
            self.renameFileHandler(old, self.node)
        }
        catch {
            name = node.url.lastPathComponent
            print(error)
        }
    }

    func select() {
        guard isEnable else {
            return
        }
        if isSelected {
            isEditName = true
        } else {
            selectHandler(self)
        }
    }
}
#endif
