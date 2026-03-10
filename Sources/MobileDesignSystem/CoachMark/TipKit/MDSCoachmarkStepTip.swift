#if canImport(TipKit)
import SwiftUI
import TipKit

/// One step of a coachmark tour expressed as a TipKit `Tip`.
///
/// Tips belong to an ordered ``TipGroup``. The group advances when the
/// current tip is invalidated via `.actionPerformed`. A static `@Parameter`
/// gates display so tips stay hidden during scroll transitions.
@available(iOS 18.0, *)
public struct MDSCoachmarkStepTip: Tip {

    /// Global gate. When `false`, all tips in the tour evaluate as
    /// ineligible and any visible popover dismisses. The coordinator
    /// toggles this around scroll transitions.
    @Parameter public static var showCurrent: Bool = false

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

    public var rules: [Rule] {
        [
            #Rule(Self.$showCurrent) { $0 == true }
        ]
    }

    public var actions: [Action] {
        var result: [Action] = []

        let infoPayload = "\(stepIndex)|\(totalSteps)|\(isFirst ? 1 : 0)|\(isLast ? 1 : 0)"
        result.append(Action(id: "__stepinfo__:\(infoPayload)", title: ""))

        if isLast {
            result.append(Action(id: "done",  title: MDSCoachmarkConstants.finishButtonLabel))
        } else {
            result.append(Action(id: "next",  title: MDSCoachmarkConstants.nextButtonLabel))
        }
        if !isLast {
            result.append(Action(id: "skip",  title: MDSCoachmarkConstants.exitButtonLabel))
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
