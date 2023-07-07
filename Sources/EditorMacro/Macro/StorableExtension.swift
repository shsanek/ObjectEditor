import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct StorableExtension: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        let extensionSyn = try declaration.getDeclarationObject()
        guard extensionSyn.type == .extensionDeclaration else {
            throw EditorMacroError.message("is not extension")
        }
        let model = declaration
            .memberBlock
            .members
            .compactMap { try? $0.decl.getDeclarationObject() }
            .first(where: { $0.name == "StorageModel"})
        guard let model = model else {
            throw EditorMacroError.message("StorageModel could not found")
        }
        let variables = try model.members
            .map({ try DeclarationVariable.make($0) })

        let storage: DeclSyntax = """
        \n
        fileprivate struct Storage {
            static var models: [ObjectIdentifier: StorageModel] = [:]
        }
        """
        return [storage] + variables.map({ createProperty($0) })
    }

    static func createProperty(_ variable: DeclarationVariable) -> DeclSyntax {
        let result: DeclSyntax = """
            \n
            public var \(raw: variable.identifier): \(raw: variable.type.fullName) {
                set {
                    let model = Storage.models[ObjectIdentifier(self)] ?? .init()
                    Storage.models[ObjectIdentifier(self)] = model
                    model.\(raw: variable.identifier) = newValue
                }
                get {
                    let model = Storage.models[ObjectIdentifier(self)] ?? .init()
                    Storage.models[ObjectIdentifier(self)] = model
                    return model.\(raw: variable.identifier)
                }
            }
        """
        return result
    }
}

