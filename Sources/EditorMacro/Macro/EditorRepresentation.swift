import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct EditorRepresentation: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        let extensionSyn = try declaration.getDeclarationObject()
        var member = declaration
            .memberBlock
            .members
            .compactMap { try? $0.decl.getDeclarationObject() }
            .first(where: { $0.protocols.contains(where: { $0.fullName == "View" }) })
        guard
            !declaration
            .memberBlock
            .members.isEmpty
        else {
            return [
            """
            \n
                public static var defaultRepresentation: Rep {
                    Rep()
                }

            public struct Rep: IValueEditorRepresentation {
                public func makeSwiftUIView(_ info: RepresentationInfo < \(raw: extensionSyn.name)>) throws -> AnyView {
                    let modification = \(raw: extensionSyn.name.removeSpace())Modification(info.container.value)
                    let listener = info.container.addListener { value in
                        modification._updateModification(.init(value: value))
                    }
                    modification._subscribeObject(info.container)
                    let content = try modification._makeEditSwiftUIView()
                    return AnyView(ModificationContentView(name: info.name, content: content, retain: [modification, listener]))
                }
            }
            \n
            """
            ]
        }

        var notExtension: Bool = false
        if extensionSyn.type == .structDeclaration && extensionSyn.protocols.contains(where: { $0.fullName == "View" }) {
            member = extensionSyn
            notExtension = true
        }

        guard let member = member, !member.name.isEmpty else {
            throw EditorMacroError.message("View not found")
        }
        let baseType = try (member
            .members
            .compactMap { try? $0.decl.getDeclarationObject()  }
            .first(where: { $0.name == "ViewModel" })?
            .protocols
            .first(where: { $0.type == "GenericEditViewModel" })?
            .subTypes
            .first?
            .fullName).noOptional()


        var name = member.name + "Representation"
        if notExtension {
            name = "Representation"
        }
        let bigName = name
        let first = "\(name.removeFirst())".lowercased()
        name = first + name


        let defaultText = """
        \n
        public static var defaultRepresentation: \(bigName) {
            \(name)
        }
        """

        let repText = """
        \n
        public static var \(name): \(bigName) {
            \(bigName)()
        }

        public struct \(bigName): IValueEditorRepresentation {
            public func makeSwiftUIView(_ info: RepresentationInfo<\(baseType)>) throws -> AnyView {
                AnyView(\(member.name)(viewModel: .init(info: info)))
            }
        }
        """

        let defaultSyn: DeclSyntax = "\(raw: defaultText)"
        let repSyn: DeclSyntax = "\(raw: repText)"

        if extensionSyn.protocols.contains(where: { $0.fullName == "IValueEditorDefaultRepresentable" }) {
            return [
                defaultSyn,
                repSyn
            ]
        } else {
            return [repSyn]
        }
    }
}

