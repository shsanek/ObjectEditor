#if canImport(AppKit)
import AppKit

public final class EditorWindow {
    @available(macOS 10.15, *)
    public class Delegate: NSObject, NSWindowDelegate {
        public let closeHandler: (() -> Void)

        public init(closeHandler: @escaping () -> Void) {
            self.closeHandler = closeHandler
        }

        public func windowWillClose(_ notification: Notification) {
            closeHandler()
        }
    }

    private let delegate: NSWindowDelegate?
    private var controller: NSWindowController?
    private var retain: AnyObject? = nil
    public var view: () -> NSView {
        didSet {
            reloadContentView()
        }
    }

    public init(_ view: @escaping () -> NSView, delegate: NSWindowDelegate?) {
        self.view = view
        self.delegate = delegate
    }

    private func reloadContentView() {
        guard let window = controller?.window, let content = window.contentView else {
            return
        }
        content.subviews.forEach({ $0.removeFromSuperview() })
        let view = view()
        view.frame = CGRect(origin: .zero, size: content.bounds.size)
        view.autoresizingMask = [.height, .width]
        content.addSubview(view)
    }

    @discardableResult
    public func show(wit size: CGSize = CGSize(width: 480, height: 270), inFullScreen: Bool = false, title: String) -> Self {
        self.retain = self
        controller = NSWindowController()
        controller?.window = NSWindow()
        controller?.showWindow(nil)

        guard let window = controller?.window else {
            return self
        }
        window.setContentSize(size)
        window.styleMask = [.closable, .resizable, .titled]
        window.title = title
        window.delegate = delegate

        reloadContentView()

        window.center()
        window.makeKeyAndOrderFront(window)
        if (inFullScreen) {
            window.collectionBehavior = .fullScreenPrimary
            if let frame = NSScreen.main?.visibleFrame {
                window.setFrame(frame, display: true)
            }
            window.toggleFullScreen(nil)
        }
        return self
    }

    public func close() {
        self.controller?.window?.close()
        self.controller = nil
        self.retain = nil
    }
}

#endif
