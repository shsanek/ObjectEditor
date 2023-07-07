#if canImport(SwiftUI)
import SwiftUI

struct EditorSelectView: View {
    struct Container {
        let select: () -> Void
        let view: AnyView

        static func make(text: String, select: @escaping () -> Void) -> Container {
            .init(select: select, view: AnyView(Text(text)))
        }
    }

    @Environment(\.dismiss) var dismiss
    let containers: [Container]

    var body: some View {
        VStack {
            HStack {
                Spacer()
                Button(action: {
                    dismiss()
                }, label: {
                    Text("X")
                })
            }
            ScrollView {
                VStack {
                    ForEach(Array(containers.enumerated()), id: \.offset) { con in
                        Button(action: {
                            con.element.select()
                            dismiss()
                        }, label: {
                            con.element.view
                        })
                    }
                }
            }
        }
    }
}
#endif
