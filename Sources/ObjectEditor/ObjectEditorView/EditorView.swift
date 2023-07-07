#if canImport(SwiftUI)
import SwiftUI

public struct EditorView: View {
    @State var refresh: Bool = false

    let context: OMContext
    let node: IOMNode
    let selectHandler: (IOMNode?) -> Void
    let actionHandler: (IEditorAction) -> Void

    @State var selectedNode: IOMNode? = nil {
        didSet {
            selectHandler(selectedNode)
        }
    }

    public init(
        context: OMContext,
        node: IOMNode,
        selectHandler: @escaping (IOMNode?) -> Void,
        actionHandler: @escaping (IEditorAction) -> Void = { _ in }
    ) {
        self.context = context
        self.node = node
        self.selectHandler = selectHandler
        self.actionHandler = actionHandler
    }

    public var body: some View {
        ScrollView {
            VStack {
                if refresh {
                    EmptyView()
                }
                HStack {
                    Text("Tree")
                    Spacer()
                    ShowPresentButton {
                        EditorSelectView(
                            containers: context
                                .getAllObjectType()
                                .map { object in
                                    .make(text: object.name) {
                                        actionHandler(
                                            ActionType.makeNew.make(input: object.identifier) { node in
                                                self.selectedNode = node
                                            }
                                        )
                                    }
                                }
                        )
                    } label: {
                        Text("+")
                    }
                }
                EditorTreeView(root: node, selectNode: selectedNode) { action in
                    if let action = ActionType.select.as(action) {
                        selectedNode = action.input
                    }
                    actionHandler(action)
                }
                Divider()
                if let node = selectedNode {
                    EditorObjectView(
                        context: context,
                        node: node,
                        updateNameHandler: { refresh.toggle() },
                        removeHandler: { selectedNode = nil }
                    )
                }
            }
        }
    }
}

#endif

