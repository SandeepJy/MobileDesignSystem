

import SwiftUI

/// A shared object that coordinates scroll requests between any active coachmark overlay
/// and the scroll container. This avoids environment-overwrite issues when multiple
/// `.coachmarkOverlay()` modifiers are chained.
public class MDSCoachmarkScrollRequestManager: ObservableObject {
    @Published public var currentRequest: MDSCoachmarkScrollRequest? = nil
    
    public static let shared = MDSCoachmarkScrollRequestManager()
    
    public init() {}
}

// MARK: - Environment Key (updated to use manager)

struct MDSCoachmarkScrollManagerKey: EnvironmentKey {
    static let defaultValue: MDSCoachmarkScrollRequestManager = .shared
}

extension EnvironmentValues {
    var coachmarkScrollManager: MDSCoachmarkScrollRequestManager {
        get { self[MDSCoachmarkScrollManagerKey.self] }
        set { self[MDSCoachmarkScrollManagerKey.self] = newValue }
    }
}

// MARK: - Coachmark Item Definition

/// Defines a single coachmark step with an identifier and the tip content to display.
///
/// Each `MDSCoachmarkItem` represents one step in a coachmark sequence. You associate
/// it with a specific UI element using a string identifier, and provide the SwiftUI
/// content to display as the tip.
///
/// ## Example
/// ```swift
/// MDSCoachmarkItem(id: "profile-button") {
///     VStack(alignment: .leading, spacing: 4) {
///         Text("Your Profile")
///             .font(.headline)
///         Text("Tap here to view your profile settings.")
///             .font(.subheadline)
///     }
/// }
/// ```
public struct MDSCoachmarkItem<Content: View>: Identifiable {
    public let id: String
    public let content: Content
    
    /// Creates a coachmark item with an identifier and tip content.
    ///
    /// - Parameters:
    ///   - id: A unique string identifier that matches the anchor ID set via `.coachmarkAnchor(_:)`.
    ///   - content: A view builder providing the tip content to display.
    public init(id: String, @ViewBuilder content: () -> Content) {
        self.id = id
        self.content = content()
    }
}

// MARK: - Type-Erased Coachmark Item

/// A type-erased wrapper for `MDSCoachmarkItem` so items with different content types
/// can be stored in a single collection.
public struct AnyMDSCoachmarkItem: Identifiable {
    public let id: String
    let contentView: AnyView
    
    /// Creates a type-erased coachmark item from a typed `MDSCoachmarkItem`.
    ///
    /// - Parameter item: The typed coachmark item to wrap.
    public init<Content: View>(_ item: MDSCoachmarkItem<Content>) {
        self.id = item.id
        self.contentView = AnyView(item.content)
    }
}

// MARK: - Arrow Direction

/// The preferred direction for the coachmark arrow/pointer relative to the anchor.
public enum MDSCoachmarkArrowDirection {
    case top
    case bottom
    case automatic
}

// MARK: - Coachmark Configuration

/// Configuration options for the coachmark overlay appearance and behavior.
///
/// Use `MDSCoachmarkConfiguration` to customise colors, paddings, button labels,
/// and whether users can dismiss the entire sequence early.
///
/// ## Example
/// ```swift
/// var config = MDSCoachmarkConfiguration()
/// config.showExitButton = true
/// config.exitButtonLabel = "Skip All"
/// config.overlayColor = Color.black.opacity(0.6)
/// ```
public struct MDSCoachmarkConfiguration {
    /// Whether to show an exit/skip button on each step. Defaults to `true`.
    public var showExitButton: Bool
    
    /// The label for the exit button. Defaults to `"Skip"`.
    public var exitButtonLabel: String
    
    /// The label for the next button. Defaults to `"Next"`.
    public var nextButtonLabel: String
    
    /// The label for the finish button shown on the last step. Defaults to `"Done"`.
    public var finishButtonLabel: String
    
    /// The label for the previous/back button. Defaults to `"Back"`.
    public var backButtonLabel: String
    
    /// Whether to show a back button. Defaults to `true`.
    public var showBackButton: Bool
    
    /// The background color of the dimmed overlay. Defaults to `black` at 50% opacity.
    public var overlayColor: Color
    
    /// The background color of the tip popover. Defaults to system background.
    public var tipBackgroundColor: Color
    
    /// The corner radius of the tip popover. Defaults to `12`.
    public var tipCornerRadius: CGFloat
    
    /// The shadow radius of the tip popover. Defaults to `8`.
    public var tipShadowRadius: CGFloat
    
    /// Horizontal padding inside the tip popover. Defaults to `16`.
    public var tipHorizontalPadding: CGFloat
    
    /// Vertical padding inside the tip popover. Defaults to `12`.
    public var tipVerticalPadding: CGFloat
    
    /// The accent color for navigation buttons and the progress indicator. Defaults to `.blue`.
    public var accentColor: Color
    
    /// The color of the spotlight border around the highlighted element. Defaults to clear.
    public var spotlightBorderColor: Color
    
    /// The width of the spotlight border. Defaults to `0`.
    public var spotlightBorderWidth: CGFloat
    
    /// The corner radius of the spotlight cutout. Defaults to `8`.
    public var spotlightCornerRadius: CGFloat
    
    /// Additional padding around the spotlight cutout. Defaults to `4`.
    public var spotlightPadding: CGFloat
    
    /// The preferred arrow direction. Defaults to `.automatic`.
    public var arrowDirection: MDSCoachmarkArrowDirection
    
    /// The size of the arrow triangle. Defaults to `8`.
    public var arrowSize: CGFloat
    
    /// Whether to animate transitions between steps. Defaults to `true`.
    public var animateTransitions: Bool
    
    /// The anchor position for scrolling. Defaults to `.center`.
    /// Controls where the anchored view is positioned after scrolling.
    public var scrollAnchor: UnitPoint
    
    /// Delay in seconds after scrolling before showing the tip.
    /// Allows the scroll animation to settle. Defaults to `0.4`.
    public var scrollSettleDelay: TimeInterval
    
    /// Creates a default configuration.
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
        accentColor: Color = .blue,
        spotlightBorderColor: Color = .clear,
        spotlightBorderWidth: CGFloat = 0,
        spotlightCornerRadius: CGFloat = 8,
        spotlightPadding: CGFloat = 4,
        arrowDirection: MDSCoachmarkArrowDirection = .automatic,
        arrowSize: CGFloat = 8,
        animateTransitions: Bool = true,
        scrollAnchor: UnitPoint = .center,
        scrollSettleDelay: TimeInterval = 0.4
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
    }
}

// MARK: - Anchor Preference Key

/// Preference key used to collect anchor frames from views marked with `.coachmarkAnchor(_:)`.
public struct MDSCoachmarkAnchorPreferenceKey: PreferenceKey {
    public static var defaultValue: [String: Anchor<CGRect>] = [:]
    
    public static func reduce(value: inout [String: Anchor<CGRect>], nextValue: () -> [String: Anchor<CGRect>]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}



/// Describes a scroll request from the coachmark system to the hosting scroll view.
public struct MDSCoachmarkScrollRequest: Equatable {
    /// The anchor ID to scroll to.
    public let targetID: String
    /// The scroll anchor position.
    public let anchor: UnitPoint
    /// A unique token so identical consecutive requests are distinguishable.
    let token: UUID
    
    public static func == (lhs: MDSCoachmarkScrollRequest, rhs: MDSCoachmarkScrollRequest) -> Bool {
        lhs.targetID == rhs.targetID && lhs.token == rhs.token
    }
}

// MARK: - Coachmark Scroll Container

/// A scroll view container that automatically scrolls coachmark anchors into view.
///
/// Wrap your scrollable content in `MDSCoachmarkScrollContainer` instead of a plain
/// `ScrollView`. The coachmark overlay will automatically scroll to bring each
/// highlighted element into the visible area before showing its tip.
///
/// ## Example
/// ```swift
/// @State private var showCoachmarks = false
///
/// MDSCoachmarkScrollContainer {
///     VStack(spacing: 20) {
///         ForEach(items) { item in
///             ItemRow(item: item)
///                 .coachmarkAnchor(item.id)
///         }
///     }
/// }
/// .coachmarkOverlay(
///     isPresented: $showCoachmarks,
///     items: coachmarkItems
/// )
/// ```
public struct MDSCoachmarkScrollContainer<Content: View>: View {
    let axes: Axis.Set
    let showsIndicators: Bool
    let content: Content
    
    @Environment(\.coachmarkScrollManager) private var scrollManager
    
    public init(
        _ axes: Axis.Set = .vertical,
        showsIndicators: Bool = true,
        @ViewBuilder content: () -> Content
    ) {
        self.axes = axes
        self.showsIndicators = showsIndicators
        self.content = content()
    }
    
    public var body: some View {
        ScrollViewReader { proxy in
            ScrollView(axes, showsIndicators: showsIndicators) {
                content
            }
            .onReceive(scrollManager.$currentRequest) { request in
                guard let request = request else { return }
                withAnimation(.easeInOut(duration: 0.3)) {
                    proxy.scrollTo(request.targetID, anchor: request.anchor)
                }
            }
        }
    }
}

// MARK: - View Extension for Anchors

public extension View {
    /// Marks this view as a coachmark anchor point.
    ///
    /// Use this modifier on any view that should be highlighted during a coachmark sequence.
    /// The `id` must match the `id` of a corresponding `MDSCoachmarkItem`.
    ///
    /// This modifier does two things:
    /// 1. Reports this view's geometry via preferences so the overlay can spotlight it.
    /// 2. Sets a scroll identity so `MDSCoachmarkScrollContainer` can scroll to it.
    ///
    /// - Parameter id: A unique string identifier for this anchor.
    /// - Returns: A modified view that reports its geometry for the coachmark overlay.
    ///
    /// ## Example
    /// ```swift
    /// Button("Profile") { }
    ///     .coachmarkAnchor("profile-button")
    /// ```
    func coachmarkAnchor(_ id: String) -> some View {
        self
            .id(id)
            .anchorPreference(
                key: MDSCoachmarkAnchorPreferenceKey.self,
                value: .bounds
            ) { anchor in
                [id: anchor]
            }
    }
}

// MARK: - Visibility Check

/// Determines whether a rect is reasonably visible within the given container bounds.
private func isRectVisible(_ rect: CGRect, in containerSize: CGSize, threshold: CGFloat = 0.5) -> Bool {
    let visibleArea = CGRect(origin: .zero, size: containerSize)
    let intersection = rect.intersection(visibleArea)
    
    guard !intersection.isNull else { return false }
    
    let visiblePortion = (intersection.width * intersection.height) / max(rect.width * rect.height, 1)
    return visiblePortion >= threshold
}

// MARK: - Coachmark Overlay Modifier

/// A view modifier that presents the coachmark overlay sequence.
struct MDSCoachmarkOverlayModifier: ViewModifier {
    @Binding var isPresented: Bool
    let items: [AnyMDSCoachmarkItem]
    let configuration: MDSCoachmarkConfiguration
    let onFinished: (() -> Void)?
    let onSkipped: ((Int) -> Void)?
    
    @State private var currentIndex: Int = 0
    @State private var isScrolling: Bool = false
    @State private var tipVisible: Bool = false
    
    @Environment(\.coachmarkScrollManager) private var scrollManager
    
    func body(content: Content) -> some View {
        content
            .overlayPreferenceValue(MDSCoachmarkAnchorPreferenceKey.self) { anchors in
                if isPresented, !items.isEmpty {
                    coachmarkOverlay(anchors: anchors)
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
    
    // MARK: - Scroll Management
    
    private func scrollToCurrentAnchor() {
        guard currentIndex < items.count else { return }
        
        let targetID = items[currentIndex].id
        
        isScrolling = true
        tipVisible = false
        
        // Send request through the shared manager
        scrollManager.currentRequest = MDSCoachmarkScrollRequest(
            targetID: targetID,
            anchor: configuration.scrollAnchor,
            token: UUID()
        )
        
        DispatchQueue.main.asyncAfter(deadline: .now() + configuration.scrollSettleDelay) {
            isScrolling = false
            withAnimation(configuration.animateTransitions ? .easeInOut(duration: 0.25) : nil) {
                tipVisible = true
            }
        }
    }
    
    // MARK: - Overlay
    
    @ViewBuilder
    private func coachmarkOverlay(anchors: [String: Anchor<CGRect>]) -> some View {
        GeometryReader { geometry in
            let safeCurrentIndex = min(currentIndex, items.count - 1)
            let currentItem = items[safeCurrentIndex]
            let anchorRect: CGRect? = anchors[currentItem.id].map { geometry[$0] }
            
            let rectIsVisible = anchorRect.map {
                isRectVisible($0, in: geometry.size)
            } ?? false
            
            ZStack {
                // Dimmed overlay with spotlight cutout
                overlayBackground(
                    anchorRect: (tipVisible && rectIsVisible) ? anchorRect : nil,
                    in: geometry
                )
                .onTapGesture { }
                
                // Tip popover
                if tipVisible, let rect = anchorRect, rectIsVisible {
                    tipPopover(
                        for: currentItem,
                        anchorRect: rect,
                        geometry: geometry,
                        stepIndex: safeCurrentIndex
                    )
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }
                
                // Loading indicator while scrolling
                if isScrolling {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.2)
                }
            }
            .ignoresSafeArea()
        }
    }
    
    // MARK: - Overlay Background
    
    @ViewBuilder
    private func overlayBackground(anchorRect: CGRect?, in geometry: GeometryProxy) -> some View {
        let spotlightPadding = configuration.spotlightPadding
        let cornerRadius = configuration.spotlightCornerRadius
        
        Canvas { context, size in
            context.fill(
                Path(CGRect(origin: .zero, size: size)),
                with: .color(configuration.overlayColor)
            )
            
            if let rect = anchorRect {
                let spotlightRect = rect.insetBy(dx: -spotlightPadding, dy: -spotlightPadding)
                let spotlightPath = Path(roundedRect: spotlightRect, cornerRadius: cornerRadius)
                context.blendMode = .destinationOut
                context.fill(spotlightPath, with: .color(.white))
            }
        }
        .compositingGroup()
        .allowsHitTesting(true)
        .overlay {
            if let rect = anchorRect, configuration.spotlightBorderWidth > 0 {
                let spotlightRect = rect.insetBy(
                    dx: -spotlightPadding,
                    dy: -spotlightPadding
                )
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(configuration.spotlightBorderColor, lineWidth: configuration.spotlightBorderWidth)
                    .frame(width: spotlightRect.width, height: spotlightRect.height)
                    .position(x: spotlightRect.midX, y: spotlightRect.midY)
            }
        }
    }
    
    // MARK: - Tip Popover
    
    @ViewBuilder
    private func tipPopover(
        for item: AnyMDSCoachmarkItem,
        anchorRect: CGRect,
        geometry: GeometryProxy,
        stepIndex: Int
    ) -> some View {
        let showBelow = shouldShowBelow(anchorRect: anchorRect, in: geometry)
        let totalSteps = items.count
        let isFirst = stepIndex == 0
        let isLast = stepIndex == totalSteps - 1

        let tipContent = tipCardContent(
            for: item,
            stepIndex: stepIndex,
            totalSteps: totalSteps,
            isFirst: isFirst,
            isLast: isLast
        )

        TipPositioningContainer(
            anchorRect: anchorRect,
            showBelow: showBelow,
            arrowSize: configuration.arrowSize,
            spotlightPadding: configuration.spotlightPadding,
            screenHeight: geometry.size.height
        ) {
            VStack(spacing: 0) {
                if showBelow {
                    arrowView(pointingUp: true)
                        .frame(
                            maxWidth: .infinity,
                            alignment: arrowAlignment(
                                anchorRect: anchorRect,
                                geometry: geometry
                            )
                        )
                        .padding(.horizontal, 24)
                }

                tipContent
                    .padding(.horizontal, configuration.tipHorizontalPadding)
                    .padding(.vertical, configuration.tipVerticalPadding)
                    .background(configuration.tipBackgroundColor)
                    .cornerRadius(configuration.tipCornerRadius)
                    .shadow(
                        color: Color.black.opacity(0.15),
                        radius: configuration.tipShadowRadius,
                        x: 0, y: 2
                    )
                    .padding(.horizontal, 16)

                if !showBelow {
                    arrowView(pointingUp: false)
                        .frame(
                            maxWidth: .infinity,
                            alignment: arrowAlignment(
                                anchorRect: anchorRect,
                                geometry: geometry
                            )
                        )
                        .padding(.horizontal, 24)
                }
            }
        }
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
        .id(stepIndex)
    }

    // MARK: - Tip Card Content

    @ViewBuilder
    private func tipCardContent(
        for item: AnyMDSCoachmarkItem,
        stepIndex: Int,
        totalSteps: Int,
        isFirst: Bool,
        isLast: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            item.contentView
                .frame(maxWidth: .infinity, alignment: .leading)

            Divider()

            HStack {
                Text("\(stepIndex + 1) of \(totalSteps)")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                if configuration.showExitButton && !isLast {
                    Button {
                        dismiss()
                        onSkipped?(stepIndex)
                    } label: {
                        Text(configuration.exitButtonLabel)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.trailing, 8)
                }

                if configuration.showBackButton && !isFirst {
                    Button {
                        goToPrevious()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.caption.bold())
                            Text(configuration.backButtonLabel)
                                .font(.subheadline.bold())
                        }
                        .foregroundColor(configuration.accentColor)
                    }
                    .padding(.trailing, 4)
                }

                Button {
                    if isLast {
                        dismiss()
                        onFinished?()
                    } else {
                        goToNext()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(
                            isLast
                                ? configuration.finishButtonLabel
                                : configuration.nextButtonLabel
                        )
                        .font(.subheadline.bold())
                        if !isLast {
                            Image(systemName: "chevron.right")
                                .font(.caption.bold())
                        }
                    }
                    .foregroundColor(
                        isLast ? .white : configuration.accentColor
                    )
                    .padding(.horizontal, isLast ? 16 : 0)
                    .padding(.vertical, isLast ? 6 : 0)
                    .background(
                        Group {
                            if isLast {
                                Capsule()
                                    .fill(configuration.accentColor)
                            }
                        }
                    )
                }
            }
        }
    }
    
    // MARK: - Arrow View
    
    @ViewBuilder
    private func arrowView(pointingUp: Bool) -> some View {
        let size = configuration.arrowSize
        Triangle()
            .fill(configuration.tipBackgroundColor)
            .frame(width: size * 2, height: size)
            .rotationEffect(.degrees(pointingUp ? 0 : 180))
            .shadow(color: Color.black.opacity(0.08), radius: 2, x: 0, y: pointingUp ? -1 : 1)
    }
    
    // MARK: - Helpers
    
    private func shouldShowBelow(anchorRect: CGRect, in geometry: GeometryProxy) -> Bool {
        switch configuration.arrowDirection {
        case .top:
            return false
        case .bottom:
            return true
        case .automatic:
            // Calculate available space above and below the spotlight
            let spotlightTop = anchorRect.minY - configuration.spotlightPadding
            let spotlightBottom = anchorRect.maxY + configuration.spotlightPadding

            let spaceAbove = spotlightTop
            let spaceBelow = geometry.size.height - spotlightBottom

            // Prefer below, but switch to above if there's significantly more room
            // Use a minimum threshold to avoid placing tips in very tight spaces
            let minimumSpace: CGFloat = 120

            if spaceBelow >= minimumSpace {
                return true
            } else if spaceAbove >= minimumSpace {
                return false
            } else {
                // Both spaces are tight — pick the larger one
                return spaceBelow >= spaceAbove
            }
        }
    }
    
    private func arrowAlignment(anchorRect: CGRect, geometry: GeometryProxy) -> Alignment {
        let midX = anchorRect.midX
        let screenWidth = geometry.size.width
        if midX < screenWidth * 0.3 {
            return .leading
        } else if midX > screenWidth * 0.7 {
            return .trailing
        } else {
            return .center
        }
    }
    
    private func goToNext() {
        let nextIndex = min(currentIndex + 1, items.count - 1)
        if configuration.animateTransitions {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentIndex = nextIndex
            }
        } else {
            currentIndex = nextIndex
        }
        scrollToCurrentAnchor()
    }
    
    private func goToPrevious() {
        let prevIndex = max(currentIndex - 1, 0)
        if configuration.animateTransitions {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentIndex = prevIndex
            }
        } else {
            currentIndex = prevIndex
        }
        scrollToCurrentAnchor()
    }
    
    private func dismiss() {
        if configuration.animateTransitions {
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

// MARK: - Triangle Shape

/// A simple triangle shape used for the arrow pointer.
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

// MARK: - View Extension for Presenting Coachmarks

public extension View {
    /// Presents a coachmark overlay sequence on this view.
    ///
    /// Use this modifier on a container view to overlay a guided coachmark sequence.
    /// Each step highlights a specific UI element (marked with `.coachmarkAnchor(_:)`)
    /// and shows a tip popover with navigation controls.
    ///
    /// When used with `MDSCoachmarkScrollContainer`, the overlay automatically scrolls
    /// the target element into view before showing each tip.
    ///
    /// - Parameters:
    ///   - isPresented: A binding that controls whether the coachmark overlay is visible.
    ///   - configuration: The appearance and behavior configuration.
    ///   - items: An array of type-erased coachmark items defining the sequence.
    ///   - onFinished: An optional closure called when the user completes all steps.
    ///   - onSkipped: An optional closure called when the user skips, receiving the step index.
    /// - Returns: A modified view with the coachmark overlay capability.
    ///
    /// ## Example
    /// ```swift
    /// @State private var showCoachmarks = false
    ///
    /// var body: some View {
    ///     MDSCoachmarkScrollContainer {
    ///         VStack {
    ///             Button("Feature") { }
    ///                 .coachmarkAnchor("feature")
    ///
    ///             // ... more content that scrolls
    ///
    ///             Button("Another Feature") { }
    ///                 .coachmarkAnchor("another")
    ///         }
    ///     }
    ///     .coachmarkOverlay(
    ///         isPresented: $showCoachmarks,
    ///         items: [
    ///             AnyMDSCoachmarkItem(MDSCoachmarkItem(id: "feature") {
    ///                 Text("This is a new feature!")
    ///             }),
    ///             AnyMDSCoachmarkItem(MDSCoachmarkItem(id: "another") {
    ///                 Text("And another one down here!")
    ///             })
    ///         ]
    ///     )
    /// }
    /// ```
    func coachmarkOverlay(
        isPresented: Binding<Bool>,
        configuration: MDSCoachmarkConfiguration = MDSCoachmarkConfiguration(),
        items: [AnyMDSCoachmarkItem],
        onFinished: (() -> Void)? = nil,
        onSkipped: ((Int) -> Void)? = nil
    ) -> some View {
        self.modifier(
            MDSCoachmarkOverlayModifier(
                isPresented: isPresented,
                items: items,
                configuration: configuration,
                onFinished: onFinished,
                onSkipped: onSkipped
            )
        )
    }
}

// MARK: - Preview

#if DEBUG
struct MDSCoachmark_Previews: PreviewProvider {
    struct PreviewWrapper: View {
        @State private var showCoachmarks = true
        
        var body: some View {
            MDSCoachmarkScrollContainer {
                VStack(spacing: 40) {
                    Button("Start Tour") {
                        showCoachmarks = true
                    }
                    .coachmarkAnchor("start-button")
                    
                    HStack(spacing: 20) {
                        Image(systemName: "star.fill")
                            .font(.title)
                            .foregroundColor(.yellow)
                            .coachmarkAnchor("star-icon")
                        
                        Image(systemName: "bell.fill")
                            .font(.title)
                            .foregroundColor(.red)
                            .coachmarkAnchor("bell-icon")
                    }
                    
                    // Spacer to push content below the fold
                    Color.clear.frame(height: 600)
                    
                    Text("Way down here!")
                        .font(.headline)
                        .coachmarkAnchor("bottom-text")
                    
                    Color.clear.frame(height: 200)
                }
                .padding()
            }
            .coachmarkOverlay(
                isPresented: $showCoachmarks,
                items: [
                    AnyMDSCoachmarkItem(MDSCoachmarkItem(id: "start-button") {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Start Here")
                                .font(.headline)
                            Text("Tap this button to begin.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }),
                    AnyMDSCoachmarkItem(MDSCoachmarkItem(id: "star-icon") {
                        Text("Favorites")
                            .font(.headline)
                    }),
                    AnyMDSCoachmarkItem(MDSCoachmarkItem(id: "bottom-text") {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Scrolled Into View!")
                                .font(.headline)
                            Text("The coachmark scrolled down to show this element.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }),
                    AnyMDSCoachmarkItem(MDSCoachmarkItem(id: "bell-icon") {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Notifications")
                                .font(.headline)
                            Text("Scrolled back up to this element.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    })
                ],
                onFinished: {
                    print("Tour finished!")
                }
            )
        }
    }
    
    static var previews: some View {
        PreviewWrapper()
    }
}
#endif

/// A container that measures its content and positions it precisely above or below
/// the spotlight anchor, ensuring it never overlaps the highlighted element.
private struct TipPositioningContainer<Content: View>: View {
    let anchorRect: CGRect
    let showBelow: Bool
    let arrowSize: CGFloat
    let spotlightPadding: CGFloat
    let screenHeight: CGFloat
    let content: Content

    @State private var tipSize: CGSize = .zero

    init(
        anchorRect: CGRect,
        showBelow: Bool,
        arrowSize: CGFloat,
        spotlightPadding: CGFloat,
        screenHeight: CGFloat,
        @ViewBuilder content: () -> Content
    ) {
        self.anchorRect = anchorRect
        self.showBelow = showBelow
        self.arrowSize = arrowSize
        self.spotlightPadding = spotlightPadding
        self.screenHeight = screenHeight
        self.content = content()
    }

    var body: some View {
        content
            .background(
                GeometryReader { tipGeometry in
                    Color.clear
                        .onAppear {
                            tipSize = tipGeometry.size
                        }
                        .onChange(of: tipGeometry.size.height) { _ in
                            tipSize = tipGeometry.size
                        }
                }
            )
            .frame(maxWidth: .infinity)
            .position(x: UIScreen.main.bounds.width / 2, y: computedY)
    }

    /// The gap between the spotlight edge and the tip content.
    private var gap: CGFloat { 4 }

    private var computedY: CGFloat {
        if showBelow {
            // Place tip below the spotlight
            let topEdge = anchorRect.maxY + spotlightPadding + gap
            let y = topEdge + tipSize.height / 2
            // Clamp so tip doesn't go off the bottom of the screen
            let maxY = screenHeight - tipSize.height / 2 - 8
            return min(y, maxY)
        } else {
            // Place tip above the spotlight
            let bottomEdge = anchorRect.minY - spotlightPadding - gap
            let y = bottomEdge - tipSize.height / 2
            // Clamp so tip doesn't go off the top of the screen
            let minY = tipSize.height / 2 + 8
            return max(y, minY)
        }
    }
}
