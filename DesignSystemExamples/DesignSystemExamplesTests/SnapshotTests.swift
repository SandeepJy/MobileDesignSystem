import Testing
import SwiftUI
import SnapshotTesting
@testable import MobileDesignSystem

// MARK: - Snapshot: Coachmark Progression

/// Snapshot-tests the full coachmark tour progression using the Point-Free library.
///
/// We drive progression by rendering the `MDSCoachmarkTipContentView` directly at each
/// step. This is the canonical visual contract users see — button configuration, step
/// counter, icon, and copy — without depending on async scrolling or anchor geometry.
///
/// A dedicated host view verifies the overlay + spotlight cutout end-to-end.
@MainActor
@Suite("MDSCoachmark Snapshots", .snapshots(record: .missing))
struct MDSCoachmarkSnapshotTests {

    // MARK: - Fixtures

    private let config = MDSCoachmarkConfiguration(
        overlayColor: .black.opacity(0.75),
        spotlightBorderColor: .green,
        spotlightBorderWidth: 2,
        tooltipBorderColor: .green,
        tooltipBorderWidth: 2,
        showExitButton: true,
        tipCornerRadius: 12
    )

    private let tourItems: [MDSCoachmarkItem] = [
        MDSCoachmarkItem(
            id: "welcome",
            title: "Welcome",
            description: "This tour will walk you through the main features.",
            iconName: "hand.wave.fill"
        ),
        MDSCoachmarkItem(
            id: "inbox",
            title: "Your Inbox",
            description: "All your messages live here. Swipe to archive.",
            iconName: "tray.fill",
            iconColor: .orange
        ),
        MDSCoachmarkItem(
            id: "settings",
            title: "Settings",
            description: "Customize your experience.",
            iconName: "gearshape.fill"
        ),
    ]

    // MARK: - Helpers

    /// Wraps the tip content in a fixed-size container so snapshots are deterministic.
    private func tipHost(stepIndex: Int) -> some View {
        MDSCoachmarkTipContentView(
            item: tourItems[stepIndex],
            stepIndex: stepIndex,
            totalSteps: tourItems.count,
            isFirst: stepIndex == 0,
            isLast: stepIndex == tourItems.count - 1,
            configuration: config,
            onBack: {}, onNext: {}, onSkip: {}, onFinish: {}
        )
        .padding(16)
        .frame(width: 360)
        .background(Color.white)
        .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: - Progression Snapshots

    /// Step 0: Skip shown, Back hidden, Next shown (not Done).
    @Test("tour progression — step 1 of 3 (first)")
    func snapshot_step1_first() {
        assertSnapshot(
            of: tipHost(stepIndex: 0),
            as: .image(layout: .sizeThatFits),
            named: "step-1-first"
        )
    }

    /// Step 1: Skip shown, Back shown, Next shown.
    @Test("tour progression — step 2 of 3 (middle)")
    func snapshot_step2_middle() {
        assertSnapshot(
            of: tipHost(stepIndex: 1),
            as: .image(layout: .sizeThatFits),
            named: "step-2-middle"
        )
    }

    /// Step 2: Skip hidden, Back shown, Done capsule shown.
    @Test("tour progression — step 3 of 3 (last)")
    func snapshot_step3_last() {
        assertSnapshot(
            of: tipHost(stepIndex: 2),
            as: .image(layout: .sizeThatFits),
            named: "step-3-last"
        )
    }

    // MARK: - Single Step Tour

    /// A one-item tour should render with no Skip, no Back, Done only.
    @Test("single-step tour renders only the Done button")
    func snapshot_singleStepTour() {
        let view = MDSCoachmarkTipContentView(
            item: tourItems[0],
            stepIndex: 0,
            totalSteps: 1,
            isFirst: true,
            isLast: true,
            configuration: config,
            onBack: {}, onNext: {}, onSkip: {}, onFinish: {}
        )
        .padding(16)
        .frame(width: 360)
        .background(Color.white)

        assertSnapshot(
            of: view,
            as: .image(layout: .sizeThatFits),
            named: "single-step-done-only"
        )
    }

    // MARK: - Exit Button Configuration

    @Test("showExitButton = false hides the Skip button on non-final steps")
    func snapshot_skipHidden() {
        let noSkipConfig = MDSCoachmarkConfiguration(showExitButton: false)
        let view = MDSCoachmarkTipContentView(
            item: tourItems[1],
            stepIndex: 1,
            totalSteps: tourItems.count,
            isFirst: false,
            isLast: false,
            configuration: noSkipConfig,
            onBack: {}, onNext: {}, onSkip: {}, onFinish: {}
        )
        .padding(16)
        .frame(width: 360)
        .background(Color.white)

        assertSnapshot(
            of: view,
            as: .image(layout: .sizeThatFits),
            named: "skip-hidden-middle"
        )
    }

    // MARK: - Content Variations

    @Test("item without icon renders in text-only arrangement")
    func snapshot_noIcon() {
        let item = MDSCoachmarkItem(
            id: "plain",
            title: "No Icon Here",
            description: "This tip has no icon and should align text only."
        )
        let view = MDSCoachmarkTipContentView(
            item: item, stepIndex: 0, totalSteps: 2,
            isFirst: true, isLast: false,
            configuration: config,
            onBack: {}, onNext: {}, onSkip: {}, onFinish: {}
        )
        .padding(16)
        .frame(width: 360)
        .background(Color.white)

        assertSnapshot(
            of: view,
            as: .image(layout: .sizeThatFits),
            named: "no-icon"
        )
    }

    @Test("item without description renders title-only content")
    func snapshot_noDescription() {
        let item = MDSCoachmarkItem(
            id: "short",
            title: "Just a Title",
            iconName: "star.fill"
        )
        let view = MDSCoachmarkTipContentView(
            item: item, stepIndex: 0, totalSteps: 2,
            isFirst: true, isLast: false,
            configuration: config,
            onBack: {}, onNext: {}, onSkip: {}, onFinish: {}
        )
        .padding(16)
        .frame(width: 360)
        .background(Color.white)

        assertSnapshot(
            of: view,
            as: .image(layout: .sizeThatFits),
            named: "no-description"
        )
    }

    @Test("long description wraps correctly and grows vertically")
    func snapshot_longDescription() {
        let item = MDSCoachmarkItem(
            id: "long",
            title: "A Longer Title For Wrapping",
            description: """
                This is a deliberately long description intended to exercise \
                multi-line text wrapping inside the tooltip. It should expand \
                vertically while respecting the fixed horizontal width, and the \
                navigation bar should remain anchored at the bottom.
                """,
            iconName: "text.alignleft"
        )
        let view = MDSCoachmarkTipContentView(
            item: item, stepIndex: 1, totalSteps: 3,
            isFirst: false, isLast: false,
            configuration: config,
            onBack: {}, onNext: {}, onSkip: {}, onFinish: {}
        )
        .padding(16)
        .frame(width: 320)
        .background(Color.white)

        assertSnapshot(
            of: view,
            as: .image(layout: .sizeThatFits),
            named: "long-description-wraps"
        )
    }

    // MARK: - Full Overlay (spotlight + tooltip)

    /// Host view with three anchors stacked vertically. We present the overlay
    /// already visible so the first step snapshot captures the spotlight cutout,
    /// tooltip, and border styling end-to-end.
    private struct OverlayHost: View {
        @State var isPresented = true

        var body: some View {
            VStack(spacing: 60) {
                label("Top",    id: "welcome")
                label("Middle", id: "inbox")
                label("Bottom", id: "settings")
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(white: 0.92))
            .coachmarkOverlay(
                isPresented: $isPresented,
                configuration: MDSCoachmarkConfiguration(
                    overlayColor: .black.opacity(0.7),
                    spotlightBorderColor: .green,
                    spotlightBorderWidth: 2,
                    tooltipBorderColor: .green,
                    tooltipBorderWidth: 2,
                    scrollSettleDelay: 0,
                    scrollInterStepDelay: 0,
                    proxyWaitTimeout: 0
                ),
                items: [
                    MDSCoachmarkItem(
                        id: "welcome", title: "Welcome",
                        description: "Spotlight on the top element.",
                        iconName: "hand.wave.fill"
                    ),
                    MDSCoachmarkItem(
                        id: "inbox", title: "Inbox",
                        description: "Middle anchor.", iconName: "tray.fill"
                    ),
                    MDSCoachmarkItem(
                        id: "settings", title: "Settings",
                        description: "Bottom anchor.", iconName: "gearshape.fill"
                    ),
                ]
            )
        }

        @ViewBuilder
        private func label(_ text: String, id: String) -> some View {
            Text(text)
                .font(.headline)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.white)
                .cornerRadius(8)
                .coachmarkAnchor(id)
        }
    }

    /// The overlay has an internal ~100ms settle delay before `tipVisible` flips on.
    /// We wait past that before snapshotting so the spotlight + tooltip are rendered.
    @Test("overlay presents with spotlight cutout and tooltip on first step")
    func snapshot_overlayFirstStep() async throws {
        let host = OverlayHost()
        let controller = UIHostingController(rootView: host)
        controller.view.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
        controller.view.layoutIfNeeded()

        // Wait past the 100ms onAppear settle + one render pass.
        try await Task.sleep(for: .milliseconds(250))

        assertSnapshot(
            of: controller,
            as: .image(on: .iPhone13),
            named: "overlay-step-1"
        )
    }
}
