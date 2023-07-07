#if canImport(SwiftUI)
import SwiftUI

public struct ModificationContentView: View {
    let name: String
    let content: AnyView
    let retain: Any

    public init(name: String, content: AnyView, retain: Any) {
        self.name = name
        self.content = content
        self.retain = retain
    }

    public var body: some View {
        AnyView(VStack {
            HStack {
                Text(name)
                Spacer()
            }
            HStack {
                Spacer().frame(width: 10)
                content
            }
        })
    }
}
#endif
