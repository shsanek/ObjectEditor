import ObjectEditor
import Foundation
import SwiftUI

class TestObject {
    var text: String = ""
    var a: Int = 2
}

@EditorModification<TestObject>
struct TestObjectModification {
    @Editable var text: String = ""
    @Editable var a: Int = 1
}
