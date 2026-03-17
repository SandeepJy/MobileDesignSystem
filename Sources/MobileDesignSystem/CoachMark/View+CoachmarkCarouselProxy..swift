import SwiftUI

// ═══════════════════════════════════════════════════════════════════
// MARK: - Public Modifiers
// ═══════════════════════════════════════════════════════════════════

public extension View {

    /// Marks this view as a coachmark anchor.
    ///
    /// On **every** iOS version it publishes anchor geometry via
    /// `MDSCoachmarkAnchorPreferenceKey`. On **iOS 18+** it also
    /// attaches a TipKit `.popoverTip()` when the tour is active.
    /// On older targets the legacy overlay handles tooltip rendering.
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
    /// | OS Version | Implementation |
    /// |---|---|
    /// | iOS 15–17.x | Legacy custom overlay (full back-navigation) |
    /// | iOS 18+ | TipKit `TipGroup(.ordered)` overlay |
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

    // MARK: Scroll-proxy helpers

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

/// Applied by every `.coachmarkAnchor()` call. On iOS 18+ it attaches
/// a `.popoverTip()` driven by the `TipGroup`. On older targets it is
/// a no-op — the legacy overlay handles tooltip rendering directly.
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

/// Attaches `.popoverTip()` when the tour is active and `tipReady` is
/// `true`. The `TipGroup(.ordered)` decides which tip is eligible — only
/// the current group tip will present its popover.
///
/// Gating on `tipReady` lets the coordinator remove all popovers during
/// scroll transitions (by setting `tipReady = false`), then re-attach
/// them after the scroll settles and the previous tip is invalidated.
@available(iOS 18.0, *)
private struct MDSTipKitAnchorPopover: ViewModifier {

    let anchorID: String
    @ObservedObject var coordinator: MDSTipKitTourCoordinator

    func body(content: Content) -> some View {
        let _ = print("debug: coordinator is active \(coordinator.isActive), tipReady \(coordinator.tipReady), tip: \(coordinator.tip(forAnchor: anchorID)?.id ?? "nil")")
        if coordinator.isActive,
           coordinator.tipReady,
           let tip = coordinator.tip(forAnchor: anchorID) {
            let _ = print ("in MDStipkitanchorpopover")
            content
                .popoverTip(tip, arrowEdge: .bottom)
        } else {
            content
        }
    }
}
#endif
