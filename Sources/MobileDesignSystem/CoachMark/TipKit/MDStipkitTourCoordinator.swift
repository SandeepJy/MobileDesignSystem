#if canImport(TipKit)
import SwiftUI
import TipKit

/// Drives a TipKit-powered coachmark tour using `TipGroup(.ordered)`.
///
/// The coordinator owns the ordered `TipGroup` and advances through
/// steps by invalidating the current tip, which causes the group to
/// promote the next tip to eligible status.
///
/// **Back navigation is not supported** — `TipGroup` does not allow
/// un-invalidating a tip. The legacy overlay (used on iOS < 18)
/// continues to provide full back-navigation support.
@available(iOS 18.0, *)
@MainActor
public final class MDSTipKitTourCoordinator: ObservableObject, @unchecked Sendable {

    @MainActor static weak var current: MDSTipKitTourCoordinator?

    // MARK: Published

    @Published public private(set) var isActive = false
    @Published public private(set) var currentStepIndex = 0
    @Published private(set) var tipReady = false

    // MARK: Configuration

    private(set) var items: [MDSCoachmarkItem] = []
    private(set) var tips: [MDSCoachmarkStepTip] = []
    private(set) var configuration = MDSCoachmarkConfiguration()
    private var tipGroup: TipGroup?
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
        self.tips = items.enumerated().map {
            MDSCoachmarkStepTip(item: $1, index: $0, total: items.count)
        }
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
        currentStepIndex = 0
        isActive = true

        tipGroup = TipGroup(.ordered) {
            for tip in tips {
                tip
            }
        }

        scrollThenReveal()
    }

    func next() {
        guard isActive, currentStepIndex < items.count else { return }
        items[currentStepIndex].onNextAction?(currentStepIndex)

        guard currentStepIndex + 1 < items.count else { finish(); return }

        let previousIndex = currentStepIndex
        tipReady = false
        currentStepIndex += 1
        scrollThenInvalidateAndReveal(previousTipIndex: previousIndex)
    }

    func skip() {
        guard isActive, currentStepIndex < items.count else { return }
        let idx = currentStepIndex
        items[idx].onExitAction?(idx)
        invalidateCurrentTip(reason: .tipClosed)
        deactivate()
        onSkipped?(idx)
    }

    func finish() {
        invalidateCurrentTip(reason: .actionPerformed)
        deactivate()
        onFinished?()
    }

    func dismiss() {
        invalidateCurrentTip(reason: .tipClosed)
        deactivate()
    }

    // MARK: Private helpers

    private func invalidateCurrentTip(reason: Tip.InvalidationReason) {
        guard tips.indices.contains(currentStepIndex) else { return }
        tips[currentStepIndex].invalidate(reason: reason)
    }

    private func deactivate() {
        if Self.current === self { Self.current = nil }
        tipReady = false
        isActive = false
        currentStepIndex = 0
        tipGroup = nil
    }

    /// Scrolls the target into view, then reveals the current tip.
    private func scrollThenReveal() {
        tipReady = false
        guard items.indices.contains(currentStepIndex) else { return }
        let item = items[currentStepIndex]

        guard let coordinator = scrollCoordinator,
              coordinator.hasRegisteredProxies,
              let steps = item.scrollSteps, !steps.isEmpty
        else {
            Task { [weak self] in
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

    /// Scrolls the next target into view, then invalidates the previous
    /// tip (advancing `TipGroup`) and reveals the new tip.
    private func scrollThenInvalidateAndReveal(previousTipIndex: Int) {
        tipReady = false
        guard items.indices.contains(currentStepIndex) else { return }
        let item = items[currentStepIndex]

        let invalidateAndReveal: () -> Void = { [weak self] in
            Task { @MainActor [weak self] in
                guard let self else { return }
                let settleNanos = UInt64(self.configuration.scrollSettleDelay * 1_000_000_000)
                try? await Task.sleep(nanoseconds: settleNanos)
                if self.tips.indices.contains(previousTipIndex) {
                    self.tips[previousTipIndex].invalidate(reason: .actionPerformed)
                }
                self.reveal()
            }
        }

        guard let coordinator = scrollCoordinator,
              coordinator.hasRegisteredProxies,
              let steps = item.scrollSteps, !steps.isEmpty
        else {
            Task { [weak self] in
                try? await Task.sleep(nanoseconds: 100_000_000)
                guard let self else { return }
                if self.tips.indices.contains(previousTipIndex) {
                    self.tips[previousTipIndex].invalidate(reason: .actionPerformed)
                }
                self.reveal()
            }
            return
        }

        coordinator.scrollSequentially(
            targetID: item.id,
            steps: steps,
            anchor: MDSCoachmarkConstants.scrollAnchor,
            animated: MDSCoachmarkConstants.animateTransitions,
            interStepDelay: configuration.scrollInterStepDelay,
            proxyWaitTimeout: configuration.proxyWaitTimeout
        ) {
            invalidateAndReveal()
        }
    }

    private func reveal() {
        
        guard isActive, items.indices.contains(currentStepIndex) else { return }
        tipReady = true
        print ("debug: reveal")
        notifyAppear()
    }

    private func notifyAppear() {
        guard items.indices.contains(currentStepIndex) else { return }
        items[currentStepIndex].onAppearAction?(currentStepIndex)
    }
}
#endif
