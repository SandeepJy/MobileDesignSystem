import SwiftUI

// MARK: - MDSCoachmarkScrollCoordinator

/// Manages registered scrollable containers and executes multi-level scroll sequences.
///
/// Any type conforming to ``MDSCoachmarkScrollable`` can register itself under a
/// unique name. When the coachmark overlay needs to scroll to a target, the
/// coordinator fires each step's scrollable in order.
@MainActor
public final class MDSCoachmarkScrollCoordinator: ObservableObject {

    private var scrollables: [String: MDSCoachmarkScrollable] = [:]

    public init() {}

    /// Returns the deterministic container ID for a named proxy.
    public static func defaultContainerID(for proxyName: String) -> String {
        "__mds_coachmark_container_\(proxyName)"
    }

    // MARK: - Registration

    /// Registers a scrollable container under a unique name.
    ///
    /// - Parameters:
    ///   - name: A unique name identifying this scrollable.
    ///   - scrollable: The scrollable container to register.
    public func register(_ name: String, scrollable: MDSCoachmarkScrollable) {
        scrollables[name] = scrollable
    }

    /// Removes a previously registered scrollable.
    public func unregister(_ name: String) {
        scrollables.removeValue(forKey: name)
    }

    /// Whether any scrollable containers are currently registered.
    public var hasRegisteredProxies: Bool { !scrollables.isEmpty }

    // MARK: - Scroll Execution

    /// Executes scroll steps sequentially, bringing a coachmark target into view.
    ///
    /// Steps fire from outermost scroll container to innermost. Between each
    /// pair of steps, the coordinator waits for the next scrollable to register
    /// (handling lazy content) and pauses for a settle delay.
    public func scrollSequentially(
        targetID: String,
        steps: [MDSCoachmarkScrollStep],
        anchor: UnitPoint,
        animated: Bool,
        interStepDelay: TimeInterval = 0.35,
        proxyWaitTimeout: TimeInterval = 3.0,
        completion: @escaping () -> Void
    ) {
        guard !steps.isEmpty else {
            completion()
            return
        }

        Task {
            for (index, step) in steps.enumerated() {
                // Poll until the scrollable is registered (handles lazy containers).
                let pollNanos: UInt64 = 50_000_000
                let maxPolls = Int(proxyWaitTimeout / 0.05)
                var polls = 0
                while scrollables[step.proxy] == nil && polls < maxPolls {
                    try? await Task.sleep(nanoseconds: pollNanos)
                    polls += 1
                }

                guard let scrollable = scrollables[step.proxy] else { continue }

                let isLastStep = (index == steps.count - 1)

                // Build the scroll target for this step.
                let scrollTarget: ScrollTarget

                if let carouselPage = step.carouselPage {
                    scrollTarget = .page(carouselPage)
                } else if isLastStep {
                    scrollTarget = .viewID(targetID)
                } else if let parentID = step.parentID {
                    scrollTarget = .viewID(parentID)
                } else {
                    let nextProxyName = steps[index + 1].proxy
                    scrollTarget = .viewID(Self.defaultContainerID(for: nextProxyName))
                }

                scrollable.scrollToTarget(scrollTarget, anchor: anchor, animated: animated)

                if index < steps.count - 1 {
                    try? await Task.sleep(
                        nanoseconds: UInt64(interStepDelay * 1_000_000_000)
                    )
                }
            }
            completion()
        }
    }
}
