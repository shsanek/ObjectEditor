import Foundation
import Observation

public enum LogLevel: String {
    case warning = "⚠️"
    case error = "❌"
    case info = "ℹ️"
    case trash = "🔵"
}

public struct LogMessage {
    public let level: LogLevel
    public let message: String
}

public class LogContainer: ILog, ObservableObject {
    @Published public var items: [LogItem] = []

    public let imageName: String?
    public let name: String

    public init(name: String, imageName: String?) {
        self.name = name
        self.imageName = imageName
    }

    public func addLogItem(_ item: LogItem) {
        self.items.append(item)
    }

    public var errorCount: Int {
        items.reduce(0, { $0 + $1.errorCount })
    }

    public var warningCount: Int {
        items.reduce(0, { $0 + $1.warningCount })
    }
}

public enum LogItem {
    case container(_ container: LogContainer)
    case message(_ message: LogMessage)

    public var errorCount: Int {
        switch self {
        case .container(let container):
            container.errorCount
        case .message(let message):
            message.level == .error ? 1 : 0
        }
    }

    public var warningCount: Int {
        switch self {
        case .container(let container):
            container.warningCount
        case .message(let message):
            message.level == .warning ? 1 : 0
        }
    }
}

public final class Logger: ILog, ObservableObject {
    public static let log = Logger()

    public let main: LogContainer = LogContainer(name: "Root", imageName: "list.bullet")

    var containerStack: [LogContainer] = []

    public func addLogItem(_ item: LogItem) {
        if let container = containerStack.last {
            container.addLogItem(item)
        } else {
            main.addLogItem(item)
        }
    }
}

public protocol ILog {
    func addLogItem(_ item: LogItem)
}

extension ILog {
    public func warning(_ message: String) {
        addLogItem(.message(.init(level: .warning, message: message)))
    }
    public func info(_ message: String){
        addLogItem(.message(.init(level: .info, message: message)))
    }
    public func error(_ message: String){
        addLogItem(.message(.init(level: .error, message: message)))
    }
    public func trash(_ message: String){
        addLogItem(.message(.init(level: .trash, message: message)))
    }
}

@discardableResult
public func logPushContainer(_ name: String, imageName: String?) -> LogContainer {
    let container = LogContainer(name: name, imageName: imageName)
    Logger.log.addLogItem(.container(container))
    Logger.log.containerStack.append(container)
    return container
}

public func logPopContainer() {
    if !Logger.log.containerStack.isEmpty {
        Logger.log.containerStack.removeLast()
    }
}

public func logDO(_ block: () throws -> Void) {
    do {
        try block()
    }
    catch {
        Logger.log.error("\(error)")
    }
}

public func warning(_ message: String) {
    Logger.log.warning(message)
}
public func info(_ message: String){
    Logger.log.warning(message)
}
public func error(_ message: String){
    Logger.log.warning(message)
}
public func trash(_ message: String){
    Logger.log.warning(message)
}

import SwiftUI

public struct LogMenuView: View {
    @ObservedObject var log: LogContainer
    var selectHandler: (LogContainer) -> Void

    public init(
        log: LogContainer,
        selectHandler: @escaping (LogContainer) -> Void
    ) {
        self.log = log
        self.selectHandler = selectHandler
    }

    public var body: some View {
        HStack {
            if let image = log.imageName {
                Image(systemName: image)
            }
            Text(log.name)
            if log.errorCount > 0 {
                Text(LogLevel.error.rawValue)
                Text("\(log.errorCount)")
            }
            if log.warningCount > 0 {
                Text(LogLevel.warning.rawValue)
                Text("\(log.errorCount)")
            }
        }
    }
}
