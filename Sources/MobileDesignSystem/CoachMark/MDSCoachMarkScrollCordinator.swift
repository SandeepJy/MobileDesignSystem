import SwiftUI

// MARK: - MDSCoachmarkScrollCoordinator

/// Manages registered scroll proxies and executes multi-level scroll sequences.
///
/// The coordinator acts as a registry of named scroll actions. Each `ScrollViewReader`
/// in the view hierarchy registers its proxy under a unique name via
/// `.coachmarkScrollProxy(_:proxy:coordinator:)`. When the coachmark overlay needs
/// to scroll to a target, it asks the coordinator to execute a sequence of
/// ``MDSCoachmarkScrollStep`` values, firing each proxy in order.
///
/// ## Proxy Lifecycle
///
/// Proxies register on `onAppear` and unregister on `onDisappear`. For content inside
/// `LazyVStack`, a proxy may not be registered when the coordinator first needs it.
/// The coordinator handles this by polling for the proxy's registration after the
/// preceding scroll step completes, waiting up to a configurable timeout.
///
/// ## Container IDs
///
/// Each call to `.coachmarkScrollProxy(_:proxy:coordinator:)` applies a deterministic
/// `.id()` to the decorated view. This ID follows the pattern
/// `__mds_coachmark_container_{name}` and allows parent proxies to scroll to the
/// container even without an explicit `parentID` in the scroll step. Use
/// ``defaultContainerID(for:)`` to compute this value if needed.
///
/// ## Usage
///
/// ```swift
/// @StateObject var coordinator = MDSCoachmarkScrollCoordinator()
/// ```
///
/// Pass the coordinator to both `.coachmarkScrollProxy` and `.coachmarkOverlay`.
@MainActor
public final class MDSCoachmarkScrollCoordinator: ObservableObject {

    private var entries: [String: (String, UnitPoint) -> Void] = [:]

    public init() {}

    /// Returns the deterministic container ID for a named proxy.
    ///
    /// This matches the `.id()` value applied by `.coachmarkScrollProxy(_:proxy:coordinator:)`.
    /// Used internally for auto-inference of intermediate scroll targets.
    ///
    /// - Parameter proxyName: The registered name of the scroll proxy.
    /// - Returns: A stable string ID of the form `__mds_coachmark_container_{proxyName}`.
    public static func defaultContainerID(for proxyName: String) -> String {
        "__mds_coachmark_container_\(proxyName)"
    }

    /// Registers a named scroll proxy's action.
    ///
    /// Called automatically by `.coachmarkScrollProxy(_:proxy:coordinator:)` on `onAppear`.
    ///
    /// - Parameters:
    ///   - name: A unique name identifying this scroll proxy.
    ///   - action: A closure that scrolls to a given ID with a given anchor point.
    internal func register(
        _ name: String,
        action: @escaping (String, UnitPoint) -> Void
    ) {
        entries[name] = action
    }

    /// Removes a previously registered scroll proxy.
    ///
    /// Called automatically by `.coachmarkScrollProxy(_:proxy:coordinator:)` on `onDisappear`.
    ///
    /// - Parameter name: The name of the proxy to remove.
    public func unregister(_ name: String) {
        entries.removeValue(forKey: name)
    }

    /// Whether any scroll proxies are currently registered.
    public var hasRegisteredProxies: Bool { !entries.isEmpty }

    /// Executes scroll steps sequentially, bringing a coachmark target into the visible viewport.
    ///
    /// Steps fire from outermost scroll container to innermost. Between each pair of steps,
    /// the coordinator waits for the next proxy to register (handling lazy content that renders
    /// only after scrolling) and then pauses for a settle delay.
    ///
    /// ### Target Resolution
    ///
    /// For each step, the scroll target is determined as follows:
    ///
    /// | Step Position | `parentID` | Scroll Target |
    /// |---|---|---|
    /// | Last | (ignored) | `targetID` — the coachmark item's own anchor |
    /// | Intermediate | non-nil | The explicit `parentID` value |
    /// | Intermediate | nil | ``defaultContainerID(for:)`` of the **next** step's proxy |
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

                guard let scrollAction = entries[step.proxy] else { continue }

                let isLastStep = (index == steps.count - 1)
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
                        scrollAction(scrollTarget, anchor)
                    }
                } else {
                    scrollAction(scrollTarget, anchor)
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

// MARK: - View Extensions

public extension View {

    /// Marks this view as a coachmark spotlight target.
    ///
    /// Applies a stable `.id()` for programmatic scrolling and registers an anchor
    /// preference so the overlay can read the view's frame for spotlight positioning.
    ///
    /// Every ``MDSCoachmarkItem`` references a target by its `id`, which must match
    /// the string passed here.
    ///
    /// ```swift
    /// Text("Settings")
    ///     .coachmarkAnchor("settings")
    /// ```
    ///
    /// - Parameter id: A unique string identifying this anchor. Must be unique within
    ///   the view hierarchy and must match an ``MDSCoachmarkItem/id``.
    /// - Returns: A modified view with the anchor preference and stable identity applied.
    func coachmarkAnchor(_ id: String) -> some View {
        self
            .id(id)
            .anchorPreference(
                key: MDSCoachmarkAnchorPreferenceKey.self,
                value: .bounds
            ) { [id: $0] }
    }

    /// Registers a `ScrollViewProxy` with the coachmark coordinator and applies a
    /// deterministic `.id()` to this view.
    ///
    /// The deterministic `.id()` (see ``MDSCoachmarkScrollCoordinator/defaultContainerID(for:)``)
    /// allows parent scroll proxies to scroll this container into view without an explicit
    /// `parentID` in the scroll step. This covers the common case of non-lazy nested scrolls.
    ///
    /// Apply this modifier on or inside the `ScrollViewReader` that wraps the `ScrollView`:
    ///
    /// ```swift
    /// ScrollViewReader { proxy in
    ///     ScrollView {
    ///         // content with .coachmarkAnchor modifiers
    ///     }
    ///     .coachmarkScrollProxy("main", proxy: proxy, coordinator: coordinator)
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - name: A unique name for this scroll proxy. Referenced by
    ///     ``MDSCoachmarkScrollStep/proxy``.
    ///   - proxy: The `ScrollViewProxy` provided by `ScrollViewReader`.
    ///   - coordinator: The shared ``MDSCoachmarkScrollCoordinator`` instance.
    /// - Returns: A modified view with the proxy registered and a deterministic identity applied.
    func coachmarkScrollProxy(
        _ name: String,
        proxy: ScrollViewProxy,
        coordinator: MDSCoachmarkScrollCoordinator
    ) -> some View {
        let containerID = MDSCoachmarkScrollCoordinator.defaultContainerID(for: name)
        return self
            .id(containerID)
            .onAppear {
                coordinator.register(name) { id, anchor in
                    proxy.scrollTo(id, anchor: anchor)
                }
            }
            .onDisappear {
                coordinator.unregister(name)
            }
    }

    /// Assigns a deterministic `.id()` to a lazily rendered container so that a parent
    /// scroll proxy can scroll to it before its children have rendered.
    ///
    /// ## When to Use
    ///
    /// This modifier is **only required** when a nested `ScrollView` (with its own
    /// `.coachmarkScrollProxy`) lives inside a `LazyVStack`, `LazyHStack`, or any
    /// other deferred-rendering container.
    ///
    /// In lazy containers, child views do not exist in the view hierarchy until they
    /// scroll into the viewport. A parent `ScrollViewReader` cannot find `.id()` values
    /// that are buried inside unrendered children. By applying `.coachmarkParent(_:)` on
    /// the `ForEach` child (the structural level that the lazy stack tracks), the parent
    /// proxy gains a known scroll target that forces the lazy content to render.
    ///
    /// ## Placement
    ///
    /// Apply on the direct child of the `ForEach` inside the lazy stack — **not** inside
    /// the nested `ScrollView`:
    ///
    /// ```swift
    /// LazyVStack {
    ///     ForEach(0..<40, id: \.self) { i in
    ///         if carouselPositions.contains(i) {
    ///             carouselSection(at: i)
    ///                 .coachmarkParent("carousel-\(i)-parent")
    ///         } else {
    ///             rowView(i)
    ///                 .coachmarkAnchor("row-\(i)")
    ///         }
    ///     }
    /// }
    /// ```
    ///
    /// Then reference the same string as the `parentID` in the scroll step:
    ///
    /// ```swift
    /// MDSCoachmarkItem(
    ///     id: "carousel-15-card-6",
    ///     title: "Card 6",
    ///     scrollSteps: [
    ///         .init(proxy: "main", parentID: "carousel-15-parent"),
    ///         .init(proxy: "carousel-15")
    ///     ]
    /// )
    /// ```
    ///
    /// - Parameter id: A unique string that the parent proxy uses as a scroll target.
    ///   Referenced by ``MDSCoachmarkScrollStep/parentID``.
    /// - Returns: A modified view with the given identity applied.
    func coachmarkParent(_ id: String) -> some View {
        self.id(id)
    }

    /// Presents a coachmark tour overlay on top of this view.
    ///
    /// When `isPresented` becomes `true`, the overlay dims the screen and sequentially
    /// highlights each item in `items`, scrolling to off-screen targets as needed.
    ///
    /// ```swift
    /// .coachmarkOverlay(
    ///     isPresented: $showTour,
    ///     items: [
    ///         MDSCoachmarkItem(id: "welcome", title: "Welcome")
    ///             .onAppear { _ in print("Showing welcome") },
    ///         MDSCoachmarkItem(id: "feature", title: "Feature",
    ///                          scrollSteps: [.init(proxy: "main")])
    ///             .onNext { i in print("Advancing from \(i)") }
    ///     ],
    ///     scrollCoordinator: coordinator,
    ///     onFinished: { print("Tour complete") }
    /// )
    /// ```
    ///
    /// - Parameters:
    ///   - isPresented: A binding that controls whether the overlay is visible.
    ///     Set to `false` to dismiss.
    ///   - configuration: Behavioral settings for the overlay.
    ///     Defaults to ``MDSCoachmarkConfiguration/init()``.
    ///   - items: An ordered array of ``MDSCoachmarkItem`` values defining the tour steps.
    ///   - scrollCoordinator: The shared ``MDSCoachmarkScrollCoordinator`` that manages
    ///     scroll proxies. Pass `nil` if no scrolling is needed.
    ///   - onFinished: Called when the user taps the finish button on the last step.
    ///   - onSkipped: Called when the user taps the skip button, with the index of the
    ///     step that was active when skipping occurred.
    /// - Returns: A view with the coachmark overlay attached.
    func coachmarkOverlay(
        isPresented: Binding<Bool>,
        configuration: MDSCoachmarkConfiguration = MDSCoachmarkConfiguration(),
        items: [MDSCoachmarkItem],
        scrollCoordinator: MDSCoachmarkScrollCoordinator? = nil,
        onFinished: (() -> Void)? = nil,
        onSkipped: ((Int) -> Void)? = nil
    ) -> some View {
        self.modifier(
            MDSCoachmarkOverlayModifier(
                isPresented: isPresented,
                items: items,
                configuration: configuration,
                scrollCoordinator: scrollCoordinator,
                onFinished: onFinished,
                onSkipped: onSkipped
            )
        )
    }
}
