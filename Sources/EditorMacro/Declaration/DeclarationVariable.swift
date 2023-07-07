import SwiftSyntax

struct DeclarationVariable {
    let identifier: String
    let type: DeclarationType
    let attributes: [Attribute]
    let initializer: String?
    let key: String

    struct Attribute {
        struct AttributeParameter {
            let label: String?
            let expression: String
        }
        let name: String
        let parameters: [AttributeParameter]
    }

    static func make(_ item: MemberDeclListItemSyntax) throws -> DeclarationVariable {
        guard
            let variable = item.decl.as(VariableDeclSyntax.self),
            let identifier = variable.bindings.first?.pattern.as(IdentifierPatternSyntax.self)?.identifier
        else {
            throw EditorMacroError.message("")
        }
        let attributes: [Attribute] = variable.attributes.compactMap({ $0.as(AttributeSyntax.self) }).map { attribute in
            let name = attribute.attributeName.as(SimpleTypeIdentifierSyntax.self)?.name.text ?? ""
            let arguments = attribute.argument?.as(TupleExprElementListSyntax.self) ?? []
            let parameters: [Attribute.AttributeParameter] = arguments.map({
                .init(
                    label: $0.label?.text,
                    expression: $0.expression.description
                )
            })
            return Attribute(name: name, parameters: parameters)
        }

        var initializer = variable.bindings.first?.initializer?.description
        if let text = initializer {
            initializer = " " + text
        }
        return .init(
            identifier: identifier.text,
            type: try (variable.bindings.first?.typeAnnotation?.type.getDeclarationType()).noOptional(),
            attributes: attributes,
            initializer: initializer,
            key: identifier.text
        )
    }
}
