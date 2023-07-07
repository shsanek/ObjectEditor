public protocol IDefaultValue {
    static var defaultValue: Self { get }
}

public protocol IEmptyInit: IDefaultValue {
    init()
}

extension IEmptyInit {
    public static var defaultValue: Self {
        Self.init()
    }
}
