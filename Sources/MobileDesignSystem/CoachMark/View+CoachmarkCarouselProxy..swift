import SwiftUI

// ═══════════════════════════════════════════════════════════════════
// MARK: - Public Modifiers
// ═══════════════════════════════════════════════════════════════════

public extension View {

    /// Marks this view as a coachmark anchor.
    ///
    /// On **every** iOS version it publishes anchor geometry.
    /// On **iOS 18+** it also attaches a TipKit popover when this
    /// step is current. The consumer never writes a version check.
    func coachmarkAnchor(_ id: String) -> some View {
        self
            .id(id)
            .anchorPreference(
                key: MDSCoachmarkAnchorPreferenceKey.self,
                value: .bounds
            ) { [id: $0] }
            .modifier(MDSCoachmarkAnchorTipKitBridge(anchorID: id))
    }

    /// Presents the coachmark tour.
    ///
    /// Internally dispatches to TipKit (iOS 18+) or the legacy custom
    /// overlay (iOS 15–17).
    func coachmarkOverlay(
        isPresented: Binding<Bool>,
        configuration: MDSCoachmarkConfiguration = MDSCoachmarkConfiguration(),
        items: [MDSCoachmarkItem],
        scrollCoordinator: MDSCoachmarkScrollCoordinator? = nil,
        onFinished: (() -> Void)? = nil,
        onSkipped: ((Int) -> Void)? = nil
    ) -> some View {
        modifier(
            MDSCoachmarkUnifiedOverlayModifier(
                isPresented: isPresented,
                items: items,
                configuration: configuration,
                scrollCoordinator: scrollCoordinator,
                onFinished: onFinished,
                onSkipped: onSkipped
            )
        )
    }

    // MARK: Scroll-proxy helpers (API unchanged)

    func coachmarkScrollableProxy(
        _ name: String,
        proxy: any CoachmarkScrollableProxy,
        coordinator: MDSCoachmarkScrollCoordinator
    ) -> some View {
        let containerID = MDSCoachmarkScrollCoordinator.defaultContainerID(for: name)
        return self
            .id(containerID)
            .onAppear   { coordinator.register(name, proxy: proxy) }
            .onDisappear { coordinator.unregister(name) }
    }

    func coachmarkScrollProxy(
        _ name: String,
        proxy: ScrollViewProxy,
        coordinator: MDSCoachmarkScrollCoordinator
    ) -> some View {
        coachmarkScrollableProxy(
            name,
            proxy: ScrollViewCoachmarkProxy(proxy),
            coordinator: coordinator
        )
    }

    func coachmarkCarouselProxy(
        _ name: String,
        proxy: CarouselScrollProxy,
        coordinator: MDSCoachmarkScrollCoordinator
    ) -> some View {
        coachmarkScrollableProxy(name, proxy: proxy, coordinator: coordinator)
    }

    func coachmarkParent(_ id: String) -> some View {
        self.id(id)
    }
}

// ═══════════════════════════════════════════════════════════════════
// MARK: - Unified Overlay Modifier (version dispatch)
// ═══════════════════════════════════════════════════════════════════

private struct MDSCoachmarkUnifiedOverlayModifier: ViewModifier {

    @Binding var isPresented: Bool
    let items: [MDSCoachmarkItem]
    let configuration: MDSCoachmarkConfiguration
    let scrollCoordinator: MDSCoachmarkScrollCoordinator?
    let onFinished: (() -> Void)?
    let onSkipped: ((Int) -> Void)?

    func body(content: Content) -> some View {
        if #available(iOS 18.0, *) {
            #if canImport(TipKit)
            content.modifier(
                MDSTipKitOverlayModifier(
                    isPresented: $isPresented,
                    items: items,
                    configuration: configuration,
                    scrollCoordinator: scrollCoordinator,
                    onFinished: onFinished,
                    onSkipped: onSkipped
                )
            )
            #else
            legacyOverlay(content: content)
            #endif
        } else {
            legacyOverlay(content: content)
        }
    }

    @ViewBuilder
    private func legacyOverlay(content: Content) -> some View {
        content.modifier(
            MDSCoachmarkOverlayModifier(
                isPresented: $isPresented,
                items: items,
                configuration: configuration,
                scrollCoordinator: scrollCoordinator,
                onFinished: onFinished,
                onSkipped: onSkipped
            )
        )
    }
}

// ═══════════════════════════════════════════════════════════════════
// MARK: - Anchor TipKit Bridge (all-iOS shell)
// ═══════════════════════════════════════════════════════════════════

/// Applied by every `.coachmarkAnchor()` call. On iOS 18+ it hands off
/// to the TipKit popover layer. On older targets it is a no-op.
private struct MDSCoachmarkAnchorTipKitBridge: ViewModifier {

    let anchorID: String
    @Environment(\.mdsTipKitCoordinator) private var coordinatorBox

    func body(content: Content) -> some View {
        if #available(iOS 18.0, *) {
            #if canImport(TipKit)
            content.modifier(
                MDSTipKitAnchorConnector(
                    anchorID: anchorID,
                    coordinatorBox: coordinatorBox
                )
            )
            #else
            content
            #endif
        } else {
            content
        }
    }
}

// ═══════════════════════════════════════════════════════════════════
// MARK: - TipKit Anchor Connector / Popover (iOS 18+)
// ═══════════════════════════════════════════════════════════════════

#if canImport(TipKit)
import TipKit

/// Resolves the coordinator reference and hands off to the popover
/// modifier so it can observe published changes.
@available(iOS 18.0, *)
private struct MDSTipKitAnchorConnector: ViewModifier {

    let anchorID: String
    let coordinatorBox: MDSCoachmarkCoordinatorBox

    func body(content: Content) -> some View {
        if let coordinator = coordinatorBox.ref as? MDSTipKitTourCoordinator {
            content.modifier(
                MDSTipKitAnchorPopover(anchorID: anchorID,
                                       coordinator: coordinator)
            )
        } else {
            content
        }
    }
}

/// Attaches the `TipGroup`'s current tip to this anchor when this anchor
/// is the active step. The group handles ordering; the `showCurrent`
/// rule handles hide-during-scroll; the `isActiveAnchor` check ensures
/// the popover appears on the correct view.
@available(iOS 18.0, *)
private struct MDSTipKitAnchorPopover: ViewModifier {

    let anchorID: String
    @ObservedObject var coordinator: MDSTipKitTourCoordinator

    private var isActiveAnchor: Bool {
        coordinator.isActive
            && coordinator.currentItem?.id == anchorID
    }

    func body(content: Content) -> some View {
        if isActiveAnchor, let group = coordinator.tipGroup {
            content
                .popoverTip(group.currentTip, arrowEdge: .bottom)
        } else {
            content
        }
    }
}
#endif
