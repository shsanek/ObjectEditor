import Foundation

enum EditorMacroError: Error {
    case message(String)
}

extension Optional {
    func noOptional() throws -> Wrapped {
        guard let value = self else {
            throw EditorMacroError.message("nil")
        }
        return value
    }
}


extension String {
    func removeSpace() -> String {
        split(separator: " ").joined()
    }
}
