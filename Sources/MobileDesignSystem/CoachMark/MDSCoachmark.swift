import SwiftUI

#if canImport(TipKit)
import TipKit
#endif

// MARK: - Shared Scroll Request Manager

/// A shared object that coordinates scroll requests between any active coachmark overlay
/// and the scroll container. This avoids environment-overwrite issues when multiple
/// `.coachmarkOverlay()` modifiers are chained.
public class MDSCoachmarkScrollRequestManager: ObservableObject {
    @Published public var currentRequest: MDSCoachmarkScrollRequest? = nil
    
    public static let shared = MDSCoachmarkScrollRequestManager()
    
    public init() {}
}

// MARK: - Environment Key

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
public struct MDSCoachmarkItem<Content: View>: Identifiable {
    public let id: String
    public let content: Content
    
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
    
    /// Plain-text title surfaced in the TipKit popover on iOS 17+.
    public var tipTitle: String?
    
    /// Plain-text description surfaced in the TipKit popover message on iOS 17+.
    public var tipDescription: String?
    
    public init<Content: View>(
        _ item: MDSCoachmarkItem<Content>,
        tipTitle: String? = nil,
        tipDescription: String? = nil
    ) {
        self.id = item.id
        self.contentView = AnyView(item.content)
        self.tipTitle = tipTitle
        self.tipDescription = tipDescription
    }
}

// MARK: - Arrow Direction

public enum MDSCoachmarkArrowDirection {
    case top
    case bottom
    case automatic
}

// MARK: - Coachmark Configuration

public struct MDSCoachmarkConfiguration: Sendable {
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

public struct MDSCoachmarkAnchorPreferenceKey: PreferenceKey {
    public static var defaultValue: [String: Anchor<CGRect>] = [:]
    
    public static func reduce(value: inout [String: Anchor<CGRect>], nextValue: () -> [String: Anchor<CGRect>]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

// MARK: - Scroll Request

public struct MDSCoachmarkScrollRequest: Equatable {
    public let targetID: String
    public let anchor: UnitPoint
    let token: UUID
    
    public static func == (lhs: MDSCoachmarkScrollRequest, rhs: MDSCoachmarkScrollRequest) -> Bool {
        lhs.targetID == rhs.targetID && lhs.token == rhs.token
    }
}

// MARK: - Coachmark Scroll Container

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

private func isRectVisible(_ rect: CGRect, in containerSize: CGSize, threshold: CGFloat = 0.5) -> Bool {
    let visibleArea = CGRect(origin: .zero, size: containerSize)
    let intersection = rect.intersection(visibleArea)
    
    guard !intersection.isNull else { return false }
    
    let visiblePortion = (intersection.width * intersection.height) / max(rect.width * rect.height, 1)
    return visiblePortion >= threshold
}

// MARK: - TipKit Integration (iOS 17+)

@available(iOS 17.0, *)
private struct MDSCoachmarkStepTip: Tip {
    let stepTitle: String
    let stepDescription: String?
    let stepIndex: Int
    let totalSteps: Int
    let showBackButton: Bool
    let showExitButton: Bool
    let backButtonLabel: String
    let nextButtonLabel: String
    let finishButtonLabel: String
    let exitButtonLabel: String
    
    var title: Text {
        Text(stepTitle)
    }
    
    var message: Text? {
        guard let desc = stepDescription, !desc.isEmpty else { return nil }
        return Text(desc)
    }
    
    var actions: [Action] {
        let isFirst = stepIndex == 0
        let isLast  = stepIndex == totalSteps - 1
        var list: [Action] = []
        
        if showBackButton && !isFirst {
            list.append(Action(id: "back", title: backButtonLabel))
        }
        
        list.append(
            Action(
                id: isLast ? "finish" : "next",
                title: isLast ? finishButtonLabel : nextButtonLabel
            )
        )
        
        if showExitButton && !isLast {
            list.append(Action(id: "skip", title: exitButtonLabel))
        }
        
        return list
    }
}

// MARK: - iOS 17+ Coachmark Overlay

@available(iOS 17.0, *)
private struct iOS17CoachmarkOverlay: View {
    let wrappedContent: AnyView
    @Binding var isPresented: Bool
    let items: [AnyMDSCoachmarkItem]
    let configuration: MDSCoachmarkConfiguration
    let onFinished: (() -> Void)?
    let onSkipped: ((Int) -> Void)?
    let scrollManager: MDSCoachmarkScrollRequestManager
    
    @State private var currentIndex: Int = 0
    @State private var isScrolling: Bool  = false
    @State private var tipVisible: Bool   = false
    @State private var currentTip: MDSCoachmarkStepTip?
    
    var body: some View {
        wrappedContent
            .overlayPreferenceValue(MDSCoachmarkAnchorPreferenceKey.self) { anchors in
                if isPresented, !items.isEmpty {
                    GeometryReader { geometry in
                        let safeAreaInsets   = geometry.safeAreaInsets
                        let safeIndex       = min(currentIndex, items.count - 1)
                        let currentItem     = items[safeIndex]
                        let anchorRect: CGRect? = anchors[currentItem.id].map { geometry[$0] }
                        let rectIsVisible   = anchorRect.map {
                            isRectVisible($0, in: geometry.size)
                        } ?? false
                        
                        ZStack {
                            spotlightOverlay(
                                anchorRect: (tipVisible && rectIsVisible) ? anchorRect : nil,
                                safeAreaInsets: safeAreaInsets,
                                in: geometry
                            )
                            .onTapGesture { }
                            
                            if tipVisible,
                               let rect = anchorRect,
                               rectIsVisible,
                               let tip  = currentTip
                            {
                                let adjusted = CGRect(
                                    x: rect.origin.x + safeAreaInsets.leading,
                                    y: rect.origin.y + safeAreaInsets.top,
                                    width: rect.width,
                                    height: rect.height
                                )
                                let fullH = geometry.size.height
                                + safeAreaInsets.top
                                + safeAreaInsets.bottom
                                
                                Color.clear
                                    .frame(width: adjusted.width, height: adjusted.height)
                                    .position(x: adjusted.midX, y: adjusted.midY)
                                    .popoverTip(tip, arrowEdge: arrowEdge(for: adjusted, screenHeight: fullH)) { action in
                                        handleTipAction(action.id, stepIndex: safeIndex)
                                    }
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
                    configureTipKitIfNeeded()
                    rebuildCurrentTip()
                    scrollToCurrentAnchor()
                } else {
                    dismissTip()
                }
            }
    }
    
    private func configureTipKitIfNeeded() {
        try? Tips.resetDatastore()
        try? Tips.configure([
            .displayFrequency(.immediate),
            .datastoreLocation(.applicationDefault)
        ])
    }
    
    private func rebuildCurrentTip() {
        guard currentIndex < items.count else { return }
        
        let item = items[currentIndex]
        currentTip = MDSCoachmarkStepTip(
            stepTitle:       item.tipTitle ?? "Step \(currentIndex + 1) of \(items.count)",
            stepDescription: item.tipDescription,
            stepIndex:       currentIndex,
            totalSteps:      items.count,
            showBackButton:  configuration.showBackButton,
            showExitButton:  configuration.showExitButton,
            backButtonLabel: configuration.backButtonLabel,
            nextButtonLabel: configuration.nextButtonLabel,
            finishButtonLabel: configuration.finishButtonLabel,
            exitButtonLabel: configuration.exitButtonLabel
        )
    }
    
    private func handleTipAction(_ actionId: String, stepIndex: Int) {
        switch actionId {
        case "next":
            goToNext()
        case "back":
            goToPrevious()
        case "skip":
            dismissTip()
            onSkipped?(stepIndex)
        case "finish":
            dismissTip()
            onFinished?()
        default:
            break
        }
    }
    
    private func goToNext() {
        currentTip?.invalidate(reason: .tipClosed)
        
        let next = min(currentIndex + 1, items.count - 1)
        if configuration.animateTransitions {
            withAnimation(.easeInOut(duration: 0.3)) { currentIndex = next }
        } else {
            currentIndex = next
        }
        
        // Reset tips datastore for the current tip to allow re-presentation
        Task { @MainActor in
            try? Tips.resetDatastore()
            rebuildCurrentTip()
            scrollToCurrentAnchor()
        }
    }
    
    private func goToPrevious() {
        currentTip?.invalidate(reason: .tipClosed)
        
        let prev = max(currentIndex - 1, 0)
        if configuration.animateTransitions {
            withAnimation(.easeInOut(duration: 0.3)) { currentIndex = prev }
        } else {
            currentIndex = prev
        }
        
        Task { @MainActor in
            try? Tips.resetDatastore()
            rebuildCurrentTip()
            scrollToCurrentAnchor()
        }
    }
    
    private func dismissTip() {
        currentTip?.invalidate(reason: .tipClosed)
        if configuration.animateTransitions {
            withAnimation(.easeInOut(duration: 0.2)) {
                isPresented  = false
                tipVisible   = false
                currentIndex = 0
            }
        } else {
            isPresented  = false
            tipVisible   = false
            currentIndex = 0
        }
        currentTip = nil
    }
    
    private func scrollToCurrentAnchor() {
        guard currentIndex < items.count else { return }
        
        isScrolling = true
        tipVisible  = false
        
        scrollManager.currentRequest = MDSCoachmarkScrollRequest(
            targetID: items[currentIndex].id,
            anchor:   configuration.scrollAnchor,
            token:    UUID()
        )
        
        DispatchQueue.main.asyncAfter(deadline: .now() + configuration.scrollSettleDelay) {
            isScrolling = false
            withAnimation(configuration.animateTransitions ? .easeInOut(duration: 0.25) : nil) {
                tipVisible = true
            }
        }
    }
    
    private func arrowEdge(for rect: CGRect, screenHeight: CGFloat) -> Edge {
        let spaceBelow = screenHeight - (rect.maxY + configuration.spotlightPadding)
        let spaceAbove = rect.minY - configuration.spotlightPadding
        return spaceBelow >= spaceAbove ? .top : .bottom
    }
    
    @ViewBuilder
    private func spotlightOverlay(
        anchorRect: CGRect?,
        safeAreaInsets: EdgeInsets,
        in geometry: GeometryProxy
    ) -> some View {
        let pad    = configuration.spotlightPadding
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
}

// MARK: - Legacy Coachmark Overlay (iOS 15/16)

private struct LegacyCoachmarkOverlay: View {
    let wrappedContent: AnyView
    @Binding var isPresented: Bool
    let items: [AnyMDSCoachmarkItem]
    let configuration: MDSCoachmarkConfiguration
    let onFinished: (() -> Void)?
    let onSkipped: ((Int) -> Void)?
    let scrollManager: MDSCoachmarkScrollRequestManager
    
    @State private var currentIndex: Int = 0
    @State private var isScrolling: Bool  = false
    @State private var tipVisible: Bool   = false
    
    var body: some View {
        wrappedContent
            .overlayPreferenceValue(MDSCoachmarkAnchorPreferenceKey.self) { anchors in
                if isPresented, !items.isEmpty {
                    GeometryReader { geometry in
                        let safeAreaInsets  = geometry.safeAreaInsets
                        let safeIndex       = min(currentIndex, items.count - 1)
                        let currentItem     = items[safeIndex]
                        let anchorRect: CGRect? = anchors[currentItem.id].map { geometry[$0] }
                        let rectIsVisible   = anchorRect.map {
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
        isScrolling = true
        tipVisible  = false
        
        scrollManager.currentRequest = MDSCoachmarkScrollRequest(
            targetID: items[currentIndex].id,
            anchor:   configuration.scrollAnchor,
            token:    UUID()
        )
        
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
        let pad    = configuration.spotlightPadding
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
        for item: AnyMDSCoachmarkItem,
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
        let fullH  = geometry.size.height + safeAreaInsets.top    + safeAreaInsets.bottom
        let fullW  = geometry.size.width  + safeAreaInsets.leading + safeAreaInsets.trailing
        let below  = shouldShowBelow(anchorRect: adjusted, screenHeight: fullH)
        let isFirst = stepIndex == 0
        let isLast  = stepIndex == items.count - 1
        
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
                
                tipCardContent(for: item, stepIndex: stepIndex, totalSteps: items.count, isFirst: isFirst, isLast: isLast)
                    .padding(.horizontal, configuration.tipHorizontalPadding)
                    .padding(.vertical,   configuration.tipVerticalPadding)
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
    private func tipCardContent(
        for item: AnyMDSCoachmarkItem,
        stepIndex: Int,
        totalSteps: Int,
        isFirst: Bool,
        isLast: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            item.contentView.frame(maxWidth: .infinity, alignment: .leading)
            Divider()
            
            HStack {
                Text("\(stepIndex + 1) of \(totalSteps)")
                    .font(.caption).foregroundColor(.secondary)
                Spacer()
                
                if configuration.showExitButton && !isLast {
                    Button { dismiss(); onSkipped?(stepIndex) } label: {
                        Text(configuration.exitButtonLabel).font(.subheadline).foregroundColor(.secondary)
                    }.padding(.trailing, 8)
                }
                
                if configuration.showBackButton && !isFirst {
                    Button { goToPrevious() } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left").font(.caption.bold())
                            Text(configuration.backButtonLabel).font(.subheadline.bold())
                        }.foregroundColor(configuration.accentColor)
                    }.padding(.trailing, 4)
                }
                
                Button {
                    if isLast { dismiss(); onFinished?() } else { goToNext() }
                } label: {
                    HStack(spacing: 4) {
                        Text(isLast ? configuration.finishButtonLabel : configuration.nextButtonLabel)
                            .font(.subheadline.bold())
                        if !isLast { Image(systemName: "chevron.right").font(.caption.bold()) }
                    }
                    .foregroundColor(isLast ? .white : configuration.accentColor)
                    .padding(.horizontal, isLast ? 16 : 0)
                    .padding(.vertical,   isLast ?  6 : 0)
                    .background(Group { if isLast { Capsule().fill(configuration.accentColor) } })
                }
            }
        }
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
        case .top:  return false
        case .bottom: return true
        case .automatic:
            let spaceAbove = anchorRect.minY - configuration.spotlightPadding
            let spaceBelow = screenHeight - anchorRect.maxY - configuration.spotlightPadding
            let min: CGFloat = 120
            if spaceBelow >= min { return true }
            if spaceAbove >= min { return false }
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

// MARK: - Triangle Shape

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
                        .onAppear {
                            tipSize = tipGeometry.size
                        }
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

// MARK: - Coachmark Overlay Modifier (Dispatcher)

struct MDSCoachmarkOverlayModifier: ViewModifier {
    @Binding var isPresented: Bool
    let items: [AnyMDSCoachmarkItem]
    let configuration: MDSCoachmarkConfiguration
    let onFinished: (() -> Void)?
    let onSkipped: ((Int) -> Void)?
    
    @Environment(\.coachmarkScrollManager) private var scrollManager
    
    func body(content: Content) -> some View {
        if #available(iOS 17.0, *) {
            iOS17CoachmarkOverlay(
                wrappedContent:  AnyView(content),
                isPresented:     $isPresented,
                items:           items,
                configuration:   configuration,
                onFinished:      onFinished,
                onSkipped:       onSkipped,
                scrollManager:   scrollManager
            )
        } else {
            LegacyCoachmarkOverlay(
                wrappedContent:  AnyView(content),
                isPresented:     $isPresented,
                items:           items,
                configuration:   configuration,
                onFinished:      onFinished,
                onSkipped:       onSkipped,
                scrollManager:   scrollManager
            )
        }
    }
}

// MARK: - View Extension for Presenting Coachmarks

public extension View {
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
