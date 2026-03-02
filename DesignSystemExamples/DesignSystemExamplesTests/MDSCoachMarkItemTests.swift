import Testing
import SwiftUI
@testable import MobileDesignSystem

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
