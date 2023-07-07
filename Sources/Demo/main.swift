import AppKit
import SwiftUI
import ObjectEditor


public struct SwiftUIView: NSViewRepresentable {
    public var wrappedView: NSView

    private var handleUpdateUIView: ((NSView, Context) -> Void)?
    private var handleMakeUIView: ((Context) -> NSView)?

    public init(closure: () -> NSView) {
        wrappedView = closure()
    }

    public func makeNSView(context: Context) -> NSView {
        guard let handler = handleMakeUIView else {
            return wrappedView
        }

        return handler(context)
    }

    public func updateNSView(_ uiView: NSView, context: Context) {
        handleUpdateUIView?(uiView, context)
    }
}

public extension SwiftUIView {
    mutating func setMakeUIView(handler: @escaping (Context) -> NSView) -> Self {
        handleMakeUIView = handler
        return self
    }

    mutating func setUpdateUIView(handler: @escaping (NSView, Context) -> Void) -> Self {
        handleUpdateUIView = handler
        return self
    }
}

@available(macOS 10.15, *)
class AppDelegate: NSObject, NSApplicationDelegate {
    let window = NSWindow()
    let two = NSWindowController()

    func applicationDidFinishLaunching(_ notification: Notification) {
        let appMenu = NSMenuItem()
        appMenu.submenu = NSMenu()
        let mainMenu = NSMenu(title: "My Swift Script")
        mainMenu.addItem(appMenu)
        NSApplication.shared.mainMenu = mainMenu

        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }
}

let downloadURL = FileManager
    .default
    .urls(for: .downloadsDirectory, in: .userDomainMask)[0]
    .appending(path: "WorkFolder")

ResourcesPool.default.addContainer(
    FolderResourcesContainer(path: downloadURL.path()),
    with: ResourcesPool.defaultContainerName
)

public final class EditorProjectManagerDelegate: IEditorProjectManagerDelegate {
    private var windows = [EditorWindow]()
    private var splitVM: SplitViewModel?

    let context: OMContext

    init(context: OMContext) {
        self.context = context
    }

    public func openNode(
        node: IOMNode,
        selectedNode: @escaping (IOMNode?) -> Void,
        actionHandler: @escaping (IEditorAction) -> Void
    ) throws -> AnyView {
        guard let view = node as? NSView else {
            throw EditorError.message("node is not NSView")
        }
        let splitVM = SplitViewModel(
            contentA: AnyView(SwiftUIView(closure: { view })),
            aspect: self.splitVM?.aspect ?? 0.7
        )
        splitVM.contentB = { [context] in
            AnyView(
                EditorView(
                    context: context,
                    node: node,
                    selectHandler: selectedNode,
                    actionHandler: actionHandler
                )
            )
        }
        self.splitVM = splitVM
        return AnyView(
            SplitView(
                viewModel: splitVM
            )
        )
    }
}

let editorDelegate = EditorProjectManagerDelegate(context: .appContext)
let editor = MACEditorProjectManager(
    baseTypeIdentifier: "NSView",
    context: .appContext,
    pool: .default,
    delegate: editorDelegate
)

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
let window = EditorWindow({ NSView() }, delegate: EditorWindow.Delegate(closeHandler: {
    editor.save()
    editor.close()
    NSApplication.shared.terminate(0)
}))
try editor.start({ view in
    window.view = {
        NSHostingView(rootView: view)
    }
})
window.show(inFullScreen: true, title: "Editor")
app.run()
