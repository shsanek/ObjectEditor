import Foundation

public final class Identifier { public init() { } }

public final class DelayedExecutor {
    private let defaultDelay: Float
    private var workItem: DispatchWorkItem?
    private var identifier: Identifier?

    public init(defaultDelay: Float = 0.5) {
        self.defaultDelay = defaultDelay
    }

    public func run(_ delay: Float? = nil, block: @escaping () -> Void) {
        let delay = delay ?? defaultDelay
        stop()
        let identifier = Identifier()
        let item = DispatchWorkItem { [weak self] in
            if identifier === self?.identifier {
                block()
                self?.workItem = nil
            }
        }
        self.workItem = item
        self.identifier = identifier
        DispatchQueue.main.asyncAfter(deadline: .now() + TimeInterval(delay), execute: item)
    }

    public func stop() {
        identifier = nil
        workItem?.cancel()
    }
}
