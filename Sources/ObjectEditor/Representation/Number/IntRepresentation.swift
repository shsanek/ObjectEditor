#if canImport(SwiftUI)
import SwiftUI
#endif

public struct GenericIntegerMapper<ValueType>: IStringMapper {
    public let defaultValue: ValueType
    let convert: (Int) -> ValueType

    public init(defaultValue: ValueType, convert: @escaping (Int) -> ValueType) {
        self.defaultValue = defaultValue
        self.convert = convert
    }

    public func toValue(_ string: String) throws -> ValueType {
        if let obj = Int(string) {
            return convert(obj)
        } else if string == "-" {
            return convert(0)
        } else {
            throw EditorError.message("incorrect convert")
        }
    }
}

extension Int: IStringMapperRepresentable, IEmptyInit {
    public static let mapper = GenericIntegerMapper(defaultValue: 0, convert: { Int($0) })
}

extension Int32: IStringMapperRepresentable, IEmptyInit {
    public static let mapper = GenericIntegerMapper(defaultValue: 0, convert: { Int32($0) })
}

extension Int64: IStringMapperRepresentable, IEmptyInit {
    public static let mapper = GenericIntegerMapper(defaultValue: 0, convert: { Int64($0) })
}
