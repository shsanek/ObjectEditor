#if canImport(SwiftUI)
import SwiftUI

public class GenericEditViewModel<ValueType>: ObservableObject {
    public let name: String
    public let container: ValueContainer<ValueType>
    private var listener: AnyObject? = nil
    private var updateLock: Bool = false

    public init(info: RepresentationInfo<ValueType>) {
        self.container = info.container
        self.name = info.name
        self.listener = info.container.addListener { [weak self] value in
            self?.updateBlock {
                self?.didUpdate(value)
            }
        }
        self.updateBlock {
            self.didUpdate(info.container.value)
        }
    }

    open func didUpdate(_ value: ValueType) {
    }

    public func update(_ value: ValueType) {
        updateBlock {
            container.value = value
        }
    }

    public func updateBlock(_ block: () -> Void) {
        guard !updateLock else {
            return
        }
        updateLock = true
        block()
        updateLock = false
    }

    deinit {
        container.removeListener(listener)
    }
}
#endif
