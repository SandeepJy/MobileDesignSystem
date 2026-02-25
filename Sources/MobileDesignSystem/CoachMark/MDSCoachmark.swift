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
///     overlayColor: Color.black.opacity(0.6),
///     spotlightBorderColor: .green,
///     tooltipBorderColor: .green,
///     showExitButton: false,
///     tipCornerRadius: 16,
///     dismissOnOverlayTap: true,
///     dismissWhenOffscreen: true,
///     isBlocking: false
/// )
/// ```
public struct MDSCoachmarkConfiguration {

    /// The color of the full-screen dim layer rendered behind the spotlight cutout.
    ///
    /// Adjust the opacity as well as the hue to match your app's visual style.
    ///
    /// ```swift
    /// MDSCoachmarkConfiguration(overlayColor: Color.indigo.opacity(0.7))
    /// ```
    ///
    /// Defaults to `Color.black.opacity(0.75)`.
    public var overlayColor: Color

    /// The color of the border drawn around the spotlight cutout.
    ///
    /// The border sits on top of the rounded-rectangle cutout that reveals the
    /// anchored view through the dim overlay. Set ``spotlightBorderWidth`` to `0`
    /// to suppress the border entirely.
    ///
    /// Defaults to `.green`.
    public var spotlightBorderColor: Color

    /// The stroke width of the border drawn around the spotlight cutout.
    ///
    /// Set to `0` to suppress the spotlight border. Defaults to `2`.
    public var spotlightBorderWidth: CGFloat

    /// The color of the border drawn around the tooltip bubble, including the arrow.
    ///
    /// The border traces the outer edge of the combined rounded-rectangle + arrow
    /// shape. The segment at the base of the arrow (where it meets the rectangle)
    /// is intentionally excluded so the interior connection appears seamless.
    /// Set ``tooltipBorderWidth`` to `0` to suppress the border entirely.
    ///
    /// Defaults to `.green`.
    public var tooltipBorderColor: Color

    /// The stroke width of the border drawn around the tooltip bubble.
    ///
    /// Set to `0` to suppress the tooltip border. Defaults to `2`.
    public var tooltipBorderWidth: CGFloat

    /// Whether a skip/exit button is shown on non-final steps. Defaults to `true`.
    public var showExitButton: Bool

    /// Corner radius of the tooltip bubble. Defaults to `12`.
    public var tipCornerRadius: CGFloat

    /// Whether tapping the dimmed overlay area outside the tooltip dismisses
    /// the coachmark tour. Defaults to `false`.
    ///
    /// - Note: Has no effect when ``isBlocking`` is `false`, because touches on the
    ///   overlay pass through to the content below rather than being captured.
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

    /// Whether the coachmark overlay blocks user interaction with the underlying content.
    ///
    /// When `true` (default), the dimmed overlay captures all touches and prevents the user
    /// from scrolling or interacting with content beneath it. Only the coachmark tooltip
    /// controls (Next, Back, Skip/Finish) remain interactive.
    ///
    /// When `false`, the overlay is **non-blocking**: touches pass through the dimmed
    /// background directly to the underlying content, allowing the user to scroll, tap,
    /// and interact freely while the coachmark tour is active. The tooltip itself remains
    /// fully interactive in both modes.
    ///
    /// ```swift
    /// // Allow users to scroll the list while the tour is running
    /// let config = MDSCoachmarkConfiguration(isBlocking: false)
    /// ```
    ///
    /// - Note: When `false`, ``dismissOnOverlayTap`` has no effect because overlay
    ///   touches are not captured — they pass through to the content below.
    ///
    /// Defaults to `true`.
    public var isBlocking: Bool

    /// Creates a configuration with the given overrides.
    ///
    /// All parameters have default values. Pass only the properties you want to customize.
    ///
    /// - Parameters:
    ///   - overlayColor: The color of the full-screen dim layer. Defaults to
    ///     `Color.black.opacity(0.75)`.
    ///   - spotlightBorderColor: Border color drawn around the spotlight cutout.
    ///     Defaults to `.green`.
    ///   - spotlightBorderWidth: Stroke width of the spotlight border. Pass `0` to hide.
    ///     Defaults to `2`.
    ///   - tooltipBorderColor: Border color drawn around the tooltip bubble and arrow.
    ///     Defaults to `.green`.
    ///   - tooltipBorderWidth: Stroke width of the tooltip border. Pass `0` to hide.
    ///     Defaults to `2`.
    ///   - showExitButton: Whether to show the skip/exit button on non-final steps.
    ///   - tipCornerRadius: Corner radius of the tooltip bubble.
    ///   - dismissOnOverlayTap: Whether tapping outside the tooltip dismisses the tour.
    ///     Has no effect when `isBlocking` is `false`.
    ///   - dismissWhenOffscreen: Whether to auto-dismiss when the target is offscreen.
    ///   - scrollSettleDelay: Post-scroll delay before showing the tooltip.
    ///   - scrollInterStepDelay: Delay between consecutive scroll steps.
    ///   - proxyWaitTimeout: Maximum wait time for lazy proxy registration.
    ///   - isBlocking: Whether the overlay blocks user interaction with underlying content.
    ///     Pass `false` to allow scrolling and tapping through the overlay.
    public init(
        overlayColor: Color = Color.clear,
        spotlightBorderColor: Color = .green,
        spotlightBorderWidth: CGFloat = 1,
        tooltipBorderColor: Color = .green,
        tooltipBorderWidth: CGFloat = 1,
        showExitButton: Bool = true,
        tipCornerRadius: CGFloat = 12,
        dismissOnOverlayTap: Bool = true,
        dismissWhenOffscreen: Bool = true,
        scrollSettleDelay: TimeInterval = 0.4,
        scrollInterStepDelay: TimeInterval = 0.35,
        proxyWaitTimeout: TimeInterval = 3.0,
        isBlocking: Bool = false
    ) {
        self.overlayColor = overlayColor
        self.spotlightBorderColor = spotlightBorderColor
        self.spotlightBorderWidth = spotlightBorderWidth
        self.tooltipBorderColor = tooltipBorderColor
        self.tooltipBorderWidth = tooltipBorderWidth
        self.showExitButton = showExitButton
        self.tipCornerRadius = tipCornerRadius
        self.dismissOnOverlayTap = dismissOnOverlayTap
        self.dismissWhenOffscreen = dismissWhenOffscreen
        self.scrollSettleDelay = scrollSettleDelay
        self.scrollInterStepDelay = scrollInterStepDelay
        self.proxyWaitTimeout = proxyWaitTimeout
        self.isBlocking = isBlocking
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

// MARK: - Internal: Tooltip Bubble Shape

private struct TooltipBubbleShape: Shape {

    /// When `true`, the arrow points upward (tooltip is shown below the spotlight).
    /// When `false`, the arrow points downward (tooltip is shown above the spotlight).
    let arrowPointingUp: Bool

    /// The horizontal centre of the arrow in the shape's local coordinate space.
    let arrowMidX: CGFloat

    /// The full base width of the triangular arrow.
    let arrowWidth: CGFloat

    /// The perpendicular height of the triangular arrow from base to tip.
    let arrowHeight: CGFloat

    /// The corner radius applied to each corner of the rectangular body.
    let cornerRadius: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()

        // Clamp the corner radius so it never exceeds the available box dimensions.
        let boxHeight = rect.height - arrowHeight
        let r = min(cornerRadius, boxHeight / 2, rect.width / 2)

        // Clamp the arrow centre so both base corners remain inside the rounded insets.
        let halfArrow = arrowWidth / 2
        let clampedMid = max(
            rect.minX + r + halfArrow,
            min(arrowMidX, rect.maxX - r - halfArrow)
        )
        let aLeft  = clampedMid - halfArrow
        let aRight = clampedMid + halfArrow

        if arrowPointingUp {
            // ┌ Layout (arrow on top) ──────────────────────────────────────┐
            // │        tip                                                  │
            // │       /   \                                                 │
            // │ aLeft       aRight                                          │
            // │ ╭───────────────────────────────────────────────────────╮  │
            // │ │               rectangular body                        │  │
            // │ ╰───────────────────────────────────────────────────────╯  │
            // └─────────────────────────────────────────────────────────────┘

            let boxTop    = rect.minY + arrowHeight
            let boxBottom = rect.maxY

            // Start at the arrow's left base (top-left of the rectangle face).
            path.move(to: CGPoint(x: aLeft, y: boxTop))
            // Rise to the arrow tip.
            path.addLine(to: CGPoint(x: clampedMid, y: rect.minY))
            // Descend to the arrow's right base.
            path.addLine(to: CGPoint(x: aRight, y: boxTop))
            // Continue right along the top face to the top-right corner tangent.
            path.addLine(to: CGPoint(x: rect.maxX - r, y: boxTop))
            // Top-right corner arc (−90° → 0°).
            path.addArc(
                center: CGPoint(x: rect.maxX - r, y: boxTop + r),
                radius: r,
                startAngle: .degrees(-90), endAngle: .degrees(0),
                clockwise: false
            )
            // Right face downward.
            path.addLine(to: CGPoint(x: rect.maxX, y: boxBottom - r))
            // Bottom-right corner arc (0° → 90°).
            path.addArc(
                center: CGPoint(x: rect.maxX - r, y: boxBottom - r),
                radius: r,
                startAngle: .degrees(0), endAngle: .degrees(90),
                clockwise: false
            )
            // Bottom face leftward.
            path.addLine(to: CGPoint(x: rect.minX + r, y: boxBottom))
            // Bottom-left corner arc (90° → 180°).
            path.addArc(
                center: CGPoint(x: rect.minX + r, y: boxBottom - r),
                radius: r,
                startAngle: .degrees(90), endAngle: .degrees(180),
                clockwise: false
            )
            // Left face upward.
            path.addLine(to: CGPoint(x: rect.minX, y: boxTop + r))
            // Top-left corner arc (180° → 270°).
            path.addArc(
                center: CGPoint(x: rect.minX + r, y: boxTop + r),
                radius: r,
                startAngle: .degrees(180), endAngle: .degrees(270),
                clockwise: false
            )
            // Top face rightward back to the arrow's left base (closes without drawing
            // the base segment between aLeft and aRight — that gap is intentional).
            path.addLine(to: CGPoint(x: aLeft, y: boxTop))
            path.closeSubpath()

        } else {
            // ┌ Layout (arrow on bottom) ────────────────────────────────────┐
            // │ ╭───────────────────────────────────────────────────────╮   │
            // │ │               rectangular body                        │   │
            // │ ╰───────────────────────────────────────────────────────╯   │
            // │ aLeft                       aRight                          │
            // │       \                   /                                  │
            // │              tip                                             │
            // └──────────────────────────────────────────────────────────────┘

            let boxTop    = rect.minY
            let boxBottom = rect.maxY - arrowHeight

            // Start at the top-left corner tangent.
            path.move(to: CGPoint(x: rect.minX + r, y: boxTop))
            // Top face rightward.
            path.addLine(to: CGPoint(x: rect.maxX - r, y: boxTop))
            // Top-right corner arc (−90° → 0°).
            path.addArc(
                center: CGPoint(x: rect.maxX - r, y: boxTop + r),
                radius: r,
                startAngle: .degrees(-90), endAngle: .degrees(0),
                clockwise: false
            )
            // Right face downward.
            path.addLine(to: CGPoint(x: rect.maxX, y: boxBottom - r))
            // Bottom-right corner arc (0° → 90°).
            path.addArc(
                center: CGPoint(x: rect.maxX - r, y: boxBottom - r),
                radius: r,
                startAngle: .degrees(0), endAngle: .degrees(90),
                clockwise: false
            )
            // Bottom face leftward to the arrow's right base.
            path.addLine(to: CGPoint(x: aRight, y: boxBottom))
            // Descend to the arrow tip.
            path.addLine(to: CGPoint(x: clampedMid, y: rect.maxY))
            // Rise to the arrow's left base.
            path.addLine(to: CGPoint(x: aLeft, y: boxBottom))
            // Continue left along the bottom face to the bottom-left corner tangent
            // (the segment aRight → aLeft is not drawn here — we jump from aLeft
            // directly, so the arrow base remains open).
            path.addLine(to: CGPoint(x: rect.minX + r, y: boxBottom))
            // Bottom-left corner arc (90° → 180°).
            path.addArc(
                center: CGPoint(x: rect.minX + r, y: boxBottom - r),
                radius: r,
                startAngle: .degrees(90), endAngle: .degrees(180),
                clockwise: false
            )
            // Left face upward.
            path.addLine(to: CGPoint(x: rect.minX, y: boxTop + r))
            // Top-left corner arc (180° → 270°).
            path.addArc(
                center: CGPoint(x: rect.minX + r, y: boxTop + r),
                radius: r,
                startAngle: .degrees(180), endAngle: .degrees(270),
                clockwise: false
            )
            path.closeSubpath()
        }

        return path
    }
}

// MARK: - Internal: Tip Positioning Container

/// Positions the tooltip bubble vertically relative to the spotlight anchor.
///
/// The container measures the height of its content (which already includes the
/// `arrowHeight` worth of top or bottom padding added in `tipPopover`) and places
/// the bubble's centre so that:
///
/// - **Below the spotlight**: the top edge of the bubble (arrow tip) sits at
///   `anchorRect.maxY + spotlightPadding + gap`.
/// - **Above the spotlight**: the bottom edge of the bubble (arrow tip) sits at
///   `anchorRect.minY − spotlightPadding − gap`.
///
/// The result is then clamped to keep the bubble within the safe-area bounds.
private struct TipPositioningContainer<Content: View>: View {
    let anchorRect: CGRect
    let showBelow: Bool
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
        spotlightPadding: CGFloat,
        screenSize: CGSize,
        safeAreaInsets: EdgeInsets,
        safeAreaMargin: CGFloat = 8,
        tipCornerRadius: CGFloat,
        @ViewBuilder content: () -> Content
    ) {
        self.anchorRect = anchorRect
        self.showBelow = showBelow
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

    /// A small visual gap between the spotlight border and the arrow tip.
    private var gap: CGFloat { 4 }

    /// Computes the vertical centre of the tooltip bubble in screen coordinates.
    ///
    /// `tipSize.height` already includes the `arrowHeight` padding added by `tipPopover`,
    /// so no separate arrow offset is required here.
    private var computedY: CGFloat {
        if showBelow {
            // Top of the bubble aligns with the bottom of the spotlight + padding + gap.
            let top = anchorRect.maxY + spotlightPadding + gap
            let y = top + tipSize.height / 2
            let maxY = screenSize.height - safeAreaInsets.bottom
                - tipSize.height / 2 - safeAreaMargin
            return min(y, maxY)
        } else {
            // Bottom of the bubble aligns with the top of the spotlight − padding − gap.
            let bottom = anchorRect.minY - spotlightPadding - gap
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
                            // The dim + spotlight canvas. In non-blocking mode, hit-testing
                            // is disabled so touches fall through to the content below.
                            overlayBackground(
                                anchorRect: (tipVisible && visible) ? anchorRect : nil,
                                safeAreaInsets: safeArea,
                                in: geometry
                            )
                            .onTapGesture {
                                // Guard is redundant when isBlocking == false (allowsHitTesting
                                // prevents this gesture from firing), but kept for clarity.
                                guard configuration.isBlocking,
                                      configuration.dismissOnOverlayTap else { return }
                                handleOverlayTap(at: safeIndex)
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
                                    // In non-blocking mode the spinner should not trap touches.
                                    .allowsHitTesting(configuration.isBlocking)
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

    /// Builds the full-screen dim layer with an optional spotlight cutout.
    ///
    /// The overlay colour comes from ``MDSCoachmarkConfiguration/overlayColor``.
    /// The spotlight border colour and width come from
    /// ``MDSCoachmarkConfiguration/spotlightBorderColor`` and
    /// ``MDSCoachmarkConfiguration/spotlightBorderWidth``.
    ///
    /// Hit-testing on the `Canvas` is controlled by ``MDSCoachmarkConfiguration/isBlocking``:
    /// - `true`  → the canvas captures touches (blocking mode).
    /// - `false` → the canvas ignores touches, passing them through to the content below
    ///             so the user can scroll or interact freely (non-blocking mode).
    @ViewBuilder
    private func overlayBackground(
        anchorRect: CGRect?,
        safeAreaInsets: EdgeInsets,
        in geometry: GeometryProxy
    ) -> some View {
        let pad    = MDSCoachmarkConstants.spotlightPadding
        let radius = MDSCoachmarkConstants.spotlightCornerRadius

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
        // When non-blocking, disable hit-testing on the dim layer so touches reach
        // the underlying content (e.g. scroll views, buttons). The tooltip, which is
        // rendered in a separate ZStack layer above this canvas, is unaffected and
        // remains fully interactive in both modes.
        .allowsHitTesting(configuration.isBlocking)
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
                    // The border ring follows the same hit-testing rule as the canvas.
                    .allowsHitTesting(configuration.isBlocking)
            }
        }
    }

    // MARK: Tip Popover

    /// Builds the positioned tooltip bubble for the current coachmark step.
    ///
    /// The tooltip is rendered as a single ``TooltipBubbleShape`` that combines the
    /// rounded-rectangle body and the directional arrow into one continuous path.
    /// This allows a stroke border (``MDSCoachmarkConfiguration/tooltipBorderColor``)
    /// to trace the full perimeter — including the arrow sides — while deliberately
    /// leaving the base of the arrow open where it meets the rectangle body, giving
    /// the appearance of a seamless connection.
    ///
    /// The arrow height is injected as top or bottom padding on the content view so
    /// that `TipPositioningContainer` sees the correct total height when measuring
    /// the bubble for vertical placement.
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
        let fullW = geometry.size.width  + safeAreaInsets.leading + safeAreaInsets.trailing
        let below = shouldShowBelow(
            anchorRect: adj,
            screenHeight: fullH,
            safeAreaInsets: safeAreaInsets
        )
        let arrowSize = MDSCoachmarkConstants.arrowSize

        TipPositioningContainer(
            anchorRect: adj,
            showBelow: below,
            spotlightPadding: MDSCoachmarkConstants.spotlightPadding,
            screenSize: CGSize(width: fullW, height: fullH),
            safeAreaInsets: safeAreaInsets,
            safeAreaMargin: MDSCoachmarkConstants.tipSafeAreaMargin,
            tipCornerRadius: configuration.tipCornerRadius
        ) {
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
            // Reserve space for the arrow so that the combined height is visible to
            // TipPositioningContainer's GeometryReader for accurate Y placement.
            .padding(.top,    below ? arrowSize : 0)
            .padding(.bottom, below ? 0 : arrowSize)
            .background(
                // Fill the combined bubble + arrow shape with the tooltip background
                // colour and apply the drop shadow to the whole shape at once.
                GeometryReader { geo in
                    let midX = resolvedArrowMidX(
                        for: item,
                        containerWidth: geo.size.width,
                        screenWidth: fullW,
                        anchorRect: adj
                    )
                    TooltipBubbleShape(
                        arrowPointingUp: below,
                        arrowMidX: midX,
                        arrowWidth: arrowSize * 2,
                        arrowHeight: arrowSize,
                        cornerRadius: configuration.tipCornerRadius
                    )
                    .fill(MDSCoachmarkConstants.tipBackgroundColor)
                    .shadow(
                        color: Color.black.opacity(0.15),
                        radius: MDSCoachmarkConstants.tipShadowRadius, x: 0, y: 2
                    )
                }
            )
            .overlay(
                // Stroke the same combined shape to produce the configurable border.
                // The border hugs the arrow on both sides but is absent at the arrow
                // base — the path simply does not include that segment.
                Group {
                    if configuration.tooltipBorderWidth > 0 {
                        GeometryReader { geo in
                            let midX = resolvedArrowMidX(
                                for: item,
                                containerWidth: geo.size.width,
                                screenWidth: fullW,
                                anchorRect: adj
                            )
                            TooltipBubbleShape(
                                arrowPointingUp: below,
                                arrowMidX: midX,
                                arrowWidth: arrowSize * 2,
                                arrowHeight: arrowSize,
                                cornerRadius: configuration.tipCornerRadius
                            )
                            .stroke(
                                configuration.tooltipBorderColor,
                                lineWidth: configuration.tooltipBorderWidth
                            )
                        }
                    }
                }
            )
            .padding(.horizontal, 16)
        }
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
        .id(stepIndex)
    }

    // MARK: Arrow X Resolution

    /// Computes the horizontal centre of the arrow in the tooltip's local coordinate space.
    ///
    /// The calculation mirrors the alignment logic that was previously inside
    /// `ArrowPositioningView`, keeping the arrow visually anchored to the spotlight.
    ///
    /// - Parameters:
    ///   - item: The coachmark item whose ``MDSCoachmarkItem/arrowAlignment`` and
    ///     ``MDSCoachmarkItem/arrowOffset`` are applied.
    ///   - containerWidth: The rendered width of the tooltip content area (from
    ///     `GeometryReader`). This is the local space in which the arrow X is expressed.
    ///   - screenWidth: The full screen width used to auto-resolve `.auto` alignment.
    ///   - anchorRect: The adjusted anchor frame in screen coordinates, used when
    ///     resolving `.auto` alignment by the anchor's horizontal midpoint.
    /// - Returns: The arrow's horizontal centre in the tooltip's local coordinate space.
    private func resolvedArrowMidX(
        for item: MDSCoachmarkItem,
        containerWidth: CGFloat,
        screenWidth: CGFloat,
        anchorRect: CGRect
    ) -> CGFloat {
        // Resolve .auto into a concrete alignment based on where the spotlight sits.
        let resolved: MDSCoachmarkArrowAlignment
        if item.arrowAlignment == .auto {
            let mid = anchorRect.midX
            if mid < screenWidth * 0.3      { resolved = .leading }
            else if mid > screenWidth * 0.7 { resolved = .trailing }
            else                             { resolved = .center }
        } else {
            resolved = item.arrowAlignment
        }

        let base: CGFloat
        switch resolved {
        case .leading:
            base = MDSCoachmarkConstants.arrowHorizontalPadding
        case .trailing:
            base = containerWidth - MDSCoachmarkConstants.arrowHorizontalPadding
        case .center, .auto:
            base = containerWidth / 2
        }

        return base + item.arrowOffset
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
