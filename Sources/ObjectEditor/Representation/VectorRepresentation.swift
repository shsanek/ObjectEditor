import simd
#if canImport(SwiftUI)
import SwiftUI
#endif

@EditorModification<vector_float3>(mutable: true)
struct vector_float3Modification: IDefaultValue {
    @Editable var x: Float = 0
    @Editable var y: Float = 0
    @Editable var z: Float = 0
}

@EditorRepresentation
extension vector_float3: IValueEditorDefaultRepresentable, IAnyValueEditorDefaultRepresentable {}

@EditorModification<vector_float4>(mutable: true)
struct vector_float4Modification: IDefaultValue {
    @Editable var x: Float = 0
    @Editable var y: Float = 0
    @Editable var z: Float = 0
    @Editable var w: Float = 0
}

@EditorRepresentation
extension vector_float4: IValueEditorDefaultRepresentable, IAnyValueEditorDefaultRepresentable {}
