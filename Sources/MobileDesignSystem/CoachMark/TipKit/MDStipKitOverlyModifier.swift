#if canImport(TipKit)
import SwiftUI
import TipKit

/// iOS 18+ overlay: injects the coordinator into the environment,
/// applies the custom ``MDSCoachmarkTipViewStyle``, and draws the
/// spotlight canvas. Individual anchors read the coordinator and
/// attach `.popoverTip(group.currentTip)` when they are the active step.
@available(iOS 18.0, *)
struct MDSTipKitOverlayModifier: ViewModifier {

    @Binding var isPresented: Bool
    let items: [MDSCoachmarkItem]
    let configuration: MDSCoachmarkConfiguration
    let scrollCoordinator: MDSCoachmarkScrollCoordinator?
    let onFinished: (() -> Void)?
    let onSkipped: ((Int) -> Void)?

    @StateObject private var coordinator = MDSTipKitTourCoordinator()

    func body(content: Content) -> some View {
        content
            .environment(\.mdsTipKitCoordinator,
                         MDSCoachmarkCoordinatorBox(ref: coordinator))
            .tipViewStyle(MDSCoachmarkTipViewStyle())
            .overlayPreferenceValue(MDSCoachmarkAnchorPreferenceKey.self) { anchors in
                spotlightOverlay(anchors: anchors)
            }
            .onAppear { if isPresented { startTour() } }
            .onChange(of: isPresented) { _, newValue in
                if newValue { startTour() } else if coordinator.isActive { coordinator.dismiss() }
            }
            .onChange(of: coordinator.isActive) { _, active in
                if !active && isPresented { isPresented = false }
            }
    }

    // MARK: Start

    private func startTour() {
        coordinator.configure(
            items: items,
            configuration: configuration,
            scrollCoordinator: scrollCoordinator,
            onFinished: { [self] in
                isPresented = false
                onFinished?()
            },
            onSkipped: { [self] idx in
                isPresented = false
                onSkipped?(idx)
            }
        )
        coordinator.start()
    }

    // MARK: Spotlight

    @ViewBuilder
    private func spotlightOverlay(anchors: [String: Anchor<CGRect>]) -> some View {
        if coordinator.isActive, coordinator.tipReady, let item = coordinator.currentItem {
            GeometryReader { geo in
                let sa = geo.safeAreaInsets
                let rect: CGRect? = anchors[item.id].map { geo[$0] }
                spotlightCanvas(anchorRect: rect, safeArea: sa)
            }
            .ignoresSafeArea()
            .animation(
                MDSCoachmarkConstants.animateTransitions
                    ? .easeInOut(duration: 0.25) : nil,
                value: coordinator.currentStepIndex
            )
        }
    }

    @ViewBuilder
    private func spotlightCanvas(
        anchorRect: CGRect?,
        safeArea: EdgeInsets
    ) -> some View {
        let pad    = MDSCoachmarkConstants.spotlightPadding
        let radius = MDSCoachmarkConstants.spotlightCornerRadius

        Canvas { ctx, size in
            ctx.fill(Path(CGRect(origin: .zero, size: size)),
                     with: .color(configuration.overlayColor))
            if let rect = anchorRect {
                let adj = CGRect(x: rect.minX + safeArea.leading,
                                 y: rect.minY + safeArea.top,
                                 width: rect.width, height: rect.height)
                let spot = adj.insetBy(dx: -pad, dy: -pad)
                ctx.blendMode = .destinationOut
                ctx.fill(Path(roundedRect: spot, cornerRadius: radius),
                         with: .color(.white))
            }
        }
        .compositingGroup()
        .allowsHitTesting(configuration.isBlocking)
        .overlay {
            if let rect = anchorRect, configuration.spotlightBorderWidth > 0 {
                let adj = CGRect(x: rect.minX + safeArea.leading,
                                 y: rect.minY + safeArea.top,
                                 width: rect.width, height: rect.height)
                let spot = adj.insetBy(dx: -pad, dy: -pad)
                RoundedRectangle(cornerRadius: radius)
                    .stroke(configuration.spotlightBorderColor,
                            lineWidth: configuration.spotlightBorderWidth)
                    .frame(width: spot.width, height: spot.height)
                    .position(x: spot.midX, y: spot.midY)
                    .allowsHitTesting(false)
            }
        }
        .onTapGesture {
            guard configuration.isBlocking,
                  configuration.dismissOnOverlayTap else { return }
            coordinator.skip()
        }
    }
}
#endif
