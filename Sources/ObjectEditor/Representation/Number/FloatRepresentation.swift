#if canImport(SwiftUI)
import SwiftUI
#endif

public struct GenericFloatMapper<ValueType>: IStringMapper {
    public let defaultValue: ValueType
    let convert: (Double) -> ValueType

    public init(defaultValue: ValueType, convert: @escaping (Double) -> ValueType) {
        self.defaultValue = defaultValue
        self.convert = convert
    }

    public func toValue(_ string: String) throws -> ValueType {
        if let obj = Double(string) {
            return convert(obj)
        } else if string.hasSuffix("."), let obj = Double(String(string.dropLast())) {
            return convert(obj)
        } else if string == "-" {
            return convert(0)
        } else {
            throw EditorError.message("incorrect convert")
        }
    }
}

extension Float: IStringMapperRepresentable, IEmptyInit {
    public static let mapper = GenericFloatMapper(defaultValue: 0, convert: { Float($0) })
}

extension Double: IStringMapperRepresentable, IEmptyInit {
    public static let mapper = GenericFloatMapper(defaultValue: 0, convert: { Double($0) })
}
