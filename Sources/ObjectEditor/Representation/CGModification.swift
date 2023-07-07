import Foundation

#if canImport(SwiftUI)
import SwiftUI

@EditorModification<CGRect>(mutable: true)
struct CGRectModification: IDefaultValue {
    @Editable var origin: CGPoint = .zero
    @Editable var size: CGSize = .zero
}

@EditorModification<CGPoint>(mutable: true)
struct CGPointModification: IDefaultValue {
    @Editable var x: CGFloat = 0
    @Editable var y: CGFloat = 0
}

@EditorModification<CGSize>(mutable: true)
struct CGSizeModification: IDefaultValue {
    @Editable var width: CGFloat = 0
    @Editable var height: CGFloat = 0
}

@EditorRepresentation
extension CGSize: IValueEditorDefaultRepresentable { }

@EditorRepresentation
extension CGRect: IValueEditorDefaultRepresentable { }

@EditorRepresentation
extension CGPoint: IValueEditorDefaultRepresentable { }

extension CGFloat: IStringMapperRepresentable {
    public static let mapper = GenericFloatMapper(defaultValue: 0, convert: { CGFloat($0) })
}

public struct CGColorMapper: IEditorDirectMapper {
    public static func modelToObject(_ model: EditorColor) -> CGColor? {
        model.toCGColor()
    }

    public static func objectToModel(_ object: CGColor) -> EditorColor {
        .init()
    }
}

#endif
