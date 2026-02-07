import SwiftUI

// MARK: - Coachmark Item

public struct MDSCoachmarkItem: Identifiable, Equatable {
    public let id: String
    public let title: String
    public let description: String?
    public let iconName: String?
    public let iconColor: Color?
    
    /// Ordered scroll proxy names from outermost to innermost.
    /// - `nil` → no scrolling (item is already visible)
    /// - `["main"]` → scroll main to target
    /// - `["main", "carousel"]` → scroll main to carousel container, then carousel to target
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

public class MDSCoachmarkScrollCoordinator: ObservableObject {
    
    /// Stores both the scroll action and the auto-generated container ID for each proxy
    private struct ProxyEntry {
        let containerID: String
        let scrollAction: (String, UnitPoint) -> Void
    }
    
    private var entries: [String: ProxyEntry] = [:]
    private var orderedNames: [String] = []
    
    public init() {}
    
    /// Register a named scroll proxy with its auto-generated container ID
    internal func register(
        _ name: String,
        containerID: String,
        action: @escaping (String, UnitPoint) -> Void
    ) {
        if entries[name] == nil {
            orderedNames.append(name)
        }
        entries[name] = ProxyEntry(containerID: containerID, scrollAction: action)
    }
    
    /// Unregister a scroll proxy
    public func unregister(_ name: String) {
        entries.removeValue(forKey: name)
        orderedNames.removeAll { $0 == name }
    }
    
    public var hasRegisteredProxies: Bool {
        !entries.isEmpty
    }
    
    /// Look up the auto-generated container ID for a named proxy
    internal func containerID(for name: String) -> String? {
        entries[name]?.containerID
    }
    
    /// Execute scroll steps sequentially: each proxy (except the last) scrolls to the
    /// NEXT proxy's container. The last proxy scrolls to the actual target.
    ///
    /// Example: proxyNames = ["main", "carousel"], targetID = "card-5"
    ///   1. "main" scrolls to carousel's container ID  (brings carousel into viewport)
    ///   2. "carousel" scrolls to "card-5"             (scrolls to the card)
    public func scrollSequentially(
        targetID: String,
        proxyNames: [String],
        anchor: UnitPoint,
        animated: Bool,
        interStepDelay: TimeInterval = 0.35,
        completion: @escaping () -> Void
    ) {
        guard !proxyNames.isEmpty else {
            completion()
            return
        }
        
        func executeStep(_ index: Int) {
            guard index < proxyNames.count else {
                completion()
                return
            }
            
            let name = proxyNames[index]
            guard let entry = entries[name] else {
                // Skip unknown proxy, continue to next
                executeStep(index + 1)
                return
            }
            
            // Determine scroll target:
            // - Last proxy → scroll to the actual target ID
            // - Earlier proxies → scroll to the NEXT proxy's container ID
            let scrollTarget: String
            if index < proxyNames.count - 1 {
                let nextName = proxyNames[index + 1]
                scrollTarget = entries[nextName]?.containerID ?? targetID
            } else {
                scrollTarget = targetID
            }
            
            let perform = {
                entry.scrollAction(scrollTarget, anchor)
            }
            
            if animated {
                withAnimation(.easeInOut(duration: 0.3)) {
                    perform()
                }
            } else {
                perform()
            }
            
            // Wait for this scroll to settle, then fire next step
            DispatchQueue.main.asyncAfter(deadline: .now() + interStepDelay) {
                executeStep(index + 1)
            }
        }
        
        executeStep(0)
    }
}

// MARK: - View Extension for Registering Scroll Proxies

public extension View {
    /// Register a ScrollViewProxy with the coachmark scroll coordinator.
    /// Automatically assigns a hidden ID so parent proxies can scroll to this container.
    func coachmarkScrollProxy(
        _ name: String,
        proxy: ScrollViewProxy,
        coordinator: MDSCoachmarkScrollCoordinator
    ) -> some View {
        // Stable, deterministic ID that won't clash with user IDs
        let containerID = "__mds_coachmark_container_\(name)"
        
        return self
            .id(containerID)
            .onAppear {
                coordinator.register(name, containerID: containerID) { id, anchor in
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
    case top, bottom, automatic
}

// MARK: - Tip Layout Style

public enum MDSCoachmarkTipLayoutStyle {
    case horizontal, vertical, textOnly
}

// MARK: - Coachmark Configuration

public struct MDSCoachmarkConfiguration {
    public var showExitButton: Bool
    public var exitButtonLabel: String
    public var nextButtonLabel: String
    public var finishButtonLabel: String
    public var backButtonLabel: String
    public var showBackButton: Bool
    public var overlayColor: Color
    public var tipBackgroundColor: Color
    public var tipCornerRadius: CGFloat
    public var tipShadowRadius: CGFloat
    public var tipHorizontalPadding: CGFloat
    public var tipVerticalPadding: CGFloat
    public var tipMaxWidth: CGFloat?
    public var tipLayoutStyle: MDSCoachmarkTipLayoutStyle
    public var titleFont: Font
    public var titleColor: Color
    public var descriptionFont: Font
    public var descriptionColor: Color
    public var stepIndicatorFont: Font
    public var stepIndicatorColor: Color
    public var defaultIconSize: CGFloat
    public var defaultIconColor: Color
    public var accentColor: Color
    public var spotlightBorderColor: Color
    public var spotlightBorderWidth: CGFloat
    public var spotlightCornerRadius: CGFloat
    public var spotlightPadding: CGFloat
    public var arrowDirection: MDSCoachmarkArrowDirection
    public var arrowSize: CGFloat
    public var animateTransitions: Bool
    public var scrollAnchor: UnitPoint
    public var scrollSettleDelay: TimeInterval
    /// Delay between sequential scroll steps (outer → inner)
    public var scrollInterStepDelay: TimeInterval
    /// Minimum margin between tip and safe area edges (nav bar/tab bar)
    public var tipSafeAreaMargin: CGFloat
    
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
        self.tipSafeAreaMargin = tipSafeAreaMargin
    }
}

// MARK: - Anchor Preference Key

public struct MDSCoachmarkAnchorPreferenceKey: PreferenceKey {
    public static var defaultValue: [String: Anchor<CGRect>] = [:]
    
    public static func reduce(
        value: inout [String: Anchor<CGRect>],
        nextValue: () -> [String: Anchor<CGRect>]
    ) {
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
                        .font(.subheadline)
                        .foregroundColor(.secondary)
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
                    Group {
                        if isLast { Capsule().fill(configuration.accentColor) }
                    }
                )
            }
        }
    }
}

// MARK: - Visibility Check

private func isRectVisible(
    _ rect: CGRect, in containerSize: CGSize, threshold: CGFloat = 0.5
) -> Bool {
    let visibleArea = CGRect(origin: .zero, size: containerSize)
    let intersection = rect.intersection(visibleArea)
    guard !intersection.isNull else { return false }
    let visiblePortion = (intersection.width * intersection.height)
        / max(rect.width * rect.height, 1)
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
            // Ensure tip doesn't go behind bottom safe area (tab bar)
            let maxY = screenSize.height - safeAreaInsets.bottom - tipSize.height / 2 - safeAreaMargin
            return min(y, maxY)
        } else {
            let bottomEdge = anchorRect.minY - spotlightPadding - gap - arrowSize
            let y = bottomEdge - tipSize.height / 2
            // Ensure tip doesn't go behind top safe area (nav bar)
            let minY = safeAreaInsets.top + tipSize.height / 2 + safeAreaMargin
            return max(y, minY)
        }
    }
}

// MARK: - Coachmark Overlay View

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
        
        // Check if we have scroll work to do
        if let coordinator = scrollCoordinator,
           coordinator.hasRegisteredProxies,
           let proxyNames = currentItem.scrollProxies,
           !proxyNames.isEmpty
        {
            // Sequential scroll: outer → inner, then show tip
            coordinator.scrollSequentially(
                targetID: currentItem.id,
                proxyNames: proxyNames,
                anchor: configuration.scrollAnchor,
                animated: configuration.animateTransitions,
                interStepDelay: configuration.scrollInterStepDelay
            ) {
                // All scroll steps done → final settle delay
                DispatchQueue.main.asyncAfter(
                    deadline: .now() + configuration.scrollSettleDelay
                ) {
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
            // No scrolling needed — show tip after brief layout pass
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
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
                context.fill(
                    Path(roundedRect: spot, cornerRadius: radius),
                    with: .color(.white)
                )
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
        let adjusted = CGRect(
            x: anchorRect.origin.x + safeAreaInsets.leading,
            y: anchorRect.origin.y + safeAreaInsets.top,
            width: anchorRect.width, height: anchorRect.height
        )
        let fullH = geometry.size.height + safeAreaInsets.top + safeAreaInsets.bottom
        let fullW = geometry.size.width + safeAreaInsets.leading + safeAreaInsets.trailing
        let below = shouldShowBelow(
            anchorRect: adjusted,
            screenHeight: fullH,
            safeAreaInsets: safeAreaInsets
        )
        let isFirst = stepIndex == 0
        let isLast = stepIndex == items.count - 1
        
        TipPositioningContainer(
            anchorRect: adjusted,
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
                            alignment: arrowAlignment(anchorRect: adjusted, screenWidth: fullW)
                        )
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
                .shadow(
                    color: Color.black.opacity(0.15),
                    radius: configuration.tipShadowRadius, x: 0, y: 2
                )
                .padding(.horizontal, 16)
                
                if !below {
                    arrowView(pointingUp: false)
                        .frame(
                            maxWidth: .infinity,
                            alignment: arrowAlignment(anchorRect: adjusted, screenWidth: fullW)
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
        anchorRect: CGRect,
        screenHeight: CGFloat,
        safeAreaInsets: EdgeInsets
    ) -> Bool {
        switch configuration.arrowDirection {
        case .top:       return false
        case .bottom:    return true
        case .automatic:
            // Available space above (accounting for nav bar/status bar)
            let above = anchorRect.minY - configuration.spotlightPadding - safeAreaInsets.top
            // Available space below (accounting for tab bar/home indicator)
            let below = screenHeight - anchorRect.maxY - configuration.spotlightPadding - safeAreaInsets.bottom
            let minRequired: CGFloat = 120
            if below >= minRequired { return true }
            if above >= minRequired { return false }
            return below >= above
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

// MARK: - View Extension for Presenting Coachmarks

public extension View {
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
