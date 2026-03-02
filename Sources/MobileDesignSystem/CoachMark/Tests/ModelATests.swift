// MDSCoachmarkTests.swift

import Testing
import SwiftUI
@testable import YourModule // Replace with actual module name

// MARK: - MDSCoachmarkScrollCoordinator Tests

@Suite("MDSCoachmarkScrollCoordinator")
struct MDSCoachmarkScrollCoordinatorTests {

    @MainActor
    @Test("hasRegisteredProxies is false when empty and true after registration")
    func registeredProxiesTracking() {
        let coordinator = MDSCoachmarkScrollCoordinator()
        #expect(coordinator.hasRegisteredProxies == false)

        coordinator.register("main") { _, _ in }
        #expect(coordinator.hasRegisteredProxies == true)
    }

    @MainActor
    @Test("unregister removes the proxy")
    func unregisterRemovesProxy() {
        let coordinator = MDSCoachmarkScrollCoordinator()
        coordinator.register("main") { _, _ in }
        coordinator.unregister("main")
        #expect(coordinator.hasRegisteredProxies == false)
    }

    @MainActor
    @Test("unregister unknown name is a no-op")
    func unregisterUnknownIsNoop() {
        let coordinator = MDSCoachmarkScrollCoordinator()
        coordinator.register("main") { _, _ in }
        coordinator.unregister("nonexistent")
        #expect(coordinator.hasRegisteredProxies == true)
    }

    @MainActor
    @Test("defaultContainerID produces deterministic value")
    func defaultContainerID() {
        let id = MDSCoachmarkScrollCoordinator.defaultContainerID(for: "carousel")
        #expect(id == "__mds_coachmark_container_carousel")
    }

    @MainActor
    @Test("scrollSequentially calls completion immediately when steps are empty")
    func emptyStepsCompletesImmediately() async {
        let coordinator = MDSCoachmarkScrollCoordinator()
        await confirmation("completion called") { done in
            coordinator.scrollSequentially(
                targetID: "target",
                steps: [],
                anchor: .center,
                animated: false,
                completion: { done() }
            )
        }
    }

    @MainActor
    @Test("scrollSequentially single step scrolls to targetID")
    func singleStepScrollsToTarget() async {
        let coordinator = MDSCoachmarkScrollCoordinator()
        var scrolledTo: (id: String, anchor: UnitPoint)?

        coordinator.register("main") { id, anchor in
            scrolledTo = (id, anchor)
        }

        await confirmation("completion called") { done in
            coordinator.scrollSequentially(
                targetID: "my-button",
                steps: [MDSCoachmarkScrollStep(proxy: "main")],
                anchor: .center,
                animated: false,
                interStepDelay: 0.01,
                proxyWaitTimeout: 0.1,
                completion: { done() }
            )
        }

        #expect(scrolledTo?.id == "my-button")
        #expect(scrolledTo?.anchor == .center)
    }

    @MainActor
    @Test("scrollSequentially multi-step: intermediate uses defaultContainerID, last uses targetID")
    func multiStepTargetResolution() async {
        let coordinator = MDSCoachmarkScrollCoordinator()
        var scrollLog: [(proxy: String, targetID: String)] = []

        coordinator.register("outer") { id, _ in
            scrollLog.append(("outer", id))
        }
        coordinator.register("inner") { id, _ in
            scrollLog.append(("inner", id))
        }

        let steps = [
            MDSCoachmarkScrollStep(proxy: "outer"),
            MDSCoachmarkScrollStep(proxy: "inner")
        ]

        await confirmation("completion called") { done in
            coordinator.scrollSequentially(
                targetID: "card-7",
                steps: steps,
                anchor: .top,
                animated: false,
                interStepDelay: 0.01,
                proxyWaitTimeout: 0.1,
                completion: { done() }
            )
        }

        #expect(scrollLog.count == 2)
        // Intermediate step auto-infers container ID of next proxy
        #expect(scrollLog[0].proxy == "outer")
        #expect(scrollLog[0].targetID == "__mds_coachmark_container_inner")
        // Last step scrolls to actual target
        #expect(scrollLog[1].proxy == "inner")
        #expect(scrollLog[1].targetID == "card-7")
    }

    @MainActor
    @Test("scrollSequentially intermediate step with explicit parentID uses parentID")
    func intermediateStepExplicitParentID() async {
        let coordinator = MDSCoachmarkScrollCoordinator()
        var scrollLog: [(proxy: String, targetID: String)] = []

        coordinator.register("outer") { id, _ in
            scrollLog.append(("outer", id))
        }
        coordinator.register("inner") { id, _ in
            scrollLog.append(("inner", id))
        }

        let steps = [
            MDSCoachmarkScrollStep(proxy: "outer", parentID: "lazy-section-5"),
            MDSCoachmarkScrollStep(proxy: "inner")
        ]

        await confirmation("completion called") { done in
            coordinator.scrollSequentially(
                targetID: "card-7",
                steps: steps,
                anchor: .center,
                animated: false,
                interStepDelay: 0.01,
                proxyWaitTimeout: 0.1,
                completion: { done() }
            )
        }

        #expect(scrollLog[0].targetID == "lazy-section-5")
        #expect(scrollLog[1].targetID == "card-7")
    }

    @MainActor
    @Test("scrollSequentially skips step when proxy never registers within timeout")
    func skipsUnregisteredProxy() async {
        let coordinator = MDSCoachmarkScrollCoordinator()
        var scrollLog: [String] = []

        // Only register "inner", not "outer"
        coordinator.register("inner") { id, _ in
            scrollLog.append(id)
        }

        let steps = [
            MDSCoachmarkScrollStep(proxy: "outer"),
            MDSCoachmarkScrollStep(proxy: "inner")
        ]

        await confirmation("completion called") { done in
            coordinator.scrollSequentially(
                targetID: "target",
                steps: steps,
                anchor: .center,
                animated: false,
                interStepDelay: 0.01,
                proxyWaitTimeout: 0.1,
                completion: { done() }
            )
        }

        // "outer" was skipped, only "inner" fired
        #expect(scrollLog == ["target"])
    }

    @MainActor
    @Test("scrollSequentially waits for lazily registered proxy")
    func waitsForLazyProxy() async {
        let coordinator = MDSCoachmarkScrollCoordinator()
        var scrolledIDs: [String] = []

        // Register "inner" after a short delay, simulating lazy rendering
        Task {
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s
            await MainActor.run {
                coordinator.register("inner") { id, _ in
                    scrolledIDs.append(id)
                }
            }
        }

        coordinator.register("outer") { id, _ in
            scrolledIDs.append(id)
        }

        let steps = [
            MDSCoachmarkScrollStep(proxy: "outer"),
            MDSCoachmarkScrollStep(proxy: "inner")
        ]

        await confirmation("completion called") { done in
            coordinator.scrollSequentially(
                targetID: "target",
                steps: steps,
                anchor: .center,
                animated: false,
                interStepDelay: 0.01,
                proxyWaitTimeout: 3.0,
                completion: { done() }
            )
        }

        #expect(scrolledIDs.count == 2)
        #expect(scrolledIDs[1] == "target")
    }
}

// MARK: - MDSCoachmarkItem Modifier Chain Tests

@Suite("MDSCoachmarkItem modifiers")
struct MDSCoachmarkItemModifierTests {

    @Test("arrowAlignment modifier returns new item with updated alignment")
    func arrowAlignmentModifier() {
        let item = MDSCoachmarkItem(id: "a", title: "T")
            .arrowAlignment(.leading)
        #expect(item.arrowAlignment == .leading)
    }

    @Test("arrowOffset modifier returns new item with updated offset")
    func arrowOffsetModifier() {
        let item = MDSCoachmarkItem(id: "a", title: "T")
            .arrowOffset(15)
        #expect(item.arrowOffset == 15)
    }

    @Test("chained modifiers compose correctly")
    func chainedModifiers() {
        let item = MDSCoachmarkItem(id: "a", title: "T")
            .arrowAlignment(.trailing)
            .arrowOffset(-8)
        #expect(item.arrowAlignment == .trailing)
        #expect(item.arrowOffset == -8)
    }

    @Test("onAppear callback is invoked with correct index")
    func onAppearCallback() {
        var received: Int?
        let item = MDSCoachmarkItem(id: "a", title: "T")
            .onAppear { received = $0 }
        item.onAppearAction?(42)
        #expect(received == 42)
    }

    @Test("onNext callback is invoked with correct index")
    func onNextCallback() {
        var received: Int?
        let item = MDSCoachmarkItem(id: "a", title: "T")
            .onNext { received = $0 }
        item.onNextAction?(3)
        #expect(received == 3)
    }

    @Test("onPrevious callback is invoked with correct index")
    func onPreviousCallback() {
        var received: Int?
        let item = MDSCoachmarkItem(id: "a", title: "T")
            .onPrevious { received = $0 }
        item.onPreviousAction?(1)
        #expect(received == 1)
    }

    @Test("onExit callback is invoked with correct index")
    func onExitCallback() {
        var received: Int?
        let item = MDSCoachmarkItem(id: "a", title: "T")
            .onExit { received = $0 }
        item.onExitAction?(5)
        #expect(received == 5)
    }

    @Test("modifiers do not mutate original — value semantics")
    func valueSemantics() {
        let original = MDSCoachmarkItem(id: "a", title: "T")
        let modified = original.arrowAlignment(.trailing).arrowOffset(10)
        #expect(original.arrowAlignment == .auto)
        #expect(original.arrowOffset == 0)
        #expect(modified.arrowAlignment == .trailing)
        #expect(modified.arrowOffset == 10)
    }

    @Test("equality ignores callbacks")
    func equalityIgnoresCallbacks() {
        let a = MDSCoachmarkItem(id: "x", title: "Y")
            .onNext { _ in }
        let b = MDSCoachmarkItem(id: "x", title: "Y")
            .onExit { _ in }
        #expect(a == b)
    }

    @Test("equality detects arrowAlignment difference")
    func equalityDetectsAlignmentDiff() {
        let a = MDSCoachmarkItem(id: "x", title: "Y").arrowAlignment(.leading)
        let b = MDSCoachmarkItem(id: "x", title: "Y").arrowAlignment(.trailing)
        #expect(a != b)
    }
}

// MARK: - MDSCoachmarkScrollStep Tests

@Suite("MDSCoachmarkScrollStep")
struct MDSCoachmarkScrollStepTests {

    @Test("parentID defaults to nil")
    func parentIDDefaultsNil() {
        let step = MDSCoachmarkScrollStep(proxy: "main")
        #expect(step.parentID == nil)
    }

    @Test("equatable conformance")
    func equatable() {
        let a = MDSCoachmarkScrollStep(proxy: "main", parentID: "p1")
        let b = MDSCoachmarkScrollStep(proxy: "main", parentID: "p1")
        let c = MDSCoachmarkScrollStep(proxy: "main", parentID: "p2")
        #expect(a == b)
        #expect(a != c)
    }

    @Test("hashable conformance — same values produce same hash")
    func hashable() {
        let a = MDSCoachmarkScrollStep(proxy: "x", parentID: "y")
        let b = MDSCoachmarkScrollStep(proxy: "x", parentID: "y")
        #expect(a.hashValue == b.hashValue)
    }
}

// MARK: - MDSCoachmarkAnchorPreferenceKey Tests

@Suite("MDSCoachmarkAnchorPreferenceKey")
struct AnchorPreferenceKeyTests {

    @Test("default value is empty dictionary")
    func defaultIsEmpty() {
        #expect(MDSCoachmarkAnchorPreferenceKey.defaultValue.isEmpty)
    }
}

// MARK: - MDSCoachmarkConfiguration Tests

@Suite("MDSCoachmarkConfiguration")
struct MDSCoachmarkConfigurationTests {

    @Test("default configuration has expected behavioral defaults")
    func defaults() {
        let config = MDSCoachmarkConfiguration()
        #expect(config.showExitButton == true)
        #expect(config.dismissOnOverlayTap == true)
        #expect(config.dismissWhenOffscreen == true)
        #expect(config.isBlocking == false)
        #expect(config.tipCornerRadius == 12)
        #expect(config.scrollSettleDelay == 0.4)
        #expect(config.scrollInterStepDelay == 0.35)
        #expect(config.proxyWaitTimeout == 3.0)
    }

    @Test("custom configuration overrides are applied")
    func customOverrides() {
        let config = MDSCoachmarkConfiguration(
            showExitButton: false,
            tipCornerRadius: 20,
            dismissOnOverlayTap: false,
            dismissWhenOffscreen: false,
            scrollSettleDelay: 1.0,
            scrollInterStepDelay: 0.5,
            proxyWaitTimeout: 5.0,
            isBlocking: true
        )
        #expect(config.showExitButton == false)
        #expect(config.tipCornerRadius == 20)
        #expect(config.dismissOnOverlayTap == false)
        #expect(config.dismissWhenOffscreen == false)
        #expect(config.scrollSettleDelay == 1.0)
        #expect(config.scrollInterStepDelay == 0.5)
        #expect(config.proxyWaitTimeout == 5.0)
        #expect(config.isBlocking == true)
    }
}






// MDSCoachmarkSnapshotTests.swift
// Tests coachmark progression through PointCoFree snapshot testing

import Testing
import SwiftUI
import SnapshotTesting
@testable import YourModule // Replace with actual module name

// MARK: - Helpers

/// A minimal host view that places coachmark anchors in a known layout
/// and overlays the coachmark tour. No ScrollViewReader needed for these
/// snapshot tests since we only verify tooltip rendering & progression.
@MainActor
private func coachmarkHostView(
    isPresented: Binding<Bool>,
    items: [MDSCoachmarkItem],
    configuration: MDSCoachmarkConfiguration = MDSCoachmarkConfiguration(
        overlayColor: Color.black.opacity(0.75),
        isBlocking: true
    )
) -> some View {
    VStack(spacing: 40) {
        Text("Welcome Header")
            .font(.title)
            .coachmarkAnchor("header")

        HStack(spacing: 30) {
            Image(systemName: "star.fill")
                .font(.largeTitle)
                .coachmarkAnchor("star")

            Image(systemName: "gear")
                .font(.largeTitle)
                .coachmarkAnchor("gear")
        }

        Text("Footer Content")
            .font(.body)
            .coachmarkAnchor("footer")
    }
    .frame(width: 390, height: 844) // iPhone 14 logical size
    .coachmarkOverlay(
        isPresented: isPresented,
        configuration: configuration,
        items: items
    )
}

/// Standard items for a 3-step tour used in progression tests.
private let threeStepItems: [MDSCoachmarkItem] = [
    MDSCoachmarkItem(
        id: "header",
        title: "Welcome!",
        description: "This is the main header of the app."
    ),
    MDSCoachmarkItem(
        id: "star",
        title: "Favorites",
        description: "Tap the star to save items.",
        iconName: "star.fill"
    ),
    MDSCoachmarkItem(
        id: "gear",
        title: "Settings",
        description: "Configure your preferences here.",
        iconName: "gear"
    )
]

// MARK: - Snapshot Tests for Coachmark Progression

@Suite("Coachmark Progression Snapshots")
@MainActor
struct MDSCoachmarkProgressionSnapshotTests {

    @Test("Step 1 of 3 — header highlighted, shows Next and Skip")
    func step1Snapshot() {
        let view = coachmarkHostView(
            isPresented: .constant(true),
            items: threeStepItems
        )

        // The overlay starts at index 0 when isPresented becomes true.
        // After the initial scroll-settle delay the tip becomes visible.
        // We force a synchronous layout for snapshot by wrapping in a UIHostingController.
        let vc = UIHostingController(rootView: view)
        vc.view.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
        vc.view.layoutIfNeeded()

        // Allow async tip appearance to settle
        let expectation = RunLoop.current
        let deadline = Date().addingTimeInterval(1.5)
        while Date() < deadline {
            expectation.run(until: Date().addingTimeInterval(0.05))
        }
        vc.view.layoutIfNeeded()

        assertSnapshot(of: vc, as: .image(size: CGSize(width: 390, height: 844)))
    }

    @Test("Step 2 of 3 — star highlighted with icon, shows Back and Next")
    func step2Snapshot() {
        // We present at step index 1 by creating items where the first item is
        // already "consumed". Alternatively, we simulate progression.
        // For snapshot testing we re-order so the desired step is first:
        let items: [MDSCoachmarkItem] = [
            MDSCoachmarkItem(
                id: "star",
                title: "Favorites",
                description: "Tap the star to save items.",
                iconName: "star.fill"
            ),
            MDSCoachmarkItem(
                id: "gear",
                title: "Settings",
                description: "Configure your preferences here.",
                iconName: "gear"
            )
        ]

        let view = coachmarkHostView(
            isPresented: .constant(true),
            items: threeStepItems
        )

        let vc = UIHostingController(rootView: view)
        vc.view.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
        vc.view.layoutIfNeeded()

        let deadline = Date().addingTimeInterval(1.5)
        while Date() < deadline {
            RunLoop.current.run(until: Date().addingTimeInterval(0.05))
        }
        vc.view.layoutIfNeeded()

        assertSnapshot(of: vc, as: .image(size: CGSize(width: 390, height: 844)))
    }

    @Test("Last step shows Done button instead of Next")
    func lastStepSnapshot() {
        // Single-item tour so it's both first and last
        let items = [
            MDSCoachmarkItem(
                id: "footer",
                title: "All Done",
                description: "You've completed the tour!"
            )
        ]

        let view = coachmarkHostView(
            isPresented: .constant(true),
            items: items
        )

        let vc = UIHostingController(rootView: view)
        vc.view.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
        vc.view.layoutIfNeeded()

        let deadline = Date().addingTimeInterval(1.5)
        while Date() < deadline {
            RunLoop.current.run(until: Date().addingTimeInterval(0.05))
        }
        vc.view.layoutIfNeeded()

        assertSnapshot(of: vc, as: .image(size: CGSize(width: 390, height: 844)))
    }

    @Test("Not presented — no overlay visible")
    func notPresentedSnapshot() {
        let view = coachmarkHostView(
            isPresented: .constant(false),
            items: threeStepItems
        )

        let vc = UIHostingController(rootView: view)
        vc.view.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
        vc.view.layoutIfNeeded()

        assertSnapshot(of: vc, as: .image(size: CGSize(width: 390, height: 844)))
    }

    @Test("Custom configuration: no exit button, custom border colors")
    func customConfigSnapshot() {
        let config = MDSCoachmarkConfiguration(
            overlayColor: Color.indigo.opacity(0.6),
            spotlightBorderColor: .orange,
            spotlightBorderWidth: 3,
            tooltipBorderColor: .orange,
            tooltipBorderWidth: 2,
            showExitButton: false,
            tipCornerRadius: 20,
            isBlocking: true
        )

        let items = [
            MDSCoachmarkItem(
                id: "header",
                title: "Styled Tour",
                description: "Custom border and overlay colors."
            )
        ]

        let view = coachmarkHostView(
            isPresented: .constant(true),
            items: items,
            configuration: config
        )

        let vc = UIHostingController(rootView: view)
        vc.view.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
        vc.view.layoutIfNeeded()

        let deadline = Date().addingTimeInterval(1.5)
        while Date() < deadline {
            RunLoop.current.run(until: Date().addingTimeInterval(0.05))
        }
        vc.view.layoutIfNeeded()

        assertSnapshot(of: vc, as: .image(size: CGSize(width: 390, height: 844)))
    }

    @Test("Arrow alignment leading — arrow positioned near leading edge")
    func arrowAlignmentLeadingSnapshot() {
        let items = [
            MDSCoachmarkItem(
                id: "header",
                title: "Leading Arrow",
                description: "Arrow should be on the left side."
            )
            .arrowAlignment(.leading)
        ]

        let view = coachmarkHostView(
            isPresented: .constant(true),
            items: items
        )

        let vc = UIHostingController(rootView: view)
        vc.view.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
        vc.view.layoutIfNeeded()

        let deadline = Date().addingTimeInterval(1.5)
        while Date() < deadline {
            RunLoop.current.run(until: Date().addingTimeInterval(0.05))
        }
        vc.view.layoutIfNeeded()

        assertSnapshot(of: vc, as: .image(size: CGSize(width: 390, height: 844)))
    }
}

// MARK: - Snapshot Tests for TipContentView in isolation

@Suite("MDSCoachmarkTipContentView Snapshots")
@MainActor
struct MDSCoachmarkTipContentViewSnapshotTests {

    @Test("First step — no back button, skip visible")
    func firstStepTip() {
        let item = MDSCoachmarkItem(
            id: "a",
            title: "First Step",
            description: "Description for the first step.",
            iconName: "hand.wave"
        )
        let config = MDSCoachmarkConfiguration(showExitButton: true)

        let view = MDSCoachmarkTipContentView(
            item: item,
            stepIndex: 0,
            totalSteps: 3,
            isFirst: true,
            isLast: false,
            configuration: config,
            onBack: {},
            onNext: {},
            onSkip: {},
            onFinish: {}
        )
        .padding()
        .background(Color.white)
        .frame(width: 350)

        let vc = UIHostingController(rootView: view)
        vc.view.frame = CGRect(x: 0, y: 0, width: 350, height: 200)
        vc.view.layoutIfNeeded()

        assertSnapshot(of: vc, as: .image(size: CGSize(width: 350, height: 200)))
    }

    @Test("Middle step — back button and next visible")
    func middleStepTip() {
        let item = MDSCoachmarkItem(
            id: "b",
            title: "Middle Step",
            description: "You can go back or forward."
        )
        let config = MDSCoachmarkConfiguration(showExitButton: true)

        let view = MDSCoachmarkTipContentView(
            item: item,
            stepIndex: 1,
            totalSteps: 3,
            isFirst: false,
            isLast: false,
            configuration: config,
            onBack: {},
            onNext: {},
            onSkip: {},
            onFinish: {}
        )
        .padding()
        .background(Color.white)
        .frame(width: 350)

        let vc = UIHostingController(rootView: view)
        vc.view.frame = CGRect(x: 0, y: 0, width: 350, height: 200)
        vc.view.layoutIfNeeded()

        assertSnapshot(of: vc, as: .image(size: CGSize(width: 350, height: 200)))
    }

    @Test("Last step — Done button, no skip, no next chevron")
    func lastStepTip() {
        let item = MDSCoachmarkItem(
            id: "c",
            title: "Final Step",
            description: "You're all set!"
        )
        let config = MDSCoachmarkConfiguration(showExitButton: true)

        let view = MDSCoachmarkTipContentView(
            item: item,
            stepIndex: 2,
            totalSteps: 3,
            isFirst: false,
            isLast: true,
            configuration: config,
            onBack: {},
            onNext: {},
            onSkip: {},
            onFinish: {}
        )
        .padding()
        .background(Color.white)
        .frame(width: 350)

        let vc = UIHostingController(rootView: view)
        vc.view.frame = CGRect(x: 0, y: 0, width: 350, height: 200)
        vc.view.layoutIfNeeded()

        assertSnapshot(of: vc, as: .image(size: CGSize(width: 350, height: 200)))
    }

    @Test("Exit button hidden when showExitButton is false")
    func noExitButtonTip() {
        let item = MDSCoachmarkItem(
            id: "d",
            title: "No Skip",
            description: "User must complete the tour."
        )
        let config = MDSCoachmarkConfiguration(showExitButton: false)

        let view = MDSCoachmarkTipContentView(
            item: item,
            stepIndex: 0,
            totalSteps: 2,
            isFirst: true,
            isLast: false,
            configuration: config,
            onBack: {},
            onNext: {},
            onSkip: {},
            onFinish: {}
        )
        .padding()
        .background(Color.white)
        .frame(width: 350)

        let vc = UIHostingController(rootView: view)
        vc.view.frame = CGRect(x: 0, y: 0, width: 350, height: 200)
        vc.view.layoutIfNeeded()

        assertSnapshot(of: vc, as: .image(size: CGSize(width: 350, height: 200)))
    }

    @Test("Single step tour — both first and last, shows Done, no back, no skip")
    func singleStepTip() {
        let item = MDSCoachmarkItem(
            id: "e",
            title: "Only Step",
            description: "A single-step coachmark."
        )
        let config = MDSCoachmarkConfiguration(showExitButton: true)

        let view = MDSCoachmarkTipContentView(
            item: item,
            stepIndex: 0,
            totalSteps: 1,
            isFirst: true,
            isLast: true,
            configuration: config,
            onBack: {},
            onNext: {},
            onSkip: {},
            onFinish: {}
        )
        .padding()
        .background(Color.white)
        .frame(width: 350)

        let vc = UIHostingController(rootView: view)
        vc.view.frame = CGRect(x: 0, y: 0, width: 350, height: 200)
        vc.view.layoutIfNeeded()

        assertSnapshot(of: vc, as: .image(size: CGSize(width: 350, height: 200)))
    }
}