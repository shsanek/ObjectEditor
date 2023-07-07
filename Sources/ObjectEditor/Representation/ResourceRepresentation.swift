#if canImport(SwiftUI)
import SwiftUI
#endif

@EditorModification<Resource>(mutable: true)
struct ResourceModification: IEditorModification, IDefaultValue {
    @Editable(
        representation: AutocompletionInputTextRepresenter(
            helper: ResourcesPool.default
        ),
        name: "path"
    ) var fullPath: String = ""
}

@EditorRepresentation
extension Resource: IValueEditorDefaultRepresentable, IAnyValueEditorDefaultRepresentable {}
