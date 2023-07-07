import XCTest
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest
import EditorMacro
import SwiftSyntax

final class ObjectManagerTests: XCTestCase {
    func testExample() throws {
        let source: SourceFileSyntax =
            """
            @EditorModification<NSView>
            struct NSViewLayerModification: IEditorModification, IDefaultValue {
                @Updatable var layer: CALayer? = nil
                @Storable var container: Int = 10
                @Editable(mapper: CGColorMapper.directOptional.self, key: "layer?.backgroundColor") var backgroundColor: EditorColor = .init()
            }
            """


        let file = BasicMacroExpansionContext.KnownSourceFile(
            moduleName: "MyModule",
            fullFilePath: "test.swift"
        )


        let context = BasicMacroExpansionContext(sourceFiles: [source: file])


        let transformedSF = source.expand(
            macros:[
                "EditorModification": EditorModification.self,
                "Storable": EmptyMacro.self,
                "Updatable": EmptyMacro.self
            ],
            in: context
        )


        let expectedDescription =
            """
            let abcd = 1145258561
            """

        let result = transformedSF.description

        print(result)

        // precondition(result == expectedDescription)
    }


    func testExample2() throws {
        let source: SourceFileSyntax =
            """
            @EditorRepresentation
            extension String {
                struct EditView: View {
                    class ViewModel: GenericEditViewModel<String> {
                        @Published var value: String = "" {
                            didSet {
                                update(value)
                            }
                        }

                        override func didUpdate(_ value: String) {
                            self.value = value
                        }
                    }

                    @ObservedObject var viewModel: ViewModel

                    var body: some View {
                        TextField("", text: $viewModel.value)
                    }
                }
            }

            @EditorRepresentation
            public struct SimpleDescriptionView<ValueType>: View {
                class ViewModel: GenericEditViewModel<ValueType> {
                    @Published var value: String

                    override func didUpdate(_ value: ValueType) {
                        self.value = ads
                    }

                    override init(info: RepresentationInfo<ValueType>) {
                        self.value = asd
                        super.init(info: info)
                    }
                }

                @ObservedObject var viewModel: ViewModel

                public var body: some View {
                    VStack {
                        Text(viewModel.name)
                        Text(viewModel.value)
                    }
                    Text("")
                }
            }
            """


        let file = BasicMacroExpansionContext.KnownSourceFile(
            moduleName: "MyModule",
            fullFilePath: "test.swift"
        )


        let context = BasicMacroExpansionContext(sourceFiles: [source: file])


        let transformedSF = source.expand(
            macros:["EditorRepresentation": EditorRepresentation.self],
            in: context
        )


        let expectedDescription =
            """
            let abcd = 1145258561
            """

        let result = transformedSF.description

        print(result)

        // precondition(result == expectedDescription)
    }

    func testExample3() throws {
        let source: SourceFileSyntax =
            """
            @StorableExtension
            extension NSView: IOMNode {
                private final class StorageModel {
                    var omIdentifier: String? = nil
                    var omIgnore: Bool = false
                    var omModifications: [IAnyOMModification] = []
                }
            }
            """


        let file = BasicMacroExpansionContext.KnownSourceFile(
            moduleName: "MyModule",
            fullFilePath: "test.swift"
        )


        let context = BasicMacroExpansionContext(sourceFiles: [source: file])


        let transformedSF = source.expand(
            macros:["StorableExtension": StorableExtension.self],
            in: context
        )


        let expectedDescription =
            """
            #GenericModificationRepresentation(CGRect.self)
            """

        let result = transformedSF.description

        print(result)

        precondition(result == expectedDescription)
    }
}
