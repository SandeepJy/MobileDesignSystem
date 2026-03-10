#if canImport(TipKit)
import SwiftUI
import TipKit

/// Drives the TipKit coachmark tour using an ordered ``TipGroup``.
///
/// The group owns the sequence. Calling `invalidate(reason: .actionPerformed)`
/// on the current tip advances the group to the next eligible tip. The
/// coordinator layers scroll orchestration and a `showCurrent` gate on top so
/// the popover only appears after the scroll animation settles.
@available(iOS 18.0, *)
@MainActor
public final class MDSTipKitTourCoordinator: ObservableObject {

    /// The tip style reads this to reach the coordinator; TipKit popovers
    /// render in a separate window and do not inherit environment values.
    @MainActor static weak var current: MDSTipKitTourCoordinator?

    // MARK: Published

    @Published public private(set) var isActive = false
    @Published public private(set) var currentStepIndex = 0
    @Published private(set) var tipReady = false

    // MARK: Configuration

    private(set) var items: [MDSCoachmarkItem] = []
    private(set) var tips: [MDSCoachmarkStepTip] = []
    private(set) var configuration = MDSCoachmarkConfiguration()
    private(set) var tipGroup: TipGroup?

    weak var scrollCoordinator: MDSCoachmarkScrollCoordinator?
    var onFinished: (() -> Void)?
    var onSkipped: ((Int) -> Void)?

    public init() {}

    func configure(
        items: [MDSCoachmarkItem],
        configuration: MDSCoachmarkConfiguration,
        scrollCoordinator: MDSCoachmarkScrollCoordinator?,
        onFinished: (() -> Void)?,
        onSkipped: ((Int) -> Void)?
    ) {
        self.items = items
        self.configuration = configuration
        self.scrollCoordinator = scrollCoordinator
        self.onFinished = onFinished
        self.onSkipped = onSkipped

        let builtTips = items.enumerated().map {
            MDSCoachmarkStepTip(item: $1, index: $0, total: items.count)
        }
        self.tips = builtTips
    }

    // MARK: Convenience

    var currentItem: MDSCoachmarkItem? {
        guard isActive, items.indices.contains(currentStepIndex) else { return nil }
        return items[currentStepIndex]
    }

    var currentTip: MDSCoachmarkStepTip? {
        guard isActive, tips.indices.contains(currentStepIndex) else { return nil }
        return tips[currentStepIndex]
    }

    func tip(forAnchor id: String) -> MDSCoachmarkStepTip? {
        tips.first { $0.id == id }
    }

    var currentStepInfo: MDSTipKitStepInfo? {
        guard isActive, items.indices.contains(currentStepIndex) else { return nil }
        return MDSTipKitStepInfo(
            index: currentStepIndex,
            total: items.count,
            isFirst: currentStepIndex == 0,
            isLast: currentStepIndex == items.count - 1,
            showExitButton: configuration.showExitButton
        )
    }

    // MARK: Tour lifecycle

    func start() {
        MDSTipKitSetup.configureIfNeeded()
        MDSTipKitSetup.resetDatastore()

        Self.current = self

        let builtTips = tips
        tipGroup = TipGroup(.ordered) {
            for tip in builtTips { tip }
        }

        MDSCoachmarkStepTip.showCurrent = false
        currentStepIndex = 0
        isActive = true
        scrollThenReveal()
    }

    func next() {
        guard isActive, currentStepIndex < items.count else { return }
        items[currentStepIndex].onNextAction?(currentStepIndex)

        advance()
    }

    func skip() {
        guard isActive, currentStepIndex < items.count else { return }
        let idx = currentStepIndex
        items[idx].onExitAction?(idx)
        hideCurrentTip()
        deactivate()
        onSkipped?(idx)
    }

    func finish() {
        hideCurrentTip()
        deactivate()
        onFinished?()
    }

    func dismiss() {
        hideCurrentTip()
        deactivate()
    }

    // MARK: Private — step transitions

    private func advance() {
        hideCurrentTip()

        guard tips.indices.contains(currentStepIndex) else { finish(); return }
        tips[currentStepIndex].invalidate(reason: .actionPerformed)

        guard currentStepIndex + 1 < items.count else { finish(); return }
        currentStepIndex += 1
        scrollThenReveal()
    }

    private func hideCurrentTip() {
        tipReady = false
        MDSCoachmarkStepTip.showCurrent = false
    }

    private func deactivate() {
        if Self.current === self { Self.current = nil }
        tipReady = false
        isActive = false
        currentStepIndex = 0
        MDSCoachmarkStepTip.showCurrent = false
        tipGroup = nil
    }

    private func scrollThenReveal() {
        tipReady = false
        guard items.indices.contains(currentStepIndex) else { return }
        let item = items[currentStepIndex]

        guard let coordinator = scrollCoordinator,
              coordinator.hasRegisteredProxies,
              let steps = item.scrollSteps, !steps.isEmpty
        else {
            Task { @MainActor [weak self] in
                try? await Task.sleep(nanoseconds: 100_000_000)
                self?.reveal()
            }
            return
        }

        let settleNanos = UInt64(configuration.scrollSettleDelay * 1_000_000_000)

        coordinator.scrollSequentially(
            targetID: item.id,
            steps: steps,
            anchor: MDSCoachmarkConstants.scrollAnchor,
            animated: MDSCoachmarkConstants.animateTransitions,
            interStepDelay: configuration.scrollInterStepDelay,
            proxyWaitTimeout: configuration.proxyWaitTimeout
        ) { [weak self] in
            Task { @MainActor [weak self] in
                try? await Task.sleep(nanoseconds: settleNanos)
                self?.reveal()
            }
        }
    }

    private func reveal() {
        guard isActive, items.indices.contains(currentStepIndex) else { return }
        tipReady = true
        MDSCoachmarkStepTip.showCurrent = true
        notifyAppear()
    }

    private func notifyAppear() {
        guard items.indices.contains(currentStepIndex) else { return }
        items[currentStepIndex].onAppearAction?(currentStepIndex)
    }
}
#endif
