import Foundation

public enum EditorError: Error {
    case message(_ text: String)
}

public final class ValueListener<ValueType> {
    let updateHandler: (_ value: ValueType) -> Void

    init(_ updateHandler: @escaping (_: ValueType) -> Void) {
        self.updateHandler = updateHandler
    }
}

final class WeakContainer<Value> {
    var value: Value? {
        get {
            storage as? Value
        }
        set {
            storage = newValue as? AnyObject
        }
    }
    private(set) weak var storage: AnyObject?

    init(value: Value? = nil) {
        self.storage = value as? AnyObject
    }
}

public final class ValueContainer<ValueType> {
    public var value: ValueType {
        didSet {
            guard !isLock else {
                return
            }
            isLock = true
            listeners.forEach({
                $0.value?.updateHandler(value)
            })
            isLock = false
        }
    }

    private var isLock: Bool = false
    private var listeners = [WeakContainer<ValueListener<ValueType>>]()

    public init(value: ValueType) {
        self.value = value
    }

    public func addListener(_ updateHandler: @escaping (ValueType) -> Void) -> AnyObject {
        let listener = ValueListener(updateHandler)
        listeners.append(.init(value: listener))
        return listener
    }

    public func removeListener(_ listener: AnyObject?) {
        listeners.removeAll(where: { $0.storage === listener })
    }
}
