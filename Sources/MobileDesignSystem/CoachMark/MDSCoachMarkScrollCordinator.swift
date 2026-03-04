import SwiftUI

// MARK: - MDSCoachmarkScrollCoordinator

/// Manages registered scrollable proxies and executes multi-level scroll
/// sequences for the coachmark system.
///
/// Any container that conforms to ``CoachmarkScrollableProxy`` can register
/// itself. When a coachmark needs to scroll to an off-screen target, the
/// coordinator fires each proxy in sequence from outermost to innermost.
///
/// ```swift
/// @StateObject var coordinator = MDSCoachmarkScrollCoordinator()
/// ```
@MainActor
public final class MDSCoachmarkScrollCoordinator: ObservableObject {

    private var entries: [String: any CoachmarkScrollableProxy] = [:]

    public init() {}

    // MARK: - Container ID

    /// Returns the deterministic container ID for a named proxy.
    ///
    /// Matches the `.id()` value applied by the registration modifiers.
    public static func defaultContainerID(for proxyName: String) -> String {
        "__mds_coachmark_container_\(proxyName)"
    }

    // MARK: - Registration

    /// Registers a scrollable proxy under the given name.
    ///
    /// Called automatically by the `.coachmarkScrollableProxy`,
    /// `.coachmarkScrollProxy`, and `.coachmarkCarouselProxy` modifiers.
    ///
    /// - Parameters:
    ///   - name: A unique name identifying this scrollable container.
    ///   - proxy: The proxy that can perform scroll operations.
    public func register(_ name: String, proxy: any CoachmarkScrollableProxy) {
        entries[name] = proxy
    }

    /// Removes a previously registered proxy.
    public func unregister(_ name: String) {
        entries.removeValue(forKey: name)
    }

    /// Whether any scrollable proxies are currently registered.
    public var hasRegisteredProxies: Bool { !entries.isEmpty }

    // MARK: - Sequential Scrolling

    /// Executes scroll steps sequentially, bringing a coachmark target into
    /// the visible viewport.
    ///
    /// Each step is dispatched to the registered ``CoachmarkScrollableProxy``
    /// that matches the step's `proxy` name:
    ///
    /// - Steps with a non-nil ``MDSCoachmarkScrollStep/carouselPage`` call
    ///   ``CoachmarkScrollableProxy/scrollTo(page:animated:)``.
    /// - All other steps resolve an ID target and call
    ///   ``CoachmarkScrollableProxy/scrollTo(id:anchor:)``.
    ///
    /// - Parameters:
    ///   - targetID: The coachmark item's anchor ID (the final scroll destination).
    ///   - steps: Ordered scroll steps from outermost to innermost.
    ///   - anchor: The alignment point within the viewport to scroll the target to.
    ///   - animated: Whether each scroll operation should animate.
    ///   - interStepDelay: Seconds to wait between consecutive scroll steps.
    ///   - proxyWaitTimeout: Maximum seconds to poll for a lazily registered proxy.
    ///   - completion: Called on the main actor after all steps complete.
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
                let pollNanos: UInt64 = 50_000_000
                let maxPolls = Int(proxyWaitTimeout / 0.05)
                var polls = 0
                while entries[step.proxy] == nil && polls < maxPolls {
                    try? await Task.sleep(nanoseconds: pollNanos)
                    polls += 1
                }

                guard let scrollProxy = entries[step.proxy] else { continue }

                let isLastStep = (index == steps.count - 1)

                if let page = step.carouselPage {
                    // ── Page-based scroll ──────────────────────────────
                    scrollProxy.scrollTo(page: page, animated: animated)
                } else {
                    // ── ID-based scroll ────────────────────────────────
                    let scrollTarget: String
                    if isLastStep {
                        scrollTarget = targetID
                    } else if let parentID = step.parentID {
                        scrollTarget = parentID
                    } else {
                        let nextProxyName = steps[index + 1].proxy
                        scrollTarget = Self.defaultContainerID(for: nextProxyName)
                    }

                    if animated {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            scrollProxy.scrollTo(id: scrollTarget, anchor: anchor)
                        }
                    } else {
                        scrollProxy.scrollTo(id: scrollTarget, anchor: anchor)
                    }
                }


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
