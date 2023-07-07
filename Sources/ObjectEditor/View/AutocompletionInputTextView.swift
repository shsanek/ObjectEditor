#if canImport(SwiftUI)
import SwiftUI
#endif

public protocol IStringInputHelper {
    func getAutocompletionVariations(_ input: String, completion: @escaping (_ variations: [String]) -> Void)
}

#if canImport(SwiftUI)

struct AutocompletionInputTextView: View {
    @ObservedObject var viewModel: ViewModel
    @FocusState var isActive: Bool {
        didSet {
            if isActive && isActive != oldValue {
                viewModel.updateAutocompletion()
            }
        }
    }

    var body: some View {
        VStack {
            TextField(
                viewModel.name,
                text: $viewModel.value,
                onCommit: { viewModel.commit() }
            ).focused($isActive).onAppear {
                viewModel.updateAutocompletion()
            }
            if isActive {
                ScrollView {
                    VStack {
                        ForEach(viewModel.autocompletionVariations, id: \.self) { variation in
                            HStack {
                                Text(variation)
                                Spacer()
                            }
                            .background(variation == viewModel.selectAutocompletionVariation ? .blue : .clear)
                            .onTapGesture {
                                viewModel.selectAutocompletionVariation = variation
                                viewModel.select()
                            }
                        }
                    }
                }.frame(height: 120)
            }
        }
    }

    init(viewModel: ViewModel) {
        self.viewModel = viewModel
        self.isActive = false
    }
}

extension AutocompletionInputTextView {
    class ViewModel: GenericEditViewModel<String> {
        @Published var value: String = "" {
            didSet {
                if (value != oldValue) {
                    updateAutocompletion()
                }
            }
        }
        @Published var autocompletionVariations: [String] = []
        @Published var selectAutocompletionVariation: String?

        private let helper: IStringInputHelper
        private let delayedExecutor: DelayedExecutor = DelayedExecutor()
        private var currentSearchAutocompletionInput: String?
        private let autoSelectFirst: Bool
        private var committedValue: String?

        init(
            info: RepresentationInfo<String>,
            autoSelectFirst: Bool = true,
            helper: IStringInputHelper
        ) {
            self.helper = helper
            self.autoSelectFirst = autoSelectFirst
            super.init(info: info)
        }

        override func didUpdate(_ value: String) {
            self.value = value
            self.committedValue = value
        }

        func commit() {
            if self.committedValue != value {
                update(value)
                self.committedValue = value
            }
        }

        func select() {
            if let variation = selectAutocompletionVariation {
                value = variation
            }
            selectAutocompletionVariation = nil
            autocompletionVariations = []
            commit()
        }

        enum MoveType: Int {
            case down = 1
            case up = -1
        }

        func moveSelect(_ moveType: MoveType) {
            guard var index = autocompletionVariations.firstIndex(where: { selectAutocompletionVariation == $0 }) else {
                guard !autocompletionVariations.isEmpty else {
                    return
                }
                if moveType.rawValue > 0 {
                    selectAutocompletionVariation = autocompletionVariations.first
                } else {
                    selectAutocompletionVariation = autocompletionVariations.last
                }
                return
            }
            index += moveType.rawValue
            if (index % autocompletionVariations.count) == index {
                selectAutocompletionVariation = autocompletionVariations[index]
            } else {
                selectAutocompletionVariation = nil
            }
        }

        func updateAutocompletion() {
            self.currentSearchAutocompletionInput = value
            self.autocompletionVariations = []
            delayedExecutor.run { [weak self, value] in
                self?.helper.getAutocompletionVariations(value) { variations in
                    guard (value == self?.currentSearchAutocompletionInput) else {
                        return
                    }
                    self?.didUpdateAutocompletion(variations)
                }
            }
        }

        private func didUpdateAutocompletion(_ variations: [String]) {
            self.autocompletionVariations = variations.filter({ $0 != value })
            if self.autoSelectFirst || variations.contains(value) {
                self.selectAutocompletionVariation = self.autocompletionVariations.first
            } else {
                self.selectAutocompletionVariation = nil
            }
        }
    }
}
#endif


