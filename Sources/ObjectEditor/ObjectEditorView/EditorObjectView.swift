#if canImport(SwiftUI)
import SwiftUI

public struct EditorObjectView: View {
    @State var refresh: Bool = false
    @State var name: String

    let updateNameHandler: () -> Void
    let removeHandler: () -> Void
    let context: OMContext?
    let node: IOMNode
    let isIdentifierShow: Bool

    public init(
        context: OMContext? = nil,
        node: IOMNode,
        isIdentifierShow: Bool = true,
        updateNameHandler: @escaping () -> Void = {},
        removeHandler: @escaping () -> Void = {}
    ) {
        self.updateNameHandler = updateNameHandler
        self.removeHandler = removeHandler
        self.context = context
        self.node = node
        self.name = node.omIdentifier ?? ""
        self.isIdentifierShow = isIdentifierShow
    }

    public var body: some View {
        VStack {
            if refresh {
                EmptyView()
            }
            if isIdentifierShow {
                HStack {
                    VStack {
                        HStack {
                            Text(node.omTypeIdentifier)
                            Spacer()
                        }
                        TextField("Identifier", text: $name, onCommit: {
                            // node.omIdentifier = name
                            updateNameHandler()
                        })
                    }
                    Spacer()
                    if let context = context {
                        ShowPresentButton {
                            EditorSelectView(
                                containers: context
                                    .getAllModifications(for: node)
                                    .map { modification in
                                            .make(text: modification.name, select: {
                                                do {
                                                    let mod = try modification.maker()
                                                    node.omModifications.append(mod)
                                                    try mod.updateAnyModification(node)
                                                    try mod.subscribeAnyObject(node)
                                                }
                                                catch {
                                                    print(error)
                                                }
                                                self.refresh.toggle()
                                            })
                                    }
                            )
                        } label: {
                            Text("+")
                        }
                    }
                }
            }
            Divider()
            ForEach(Array(node.omModifications.compactMap({ $0 as? IAnyEditorModification }).enumerated()), id: \.offset) { container in
                VStack {
                    if let view = try? container.element.makeAnyEditSwiftUIView() {
                        HStack {
                            view
                            Spacer().frame(width: 10)
                        }
                    } else {
                        Text("error")
                    }
                    Divider()
                }
            }
        }
    }
}
#endif
