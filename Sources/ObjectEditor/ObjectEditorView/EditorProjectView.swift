#if canImport(SwiftUI)

import SwiftUI

public struct EditorProjectView: View {
    var viewModel: EditorProjectViewModel

    public init(
        url: URL,
        fileTypeManager: IFileTypeManager,
        selectHandler: @escaping (FileInfo) -> Void,
        renameFileHandler: @escaping (FileInfo, FileInfo) -> Void
    ) {
        self.viewModel = .init(
            url: url,
            fileTypeManager: fileTypeManager,
            selectHandler: selectHandler,
            renameFileHandler: renameFileHandler
        )
    }

    public var body: some View {
        VStack {
            HStack {
                Spacer()
                Button(action: {
                    viewModel.addFolder()
                }, label: {
                    Image(systemName: "folder.fill.badge.plus")
                }).frame(width: 60, height: 60).background(.clear)
                ShowPresentButton {
                    EditorSelectView(containers: viewModel.fileTypeManager.fileTypes.map({ fileType in
                            .init(
                                select: {
                                    viewModel.addFile(fileType)
                                },
                                view: AnyView(Text(fileType.name)
                                             )
                            )
                    }))
                } label: {
                    Image(systemName: "plus.app.fill")
                }.frame(width: 60, height: 60).background(.clear)
            }
            .frame(height: 40)
            Divider().padding(.zero)
            ScrollView {
                FolderFilesView(
                    viewModel: viewModel.rootViewModel
                )
            }
        }
    }
}

final class EditorProjectViewModel {
    let url: URL
    let selectHandler: (FileInfo) -> Void
    let renameFileHandler: (FileInfo, FileInfo) -> Void
    let fileTypeManager: IFileTypeManager
    var selectedViewModel: FolderFilesViewModel? = nil {
        didSet {
            oldValue?.isSelected = false
            selectedViewModel?.isSelected = true
            if let vm = selectedViewModel {
                selectHandler(vm.node)
            }
        }
    }
    lazy var rootViewModel: FolderFilesViewModel = {
        .init(
            node: .init(
                name: url.lastPathComponent,
                fileType: .folder,
                url: url,
                subnodes: (try? url.getAllItems()) ?? []
            ),
            fileTypeManager: fileTypeManager,
            renameFileHandler: renameFileHandler,
            selectHandler: { [weak self] vm in
                self?.selectedViewModel = vm
            }
        )
    }()

    init(
        url: URL,
        fileTypeManager: IFileTypeManager,
        selectedViewModel: FolderFilesViewModel? = nil,
        selectHandler: @escaping (FileInfo) -> Void,
        renameFileHandler: @escaping (FileInfo, FileInfo) -> Void
    ) {
        self.url = url
        self.selectHandler = selectHandler
        self.renameFileHandler = renameFileHandler
        self.fileTypeManager = fileTypeManager
        self.selectedViewModel = selectedViewModel
    }

    func addFile(_ file: FileType) {
        var vm = selectedViewModel ?? rootViewModel
        if vm.node.fileType.isFile {
            guard let parent = vm.parent else {
                return
            }
            vm = parent
        }
        let fileNamePattern = "NewFile%d.\(file.ext)"
        var i = 1
        var fileName = fileNamePattern.replacingOccurrences(of: "%d", with: "")
        while true {
            if !FileManager.default.fileExists(atPath: vm.node.url.appending(path: fileName).path()) {
                break
            }
            fileName = fileNamePattern.replacingOccurrences(of: "%d", with: "\(i)")
            i += 1
        }
        let template = file.template()
        do {
            try template.write(toFile: vm.node.url.appending(path: fileName).path(), atomically: true, encoding: .utf8)
            vm.reloadNode()
            selectedViewModel = vm.subnodes.first(where: { $0.name == fileName })
            var parent = selectedViewModel?.parent
            while parent != nil {
                parent?.isOpen = true
                parent = parent?.parent
            }
        }
        catch {
            print(error)
        }
    }

    func addFolder() {
        var vm = selectedViewModel ?? rootViewModel
        if vm.node.fileType.isFile {
            guard let parent = vm.parent else {
                return
            }
            vm = parent
        }
        let fileNamePattern = "NewFolder%d"
        var i = 1
        var fileName = fileNamePattern.replacingOccurrences(of: "%d", with: "")
        while true {
            if !FileManager.default.fileExists(atPath: vm.node.url.appending(path: fileName).path()) {
                break
            }
            fileName = fileNamePattern.replacingOccurrences(of: "%d", with: "\(i)")
            i += 1
        }
        do {
            try FileManager.default.createDirectory(at: vm.node.url.appending(path: fileName), withIntermediateDirectories: true)
            vm.reloadNode()
        }
        catch {
            print(error)
        }
    }
}
#endif
