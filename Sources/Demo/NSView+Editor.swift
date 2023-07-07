import ObjectEditor
import AppKit
import SwiftUI

extension OMContext {
    static let appContext: OMContext = {
        let context = OMContext()
        do {
            try context.registerObjects([
                .make(name: "View", { NSView.init() }),
                .make(name: "Image", { NSImageView() })
            ])
            try context.registerModifications([
                .make(name: "Base", { NSViewBaseModification.init() }),
                .make(name: "Image", { NSImageModification.init() }),
                .make(name: "Layer", { NSViewLayerModification.init() })

            ])
        }
        catch {
            print(error)
        }
        return context
    }()
}

@StorableExtension
extension NSView {
    fileprivate final class StorageModel {
        var omIdentifier: String? = nil
        var omIgnore: Bool = false
        var omTemplate: Resource? = nil
        var omModifications: [IAnyOMModification] = []
    }
}

extension NSView : IOMNode {

    public func omAddSubnode(_ node: IOMNode) throws {
        guard let child = node as? NSView else {
            throw EditorError.message("\(node) is not NSView")
        }
        child.wantsLayer = true
        self.addSubview(child)
    }

    public func omRemoveFromSupernode() throws {
        self.removeFromSuperview()
    }

    public var omSubnodes: [IOMNode] {
        subviews
    }
}

@EditorModification<NSView>
struct NSViewBaseModification: IEditorModification {
    @Editable var frame: CGRect = .zero
}

@EditorModification<NSView>
struct NSViewLayerModification: IEditorModification, IDefaultValue {
    @Editable(mapper: CGColorMapper.directOptional.self, key: "layer?.backgroundColor") var backgroundColor: EditorColor = .init()
}

struct NSImageEditorMapper: IEditorDirectMapper {
    static func modelToObject(_ model: ObjectEditor.Resource) -> NSImage? {
        guard let data = try? ResourcesPool.default.getData(model), let image = NSImage(data: data) else {
            return nil
        }
        return image
    }

    static func objectToModel(_ object: NSImage) -> Resource {
        .init("")
    }
}

@EditorModification<NSImageView>
struct NSImageModification: IEditorModification {
    @Editable(mapper: NSImageEditorMapper.directOptional.self) var image: Resource = .init("")
}

