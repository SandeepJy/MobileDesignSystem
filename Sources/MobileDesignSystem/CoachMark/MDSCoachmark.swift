import SwiftUI

// MARK: - Coachmark Item (Simplified - No Type Erasure)

/// Defines a single coachmark step with standardized content.
public struct MDSCoachmarkItem: Identifiable, Equatable {
    public let id: String
    
    /// Title displayed prominently in the tip
    public let title: String
    
    /// Optional description text below the title
    public let description: String?
    
    /// Optional SF Symbol name for the icon
    public let iconName: String?
    
    /// Optional custom icon color (defaults to accent color)
    public let iconColor: Color?
    
    /// Names of scroll proxies to use when scrolling to this anchor.
    /// If nil, all registered proxies will be used in registration order.
    /// If empty array, no scrolling will be performed.
    public let scrollProxies: [String]?
    
    public init(
        id: String,
        title: String,
        description: String? = nil,
        iconName: String? = nil,
        iconColor: Color? = nil,
        scrollProxies: [String]? = nil
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.iconName = iconName
        self.iconColor = iconColor
        self.scrollProxies = scrollProxies
    }
    
    public static func == (lhs: MDSCoachmarkItem, rhs: MDSCoachmarkItem) -> Bool {
        lhs.id == rhs.id &&
        lhs.title == rhs.title &&
        lhs.description == rhs.description &&
        lhs.iconName == rhs.iconName &&
        lhs.scrollProxies == rhs.scrollProxies
    }
}

// MARK: - Scroll Coordinator

/// Coordinates scrolling across multiple ScrollViews in the consumer's view hierarchy.
public class MDSCoachmarkScrollCoordinator: ObservableObject {
    
    private var scrollActions: [String: (String, UnitPoint) -> Void] = [:]
    private var orderedNames: [String] = []
    
    public init() {}
    
    /// Register a named scroll proxy action
    public func register(_ name: String, action: @escaping (String, UnitPoint) -> Void) {
        if scrollActions[name] == nil {
            orderedNames.append(name)
        }
        scrollActions[name] = action
    }
    
    /// Unregister a scroll proxy
    public func unregister(_ name: String) {
        scrollActions.removeValue(forKey: name)
        orderedNames.removeAll { $0 == name }
    }
    
    /// Scroll to target using specified proxies (in order), or all registered proxies if none specified
    public func scrollTo(
        _ targetID: String,
        anchor: UnitPoint,
        using proxyNames: [String]?,
        animated: Bool = true
    ) {
        let namesToUse = proxyNames ?? orderedNames
        
        let performScroll = {
            for name in namesToUse {
                self.scrollActions[name]?(targetID, anchor)
            }
        }
        
        if animated {
            withAnimation(.easeInOut(duration: 0.3)) {
                performScroll()
            }
        } else {
            performScroll()
        }
    }
    
    /// Check if any scroll proxies are registered
    public var hasRegisteredProxies: Bool {
        !scrollActions.isEmpty
    }
}

// MARK: - View Extension for Registering Scroll Proxies

public extension View {
    /// Register a ScrollViewProxy with the coachmark scroll coordinator.
    func coachmarkScrollProxy(
        _ name: String,
        proxy: ScrollViewProxy,
        coordinator: MDSCoachmarkScrollCoordinator
    ) -> some View {
        self
            .onAppear {
                coordinator.register(name) { id, anchor in
                    proxy.scrollTo(id, anchor: anchor)
                }
            }
            .onDisappear {
                coordinator.unregister(name)
            }
    }
}

// MARK: - Arrow Direction

public enum MDSCoachmarkArrowDirection {
    case top
    case bottom
    case automatic
}

// MARK: - Tip Layout Style

public enum MDSCoachmarkTipLayoutStyle {
    /// Icon on the leading side, title and description stacked vertically
    case horizontal
    /// Icon above title and description
    case vertical
    /// No icon area reserved, just title and description
    case textOnly
}

// MARK: - Coachmark Configuration

public struct MDSCoachmarkConfiguration {
    // MARK: Button Labels
    public var showExitButton: Bool
    public var exitButtonLabel: String
    public var nextButtonLabel: String
    public var finishButtonLabel: String
    public var backButtonLabel: String
    public var showBackButton: Bool
    
    // MARK: Overlay Appearance
    public var overlayColor: Color
    
    // MARK: Tip Appearance
    public var tipBackgroundColor: Color
    public var tipCornerRadius: CGFloat
    public var tipShadowRadius: CGFloat
    public var tipHorizontalPadding: CGFloat
    public var tipVerticalPadding: CGFloat
    public var tipMaxWidth: CGFloat?
    public var tipLayoutStyle: MDSCoachmarkTipLayoutStyle
    
    // MARK: Typography
    public var titleFont: Font
    public var titleColor: Color
    public var descriptionFont: Font
    public var descriptionColor: Color
    public var stepIndicatorFont: Font
    public var stepIndicatorColor: Color
    
    // MARK: Icon Defaults
    public var defaultIconSize: CGFloat
    public var defaultIconColor: Color
    
    // MARK: Accent & Spotlight
    public var accentColor: Color
    public var spotlightBorderColor: Color
    public var spotlightBorderWidth: CGFloat
    public var spotlightCornerRadius: CGFloat
    public var spotlightPadding: CGFloat
    
    // MARK: Arrow
    public var arrowDirection: MDSCoachmarkArrowDirection
    public var arrowSize: CGFloat
    
    // MARK: Animation & Scrolling
    public var animateTransitions: Bool
    public var scrollAnchor: UnitPoint
    public var scrollSettleDelay: TimeInterval
    
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
    }
}

// MARK: - Anchor Preference Key

public struct MDSCoachmarkAnchorPreferenceKey: PreferenceKey {
    public static var defaultValue: [String: Anchor<CGRect>] = [:]
    
    public static func reduce(value: inout [String: Anchor<CGRect>], nextValue: () -> [String: Anchor<CGRect>]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

// MARK: - View Extension for Anchors

public extension View {
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

// MARK: - Standardized Tip Content View

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
            // Content area based on layout style
            contentLayout
            
            Divider()
            
            // Navigation area
            navigationBar
        }
    }
    
    @ViewBuilder
    private var contentLayout: some View {
        switch configuration.tipLayoutStyle {
        case .horizontal:
            horizontalLayout
        case .vertical:
            verticalLayout
        case .textOnly:
            textOnlyLayout
        }
    }
    
    @ViewBuilder
    private var horizontalLayout: some View {
        HStack(alignment: .top, spacing: 12) {
            if let iconName = item.iconName {
                iconView(systemName: iconName)
            }
            
            textContent
        }
    }
    
    @ViewBuilder
    private var verticalLayout: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let iconName = item.iconName {
                iconView(systemName: iconName)
            }
            
            textContent
        }
    }
    
    @ViewBuilder
    private var textOnlyLayout: some View {
        textContent
    }
    
    @ViewBuilder
    private var textContent: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(item.title)
                .font(configuration.titleFont)
                .foregroundColor(configuration.titleColor)
                .fixedSize(horizontal: false, vertical: true)
            
            if let description = item.description, !description.isEmpty {
                Text(description)
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
            .frame(width: configuration.defaultIconSize + 8, height: configuration.defaultIconSize + 8)
    }
    
    @ViewBuilder
    private var navigationBar: some View {
        HStack {
            // Step indicator
            Text("\(stepIndex + 1) of \(totalSteps)")
                .font(configuration.stepIndicatorFont)
                .foregroundColor(configuration.stepIndicatorColor)
            
            Spacer()
            
            // Skip button
            if configuration.showExitButton && !isLast {
                Button(action: onSkip) {
                    Text(configuration.exitButtonLabel)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.trailing, 8)
            }
            
            // Back button
            if configuration.showBackButton && !isFirst {
                Button(action: onBack) {
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
            
            // Next/Finish button
            Button(action: isLast ? onFinish : onNext) {
                HStack(spacing: 4) {
                    Text(isLast ? configuration.finishButtonLabel : configuration.nextButtonLabel)
                        .font(.subheadline.bold())
                    if !isLast {
                        Image(systemName: "chevron.right")
                            .font(.caption.bold())
                    }
                }
                .foregroundColor(isLast ? .white : configuration.accentColor)
                .padding(.horizontal, isLast ? 16 : 0)
                .padding(.vertical, isLast ? 6 : 0)
                .background(
                    Group {
                        if isLast {
                            Capsule().fill(configuration.accentColor)
                        }
                    }
                )
            }
        }
    }
}

// MARK: - Visibility Check

private func isRectVisible(_ rect: CGRect, in containerSize: CGSize, threshold: CGFloat = 0.5) -> Bool {
    let visibleArea = CGRect(origin: .zero, size: containerSize)
    let intersection = rect.intersection(visibleArea)
    
    guard !intersection.isNull else { return false }
    
    let visiblePortion = (intersection.width * intersection.height) / max(rect.width * rect.height, 1)
    return visiblePortion >= threshold
}

// MARK: - Triangle Shape

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Tip Positioning Container

private struct TipPositioningContainer<Content: View>: View {
    let anchorRect: CGRect
    let showBelow: Bool
    let arrowSize: CGFloat
    let spotlightPadding: CGFloat
    let screenSize: CGSize
    let safeAreaInsets: EdgeInsets
    let content: Content
    
    @State private var tipSize: CGSize = .zero
    
    init(
        anchorRect: CGRect,
        showBelow: Bool,
        arrowSize: CGFloat,
        spotlightPadding: CGFloat,
        screenSize: CGSize,
        safeAreaInsets: EdgeInsets,
        @ViewBuilder content: () -> Content
    ) {
        self.anchorRect = anchorRect
        self.showBelow = showBelow
        self.arrowSize = arrowSize
        self.spotlightPadding = spotlightPadding
        self.screenSize = screenSize
        self.safeAreaInsets = safeAreaInsets
        self.content = content()
    }
    
    var body: some View {
        content
            .background(
                GeometryReader { tipGeometry in
                    Color.clear
                        .onAppear { tipSize = tipGeometry.size }
                        .onChange(of: tipGeometry.size.height) { _ in
                            tipSize = tipGeometry.size
                        }
                }
            )
            .frame(maxWidth: .infinity)
            .position(x: screenSize.width / 2, y: computedY)
    }
    
    private var gap: CGFloat { 4 }
    
    private var computedY: CGFloat {
        if showBelow {
            let topEdge = anchorRect.maxY + spotlightPadding + gap + arrowSize
            let y = topEdge + tipSize.height / 2
            let maxY = screenSize.height - tipSize.height / 2 - 8
            return min(y, maxY)
        } else {
            let bottomEdge = anchorRect.minY - spotlightPadding - gap - arrowSize
            let y = bottomEdge - tipSize.height / 2
            let minY = tipSize.height / 2 + 8
            return max(y, minY)
        }
    }
}

// MARK: - Coachmark Overlay View

private struct MDSCoachmarkOverlayView: View {
    let wrappedContent: AnyView
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
                        let safeAreaInsets = geometry.safeAreaInsets
                        let safeIndex = min(currentIndex, items.count - 1)
                        let currentItem = items[safeIndex]
                        let anchorRect: CGRect? = anchors[currentItem.id].map { geometry[$0] }
                        let rectIsVisible = anchorRect.map {
                            isRectVisible($0, in: geometry.size)
                        } ?? false
                        
                        ZStack {
                            overlayBackground(
                                anchorRect: (tipVisible && rectIsVisible) ? anchorRect : nil,
                                safeAreaInsets: safeAreaInsets,
                                in: geometry
                            )
                            .onTapGesture { }
                            
                            if tipVisible, let rect = anchorRect, rectIsVisible {
                                tipPopover(
                                    for: currentItem,
                                    anchorRect: rect,
                                    safeAreaInsets: safeAreaInsets,
                                    geometry: geometry,
                                    stepIndex: safeIndex
                                )
                                .transition(.opacity.combined(with: .scale(scale: 0.95)))
                            }
                            
                            if isScrolling {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
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
        
        let currentItem = items[currentIndex]
        isScrolling = true
        tipVisible = false
        
        if let coordinator = scrollCoordinator, coordinator.hasRegisteredProxies {
            coordinator.scrollTo(
                currentItem.id,
                anchor: configuration.scrollAnchor,
                using: currentItem.scrollProxies,
                animated: configuration.animateTransitions
            )
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + configuration.scrollSettleDelay) {
            isScrolling = false
            withAnimation(configuration.animateTransitions ? .easeInOut(duration: 0.25) : nil) {
                tipVisible = true
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
        
        Canvas { context, size in
            context.fill(
                Path(CGRect(origin: .zero, size: size)),
                with: .color(configuration.overlayColor)
            )
            if let rect = anchorRect {
                let adjusted = CGRect(
                    x: rect.origin.x + safeAreaInsets.leading,
                    y: rect.origin.y + safeAreaInsets.top,
                    width: rect.width, height: rect.height
                )
                let spot = adjusted.insetBy(dx: -pad, dy: -pad)
                context.blendMode = .destinationOut
                context.fill(Path(roundedRect: spot, cornerRadius: radius), with: .color(.white))
            }
        }
        .compositingGroup()
        .allowsHitTesting(true)
        .overlay {
            if let rect = anchorRect, configuration.spotlightBorderWidth > 0 {
                let adjusted = CGRect(
                    x: rect.origin.x + safeAreaInsets.leading,
                    y: rect.origin.y + safeAreaInsets.top,
                    width: rect.width, height: rect.height
                )
                let spot = adjusted.insetBy(dx: -pad, dy: -pad)
                RoundedRectangle(cornerRadius: radius)
                    .stroke(configuration.spotlightBorderColor, lineWidth: configuration.spotlightBorderWidth)
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
        let adjusted = CGRect(
            x: anchorRect.origin.x + safeAreaInsets.leading,
            y: anchorRect.origin.y + safeAreaInsets.top,
            width: anchorRect.width, height: anchorRect.height
        )
        let fullH = geometry.size.height + safeAreaInsets.top + safeAreaInsets.bottom
        let fullW = geometry.size.width + safeAreaInsets.leading + safeAreaInsets.trailing
        let below = shouldShowBelow(anchorRect: adjusted, screenHeight: fullH)
        let isFirst = stepIndex == 0
        let isLast = stepIndex == items.count - 1
        
        TipPositioningContainer(
            anchorRect: adjusted,
            showBelow: below,
            arrowSize: configuration.arrowSize,
            spotlightPadding: configuration.spotlightPadding,
            screenSize: CGSize(width: fullW, height: fullH),
            safeAreaInsets: safeAreaInsets
        ) {
            VStack(spacing: 0) {
                if below {
                    arrowView(pointingUp: true)
                        .frame(maxWidth: .infinity, alignment: arrowAlignment(anchorRect: adjusted, screenWidth: fullW))
                        .padding(.horizontal, 24)
                }
                
                MDSCoachmarkTipContentView(
                    item: item,
                    stepIndex: stepIndex,
                    totalSteps: items.count,
                    isFirst: isFirst,
                    isLast: isLast,
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
                .shadow(color: Color.black.opacity(0.15), radius: configuration.tipShadowRadius, x: 0, y: 2)
                .padding(.horizontal, 16)
                
                if !below {
                    arrowView(pointingUp: false)
                        .frame(maxWidth: .infinity, alignment: arrowAlignment(anchorRect: adjusted, screenWidth: fullW))
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
            .shadow(color: Color.black.opacity(0.08), radius: 2, x: 0, y: pointingUp ? -1 : 1)
    }
    
    private func shouldShowBelow(anchorRect: CGRect, screenHeight: CGFloat) -> Bool {
        switch configuration.arrowDirection {
        case .top: return false
        case .bottom: return true
        case .automatic:
            let spaceAbove = anchorRect.minY - configuration.spotlightPadding
            let spaceBelow = screenHeight - anchorRect.maxY - configuration.spotlightPadding
            let minSpace: CGFloat = 120
            if spaceBelow >= minSpace { return true }
            if spaceAbove >= minSpace { return false }
            return spaceBelow >= spaceAbove
        }
    }
    
    private func arrowAlignment(anchorRect: CGRect, screenWidth: CGFloat) -> Alignment {
        let mid = anchorRect.midX
        if mid < screenWidth * 0.3 { return .leading }
        if mid > screenWidth * 0.7 { return .trailing }
        return .center
    }
    
    private func goToNext() {
        let next = min(currentIndex + 1, items.count - 1)
        if configuration.animateTransitions {
            withAnimation(.easeInOut(duration: 0.3)) { currentIndex = next }
        } else {
            currentIndex = next
        }
        scrollToCurrentAnchor()
    }
    
    private func goToPrevious() {
        let prev = max(currentIndex - 1, 0)
        if configuration.animateTransitions {
            withAnimation(.easeInOut(duration: 0.3)) { currentIndex = prev }
        } else {
            currentIndex = prev
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

// MARK: - Coachmark Overlay Modifier

private struct MDSCoachmarkOverlayModifier: ViewModifier {
    @Binding var isPresented: Bool
    let items: [MDSCoachmarkItem]
    let configuration: MDSCoachmarkConfiguration
    let scrollCoordinator: MDSCoachmarkScrollCoordinator?
    let onFinished: (() -> Void)?
    let onSkipped: ((Int) -> Void)?
    
    func body(content: Content) -> some View {
        MDSCoachmarkOverlayView(
            wrappedContent: AnyView(content),
            isPresented: $isPresented,
            items: items,
            configuration: configuration,
            onFinished: onFinished,
            onSkipped: onSkipped,
            scrollCoordinator: scrollCoordinator
        )
    }
}

// MARK: - View Extension for Presenting Coachmarks

public extension View {
    /// Present a coachmark overlay.
    ///
    /// - Parameters:
    ///   - isPresented: Binding to control visibility
    ///   - configuration: Styling and behavior configuration
    ///   - items: Array of coachmark items defining the tour
    ///   - scrollCoordinator: Optional coordinator for consumer-controlled scrolling
    ///   - onFinished: Called when user completes the tour
    ///   - onSkipped: Called when user skips, with the step index
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

// MARK: - Preview

#if DEBUG
struct MDSCoachmark_Previews: PreviewProvider {
    struct PreviewWrapper: View {
        @State private var showCoachmarks = true
        @StateObject private var scrollCoordinator = MDSCoachmarkScrollCoordinator()
        
        var body: some View {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 40) {
                        Button("Start Tour") {
                            showCoachmarks = true
                        }
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
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
                        
                        Color.clear.frame(height: 600)
                        
                        Text("Way down here!")
                            .font(.headline)
                            .coachmarkAnchor("bottom-text")
                        
                        Color.clear.frame(height: 200)
                    }
                    .padding()
                }
                .coachmarkScrollProxy("main", proxy: proxy, coordinator: scrollCoordinator)
            }
            .coachmarkOverlay(
                isPresented: $showCoachmarks,
                items: [
                    MDSCoachmarkItem(
                        id: "start-button",
                        title: "Welcome! 👋",
                        description: "Tap this button to begin the tour at any time.",
                        iconName: "hand.wave.fill",
                        iconColor: .orange
                    ),
                    MDSCoachmarkItem(
                        id: "star-icon",
                        title: "Favorites",
                        description: "Mark items as favorites for quick access.",
                        iconName: "star.fill",
                        iconColor: .yellow
                    ),
                    MDSCoachmarkItem(
                        id: "bottom-text",
                        title: "Scrolled Into View!",
                        description: "The coachmark automatically scrolled to show this element.",
                        iconName: "arrow.down.circle.fill",
                        iconColor: .teal
                    ),
                    MDSCoachmarkItem(
                        id: "bell-icon",
                        title: "Notifications",
                        description: "Stay updated with important alerts and messages.",
                        iconName: "bell.fill",
                        iconColor: .red
                    )
                ],
                scrollCoordinator: scrollCoordinator,
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
