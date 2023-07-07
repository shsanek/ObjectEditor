#if canImport(SwiftUI)
import SwiftUI

extension IOMNode {
    fileprivate var id: ObjectIdentifier { ObjectIdentifier(self) }
}

public struct EditorTreeView: View {
    @State var refresh: Bool = false
    @FocusState var isActive: Bool
    
    let root: IOMNode
    let selectNode: IOMNode?
    let actionHandler: (IEditorAction) -> Void

    public init(root: IOMNode, selectNode: IOMNode?, actionHandler: @escaping (IEditorAction) -> Void) {
        self.root = root
        self.actionHandler = actionHandler
        self.selectNode = selectNode
    }

    public var menuItems: some View {
        Group {
            Button(
                "copy",
                action: {
                    actionHandler(ActionType.copy.make(input: root))
                }
            )
            .keyboardShortcut("c")
            Button(
                "past",
                action: {
                    actionHandler(ActionType.past.make(input: root))
                    refresh.toggle()
                }
            )
            .keyboardShortcut("v")
        }
    }

    public var body: some View {
        VStack {
            if refresh {
                EmptyView()
            }
            HStack {
                Text(root.omIdentifier ?? root.omTypeIdentifier)
                    .background(selectNode === root ? .black : .clear)
                Spacer()
                if selectNode === root {
                    ZStack {
                        menuItems
                    }
                    .frame(width: 0, height: 0)
                    .opacity(0)
                    .position(.init(x: 100000, y: 100000))
                }
            }.onTapGesture {
                actionHandler(ActionType.select.make(input: root))
            }.contextMenu(menuItems: {
                menuItems
            })
            if !root.omSubnodes.isEmpty {
                HStack {
                    if selectNode === root {
                        Spacer().frame(width: 4)
                        Divider()
                            .overlay(.blue)
                            .frame(width: 2)
                            .padding(.zero)
                        Spacer().frame(width: 4)
                    } else {
                        Spacer().frame(width: 10)
                    }
                    VStack {
                        ForEach(root.omSubnodes.filter({ !$0.omIgnore }), id: \.id) { node in
                            EditorTreeView(root: node, selectNode: selectNode, actionHandler: actionHandler)
                        }
                    }
                }
            }
        }
    }
}

#endif
