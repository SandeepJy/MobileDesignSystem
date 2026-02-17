import SwiftUI

// MARK: - MDSCoachmark Overview

/// A guided tour system for SwiftUI that highlights UI elements with spotlights and tooltip-style tips.
///
/// ## Overview
///
/// `MDSCoachmark` provides a declarative API for building step-by-step guided tours
/// that work with any combination of vertical scrolling, horizontal carousels, lazy stacks,
/// and arbitrarily deep nesting. The system handles scrolling to off-screen targets,
/// waiting for lazily rendered content, and presenting animated spotlight overlays.
///
/// ### Core Concepts
///
/// The framework exposes three view modifiers and one model type for defining tours:
///
/// | Modifier | Purpose |
/// |---|---|
/// | `.coachmarkAnchor(_:)` | Marks a view as a spotlight target |
/// | `.coachmarkScrollProxy(_:proxy:coordinator:)` | Registers a `ScrollViewProxy` so the system can scroll programmatically |
/// | `.coachmarkParent(_:)` | Assigns a deterministic ID on a lazy container so a parent proxy can scroll to it before its children render |
///
/// ### Decision Tree
///
/// Use the following to determine which modifiers and scroll steps each coachmark item requires:
///
/// ```
///                 Is the target inside a nested ScrollView?
///                 ┌─── No ──→ scrollSteps: [.init(proxy: "main")]
///                 │
///                 Yes
///                 │
///                 Is the nested ScrollView inside a LazyVStack?
///                 ├─── No ──→ scrollSteps: [
///                 │              .init(proxy: "main"),
///                 │              .init(proxy: "carousel")
///                 │           ]
///                 │           (auto-infers intermediate target)
///                 │
///                 └─── Yes ─→ 1. Add .coachmarkParent("x") on ForEach child
///                             2. scrollSteps: [
///                                  .init(proxy: "main", parentID: "x"),
///                                  .init(proxy: "carousel")
///                                ]
/// ```
///
/// ### Minimal Example
///
/// ```swift
/// struct ContentView: View {
///     @StateObject var coordinator = MDSCoachmarkScrollCoordinator()
///     @State var showTour = false
///
///     var body: some View {
///         ScrollViewReader { proxy in
///             ScrollView {
///                 VStack {
///                     Text("Welcome")
///                         .coachmarkAnchor("welcome")
///                     Text("Feature")
///                         .coachmarkAnchor("feature")
///                 }
///             }
///             .coachmarkScrollProxy("main", proxy: proxy, coordinator: coordinator)
///         }
///         .coachmarkOverlay(
///             isPresented: $showTour,
///             items: [
///                 MDSCoachmarkItem(id: "welcome", title: "Welcome"),
///                 MDSCoachmarkItem(
///                     id: "feature",
///                     title: "Feature",
///                     scrollSteps: [.init(proxy: "main")]
///                 )
///             ],
///             scrollCoordinator: coordinator
///         )
///     }
/// }
/// ```
///
/// ### Nested Scroll Example (Non-Lazy)
///
/// When a target lives inside a horizontal carousel that itself is inside a vertical scroll,
/// the system scrolls each level sequentially. For non-lazy content, intermediate scroll
/// targets are inferred automatically from the proxy container IDs:
///
/// ```swift
/// ScrollViewReader { mainProxy in
///     ScrollView {
///         ScrollViewReader { carouselProxy in
///             ScrollView(.horizontal) {
///                 HStack {
///                     ForEach(0..<10) { i in
///                         CardView(index: i)
///                             .coachmarkAnchor("card-\(i)")
///                     }
///                 }
///             }
///             .coachmarkScrollProxy("carousel", proxy: carouselProxy, coordinator: coordinator)
///         }
///     }
///     .coachmarkScrollProxy("main", proxy: mainProxy, coordinator: coordinator)
/// }
/// ```
///
/// Items reference the chain of proxies:
/// ```swift
/// MDSCoachmarkItem(
///     id: "card-7",
///     title: "Card 7",
///     scrollSteps: [
///         .init(proxy: "main"),      // scrolls main to carousel container
///         .init(proxy: "carousel")   // scrolls carousel to card-7
///     ]
/// )
/// ```
///
/// ### Lazy Stack Example
///
/// Inside a `LazyVStack`, child views are not rendered until they scroll into the viewport.
/// The parent `ScrollViewReader` cannot find IDs that live inside unrendered children.
/// To solve this, apply `.coachmarkParent(_:)` on the `ForEach` child. This gives
/// the outer `ScrollViewReader` a known ID to scroll to, which forces the lazy content
/// to render, which in turn registers the inner proxy:
///
/// ```swift
/// LazyVStack {
///     ForEach(0..<40, id: \.self) { i in
///         if i == 15 {
///             carouselSection()
///                 .coachmarkParent("carousel-15-parent")
///         } else {
///             rowView(i)
///                 .coachmarkAnchor("row-\(i)")
///         }
///     }
/// }
/// ```
///
/// Items reference the explicit parent ID:
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

// MARK: - MDSCoachmarkScrollStep

/// Describes a single scroll operation within a multi-level scroll chain.
///
/// Each step pairs a named scroll proxy (the `ScrollView` that performs the scroll)
/// with an optional target ID (the view it scrolls to). Steps execute sequentially
/// from outermost scroll container to innermost.
///
/// ## Automatic Target Inference
///
/// When `parentID` is `nil`:
/// - On the **last step**, the proxy scrolls to the coachmark item's own `id`.
/// - On an **intermediate step**, the proxy scrolls to the next step's proxy container ID.
///   This works because `.coachmarkScrollProxy(_:proxy:coordinator:)` applies a
///   deterministic `.id()` to the scroll view it decorates.
///
/// ## Explicit Parent ID
///
/// Set `parentID` when the next scroll proxy lives inside a `LazyVStack` or similar
/// deferred-rendering container. The explicit ID must match the value passed to
/// `.coachmarkParent(_:)` on the lazy `ForEach` child.
///
/// ## Examples
///
/// Simple single-level scroll:
/// ```swift
/// MDSCoachmarkScrollStep(proxy: "main")
/// ```
///
/// Intermediate step with auto-inference (non-lazy):
/// ```swift
/// MDSCoachmarkScrollStep(proxy: "main")  // auto-targets carousel container
/// ```
///
/// Intermediate step with explicit parent (lazy):
/// ```swift
/// MDSCoachmarkScrollStep(proxy: "main", parentID: "carousel-parent")
/// ```
public struct MDSCoachmarkScrollStep: Equatable, Hashable {

    /// The name of the registered scroll proxy that performs this scroll operation.
    ///
    /// Must match the `name` parameter passed to `.coachmarkScrollProxy(_:proxy:coordinator:)`.
    public let proxy: String

    /// The explicit scroll target ID for this step.
    ///
    /// - When `nil` on the last step: the proxy scrolls to the coachmark item's `id`.
    /// - When `nil` on an intermediate step: the proxy scrolls to the next step's
    ///   proxy container ID (auto-inferred).
    /// - When set: the proxy scrolls to this exact ID. Use this when the next proxy
    ///   lives inside lazy content and needs `.coachmarkParent(_:)` to be reachable.
    public let parentID: String?

    /// Creates a scroll step.
    ///
    /// - Parameters:
    ///   - proxy: The name of the scroll proxy that performs this scroll.
    ///   - parentID: An explicit scroll target. Pass `nil` to use automatic inference.
    public init(proxy: String, parentID: String? = nil) {
        self.proxy = proxy
        self.parentID = parentID
    }
}

// MARK: - MDSCoachmarkItem

/// A single step in a coachmark tour, describing which view to spotlight and how to reach it.
///
/// Each item identifies its target view by `id` (which must match the value passed to
/// `.coachmarkAnchor(_:)`) and optionally defines a sequence of ``MDSCoachmarkScrollStep``
/// values that describe how to scroll the target into the visible viewport.
///
/// ## Example
///
/// ```swift
/// MDSCoachmarkItem(
///     id: "settings-button",
///     title: "Settings",
///     description: "Tap here to open your preferences.",
///     iconName: "gear",
///     iconColor: .blue,
///     scrollSteps: [.init(proxy: "main")]
/// )
/// ```
public struct MDSCoachmarkItem: Identifiable, Equatable {

    /// The unique identifier for this coachmark step.
    ///
    /// Must match the string passed to `.coachmarkAnchor(_:)` on the target view.
    public let id: String

    /// The title displayed in the tooltip tip.
    public let title: String

    /// An optional longer description displayed below the title.
    public let description: String?

    /// An optional SF Symbol name displayed alongside the text content.
    public let iconName: String?

    /// The color applied to the icon. Falls back to ``MDSCoachmarkConfiguration/defaultIconColor``
    /// when `nil`.
    public let iconColor: Color?

    /// An ordered sequence of scroll operations to execute before showing this coachmark.
    ///
    /// - `nil`: No scrolling is performed; the target is assumed to be already visible.
    /// - One step: A single scroll proxy scrolls directly to the target.
    /// - Multiple steps: Proxies fire sequentially from outermost to innermost,
    ///   each bringing the next scroll container into the viewport.
    ///
    /// See ``MDSCoachmarkScrollStep`` for details on automatic target inference
    /// and explicit parent IDs for lazy content.
    public let scrollSteps: [MDSCoachmarkScrollStep]?

    /// Creates a coachmark item.
    ///
    /// - Parameters:
    ///   - id: Unique identifier matching a `.coachmarkAnchor(_:)` value.
    ///   - title: The tooltip title text.
    ///   - description: Optional descriptive text below the title.
    ///   - iconName: Optional SF Symbol name for the tooltip icon.
    ///   - iconColor: Optional color override for the icon.
    ///   - scrollSteps: Ordered scroll operations to reach this target, or `nil` if already visible.
    public init(
        id: String,
        title: String,
        description: String? = nil,
        iconName: String? = nil,
        iconColor: Color? = nil,
        scrollSteps: [MDSCoachmarkScrollStep]? = nil
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.iconName = iconName
        self.iconColor = iconColor
        self.scrollSteps = scrollSteps
    }

    public static func == (lhs: MDSCoachmarkItem, rhs: MDSCoachmarkItem) -> Bool {
        lhs.id == rhs.id &&
        lhs.title == rhs.title &&
        lhs.description == rhs.description &&
        lhs.iconName == rhs.iconName &&
        lhs.scrollSteps == rhs.scrollSteps
    }
}

// MARK: - MDSCoachmarkScrollCoordinator

/// Manages registered scroll proxies and executes multi-level scroll sequences.
///
/// ## Overview
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
    ///   - interStepDelay: Seconds to wait between consecutive scroll steps for the
    ///     animation to settle. Defaults to `0.35`.
    ///   - proxyWaitTimeout: Maximum seconds to poll for a lazily registered proxy
    ///     before skipping the step. Defaults to `3.0`.
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

                guard let scrollAction = entries[step.proxy] else {
                    continue
                }

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
    ///                 .coachmarkParent("carousel-\(i)-parent")   // ← here
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
    ///         MDSCoachmarkItem(id: "welcome", title: "Welcome"),
    ///         MDSCoachmarkItem(id: "feature", title: "Feature",
    ///                          scrollSteps: [.init(proxy: "main")])
    ///     ],
    ///     scrollCoordinator: coordinator,
    ///     onFinished: { print("Tour complete") }
    /// )
    /// ```
    ///
    /// - Parameters:
    ///   - isPresented: A binding that controls whether the overlay is visible.
    ///     Set to `false` to dismiss.
    ///   - configuration: Visual and behavioral settings for the overlay.
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

// MARK: - MDSCoachmarkArrowDirection

/// Controls the placement of the tooltip arrow relative to the spotlight.
///
/// - ``automatic``: The system chooses above or below based on available space,
///   preferring below when sufficient room exists.
/// - ``top``: The tooltip always appears above the spotlight (arrow points down).
/// - ``bottom``: The tooltip always appears below the spotlight (arrow points up).
public enum MDSCoachmarkArrowDirection {
    case top, bottom, automatic
}

// MARK: - MDSCoachmarkTipLayoutStyle

/// Controls how the icon and text are arranged inside the tooltip.
///
/// - ``horizontal``: Icon and text sit side by side.
/// - ``vertical``: Icon appears above the text.
/// - ``textOnly``: No icon is rendered regardless of the item's `iconName`.
public enum MDSCoachmarkTipLayoutStyle {
    case horizontal, vertical, textOnly
}

// MARK: - MDSCoachmarkConfiguration

/// Visual and behavioral settings for the coachmark overlay.
///
/// All properties have sensible defaults. Create an instance with only the
/// overrides you need:
///
/// ```swift
/// let config = MDSCoachmarkConfiguration(
///     overlayColor: Color.black.opacity(0.7),
///     accentColor: .green,
///     spotlightCornerRadius: 16
/// )
/// ```
public struct MDSCoachmarkConfiguration {

    // MARK: Navigation Buttons

    /// Whether a skip/exit button is shown on non-final steps. Defaults to `true`.
    public var showExitButton: Bool

    /// Label text for the exit/skip button. Defaults to `"Skip"`.
    public var exitButtonLabel: String

    /// Label text for the next button. Defaults to `"Next"`.
    public var nextButtonLabel: String

    /// Label text for the finish button on the last step. Defaults to `"Done"`.
    public var finishButtonLabel: String

    /// Label text for the back button. Defaults to `"Back"`.
    public var backButtonLabel: String

    /// Whether a back button is shown on non-first steps. Defaults to `true`.
    public var showBackButton: Bool

    // MARK: Overlay

    /// The color of the dimming overlay behind the spotlight. Defaults to `black` at 50% opacity.
    public var overlayColor: Color

    // MARK: Tooltip Appearance

    /// Background color of the tooltip bubble. Defaults to `systemBackground`.
    public var tipBackgroundColor: Color

    /// Corner radius of the tooltip bubble. Defaults to `12`.
    public var tipCornerRadius: CGFloat

    /// Shadow radius of the tooltip bubble. Defaults to `8`.
    public var tipShadowRadius: CGFloat

    /// Horizontal padding inside the tooltip bubble. Defaults to `16`.
    public var tipHorizontalPadding: CGFloat

    /// Vertical padding inside the tooltip bubble. Defaults to `12`.
    public var tipVerticalPadding: CGFloat

    /// Maximum width of the tooltip. When `nil`, the tooltip stretches to fill available space.
    public var tipMaxWidth: CGFloat?

    /// Layout arrangement of icon and text inside the tooltip. Defaults to ``MDSCoachmarkTipLayoutStyle/horizontal``.
    public var tipLayoutStyle: MDSCoachmarkTipLayoutStyle

    // MARK: Typography

    /// Font for the tooltip title. Defaults to `.headline`.
    public var titleFont: Font

    /// Color for the tooltip title. Defaults to `.primary`.
    public var titleColor: Color

    /// Font for the tooltip description. Defaults to `.subheadline`.
    public var descriptionFont: Font

    /// Color for the tooltip description. Defaults to `.secondary`.
    public var descriptionColor: Color

    /// Font for the step indicator (e.g., "2 of 5"). Defaults to `.caption`.
    public var stepIndicatorFont: Font

    /// Color for the step indicator text. Defaults to `.secondary`.
    public var stepIndicatorColor: Color

    // MARK: Icon

    /// Size of the tooltip icon in points. Defaults to `24`.
    public var defaultIconSize: CGFloat

    /// Fallback color for tooltip icons when ``MDSCoachmarkItem/iconColor`` is `nil`. Defaults to `.blue`.
    public var defaultIconColor: Color

    // MARK: Accent

    /// The accent color used for navigation buttons and the finish button background. Defaults to `.blue`.
    public var accentColor: Color

    // MARK: Spotlight

    /// Color of the border drawn around the spotlight cutout. Defaults to `.clear` (no border).
    public var spotlightBorderColor: Color

    /// Width of the spotlight border. Defaults to `0` (no border).
    public var spotlightBorderWidth: CGFloat

    /// Corner radius of the spotlight cutout. Defaults to `8`.
    public var spotlightCornerRadius: CGFloat

    /// Padding between the target view's bounds and the spotlight cutout edge. Defaults to `4`.
    public var spotlightPadding: CGFloat

    // MARK: Arrow

    /// Placement of the tooltip relative to the spotlight. Defaults to ``MDSCoachmarkArrowDirection/automatic``.
    public var arrowDirection: MDSCoachmarkArrowDirection

    /// Size of the tooltip arrow in points. The arrow is twice this width and this height tall. Defaults to `8`.
    public var arrowSize: CGFloat

    // MARK: Animation & Scrolling

    /// Whether transitions between steps and tooltip appearances are animated. Defaults to `true`.
    public var animateTransitions: Bool

    /// The anchor point within the viewport that scroll operations target. Defaults to `.center`.
    public var scrollAnchor: UnitPoint

    /// Seconds to wait after all scroll steps complete before showing the tooltip.
    /// Allows the scroll animation to fully settle. Defaults to `0.4`.
    public var scrollSettleDelay: TimeInterval

    /// Seconds to wait between consecutive scroll steps in a multi-level chain.
    /// Allows each scroll animation to complete before the next fires. Defaults to `0.35`.
    public var scrollInterStepDelay: TimeInterval

    /// Maximum seconds to wait for a lazily registered scroll proxy before skipping the step.
    /// Increase this value for very complex lazy layouts. Defaults to `3.0`.
    public var proxyWaitTimeout: TimeInterval

    // MARK: Safe Area

    /// Minimum margin between the tooltip edge and the safe area boundary (navigation bar,
    /// tab bar, home indicator). Prevents the tooltip from appearing behind system UI. Defaults to `8`.
    public var tipSafeAreaMargin: CGFloat

    /// Creates a configuration with the given overrides.
    ///
    /// All parameters have default values. Pass only the properties you want to customize.
    public init(
        showExitButton: Bool = true,
        exitButtonLabel: String = "Skip",
        nextButtonLabel: String = "Next",
        finishButtonLabel: String = "Done",
        backButtonLabel: String = "Back",
        showBackButton: Bool = true,
        overlayColor: Color = Color.black.opacity(0.5),
        tipBackgroundColor: Color = Color(UIColor.systemBackground),
        tipCornerRadius: CGFloat = 12,
        tipShadowRadius: CGFloat = 8,
        tipHorizontalPadding: CGFloat = 16,
        tipVerticalPadding: CGFloat = 12,
        tipMaxWidth: CGFloat? = nil,
        tipLayoutStyle: MDSCoachmarkTipLayoutStyle = .horizontal,
        titleFont: Font = .headline,
        titleColor: Color = .primary,
        descriptionFont: Font = .subheadline,
        descriptionColor: Color = .secondary,
        stepIndicatorFont: Font = .caption,
        stepIndicatorColor: Color = .secondary,
        defaultIconSize: CGFloat = 24,
        defaultIconColor: Color = .blue,
        accentColor: Color = .blue,
        spotlightBorderColor: Color = .clear,
        spotlightBorderWidth: CGFloat = 0,
        spotlightCornerRadius: CGFloat = 8,
        spotlightPadding: CGFloat = 4,
        arrowDirection: MDSCoachmarkArrowDirection = .automatic,
        arrowSize: CGFloat = 8,
        animateTransitions: Bool = true,
        scrollAnchor: UnitPoint = .center,
        scrollSettleDelay: TimeInterval = 0.4,
        scrollInterStepDelay: TimeInterval = 0.35,
        proxyWaitTimeout: TimeInterval = 3.0,
        tipSafeAreaMargin: CGFloat = 8
    ) {
        self.showExitButton = showExitButton
        self.exitButtonLabel = exitButtonLabel
        self.nextButtonLabel = nextButtonLabel
        self.finishButtonLabel = finishButtonLabel
        self.backButtonLabel = backButtonLabel
        self.showBackButton = showBackButton
        self.overlayColor = overlayColor
        self.tipBackgroundColor = tipBackgroundColor
        self.tipCornerRadius = tipCornerRadius
        self.tipShadowRadius = tipShadowRadius
        self.tipHorizontalPadding = tipHorizontalPadding
        self.tipVerticalPadding = tipVerticalPadding
        self.tipMaxWidth = tipMaxWidth
        self.tipLayoutStyle = tipLayoutStyle
        self.titleFont = titleFont
        self.titleColor = titleColor
        self.descriptionFont = descriptionFont
        self.descriptionColor = descriptionColor
        self.stepIndicatorFont = stepIndicatorFont
        self.stepIndicatorColor = stepIndicatorColor
        self.defaultIconSize = defaultIconSize
        self.defaultIconColor = defaultIconColor
        self.accentColor = accentColor
        self.spotlightBorderColor = spotlightBorderColor
        self.spotlightBorderWidth = spotlightBorderWidth
        self.spotlightCornerRadius = spotlightCornerRadius
        self.spotlightPadding = spotlightPadding
        self.arrowDirection = arrowDirection
        self.arrowSize = arrowSize
        self.animateTransitions = animateTransitions
        self.scrollAnchor = scrollAnchor
        self.scrollSettleDelay = scrollSettleDelay
        self.scrollInterStepDelay = scrollInterStepDelay
        self.proxyWaitTimeout = proxyWaitTimeout
        self.tipSafeAreaMargin = tipSafeAreaMargin
    }
}

// MARK: - MDSCoachmarkAnchorPreferenceKey

/// A preference key that collects anchor geometry from views marked with `.coachmarkAnchor(_:)`.
///
/// The overlay reads these anchors to position the spotlight cutout and tooltip arrow.
/// Consumers do not interact with this key directly.
public struct MDSCoachmarkAnchorPreferenceKey: PreferenceKey {
    public static let defaultValue: [String: Anchor<CGRect>] = [:]
    public static func reduce(
        value: inout [String: Anchor<CGRect>],
        nextValue: () -> [String: Anchor<CGRect>]
    ) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

// MARK: - Internal: Tip Content View

private struct MDSCoachmarkTipContentView: View {
    let item: MDSCoachmarkItem
    let stepIndex: Int
    let totalSteps: Int
    let isFirst: Bool
    let isLast: Bool
    let configuration: MDSCoachmarkConfiguration
    let onBack: () -> Void
    let onNext: () -> Void
    let onSkip: () -> Void
    let onFinish: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            contentLayout
            Divider()
            navigationBar
        }
    }

    @ViewBuilder
    private var contentLayout: some View {
        switch configuration.tipLayoutStyle {
        case .horizontal: horizontalLayout
        case .vertical:   verticalLayout
        case .textOnly:   textOnlyLayout
        }
    }

    @ViewBuilder
    private var horizontalLayout: some View {
        HStack(alignment: .top, spacing: 12) {
            if let iconName = item.iconName { iconView(systemName: iconName) }
            textContent
        }
    }

    @ViewBuilder
    private var verticalLayout: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let iconName = item.iconName { iconView(systemName: iconName) }
            textContent
        }
    }

    @ViewBuilder
    private var textOnlyLayout: some View { textContent }

    @ViewBuilder
    private var textContent: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(item.title)
                .font(configuration.titleFont)
                .foregroundColor(configuration.titleColor)
                .fixedSize(horizontal: false, vertical: true)
            if let desc = item.description, !desc.isEmpty {
                Text(desc)
                    .font(configuration.descriptionFont)
                    .foregroundColor(configuration.descriptionColor)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func iconView(systemName: String) -> some View {
        let color = item.iconColor ?? configuration.defaultIconColor
        Image(systemName: systemName)
            .font(.system(size: configuration.defaultIconSize))
            .foregroundColor(color)
            .frame(
                width: configuration.defaultIconSize + 8,
                height: configuration.defaultIconSize + 8
            )
    }

    @ViewBuilder
    private var navigationBar: some View {
        HStack {
            Text("\(stepIndex + 1) of \(totalSteps)")
                .font(configuration.stepIndicatorFont)
                .foregroundColor(configuration.stepIndicatorColor)
            Spacer()
            if configuration.showExitButton && !isLast {
                Button(action: onSkip) {
                    Text(configuration.exitButtonLabel)
                        .font(.subheadline).foregroundColor(.secondary)
                }
                .padding(.trailing, 8)
            }
            if configuration.showBackButton && !isFirst {
                Button(action: onBack) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left").font(.caption.bold())
                        Text(configuration.backButtonLabel).font(.subheadline.bold())
                    }
                    .foregroundColor(configuration.accentColor)
                }
                .padding(.trailing, 4)
            }
            Button(action: isLast ? onFinish : onNext) {
                HStack(spacing: 4) {
                    Text(isLast ? configuration.finishButtonLabel : configuration.nextButtonLabel)
                        .font(.subheadline.bold())
                    if !isLast {
                        Image(systemName: "chevron.right").font(.caption.bold())
                    }
                }
                .foregroundColor(isLast ? .white : configuration.accentColor)
                .padding(.horizontal, isLast ? 16 : 0)
                .padding(.vertical, isLast ? 6 : 0)
                .background(
                    Group { if isLast { Capsule().fill(configuration.accentColor) } }
                )
            }
        }
    }
}

// MARK: - Internal: Visibility Check

private func isRectVisible(
    _ rect: CGRect, in containerSize: CGSize, threshold: CGFloat = 0.5
) -> Bool {
    let visible = CGRect(origin: .zero, size: containerSize)
    let intersection = rect.intersection(visible)
    guard !intersection.isNull else { return false }
    let portion = (intersection.width * intersection.height)
        / max(rect.width * rect.height, 1)
    return portion >= threshold
}

// MARK: - Internal: Triangle Shape

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

// MARK: - Internal: Tip Positioning Container

private struct TipPositioningContainer<Content: View>: View {
    let anchorRect: CGRect
    let showBelow: Bool
    let arrowSize: CGFloat
    let spotlightPadding: CGFloat
    let screenSize: CGSize
    let safeAreaInsets: EdgeInsets
    let safeAreaMargin: CGFloat
    let content: Content

    @State private var tipSize: CGSize = .zero

    init(
        anchorRect: CGRect,
        showBelow: Bool,
        arrowSize: CGFloat,
        spotlightPadding: CGFloat,
        screenSize: CGSize,
        safeAreaInsets: EdgeInsets,
        safeAreaMargin: CGFloat = 8,
        @ViewBuilder content: () -> Content
    ) {
        self.anchorRect = anchorRect
        self.showBelow = showBelow
        self.arrowSize = arrowSize
        self.spotlightPadding = spotlightPadding
        self.screenSize = screenSize
        self.safeAreaInsets = safeAreaInsets
        self.safeAreaMargin = safeAreaMargin
        self.content = content()
    }

    var body: some View {
        content
            .background(
                GeometryReader { g in
                    Color.clear
                        .onAppear { tipSize = g.size }
                        .onChange(of: g.size.height) { _ in tipSize = g.size }
                }
            )
            .frame(maxWidth: .infinity)
            .position(x: screenSize.width / 2, y: computedY)
    }

    private var gap: CGFloat { 4 }

    private var computedY: CGFloat {
        if showBelow {
            let top = anchorRect.maxY + spotlightPadding + gap + arrowSize
            let y = top + tipSize.height / 2
            let maxY = screenSize.height - safeAreaInsets.bottom
                - tipSize.height / 2 - safeAreaMargin
            return min(y, maxY)
        } else {
            let bottom = anchorRect.minY - spotlightPadding - gap - arrowSize
            let y = bottom - tipSize.height / 2
            let minY = safeAreaInsets.top + tipSize.height / 2 + safeAreaMargin
            return max(y, minY)
        }
    }
}

// MARK: - Internal: Coachmark Overlay View

private struct MDSCoachmarkOverlayView<WrappedContent: View>: View {
    let wrappedContent: WrappedContent
    @Binding var isPresented: Bool
    let items: [MDSCoachmarkItem]
    let configuration: MDSCoachmarkConfiguration
    let onFinished: (() -> Void)?
    let onSkipped: ((Int) -> Void)?
    let scrollCoordinator: MDSCoachmarkScrollCoordinator?

    @State private var currentIndex: Int = 0
    @State private var isScrolling: Bool = false
    @State private var tipVisible: Bool = false

    var body: some View {
        wrappedContent
            .overlayPreferenceValue(MDSCoachmarkAnchorPreferenceKey.self) { anchors in
                if isPresented, !items.isEmpty {
                    GeometryReader { geometry in
                        let safeArea = geometry.safeAreaInsets
                        let safeIndex = min(currentIndex, items.count - 1)
                        let current = items[safeIndex]
                        let anchorRect: CGRect? = anchors[current.id].map { geometry[$0] }
                        let visible = anchorRect.map {
                            isRectVisible($0, in: geometry.size)
                        } ?? false

                        ZStack {
                            overlayBackground(
                                anchorRect: (tipVisible && visible) ? anchorRect : nil,
                                safeAreaInsets: safeArea,
                                in: geometry
                            )
                            .onTapGesture { }

                            if tipVisible, let rect = anchorRect, visible {
                                tipPopover(
                                    for: current,
                                    anchorRect: rect,
                                    safeAreaInsets: safeArea,
                                    geometry: geometry,
                                    stepIndex: safeIndex
                                )
                                .transition(.opacity.combined(with: .scale(scale: 0.95)))
                            }

                            if isScrolling {
                                ProgressView()
                                    .progressViewStyle(
                                        CircularProgressViewStyle(tint: .white)
                                    )
                                    .scaleEffect(1.2)
                            }
                        }
                        .ignoresSafeArea()
                    }
                }
            }
            .onChange(of: isPresented) { newValue in
                if newValue {
                    currentIndex = 0
                    scrollToCurrentAnchor()
                } else {
                    tipVisible = false
                }
            }
    }

    private func scrollToCurrentAnchor() {
        guard currentIndex < items.count else { return }

        let current = items[currentIndex]
        isScrolling = true
        tipVisible = false

        if let coordinator = scrollCoordinator,
           coordinator.hasRegisteredProxies,
           let steps = current.scrollSteps,
           !steps.isEmpty
        {
            coordinator.scrollSequentially(
                targetID: current.id,
                steps: steps,
                anchor: configuration.scrollAnchor,
                animated: configuration.animateTransitions,
                interStepDelay: configuration.scrollInterStepDelay,
                proxyWaitTimeout: configuration.proxyWaitTimeout
            ) {
                Task {
                    try? await Task.sleep(
                        nanoseconds: UInt64(
                            configuration.scrollSettleDelay * 1_000_000_000
                        )
                    )
                    self.isScrolling = false
                    withAnimation(
                        configuration.animateTransitions
                            ? .easeInOut(duration: 0.25) : nil
                    ) {
                        self.tipVisible = true
                    }
                }
            }
        } else {
            Task {
                try? await Task.sleep(nanoseconds: 100_000_000)
                self.isScrolling = false
                withAnimation(
                    configuration.animateTransitions
                        ? .easeInOut(duration: 0.25) : nil
                ) {
                    self.tipVisible = true
                }
            }
        }
    }

    @ViewBuilder
    private func overlayBackground(
        anchorRect: CGRect?,
        safeAreaInsets: EdgeInsets,
        in geometry: GeometryProxy
    ) -> some View {
        let pad = configuration.spotlightPadding
        let radius = configuration.spotlightCornerRadius

        Canvas { ctx, size in
            ctx.fill(
                Path(CGRect(origin: .zero, size: size)),
                with: .color(configuration.overlayColor)
            )
            if let rect = anchorRect {
                let adj = CGRect(
                    x: rect.origin.x + safeAreaInsets.leading,
                    y: rect.origin.y + safeAreaInsets.top,
                    width: rect.width, height: rect.height
                )
                let spot = adj.insetBy(dx: -pad, dy: -pad)
                ctx.blendMode = .destinationOut
                ctx.fill(
                    Path(roundedRect: spot, cornerRadius: radius),
                    with: .color(.white)
                )
            }
        }
        .compositingGroup()
        .allowsHitTesting(true)
        .overlay {
            if let rect = anchorRect, configuration.spotlightBorderWidth > 0 {
                let adj = CGRect(
                    x: rect.origin.x + safeAreaInsets.leading,
                    y: rect.origin.y + safeAreaInsets.top,
                    width: rect.width, height: rect.height
                )
                let spot = adj.insetBy(dx: -pad, dy: -pad)
                RoundedRectangle(cornerRadius: radius)
                    .stroke(
                        configuration.spotlightBorderColor,
                        lineWidth: configuration.spotlightBorderWidth
                    )
                    .frame(width: spot.width, height: spot.height)
                    .position(x: spot.midX, y: spot.midY)
            }
        }
    }

    @ViewBuilder
    private func tipPopover(
        for item: MDSCoachmarkItem,
        anchorRect: CGRect,
        safeAreaInsets: EdgeInsets,
        geometry: GeometryProxy,
        stepIndex: Int
    ) -> some View {
        let adj = CGRect(
            x: anchorRect.origin.x + safeAreaInsets.leading,
            y: anchorRect.origin.y + safeAreaInsets.top,
            width: anchorRect.width, height: anchorRect.height
        )
        let fullH = geometry.size.height + safeAreaInsets.top + safeAreaInsets.bottom
        let fullW = geometry.size.width + safeAreaInsets.leading + safeAreaInsets.trailing
        let below = shouldShowBelow(
            anchorRect: adj, screenHeight: fullH, safeAreaInsets: safeAreaInsets
        )

        TipPositioningContainer(
            anchorRect: adj,
            showBelow: below,
            arrowSize: configuration.arrowSize,
            spotlightPadding: configuration.spotlightPadding,
            screenSize: CGSize(width: fullW, height: fullH),
            safeAreaInsets: safeAreaInsets,
            safeAreaMargin: configuration.tipSafeAreaMargin
        ) {
            VStack(spacing: 0) {
                if below {
                    arrowView(pointingUp: true)
                        .frame(
                            maxWidth: .infinity,
                            alignment: arrowAlignment(anchorRect: adj, screenWidth: fullW)
                        )
                        .padding(.horizontal, 24)
                }

                MDSCoachmarkTipContentView(
                    item: item,
                    stepIndex: stepIndex,
                    totalSteps: items.count,
                    isFirst: stepIndex == 0,
                    isLast: stepIndex == items.count - 1,
                    configuration: configuration,
                    onBack: goToPrevious,
                    onNext: goToNext,
                    onSkip: { dismiss(); onSkipped?(stepIndex) },
                    onFinish: { dismiss(); onFinished?() }
                )
                .padding(.horizontal, configuration.tipHorizontalPadding)
                .padding(.vertical, configuration.tipVerticalPadding)
                .frame(maxWidth: configuration.tipMaxWidth)
                .background(configuration.tipBackgroundColor)
                .cornerRadius(configuration.tipCornerRadius)
                .shadow(
                    color: Color.black.opacity(0.15),
                    radius: configuration.tipShadowRadius, x: 0, y: 2
                )
                .padding(.horizontal, 16)

                if !below {
                    arrowView(pointingUp: false)
                        .frame(
                            maxWidth: .infinity,
                            alignment: arrowAlignment(anchorRect: adj, screenWidth: fullW)
                        )
                        .padding(.horizontal, 24)
                }
            }
        }
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
        .id(stepIndex)
    }

    @ViewBuilder
    private func arrowView(pointingUp: Bool) -> some View {
        Triangle()
            .fill(configuration.tipBackgroundColor)
            .frame(width: configuration.arrowSize * 2, height: configuration.arrowSize)
            .rotationEffect(.degrees(pointingUp ? 0 : 180))
            .shadow(
                color: Color.black.opacity(0.08),
                radius: 2, x: 0, y: pointingUp ? -1 : 1
            )
    }

    private func shouldShowBelow(
        anchorRect: CGRect, screenHeight: CGFloat, safeAreaInsets: EdgeInsets
    ) -> Bool {
        switch configuration.arrowDirection {
        case .top:    return false
        case .bottom: return true
        case .automatic:
            let above = anchorRect.minY - configuration.spotlightPadding
                - safeAreaInsets.top
            let below = screenHeight - anchorRect.maxY
                - configuration.spotlightPadding - safeAreaInsets.bottom
            let min: CGFloat = 120
            if below >= min { return true }
            if above >= min { return false }
            return below >= above
        }
    }

    private func arrowAlignment(
        anchorRect: CGRect, screenWidth: CGFloat
    ) -> Alignment {
        let mid = anchorRect.midX
        if mid < screenWidth * 0.3 { return .leading }
        if mid > screenWidth * 0.7 { return .trailing }
        return .center
    }

    private func goToNext() {
        let next = min(currentIndex + 1, items.count - 1)
        if configuration.animateTransitions {
            withAnimation(.easeInOut(duration: 0.3)) { currentIndex = next }
        } else { currentIndex = next }
        scrollToCurrentAnchor()
    }

    private func goToPrevious() {
        let prev = max(currentIndex - 1, 0)
        if configuration.animateTransitions {
            withAnimation(.easeInOut(duration: 0.3)) { currentIndex = prev }
        } else { currentIndex = prev }
        scrollToCurrentAnchor()
    }

    private func dismiss() {
        if configuration.animateTransitions {
            withAnimation(.easeInOut(duration: 0.2)) {
                isPresented = false; tipVisible = false; currentIndex = 0
            }
        } else {
            isPresented = false; tipVisible = false; currentIndex = 0
        }
    }
}

// MARK: - Internal: Coachmark Overlay Modifier

private struct MDSCoachmarkOverlayModifier: ViewModifier {
    @Binding var isPresented: Bool
    let items: [MDSCoachmarkItem]
    let configuration: MDSCoachmarkConfiguration
    let scrollCoordinator: MDSCoachmarkScrollCoordinator?
    let onFinished: (() -> Void)?
    let onSkipped: ((Int) -> Void)?

    func body(content: Content) -> some View {
        MDSCoachmarkOverlayView(
            wrappedContent: content,
            isPresented: $isPresented,
            items: items,
            configuration: configuration,
            onFinished: onFinished,
            onSkipped: onSkipped,
            scrollCoordinator: scrollCoordinator
        )
    }
}
