import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros


public struct EditorModification: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        let arg = try (
            node
                .attributeName
                .as(SimpleTypeIdentifierSyntax.self)?
                .genericArgumentClause?
                .as(GenericArgumentClauseSyntax.self)?
                .arguments
                .first?
                .argumentType
                .getDeclarationType()
        ).noOptional()
        let modelName = arg.fullName == "CreateModel" ? "Model": arg.fullName
        let objectType = node.argument?.description.removeSpace() == "mutable:true" ? "ValueContainer<\(modelName)>" : modelName
        let isMutable = node.argument?.description.removeSpace() == "mutable:true" || arg.type == "ValueContainer"
        let variables = try declaration
            .memberBlock
            .members
            .map({ try DeclarationVariable.make($0) })
            .filter({ $0.isStorable || $0.isObjectUpdatable || $0.isModificationUpdatable })
        // We could make issue generic but for now let's leave it as a string parameter
        let prefixName = isMutable ? "object.value" : "object"

        let subscribe = try variables.filter({ $0.isObjectUpdatable })
            .map({
                """
                \n
                self._\($0.identifier).updateObjectHandler = { [weak object] in
                    guard let object = object else { return }
                    \(try $0.mapEditorModificationModel(prefixName, model: "$0"))
                }
            """})
            .joined(separator: "\n")

        let subscribeFun: DeclSyntax  = """
        \n
        public func _subscribeObject(_ object: \(raw: objectType)) {
            \(raw: subscribe)
        }
        """

        let update = try variables.filter({ $0.isObjectUpdatable })
            .map({ "\(try $0.mapEditorModificationModel(prefixName, model: "self.\($0.identifier)"))" })
            .joined(separator: "\n")
        let updateFun: DeclSyntax  = """
        \n
        public func _updateObject(_ object: \(raw: objectType)) {
            \(raw: update)
        }
        """

        let modification = try variables.filter({ $0.isModificationUpdatable })
            .map({ "self.\($0.identifier) = \(try $0.mapEditorModificationObject("\(prefixName).\(try $0.editorModificationObjectKey())"))" })
            .joined(separator: "\n")
        let modificationFun: DeclSyntax = """
        \n
        public func _updateModification(_ object: \(raw: objectType)) {
            \(raw: modification)
        }
        """

        var defaultValue: DeclSyntax = ""
        if !variables.contains(where: { $0.initializer == nil }) {
            defaultValue = """
            public static var defaultValue: Self {
                .init()
            }
            """
        }
        var mutableInitValue: DeclSyntax = ""

        if isMutable {
            mutableInitValue = """
            public init(_ obj: \(raw: objectType)) {
                self.init(obj.value)
            }
            """
        }


        return [
            makeCodingKeys(variables),
            makeDecodeFun(variables),
            makeInit(variables),
            makeEncodeFun(variables),
            makeSwiftUIFunc(variables),
            try makeInit(variables, object: modelName),
            subscribeFun,
            updateFun,
            modificationFun,
            defaultValue,
            mutableInitValue
        ]
    }

//    static func createModel(_ variables: [DeclarationVariable]) -> String {
//        """
//        \n
//        public struct Model: Codable \(!variables.contains(where: { $0.initializer == nil }) ? ", IDefaultValue" : "") {
//        \(variables.map({ "var \($0.identifier): \($0.type.fullName)" + ($0.initializer ?? "") }).joined(separator: "\n"))
//        \(makeInit(variables).description)
//        }
//        """
//    }

    static func makeCodingKeys(_ variables: [DeclarationVariable]) -> DeclSyntax {
        let result: DeclSyntax = """
        enum CodingKeys: String, CodingKey {
            \(raw: variables.filter({ $0.isStorable }).map { "case \($0.identifier)" + (($0.identifier != $0.key) ? "= \"\($0.key)\"" : "") }.joined(separator: "\n"))
        }
        """
        return result
    }

    static func makeInit(_ variables: [DeclarationVariable]) -> DeclSyntax {
        let arguments = variables.map({ "\($0.identifier): \($0.type.fullName)" + ($0.initializer ?? "") }).joined(separator: ",\n")
        let initialize = variables.map({"self.\($0.identifier) = \($0.identifier)"}).joined(separator: "\n")
        let result: DeclSyntax = """
        \n
        public init(\(raw: arguments)) {
            \(raw: initialize)
        }
        """
        return result
    }

    static func makeInit(_ variables: [DeclarationVariable], object: String) throws -> DeclSyntax {
        let initialize = try variables.filter({ $0.isModificationUpdatable }).map({"self.\($0.identifier) = \(try $0.mapEditorModificationObject("object.\(try $0.editorModificationObjectKey())"))"}).joined(separator: "\n")
        let result: DeclSyntax = """
        \n
        public init(_ object: \(raw: object)) {
            \(raw: initialize)
        }
        """
        return result
    }


    static func makeDecode(_ variable: DeclarationVariable) -> String {
        if variable.type.isOptional {
            "self.\(variable.identifier) = try container.decodeIfPresent(\(variable.type.fullNoOptionName).self, forKey: .\(variable.identifier))"
        } else {
            "self.\(variable.identifier) = try container.decode(\(variable.type.fullNoOptionName).self, forKey: .\(variable.identifier))"
        }
    }

    static func makeDecodeFun(_ variables: [DeclarationVariable]) -> DeclSyntax {
        let result: DeclSyntax = """
            \n
            public init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                \(raw: variables.filter({ $0.isStorable }).map({makeDecode($0)}).joined(separator: "\n"))
            }
        """
        return result
    }

    static func makeFunc(_ variables: [DeclarationVariable]) -> DeclSyntax {
        let result: DeclSyntax = """
            \n
            public init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                \(raw: variables.filter({ $0.isStorable }).map({makeDecode($0)}).joined(separator: "\n"))
            }
        """
        return result
    }

    static func makeEncode(_ variable: DeclarationVariable) -> String {
        if variable.type.isOptional {
            "try container.encodeIfPresent(self.\(variable.identifier), forKey: .\(variable.identifier))"
        } else {
            "try container.encode(self.\(variable.identifier), forKey: .\(variable.identifier))"
        }
    }

    static func makeEncodeFun(_ variables: [DeclarationVariable]) -> DeclSyntax {
        let result: DeclSyntax = """
            \n
            public func encode(to encoder: Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)
                \(raw: variables.filter({ $0.isStorable }).map({makeEncode($0)}).joined(separator: "\n"))
            }
        """
        return result
    }

    static func makeSwiftUI(_ variable: DeclarationVariable) -> String {
        let result = """
            .init(id: "\(variable.identifier)", view: try _\(variable.identifier).createEditorSwiftUIView(with: "\(variable.identifier)"))
        """
        return result
    }

    static func makeSwiftUIFunc(_ variables: [DeclarationVariable]) -> DeclSyntax {
        let result: DeclSyntax = """
            \n
            #if canImport(SwiftUI)
            public func _makeEditSwiftUIView() throws -> AnyView {
                let views: [EditorModificationView.ViewContainer] = [
                    \(raw: variables.filter({ $0.isObjectUpdatable }).map(makeSwiftUI).joined(separator: ",\n"))
                ]
                return AnyView(EditorModificationView(views: views))
            }
            #endif
        """
        return result
    }
}

extension DeclarationVariable {
    func editorModificationObjectKey() throws -> String {
        guard let parameter = attributes
            .first(where: { $0.name == "Editable" })?
            .parameters
            .first(where: { $0.label == "key" })?
            .expression
        else {
            return identifier
        }
        guard parameter.count > 1, parameter.hasSuffix("\""), parameter.hasPrefix("\"") else {
            throw EditorMacroError.message("for key string literal required (property '\(identifier)')")
        }
        return String(parameter.dropFirst().dropLast())
    }

    private func getEditorModificationMapper() throws -> String? {
        guard let parameter = attributes
            .first(where: { $0.name == "Editable" })?
            .parameters
            .first(where: { $0.label == "mapper" })?
            .expression
        else {
            return nil
        }
        guard parameter.hasSuffix(".self") else {
            throw EditorMacroError.message("for map Mapper.self literal required (property '\(identifier)')")
        }
        return String(parameter.dropLast(5))
    }

    func mapEditorModificationObject(_ obj: String) throws -> String {
        guard let mapper = try getEditorModificationMapper() else {
            return obj
        }
        return "\(mapper).objectToModel(\(obj))"
    }

    func mapEditorModificationModel(_ obj: String, model: String) throws -> String {
        let key = try editorModificationObjectKey()
        guard let mapper = try getEditorModificationMapper() else {
            return "\(obj).\(key) = \(model)"
        }
        guard key.contains("?.") else {
            return "\(mapper).fillObject(&\(obj).\(key), from: \(model))"
        }
        var components = key.components(separatedBy: ".")
        let right = components.removeLast()
        var left = components.joined(separator: ".")
        if left.hasSuffix("?") {
            left.removeLast()
        }

        return """
        if var prop = \(obj).\(left) {
            \(mapper).fillObject(&prop.\(right), from: \(model))
        }
        """
    }

    var isStorable: Bool {
        attributes.contains { $0.name == "Editable" || $0.name == "Storable" }
    }

    var isModificationUpdatable: Bool {
        attributes.contains { $0.name == "Editable" || $0.name == "Updatable" }
    }

    var isObjectUpdatable: Bool {
        attributes.contains { $0.name == "Editable" }
    }
}
