import SwiftUI
import TipKit

// MARK: - TipKit Integration (iOS 17+)

@available(iOS 17.0, *)
struct MDSCoachmarkTip: Tip {
    let id: String
    let content: AnyView
    let stepIndex: Int
    let totalSteps: Int
    
    var title: Text {
        Text("Step \(stepIndex + 1) of \(totalSteps)")
    }
    
    var message: Text? {
        Text("") // We'll use custom view instead
    }
    
    var actions: [Action] {
        [] // We'll handle navigation separately
    }
}

@available(iOS 17.0, *)
class MDSCoachmarkTipManager: ObservableObject {
    @Published var currentTip: MDSCoachmarkTip?
    @Published var currentIndex: Int = 0
    
    func showTip(_ tip: MDSCoachmarkTip) {
        currentTip = tip
    }
    
    func hideTip() {
        currentTip = nil
    }
}
