import Foundation

#if canImport(SwiftUI)
import SwiftUI

public protocol IEditorProjectManagerDelegate: AnyObject {
    func openNode(
        node: IOMNode,
        selectedNode: @escaping (IOMNode?) -> Void,
        actionHandler: @escaping (IEditorAction) -> Void
    ) throws -> AnyView
}

public class MACEditorProjectManager: IFileTypeManager {
    public var storageFileTypes: [FileType] = []
    public var fileTypes: [FileType] {
        var result: [FileType] = []
        if let selectedNode = currentSubNode, currentSubNode !== current {
            result.append(
                .init(
                    name: "From select",
                    ext: "node",
                    systemImageName: "square.3.layers.3d.down.forward",
                    template: { [serialization, baseTypeIdentifier] in
                        guard
                            let data = try? serialization.saveNode(selectedNode),
                            let text = String(data: data, encoding: .utf8)
                        else {
                            return FileType.node(baseTypeIdentifier: baseTypeIdentifier).template()
                        }
                        return text
                    })
            )
        }
        if let data = nodeBuffer {
            result.append(
                .init(
                    name: "From buffer",
                    ext: "node",
                    systemImageName: "square.3.layers.3d.down.forward",
                    template: { [baseTypeIdentifier] in
                        guard
                            let text = String(data: data, encoding: .utf8)
                        else {
                            return FileType.node(baseTypeIdentifier: baseTypeIdentifier).template()
                        }
                        return text
                    })
            )
        }
        return result + storageFileTypes
    }

    private let context: OMContext
    private let serialization: OMSerialization

    private var current: IOMNode?
    private var currentFile: FileInfo?
    private var currentSubNode: IOMNode?

    private weak var delegate: IEditorProjectManagerDelegate?
    private let pool: ResourcesPool
    private let baseTypeIdentifier: String
    private var updateViewHandler: ((AnyView) -> Void)?
    private lazy var splitView = SplitView(viewModel: splitViewModel)

    private let splitViewModel = SplitViewModel(
        contentA: AnyView(EmptyView()),
        aspect: 0.15
    )

    public init(baseTypeIdentifier: String, context: OMContext, pool: ResourcesPool, delegate: IEditorProjectManagerDelegate) {
        self.context = context
        self.baseTypeIdentifier = baseTypeIdentifier
        self.serialization = OMSerialization(
            omContext: context,
            resourcesPool: pool
        )
        self.pool = pool
        storageFileTypes.append(
            .node(baseTypeIdentifier: baseTypeIdentifier)
        )
        self.delegate = delegate
    }

    private var editorProjectView: EditorProjectView?
    private var isLoaded: Bool = false

    public func start(_ updateViewHandler: @escaping (AnyView) -> Void) throws {
        guard let container = self.pool.containers[ResourcesPool.defaultContainerName] else {
            throw EditorError.message("default pool could't found")
        }
        isLoaded = false
        let editor = EditorProjectView(
            url: URL(filePath: container.path),
            fileTypeManager: self,
            selectHandler: { [weak self] node in
                self?.open(node)
            },
            renameFileHandler: { [weak self] old, node in
                self?.updateRename(old, node: node)
            }
        )
        editorProjectView = editor
        splitViewModel.contentA = AnyView(editor)

        self.updateViewHandler = updateViewHandler
        if
            let data = try? pool.getData(ProjectState.resource),
            let state = try? JSONDecoder().decode(ProjectState.self, from: data)
        {
            editor.viewModel.rootViewModel.loadState(state, rootPath: editor.viewModel.rootViewModel.node.url.path())
        }
        if !isLoaded {
            updateViewHandler(
                AnyView(
                    splitView
                )
            )
        }
    }

    public func close() {
        guard let container = self.pool.containers[ResourcesPool.defaultContainerName] else {
            return
        }
        guard
            let root = editorProjectView?.viewModel.rootViewModel.node.url.path(),
            let state = editorProjectView?.viewModel.rootViewModel.saveState(root),
            let data = try? JSONEncoder().encode(state)
        else {
            return
        }
        let url = URL(filePath: container.path).appending(path: ProjectState.resource.path)
        try? data.write(to: url)
    }

    public func save() {
        do {
            guard let node = current, let file = currentFile else {
                return
            }
            let data = try serialization.saveNode(node)
            try data.write(to: file.url)
        }
        catch {
            print(error)
        }
    }

    private func handleAction(_ action: IEditorAction) {
        let handler = ActionsHandler()
        handler.registerHandler(ActionType.copy) { [weak self] action in
            self?.copyNode(action.input)
            action.completion?(Void())
        }
        handler.registerHandler(ActionType.past) { [weak self] action in
            self?.pastNode(action.input)
            action.completion?(Void())
        }
        handler.registerHandler(ActionType.makeNew) { [weak self] action in
            try self?.makeNew(name: action.input, completion: action.completion)
        }
        do {
            try handler.handle(action)
        }
        catch {
            print(error)
        }
    }

    private var nodeBuffer: Data?

    private func makeNew(name: String, completion: ((IOMNode) -> Void)?) throws {
        guard let object = context.objects[name] else {
            throw EditorError.message("Type with name `\(name)` could't found")
        }
        guard let node = currentSubNode ?? current else {
            throw EditorError.message("Node not found")
        }
        let newObject = try object.maker()
        try node.omAddSubnode(newObject)
        let modifications = try context.getAllModifications(for: newObject).map { try $0.maker() }
        try modifications.forEach {
            newObject.omModifications.append($0)
            try $0.updateAnyObject(newObject)
            try $0.subscribeAnyObject(newObject)
        }
        completion?(newObject)
    }

    private func copyNode(_ node: IOMNode) {
        guard let data = try? serialization.saveNode(node) else {
            return
        }
        return nodeBuffer = data
    }

    private func pastNode(_ node: IOMNode) {
        guard let data = nodeBuffer, let newNode = try? serialization.loadNode(data) else {
            return
        }
        try? node.omAddSubnode(newNode)
    }

    private func updateRename(_ old: FileInfo, node: FileInfo) {
        guard let current = currentFile else {
            return
        }
        if current.url == old.url {
            self.currentFile = node
        }
        if current.url.path().hasPrefix(old.url.path()) {
            let url = node.url.appending(path: current.url.path().dropFirst(old.url.path().count))
            self.currentFile = .init(
                name: url.lastPathComponent,
                fileType: current.fileType,
                url: url,
                subnodes: (try? url.getAllItems()) ?? []
            )
        }
    }

    private func open(_ file: FileInfo) {
        guard file.fileType.fileExtension == "node" else {
            return
        }
        save()
        guard let data = try? Data(contentsOf: file.url), let node = try? serialization.loadNode(data) else {
            return
        }
        let view = try? delegate?.openNode(node: node, selectedNode: { [weak self] node in
            self?.currentSubNode = node
        }, actionHandler: { [weak self] action in
            self?.handleAction(action)
        })
        guard let view = view else {
            return
        }
        self.current = node
        self.currentFile = file
        self.currentSubNode = nil

        splitViewModel.contentB = { [weak self] in
            AnyView(
                VStack {
                    HStack {
                        Button(action: {
                            self?.save()
                        }, label: {
                            Image(systemName: "square.and.pencil")
                        }).frame(width: 60, height: 60).background(.clear)
                        Text(file.name)
                        Spacer()
                    }.frame(height: 40)
                    Divider().padding(.zero)
                    view
                }
            )
        }
        updateViewHandler?(
            AnyView(
                splitView
            )
        )
        isLoaded = true
    }
}
#endif
