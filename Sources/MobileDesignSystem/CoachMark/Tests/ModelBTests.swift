import Testing
import SwiftUI
@testable import YourModule

// MARK: - Scroll Coordinator Logic Tests

@MainActor
@Suite("MDSCoachmarkScrollCoordinator")
struct MDSCoachmarkScrollCoordinatorTests {

    // MARK: - Helpers

    /// Records every invocation a registered proxy receives so we can assert
    /// on call order, resolved target IDs, and anchor points.
    final class ScrollRecorder {
        struct Invocation: Equatable {
            let proxy: String
            let target: String
            let anchor: UnitPoint
        }
        private(set) var invocations: [Invocation] = []

        func record(proxy: String, target: String, anchor: UnitPoint) {
            invocations.append(.init(proxy: proxy, target: target, anchor: anchor))
        }

        var targets: [String] { invocations.map(\.target) }
        var proxies: [String] { invocations.map(\.proxy) }
    }

    /// Registers a proxy that pipes every scroll request into the recorder.
    private func register(
        _ name: String,
        on coordinator: MDSCoachmarkScrollCoordinator,
        recorder: ScrollRecorder
    ) {
        coordinator.register(name) { target, anchor in
            recorder.record(proxy: name, target: target, anchor: anchor)
        }
    }

    /// Awaits `scrollSequentially` by bridging its completion callback.
    private func runSequence(
        coordinator: MDSCoachmarkScrollCoordinator,
        targetID: String,
        steps: [MDSCoachmarkScrollStep],
        anchor: UnitPoint = .center,
        animated: Bool = false,
        interStepDelay: TimeInterval = 0.01,
        proxyWaitTimeout: TimeInterval = 0.2
    ) async {
        await withCheckedContinuation { continuation in
            coordinator.scrollSequentially(
                targetID: targetID,
                steps: steps,
                anchor: anchor,
                animated: animated,
                interStepDelay: interStepDelay,
                proxyWaitTimeout: proxyWaitTimeout
            ) {
                continuation.resume()
            }
        }
    }

    // MARK: - Container ID

    @Test("defaultContainerID produces the documented deterministic format")
    func defaultContainerIDFormat() {
        #expect(
            MDSCoachmarkScrollCoordinator.defaultContainerID(for: "main")
                == "__mds_coachmark_container_main"
        )
        #expect(
            MDSCoachmarkScrollCoordinator.defaultContainerID(for: "carousel-15")
                == "__mds_coachmark_container_carousel-15"
        )
    }

    // MARK: - Registration Lifecycle

    @Test("registering and unregistering toggles hasRegisteredProxies")
    func registrationLifecycle() {
        let sut = MDSCoachmarkScrollCoordinator()
        #expect(sut.hasRegisteredProxies == false)

        sut.register("main") { _, _ in }
        #expect(sut.hasRegisteredProxies == true)

        sut.unregister("main")
        #expect(sut.hasRegisteredProxies == false)
    }

    @Test("re-registering a proxy replaces the stored action")
    func reregistrationReplacesAction() async {
        let sut = MDSCoachmarkScrollCoordinator()
        var firstFired = false
        var secondFired = false

        sut.register("main") { _, _ in firstFired = true }
        sut.register("main") { _, _ in secondFired = true } // overwrite

        await runSequence(
            coordinator: sut,
            targetID: "anchor",
            steps: [.init(proxy: "main")]
        )

        #expect(firstFired == false)
        #expect(secondFired == true)
    }

    // MARK: - Empty / Guard Paths

    @Test("empty step list invokes completion immediately without any scroll")
    func emptyStepsCompleteImmediately() async {
        let sut = MDSCoachmarkScrollCoordinator()
        let recorder = ScrollRecorder()
        register("main", on: sut, recorder: recorder)

        await runSequence(coordinator: sut, targetID: "anchor", steps: [])

        #expect(recorder.invocations.isEmpty)
    }

    @Test("unregistered proxy is skipped after timeout but completion still fires")
    func unregisteredProxyIsSkipped() async {
        let sut = MDSCoachmarkScrollCoordinator()
        let recorder = ScrollRecorder()
        // "inner" is registered, "outer" is not.
        register("inner", on: sut, recorder: recorder)

        await runSequence(
            coordinator: sut,
            targetID: "anchor",
            steps: [
                .init(proxy: "outer"), // never registers → skipped after timeout
                .init(proxy: "inner")
            ],
            proxyWaitTimeout: 0.1
        )

        // Only the inner proxy fires; it's the last step so it scrolls to targetID.
        #expect(recorder.invocations.count == 1)
        #expect(recorder.invocations.first?.proxy == "inner")
        #expect(recorder.invocations.first?.target == "anchor")
    }

    // MARK: - Target Resolution (core logic table from the docs)

    @Test("single step: proxy scrolls directly to the item's target ID")
    func singleStepScrollsToTargetID() async {
        let sut = MDSCoachmarkScrollCoordinator()
        let recorder = ScrollRecorder()
        register("main", on: sut, recorder: recorder)

        await runSequence(
            coordinator: sut,
            targetID: "settings-button",
            steps: [.init(proxy: "main")]
        )

        #expect(recorder.targets == ["settings-button"])
    }

    @Test("intermediate step with nil parentID auto-infers next proxy's container ID")
    func intermediateStepAutoInfersContainerID() async {
        let sut = MDSCoachmarkScrollCoordinator()
        let recorder = ScrollRecorder()
        register("outer", on: sut, recorder: recorder)
        register("inner", on: sut, recorder: recorder)

        await runSequence(
            coordinator: sut,
            targetID: "card-6",
            steps: [
                .init(proxy: "outer"), // nil parentID → auto-infer
                .init(proxy: "inner")
            ]
        )

        let expectedContainer = MDSCoachmarkScrollCoordinator
            .defaultContainerID(for: "inner")

        #expect(recorder.targets == [expectedContainer, "card-6"])
    }

    @Test("intermediate step with explicit parentID uses that value verbatim")
    func intermediateStepUsesExplicitParentID() async {
        let sut = MDSCoachmarkScrollCoordinator()
        let recorder = ScrollRecorder()
        register("main", on: sut, recorder: recorder)
        register("carousel-15", on: sut, recorder: recorder)

        await runSequence(
            coordinator: sut,
            targetID: "carousel-15-card-6",
            steps: [
                .init(proxy: "main", parentID: "carousel-15-parent"),
                .init(proxy: "carousel-15")
            ]
        )

        #expect(recorder.targets == ["carousel-15-parent", "carousel-15-card-6"])
    }

    @Test("last step always uses targetID even when parentID is set")
    func lastStepIgnoresParentID() async {
        let sut = MDSCoachmarkScrollCoordinator()
        let recorder = ScrollRecorder()
        register("main", on: sut, recorder: recorder)

        await runSequence(
            coordinator: sut,
            targetID: "final-anchor",
            steps: [.init(proxy: "main", parentID: "ignored-parent")]
        )

        #expect(recorder.targets == ["final-anchor"])
    }

    @Test("three-level chain mixes explicit parentID and auto-inference correctly")
    func threeLevelChainResolution() async {
        let sut = MDSCoachmarkScrollCoordinator()
        let recorder = ScrollRecorder()
        register("outer", on: sut, recorder: recorder)
        register("middle", on: sut, recorder: recorder)
        register("inner", on: sut, recorder: recorder)

        await runSequence(
            coordinator: sut,
            targetID: "deep-target",
            steps: [
                .init(proxy: "outer", parentID: "middle-row"), // explicit
                .init(proxy: "middle"),                        // auto-infer → inner container
                .init(proxy: "inner")                          // → deep-target
            ]
        )

        let innerContainer = MDSCoachmarkScrollCoordinator
            .defaultContainerID(for: "inner")

        #expect(recorder.targets == ["middle-row", innerContainer, "deep-target"])
    }

    // MARK: - Ordering

    @Test("steps fire strictly in array order (outermost → innermost)")
    func stepsFireInOrder() async {
        let sut = MDSCoachmarkScrollCoordinator()
        let recorder = ScrollRecorder()
        register("a", on: sut, recorder: recorder)
        register("b", on: sut, recorder: recorder)
        register("c", on: sut, recorder: recorder)

        await runSequence(
            coordinator: sut,
            targetID: "x",
            steps: [.init(proxy: "a"), .init(proxy: "b"), .init(proxy: "c")]
        )

        #expect(recorder.proxies == ["a", "b", "c"])
    }

    @Test("anchor point is forwarded to every proxy unchanged")
    func anchorPointPropagation() async {
        let sut = MDSCoachmarkScrollCoordinator()
        let recorder = ScrollRecorder()
        register("main", on: sut, recorder: recorder)
        register("inner", on: sut, recorder: recorder)

        await runSequence(
            coordinator: sut,
            targetID: "x",
            steps: [.init(proxy: "main"), .init(proxy: "inner")],
            anchor: .topLeading
        )

        #expect(recorder.invocations.allSatisfy { $0.anchor == .topLeading })
    }

    // MARK: - Lazy Proxy Registration (polling)

    @Test(
        "coordinator polls and picks up a proxy that registers mid-sequence",
        .timeLimit(.minutes(1))
    )
    func lazyProxyPolling() async {
        let sut = MDSCoachmarkScrollCoordinator()
        let recorder = ScrollRecorder()

        // Outer proxy is available immediately.
        register("outer", on: sut, recorder: recorder)

        // Simulate lazy content: inner proxy registers only *after* the
        // outer scroll fires (mimicking LazyVStack rendering).
        sut.register("outer") { target, anchor in
            recorder.record(proxy: "outer", target: target, anchor: anchor)
            // Register inner asynchronously as if the lazy view just appeared.
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 50_000_000) // 50ms
                sut.register("inner") { t, a in
                    recorder.record(proxy: "inner", target: t, anchor: a)
                }
            }
        }

        await runSequence(
            coordinator: sut,
            targetID: "lazy-anchor",
            steps: [
                .init(proxy: "outer", parentID: "lazy-row"),
                .init(proxy: "inner")
            ],
            interStepDelay: 0.01,
            proxyWaitTimeout: 1.0
        )

        #expect(recorder.proxies == ["outer", "inner"])
        #expect(recorder.targets == ["lazy-row", "lazy-anchor"])
    }
}


import Testing
import SwiftUI
@testable import YourModule

@Suite("MDSCoachmarkItem")
struct MDSCoachmarkItemTests {

    // MARK: - Builder / Modifier Semantics

    @Test("modifier methods return a copy without mutating the original")
    func modifiersAreValueSemantics() {
        let original = MDSCoachmarkItem(id: "a", title: "A")
        let modified = original
            .arrowAlignment(.trailing)
            .arrowOffset(20)

        // Original must remain untouched (value-type builder semantics).
        #expect(original.arrowAlignment == .auto)
        #expect(original.arrowOffset == 0)
        #expect(modified.arrowAlignment == .trailing)
        #expect(modified.arrowOffset == 20)
    }

    @Test("callback modifiers are independent — attaching one does not clear others")
    func callbackModifierIndependence() {
        var appearFired = false
        var nextFired = false
        var prevFired = false
        var exitFired = false

        let item = MDSCoachmarkItem(id: "a", title: "A")
            .onAppear   { _ in appearFired = true }
            .onNext     { _ in nextFired = true }
            .onPrevious { _ in prevFired = true }
            .onExit     { _ in exitFired = true }

        item.onAppearAction?(0)
        item.onNextAction?(0)
        item.onPreviousAction?(0)
        item.onExitAction?(0)

        #expect(appearFired && nextFired && prevFired && exitFired)
    }

    @Test("chaining callback modifiers overwrites the previous closure of that type only")
    func callbackOverwrite() {
        var firstNextFired = false
        var secondNextFired = false
        var appearFired = false

        let item = MDSCoachmarkItem(id: "a", title: "A")
            .onAppear { _ in appearFired = true }
            .onNext { _ in firstNextFired = true }
            .onNext { _ in secondNextFired = true } // should overwrite onNext only

        item.onNextAction?(0)
        item.onAppearAction?(0)

        #expect(firstNextFired == false)
        #expect(secondNextFired == true)
        #expect(appearFired == true, "Overwriting onNext must not clear onAppear")
    }

    @Test("callbacks receive the step index the caller passes in")
    func callbacksReceiveStepIndex() {
        var capturedIndex: Int?
        let item = MDSCoachmarkItem(id: "a", title: "A")
            .onNext { idx in capturedIndex = idx }

        item.onNextAction?(7)
        #expect(capturedIndex == 7)
    }

    // MARK: - Equatable

    @Test("equality compares identity and display props, ignoring callbacks")
    func equatableIgnoresCallbacks() {
        let a = MDSCoachmarkItem(id: "x", title: "T")
            .onNext { _ in }
            .onAppear { _ in }
        let b = MDSCoachmarkItem(id: "x", title: "T")

        #expect(a == b)
    }

    @Test(
        "equality diverges when any display property differs",
        arguments: [
            ("id", MDSCoachmarkItem(id: "y", title: "T")),
            ("title", MDSCoachmarkItem(id: "x", title: "Other")),
            ("description", MDSCoachmarkItem(id: "x", title: "T", description: "d")),
            ("iconName", MDSCoachmarkItem(id: "x", title: "T", iconName: "gear")),
            ("scrollSteps", MDSCoachmarkItem(
                id: "x", title: "T",
                scrollSteps: [.init(proxy: "main")]
            )),
            ("arrowAlignment", MDSCoachmarkItem(id: "x", title: "T")
                .arrowAlignment(.leading)),
            ("arrowOffset", MDSCoachmarkItem(id: "x", title: "T")
                .arrowOffset(10)),
        ]
    )
    func equatableDivergence(label: String, other: MDSCoachmarkItem) {
        let base = MDSCoachmarkItem(id: "x", title: "T")
        #expect(base != other, "Expected inequality when \(label) differs")
    }
}


import Testing
import SwiftUI
import SnapshotTesting
@testable import YourModule

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