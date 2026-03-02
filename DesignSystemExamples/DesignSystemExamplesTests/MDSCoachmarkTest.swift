// MDSCoachmarkTests.swift

import Testing
import SwiftUI
@testable import MobileDesignSystem

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
