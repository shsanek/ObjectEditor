import Foundation

public enum ActionType {
    public static let copy = EditorActionType<IOMNode, Void>(identifier: "copy")
    public static let past = EditorActionType<IOMNode, Void>(identifier: "past")
    public static let select = EditorActionType<IOMNode, Void>(identifier: "select")
    public static let makeNew = EditorActionType<String, IOMNode>(identifier: "makeNew")
}

public final class ActionsHandler {
    private var handlers = [String: (IEditorAction) throws -> Void]()

    public init() { }

    public func registerHandler<Input, Output>(
        _ type: EditorActionType<Input, Output>,
        _ handler: @escaping (EditorAction<Input, Output>) throws -> Void
    ) -> Void {
        handlers[type.identifier] = { action in
            guard let action = type.as(action) else {
                throw EditorError.message("is not \(EditorAction<Input, Output>.self)")
            }
            try handler(action)
        }
    }

    public func handle(_ action: IEditorAction) throws {
        try handlers[action.identifier]?(action)
    }
}

public protocol IEditorAction {
    var identifier: String { get }
}

public struct EditorActionType<Input, Output> {
    let identifier: String

    public init(identifier: String) {
        self.identifier = identifier
    }

    public func make(input: Input, completion: ((Output) -> Void)? = nil) -> EditorAction<Input, Output> {
        return .init(identifier: identifier, input: input, completion: completion)
    }

    public func `as`(_ action: IEditorAction) -> EditorAction<Input, Output>? {
        guard action.identifier == identifier, let action = action as? EditorAction<Input, Output> else {
            return nil
        }
        return action
    }
}

public struct EditorAction<Input, Output>: IEditorAction {
    public let identifier: String
    public let input: Input
    public let completion: ((Output) -> Void)?

    init(identifier: String, input: Input, completion: ((Output) -> Void)?) {
        self.identifier = identifier
        self.input = input
        self.completion = completion
    }
}
