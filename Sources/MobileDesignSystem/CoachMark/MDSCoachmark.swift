import SwiftUI

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

// MARK: - MDSCoachmarkArrowAlignment

/// Controls the horizontal alignment of the tooltip arrow relative to the tooltip bubble.
///
/// When set to ``auto``, the system positions the arrow based on where the spotlight
/// sits on screen — leading for left-aligned targets, trailing for right-aligned targets,
/// and centered otherwise.
///
/// Use ``leading``, ``center``, or ``trailing`` to override the automatic behavior.
/// Combine with ``MDSCoachmarkItem/arrowOffset(_:)`` for fine-grained control.
///
/// ## Example
///
/// ```swift
/// MDSCoachmarkItem(id: "avatar", title: "Profile Photo")
///     .arrowAlignment(.leading)
///     .arrowOffset(12)
/// ```
public enum MDSCoachmarkArrowAlignment: Equatable {

    /// The system chooses alignment based on the spotlight's horizontal position.
    case auto

    /// The arrow aligns to the leading edge of the tooltip.
    case leading

    /// The arrow aligns to the horizontal center of the tooltip.
    case center

    /// The arrow aligns to the trailing edge of the tooltip.
    case trailing
}

// MARK: - MDSCoachmarkItem

/// A single step in a coachmark tour, describing which view to spotlight and how to reach it.
///
/// Each item identifies its target view by `id` (which must match the value passed to
/// `.coachmarkAnchor(_:)`) and optionally defines a sequence of ``MDSCoachmarkScrollStep``
/// values that describe how to scroll the target into the visible viewport.
///
/// Per-step lifecycle callbacks can be attached using modifier-style methods:
///
/// ```swift
/// MDSCoachmarkItem(
///     id: "settings-button",
///     title: "Settings",
///     description: "Tap here to open your preferences.",
///     iconName: "gear",
///     scrollSteps: [.init(proxy: "main")]
/// )
/// .onAppear { index in print("Showing step \(index)") }
/// .onNext { index in analytics.track("coachmark_next", step: index) }
/// .onPrevious { index in analytics.track("coachmark_back", step: index) }
/// .onExit { index in analytics.track("coachmark_skip", step: index) }
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

    /// The color applied to the icon. Falls back to the design system default when `nil`.
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

    /// The horizontal alignment of the tooltip arrow. Defaults to ``MDSCoachmarkArrowAlignment/auto``.
    public private(set) var arrowAlignment: MDSCoachmarkArrowAlignment

    /// A horizontal offset in points applied to the arrow after alignment.
    /// Positive values shift toward trailing, negative toward leading. Defaults to `0`.
    public private(set) var arrowOffset: CGFloat

    /// Called when this step's tooltip becomes visible. Receives the step index.
    internal private(set) var onAppearAction: ((Int) -> Void)?

    /// Called when the user taps Next on this step. Receives the step index.
    internal private(set) var onNextAction: ((Int) -> Void)?

    /// Called when the user taps Back on this step. Receives the step index.
    internal private(set) var onPreviousAction: ((Int) -> Void)?

    /// Called when the user taps Skip/Exit on this step. Receives the step index.
    internal private(set) var onExitAction: ((Int) -> Void)?

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
        self.arrowAlignment = .auto
        self.arrowOffset = 0
    }

    // MARK: - Modifier Methods

    /// Sets the horizontal alignment of the tooltip arrow.
    ///
    /// ```swift
    /// MDSCoachmarkItem(id: "avatar", title: "Profile")
    ///     .arrowAlignment(.leading)
    /// ```
    ///
    /// - Parameter alignment: The desired arrow alignment.
    /// - Returns: A copy of this item with the updated alignment.
    public func arrowAlignment(_ alignment: MDSCoachmarkArrowAlignment) -> MDSCoachmarkItem {
        var copy = self
        copy.arrowAlignment = alignment
        return copy
    }

    /// Applies a horizontal offset to the arrow position after alignment.
    ///
    /// ```swift
    /// MDSCoachmarkItem(id: "avatar", title: "Profile")
    ///     .arrowAlignment(.leading)
    ///     .arrowOffset(12)
    /// ```
    ///
    /// - Parameter offset: The offset in points. Positive shifts toward trailing.
    /// - Returns: A copy of this item with the updated offset.
    public func arrowOffset(_ offset: CGFloat) -> MDSCoachmarkItem {
        var copy = self
        copy.arrowOffset = offset
        return copy
    }

    /// Registers a closure that fires when this step's tooltip becomes visible.
    ///
    /// ```swift
    /// MDSCoachmarkItem(id: "inbox", title: "Inbox")
    ///     .onAppear { index in
    ///         analytics.track("coachmark_shown", step: index)
    ///     }
    /// ```
    ///
    /// - Parameter action: A closure receiving the zero-based step index.
    /// - Returns: A copy of this item with the callback attached.
    public func onAppear(_ action: @escaping (_ stepIndex: Int) -> Void) -> MDSCoachmarkItem {
        var copy = self
        copy.onAppearAction = action
        return copy
    }

    /// Registers a closure that fires when the user taps Next on this step.
    ///
    /// ```swift
    /// MDSCoachmarkItem(id: "inbox", title: "Inbox")
    ///     .onNext { index in
    ///         analytics.track("coachmark_next", step: index)
    ///     }
    /// ```
    ///
    /// - Parameter action: A closure receiving the zero-based step index.
    /// - Returns: A copy of this item with the callback attached.
    public func onNext(_ action: @escaping (_ stepIndex: Int) -> Void) -> MDSCoachmarkItem {
        var copy = self
        copy.onNextAction = action
        return copy
    }

    /// Registers a closure that fires when the user taps Back on this step.
    ///
    /// ```swift
    /// MDSCoachmarkItem(id: "inbox", title: "Inbox")
    ///     .onPrevious { index in
    ///         analytics.track("coachmark_back", step: index)
    ///     }
    /// ```
    ///
    /// - Parameter action: A closure receiving the zero-based step index.
    /// - Returns: A copy of this item with the callback attached.
    public func onPrevious(_ action: @escaping (_ stepIndex: Int) -> Void) -> MDSCoachmarkItem {
        var copy = self
        copy.onPreviousAction = action
        return copy
    }

    /// Registers a closure that fires when the user taps Skip on this step.
    ///
    /// This fires **before** the tour-level `onSkipped` closure passed to `.coachmarkOverlay`.
    ///
    /// ```swift
    /// MDSCoachmarkItem(id: "inbox", title: "Inbox")
    ///     .onExit { index in
    ///         analytics.track("coachmark_skipped", step: index)
    ///     }
    /// ```
    ///
    /// - Parameter action: A closure receiving the zero-based step index.
    /// - Returns: A copy of this item with the callback attached.
    public func onExit(_ action: @escaping (_ stepIndex: Int) -> Void) -> MDSCoachmarkItem {
        var copy = self
        copy.onExitAction = action
        return copy
    }

    /// Equatable conformance compares identity and display properties only.
    /// Callback closures are excluded from equality checks.
    public static func == (lhs: MDSCoachmarkItem, rhs: MDSCoachmarkItem) -> Bool {
        lhs.id == rhs.id &&
        lhs.title == rhs.title &&
        lhs.description == rhs.description &&
        lhs.iconName == rhs.iconName &&
        lhs.scrollSteps == rhs.scrollSteps &&
        lhs.arrowAlignment == rhs.arrowAlignment &&
        lhs.arrowOffset == rhs.arrowOffset
    }
}

// MARK: - MDSCoachmarkArrowDirection

/// Controls vertical placement of the tooltip relative to the spotlight.
internal enum MDSCoachmarkArrowDirection {
    case top, bottom, automatic
}

// MARK: - MDSCoachmarkTipLayoutStyle

/// Controls how the icon and text are arranged inside the tooltip.
internal enum MDSCoachmarkTipLayoutStyle {
    case horizontal, vertical, textOnly
}

// MARK: - MDSCoachmarkConstants

/// Design system constants for the coachmark overlay.
internal enum MDSCoachmarkConstants {

    // MARK: Navigation Buttons

    static let exitButtonLabel = "Skip"
    static let nextButtonLabel = "Next"
    static let finishButtonLabel = "Done"
    static let backButtonLabel = "Back"
    static let showBackButton = true

    // MARK: Overlay

    static let overlayColor = Color.black.opacity(0.75)

    // MARK: Tooltip Appearance

    static let tipBackgroundColor = Color.white
    static let tipShadowRadius: CGFloat = 8
    static let tipHorizontalPadding: CGFloat = 16
    static let tipVerticalPadding: CGFloat = 12
    static let tipMaxWidth: CGFloat? = nil
    static let tipLayoutStyle: MDSCoachmarkTipLayoutStyle = .horizontal

    // MARK: Typography

    static let titleFont: Font = .headline
    static let titleColor = Color(UIColor.darkText)
    static let descriptionFont: Font = .subheadline
    static let descriptionColor = Color(UIColor.darkGray)
    static let stepIndicatorFont: Font = .caption
    static let stepIndicatorColor = Color(UIColor.darkGray)

    // MARK: Icon

    static let defaultIconSize: CGFloat = 24
    static let defaultIconColor = Color.blue

    // MARK: Accent

    static let accentColor = Color.blue

    // MARK: Spotlight

    static let spotlightBorderColor = Color.white
    static let spotlightBorderWidth: CGFloat = 2
    static let spotlightCornerRadius: CGFloat = 8
    static let spotlightPadding: CGFloat = 4

    // MARK: Arrow

    static let arrowDirection: MDSCoachmarkArrowDirection = .automatic
    static let arrowSize: CGFloat = 8
    static let arrowHorizontalPadding: CGFloat = 24

    // MARK: Animation & Scrolling

    static let animateTransitions = true
    static let scrollAnchor: UnitPoint = .center

    // MARK: Safe Area

    static let tipSafeAreaMargin: CGFloat = 8

    // MARK: Failsafe

    static let visibilityCheckDelay: TimeInterval = 0.5
    static let visibilityThreshold: CGFloat = 0.3
}

// MARK: - MDSCoachmarkConfiguration

/// Behavioral settings for the coachmark overlay.
///
/// Visual properties are controlled by the design system for consistency.
/// Only essential customization options are exposed.
///
/// ```swift
/// let config = MDSCoachmarkConfiguration(
///     showExitButton: false,
///     tipCornerRadius: 16,
///     dismissOnOverlayTap: true,
///     dismissWhenOffscreen: true
/// )
/// ```
public struct MDSCoachmarkConfiguration {

    /// Whether a skip/exit button is shown on non-final steps. Defaults to `true`.
    public var showExitButton: Bool

    /// Corner radius of the tooltip bubble. Defaults to `12`.
    public var tipCornerRadius: CGFloat

    /// Whether tapping the dimmed overlay area outside the tooltip dismisses
    /// the coachmark tour. Defaults to `false`.
    public var dismissOnOverlayTap: Bool

    /// Whether the coachmark tour automatically dismisses when the current step's
    /// target anchor is offscreen and cannot be scrolled into view. When `false`,
    /// the overlay remains visible and waits for the user to interact with
    /// navigation controls. Defaults to `false`.
    public var dismissWhenOffscreen: Bool

    /// Seconds to wait after all scroll steps complete before showing the tooltip.
    /// Allows the scroll animation to fully settle. Defaults to `0.4`.
    public var scrollSettleDelay: TimeInterval

    /// Seconds to wait between consecutive scroll steps in a multi-level chain.
    /// Allows each scroll animation to complete before the next fires. Defaults to `0.35`.
    public var scrollInterStepDelay: TimeInterval

    /// Maximum seconds to wait for a lazily registered scroll proxy before skipping the step.
    /// Increase this value for very complex lazy layouts. Defaults to `3.0`.
    public var proxyWaitTimeout: TimeInterval

    /// Creates a configuration with the given overrides.
    ///
    /// All parameters have default values. Pass only the properties you want to customize.
    ///
    /// - Parameters:
    ///   - showExitButton: Whether to show the skip/exit button on non-final steps.
    ///   - tipCornerRadius: Corner radius of the tooltip bubble.
    ///   - dismissOnOverlayTap: Whether tapping outside the tooltip dismisses the tour.
    ///   - dismissWhenOffscreen: Whether to auto-dismiss when the target is offscreen.
    ///   - scrollSettleDelay: Post-scroll delay before showing the tooltip.
    ///   - scrollInterStepDelay: Delay between consecutive scroll steps.
    ///   - proxyWaitTimeout: Maximum wait time for lazy proxy registration.
    public init(
        showExitButton: Bool = true,
        tipCornerRadius: CGFloat = 12,
        dismissOnOverlayTap: Bool = true,
        dismissWhenOffscreen: Bool = true,
        scrollSettleDelay: TimeInterval = 0.4,
        scrollInterStepDelay: TimeInterval = 0.35,
        proxyWaitTimeout: TimeInterval = 3.0
    ) {
        self.showExitButton = showExitButton
        self.tipCornerRadius = tipCornerRadius
        self.dismissOnOverlayTap = dismissOnOverlayTap
        self.dismissWhenOffscreen = dismissWhenOffscreen
        self.scrollSettleDelay = scrollSettleDelay
        self.scrollInterStepDelay = scrollInterStepDelay
        self.proxyWaitTimeout = proxyWaitTimeout
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


// MARK: - Internal: Visibility Check

private func isRectVisible(
    _ rect: CGRect,
    in containerSize: CGSize,
    threshold: CGFloat = 0.5
) -> Bool {
    let visible = CGRect(origin: .zero, size: containerSize)
    let intersection = rect.intersection(visible)
    guard !intersection.isNull else { return false }
    let portion = (intersection.width * intersection.height)
        / max(rect.width * rect.height, 1)
    return portion >= threshold
}

private func isRectFullyOffscreen(_ rect: CGRect, in containerSize: CGSize) -> Bool {
    let visible = CGRect(origin: .zero, size: containerSize)
    return !rect.intersects(visible)
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

// MARK: - Internal: Arrow Positioning View

private struct ArrowPositioningView: View {
    let pointingUp: Bool
    let alignment: MDSCoachmarkArrowAlignment
    let offset: CGFloat
    let anchorRect: CGRect
    let screenWidth: CGFloat

    var body: some View {
        GeometryReader { geometry in
            Triangle()
                .fill(MDSCoachmarkConstants.tipBackgroundColor)
                .frame(
                    width: MDSCoachmarkConstants.arrowSize * 2,
                    height: MDSCoachmarkConstants.arrowSize
                )
                .rotationEffect(.degrees(pointingUp ? 0 : 180))
                .shadow(
                    color: Color.black.opacity(0.08),
                    radius: 2, x: 0, y: pointingUp ? -1 : 1
                )
                .position(
                    x: arrowXPosition(in: geometry.size.width),
                    y: MDSCoachmarkConstants.arrowSize / 2
                )
        }
        .frame(height: MDSCoachmarkConstants.arrowSize)
        .padding(.horizontal, 16)
    }

    private func arrowXPosition(in containerWidth: CGFloat) -> CGFloat {
        let resolved = resolveAlignment()
        let base: CGFloat

        switch resolved {
        case .leading:
            base = MDSCoachmarkConstants.arrowHorizontalPadding
        case .trailing:
            base = containerWidth - MDSCoachmarkConstants.arrowHorizontalPadding
        case .center, .auto:
            base = containerWidth / 2
        }

        return base + offset
    }

    private func resolveAlignment() -> MDSCoachmarkArrowAlignment {
        guard alignment == .auto else { return alignment }
        let mid = anchorRect.midX
        if mid < screenWidth * 0.3 { return .leading }
        if mid > screenWidth * 0.7 { return .trailing }
        return .center
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
    let tipCornerRadius: CGFloat
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
        tipCornerRadius: CGFloat,
        @ViewBuilder content: () -> Content
    ) {
        self.anchorRect = anchorRect
        self.showBelow = showBelow
        self.arrowSize = arrowSize
        self.spotlightPadding = spotlightPadding
        self.screenSize = screenSize
        self.safeAreaInsets = safeAreaInsets
        self.safeAreaMargin = safeAreaMargin
        self.tipCornerRadius = tipCornerRadius
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
    @State private var visibilityCheckTask: Task<Void, Never>?

    var body: some View {
        wrappedContent
            .overlayPreferenceValue(MDSCoachmarkAnchorPreferenceKey.self) { anchors in
                if isPresented, !items.isEmpty {
                    GeometryReader { geometry in
                        let safeArea = geometry.safeAreaInsets
                        let safeIndex = min(currentIndex, items.count - 1)
                        let current = items[safeIndex]
                        let anchorRect: CGRect? = anchors[current.id].map {
                            geometry[$0]
                        }
                        let visible = anchorRect.map {
                            isRectVisible(
                                $0,
                                in: geometry.size,
                                threshold: MDSCoachmarkConstants.visibilityThreshold
                            )
                        } ?? false

                        ZStack {
                            overlayBackground(
                                anchorRect: (tipVisible && visible) ? anchorRect : nil,
                                safeAreaInsets: safeArea,
                                in: geometry
                            )
                            .onTapGesture {
                                if configuration.dismissOnOverlayTap {
                                    handleOverlayTap(at: safeIndex)
                                }
                            }

                            if tipVisible, let rect = anchorRect, visible {
                                tipPopover(
                                    for: current,
                                    anchorRect: rect,
                                    safeAreaInsets: safeArea,
                                    geometry: geometry,
                                    stepIndex: safeIndex
                                )
                                .transition(
                                    .opacity.combined(with: .scale(scale: 0.95))
                                )
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
                        .onChange(of: tipVisible) { newValue in
                            if newValue && configuration.dismissWhenOffscreen {
                                scheduleVisibilityCheck(
                                    anchorRect: anchorRect,
                                    containerSize: geometry.size,
                                    stepIndex: safeIndex
                                )
                            }
                        }
                    }
                }
            }
            .onChange(of: isPresented) { newValue in
                if newValue {
                    currentIndex = 0
                    scrollToCurrentAnchor()
                } else {
                    cancelVisibilityCheck()
                    tipVisible = false
                }
            }
    }

    // MARK: Visibility Failsafe

    private func scheduleVisibilityCheck(
        anchorRect: CGRect?,
        containerSize: CGSize,
        stepIndex: Int
    ) {
        cancelVisibilityCheck()

        visibilityCheckTask = Task {
            try? await Task.sleep(
                nanoseconds: UInt64(
                    MDSCoachmarkConstants.visibilityCheckDelay * 1_000_000_000
                )
            )

            guard !Task.isCancelled else { return }

            let shouldDismiss: Bool

            if let rect = anchorRect {
                shouldDismiss = isRectFullyOffscreen(rect, in: containerSize)
            } else {
                shouldDismiss = true
            }

            if shouldDismiss {
                await MainActor.run {
                    dismissDueToFailsafe(stepIndex: stepIndex)
                }
            }
        }
    }

    private func cancelVisibilityCheck() {
        visibilityCheckTask?.cancel()
        visibilityCheckTask = nil
    }

    private func dismissDueToFailsafe(stepIndex: Int) {
        guard stepIndex < items.count else { return }
        items[stepIndex].onExitAction?(stepIndex)
        dismiss()
        onSkipped?(stepIndex)
    }

    // MARK: Overlay Tap

    private func handleOverlayTap(at stepIndex: Int) {
        guard stepIndex < items.count else { return }
        items[stepIndex].onExitAction?(stepIndex)
        dismiss()
        onSkipped?(stepIndex)
    }

    // MARK: Scrolling

    private func scrollToCurrentAnchor() {
        guard currentIndex < items.count else { return }

        cancelVisibilityCheck()

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
                anchor: MDSCoachmarkConstants.scrollAnchor,
                animated: MDSCoachmarkConstants.animateTransitions,
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
                        MDSCoachmarkConstants.animateTransitions
                            ? .easeInOut(duration: 0.25) : nil
                    ) {
                        self.tipVisible = true
                    }
                    self.notifyAppear()
                }
            }
        } else {
            Task {
                try? await Task.sleep(nanoseconds: 100_000_000)
                self.isScrolling = false
                withAnimation(
                    MDSCoachmarkConstants.animateTransitions
                        ? .easeInOut(duration: 0.25) : nil
                ) {
                    self.tipVisible = true
                }
                self.notifyAppear()
            }
        }
    }

    // MARK: Callbacks

    private func notifyAppear() {
        guard currentIndex < items.count else { return }
        items[currentIndex].onAppearAction?(currentIndex)
    }

    // MARK: Overlay Background

    @ViewBuilder
    private func overlayBackground(
        anchorRect: CGRect?,
        safeAreaInsets: EdgeInsets,
        in geometry: GeometryProxy
    ) -> some View {
        let pad = MDSCoachmarkConstants.spotlightPadding
        let radius = MDSCoachmarkConstants.spotlightCornerRadius

        Canvas { ctx, size in
            ctx.fill(
                Path(CGRect(origin: .zero, size: size)),
                with: .color(MDSCoachmarkConstants.overlayColor)
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
            if let rect = anchorRect, MDSCoachmarkConstants.spotlightBorderWidth > 0 {
                let adj = CGRect(
                    x: rect.origin.x + safeAreaInsets.leading,
                    y: rect.origin.y + safeAreaInsets.top,
                    width: rect.width, height: rect.height
                )
                let spot = adj.insetBy(dx: -pad, dy: -pad)
                RoundedRectangle(cornerRadius: radius)
                    .stroke(
                        MDSCoachmarkConstants.spotlightBorderColor,
                        lineWidth: MDSCoachmarkConstants.spotlightBorderWidth
                    )
                    .frame(width: spot.width, height: spot.height)
                    .position(x: spot.midX, y: spot.midY)
            }
        }
    }

    // MARK: Tip Popover

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
        let fullH = geometry.size.height + safeAreaInsets.top
            + safeAreaInsets.bottom
        let fullW = geometry.size.width + safeAreaInsets.leading
            + safeAreaInsets.trailing
        let below = shouldShowBelow(
            anchorRect: adj,
            screenHeight: fullH,
            safeAreaInsets: safeAreaInsets
        )

        TipPositioningContainer(
            anchorRect: adj,
            showBelow: below,
            arrowSize: MDSCoachmarkConstants.arrowSize,
            spotlightPadding: MDSCoachmarkConstants.spotlightPadding,
            screenSize: CGSize(width: fullW, height: fullH),
            safeAreaInsets: safeAreaInsets,
            safeAreaMargin: MDSCoachmarkConstants.tipSafeAreaMargin,
            tipCornerRadius: configuration.tipCornerRadius
        ) {
            VStack(spacing: 0) {
                if below {
                    ArrowPositioningView(
                        pointingUp: true,
                        alignment: item.arrowAlignment,
                        offset: item.arrowOffset,
                        anchorRect: adj,
                        screenWidth: fullW
                    )
                }

                MDSCoachmarkTipContentView(
                    item: item,
                    stepIndex: stepIndex,
                    totalSteps: items.count,
                    isFirst: stepIndex == 0,
                    isLast: stepIndex == items.count - 1,
                    configuration: configuration,
                    onBack: { goToPrevious() },
                    onNext: { goToNext() },
                    onSkip: { handleSkip(at: stepIndex) },
                    onFinish: { handleFinish() }
                )
                .padding(.horizontal, MDSCoachmarkConstants.tipHorizontalPadding)
                .padding(.vertical, MDSCoachmarkConstants.tipVerticalPadding)
                .frame(maxWidth: MDSCoachmarkConstants.tipMaxWidth)
                .background(MDSCoachmarkConstants.tipBackgroundColor)
                .cornerRadius(configuration.tipCornerRadius)
                .shadow(
                    color: Color.black.opacity(0.15),
                    radius: MDSCoachmarkConstants.tipShadowRadius, x: 0, y: 2
                )
                .padding(.horizontal, 16)

                if !below {
                    ArrowPositioningView(
                        pointingUp: false,
                        alignment: item.arrowAlignment,
                        offset: item.arrowOffset,
                        anchorRect: adj,
                        screenWidth: fullW
                    )
                }
            }
        }
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
        .id(stepIndex)
    }

    // MARK: Arrow Direction

    private func shouldShowBelow(
        anchorRect: CGRect,
        screenHeight: CGFloat,
        safeAreaInsets: EdgeInsets
    ) -> Bool {
        switch MDSCoachmarkConstants.arrowDirection {
        case .top:    return false
        case .bottom: return true
        case .automatic:
            let above = anchorRect.minY - MDSCoachmarkConstants.spotlightPadding
                - safeAreaInsets.top
            let below = screenHeight - anchorRect.maxY
                - MDSCoachmarkConstants.spotlightPadding - safeAreaInsets.bottom
            let min: CGFloat = 120
            if below >= min { return true }
            if above >= min { return false }
            return below >= above
        }
    }

    // MARK: Navigation

    private func goToNext() {
        let index = currentIndex
        guard index < items.count else { return }
        items[index].onNextAction?(index)

        let next = min(index + 1, items.count - 1)
        if MDSCoachmarkConstants.animateTransitions {
            withAnimation(.easeInOut(duration: 0.3)) { currentIndex = next }
        } else {
            currentIndex = next
        }
        scrollToCurrentAnchor()
    }

    private func goToPrevious() {
        let index = currentIndex
        guard index < items.count else { return }
        items[index].onPreviousAction?(index)

        let prev = max(index - 1, 0)
        if MDSCoachmarkConstants.animateTransitions {
            withAnimation(.easeInOut(duration: 0.3)) { currentIndex = prev }
        } else {
            currentIndex = prev
        }
        scrollToCurrentAnchor()
    }

    private func handleSkip(at stepIndex: Int) {
        guard stepIndex < items.count else { return }
        items[stepIndex].onExitAction?(stepIndex)
        dismiss()
        onSkipped?(stepIndex)
    }

    private func handleFinish() {
        dismiss()
        onFinished?()
    }

    private func dismiss() {
        cancelVisibilityCheck()

        if MDSCoachmarkConstants.animateTransitions {
            withAnimation(.easeInOut(duration: 0.2)) {
                isPresented = false
                tipVisible = false
                currentIndex = 0
            }
        } else {
            isPresented = false
            tipVisible = false
            currentIndex = 0
        }
    }
}

// MARK: - Internal: Coachmark Overlay Modifier

struct MDSCoachmarkOverlayModifier: ViewModifier {
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
