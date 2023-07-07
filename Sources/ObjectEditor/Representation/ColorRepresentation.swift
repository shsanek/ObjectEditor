#if canImport(SwiftUI)
import SwiftUI
#endif

public struct EditorColor: Codable, IDefaultValue {
    public var description: String = ""
    public var r: Int = 0
    public var g: Int = 0
    public var b: Int = 0
    public var a: Int = 1

    public init(r: Int = 0, g: Int = 0, b: Int = 0, a: Int = 255) {
        self.r = r
        self.g = g
        self.b = b
        self.a = a
    }

    public static var defaultValue: EditorColor {
        .init()
    }
}

@EditorModification<EditorColor>(mutable: true)
struct EditorColorModification {
    @Editable(representation: SimpleDescriptionRepresentation()) var description: String = ""
    @Editable var r: Int = 0
    @Editable var g: Int = 0
    @Editable var b: Int = 0
    @Editable var a: Int = 255
}

@EditorRepresentation
extension EditorColor: IValueEditorDefaultRepresentable { }

extension EditorColor {
#if canImport(SwiftUI)
    public func toCGColor() -> CGColor {
        .init(
            red: CGFloat(CGFloat(r) / 255.0),
            green: CGFloat(CGFloat(g) / 255.0),
            blue: CGFloat(CGFloat(b) / 255.0),
            alpha: CGFloat(CGFloat(a) / 255.0)
        )
    }
#endif
}
