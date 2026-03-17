#if canImport(TipKit)
import SwiftUI
import TipKit

/// A single step in a TipKit-powered coachmark tour.
///
/// Each instance carries the display content (title, message, icon) and
/// navigation metadata (step index, position flags) for one tour step.
/// Sequencing is managed externally by a `TipGroup(.ordered)` in the
/// coordinator — the tip itself declares no rules.
@available(iOS 18.0, *)
public struct MDSCoachmarkStepTip: Tip {

    public let id: String

    let stepTitle: String
    let stepMessage: String?
    let stepImageName: String?
    let isFirst: Bool
    let isLast: Bool
    let stepIndex: Int
    let totalSteps: Int

    init(item: MDSCoachmarkItem, index: Int, total: Int) {
        self.id             = item.id
        self.stepTitle      = item.title
        self.stepMessage    = item.description
        self.stepImageName  = item.iconName
        self.isFirst        = index == 0
        self.isLast         = index == total - 1
        self.stepIndex      = index
        self.totalSteps     = total
    }

    // MARK: Tip

    public var title: Text { Text(stepTitle) }
    public var message: Text? { stepMessage.map { Text($0) } }
    public var image: Image? { stepImageName.map { Image(systemName: $0) } }

    /// Empty — `TipGroup(.ordered)` controls which tip is eligible.
    public var rules: [Rule] { [] }

    public var actions: [Action] {
        var result: [Action] = []

        let infoPayload = "\(stepIndex)|\(totalSteps)|\(isFirst ? 1 : 0)|\(isLast ? 1 : 0)"
        result.append(Action(id: "__stepinfo__:\(infoPayload)", title: ""))

        if isLast {
            result.append(Action(id: "done", title: MDSCoachmarkConstants.finishButtonLabel))
        } else {
            result.append(Action(id: "next", title: MDSCoachmarkConstants.nextButtonLabel))
        }

        if !isLast {
            result.append(Action(id: "skip", title: MDSCoachmarkConstants.exitButtonLabel))
        }

        return result
    }

    public var options: [any TipOption] {
        [
            MaxDisplayCount(.max),
            IgnoresDisplayFrequency(true)
        ]
    }
}
#endif
