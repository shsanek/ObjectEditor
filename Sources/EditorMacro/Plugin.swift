import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

@main
struct EditableMacroPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        EditorModification.self,
        EditorRepresentation.self,
        StorableExtension.self,
        EmptyMacro.self
    ]
}


