import XCTest

// MARK: - Identifiers (mirrors MDSCoachmarkAccessibility)

private enum AID {
    static let overlay       = "mds_coachmark_overlay"
    static let title         = "mds_coachmark_title"
    static let description   = "mds_coachmark_description"
    static let nextButton    = "mds_coachmark_next"
    static let backButton    = "mds_coachmark_back"
    static let skipButton    = "mds_coachmark_skip"
    static let finishButton  = "mds_coachmark_finish"
    static let stepIndicator = "mds_coachmark_step_indicator"
}

// MARK: - Steps (mirrors the demo's coachmark items)

/// Describes the expected state at each coachmark step.
private struct ExpectedStep {
    let title: String
    let description: String?
    let stepText: String
    let hasBack: Bool
    let hasSkip: Bool
    let isLast: Bool
}

private let allSteps: [ExpectedStep] = [
    ExpectedStep(
        title: "Welcome!",
        description: "This is the top of the page.",
        stepText: "1 of 5",
        hasBack: false, hasSkip: true, isLast: false
    ),
    ExpectedStep(
        title: "Special Offer",
        description: "Check out this promotion.",
        stepText: "2 of 5",
        hasBack: true, hasSkip: true, isLast: false
    ),
    ExpectedStep(
        title: "Another Deal",
        description: "Swipe to find more.",
        stepText: "3 of 5",
        hasBack: true, hasSkip: true, isLast: false
    ),
    ExpectedStep(
        title: "Collection Item",
        description: "Inside the collection carousel.",
        stepText: "4 of 5",
        hasBack: true, hasSkip: true, isLast: false
    ),
    ExpectedStep(
        title: "Footer",
        description: "That's everything!",
        stepText: "5 of 5",
        hasBack: true, hasSkip: false, isLast: true
    )
]

// MARK: - Test Case

@MainActor

final class CoachmarkUITests: XCTestCase {

    private var app: XCUIApplication!

    // MARK: Convenience accessors

    private var tooltipTitle:       XCUIElement { app.staticTexts[AID.title] }
    private var tooltipDescription: XCUIElement { app.staticTexts[AID.description] }
    private var nextButton:         XCUIElement { app.buttons[AID.nextButton] }
    private var backButton:         XCUIElement { app.buttons[AID.backButton] }
    private var skipButton:         XCUIElement { app.buttons[AID.skipButton] }
    private var finishButton:       XCUIElement { app.buttons[AID.finishButton] }
    private var stepIndicator:      XCUIElement { app.staticTexts[AID.stepIndicator] }

    // MARK: Lifecycle

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments.append("--ui-testing-coachmarks")
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Helpers

    /// Waits until the tooltip title element exists **and** has the expected label.
    /// Handles the brief gap where SwiftUI destroys the old tip and creates a new one.
    @discardableResult
    private func waitForTooltip(
        title expected: String,
        timeout: TimeInterval = 6,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Bool {
        let predicate = NSPredicate(format: "exists == true AND label == %@", expected)
        let expectation = XCTNSPredicateExpectation(
            predicate: predicate,
            object: tooltipTitle
        )
        let result = XCTWaiter().wait(for: [expectation], timeout: timeout)
        XCTAssertEqual(
            result, .completed,
            "Expected tooltip '\(expected)' — got '\(tooltipTitle.exists ? tooltipTitle.label : "<missing>")'",
            file: file, line: line
        )
        return result == .completed
    }

    /// Waits for an element to vanish from the hierarchy.
    @discardableResult
    private func waitForNonExistence(
        _ element: XCUIElement,
        timeout: TimeInterval = 5,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Bool {
        let predicate = NSPredicate(format: "exists == false")
        let expectation = XCTNSPredicateExpectation(
            predicate: predicate,
            object: element
        )
        let result = XCTWaiter().wait(for: [expectation], timeout: timeout)
        XCTAssertEqual(
            result, .completed,
            "Element still exists after \(timeout)s",
            file: file, line: line
        )
        return result == .completed
    }

    /// Asserts every visible property of a step matches expectations.
    private func assertStep(
        _ step: ExpectedStep,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        // Title
        waitForTooltip(title: step.title, file: file, line: line)

        // Description
        if let desc = step.description {
            XCTAssertTrue(tooltipDescription.exists, "Description missing", file: file, line: line)
            XCTAssertEqual(tooltipDescription.label, desc, file: file, line: line)
        }

        // Step indicator
        XCTAssertTrue(stepIndicator.exists, "Step indicator missing", file: file, line: line)
        XCTAssertEqual(stepIndicator.label, step.stepText, file: file, line: line)

        // Back button visibility
        XCTAssertEqual(backButton.exists, step.hasBack,
            "Back button existence mismatch on '\(step.title)'", file: file, line: line)

        // Skip button visibility
        XCTAssertEqual(skipButton.exists, step.hasSkip,
            "Skip button existence mismatch on '\(step.title)'", file: file, line: line)

        // Next vs Finish
        if step.isLast {
            XCTAssertTrue(finishButton.exists, "Finish button missing on last step", file: file, line: line)
            XCTAssertFalse(nextButton.exists, "Next button should not exist on last step", file: file, line: line)
        } else {
            XCTAssertTrue(nextButton.exists, "Next button missing", file: file, line: line)
            XCTAssertFalse(finishButton.exists, "Finish should not exist on non-last step", file: file, line: line)
        }
    }

    /// Navigates forward `count` steps by tapping Next, then asserts the step.
    private func advanceTo(stepIndex: Int) {
        for i in 0..<stepIndex {
            let btn = allSteps[i].isLast ? finishButton : nextButton
            XCTAssertTrue(btn.waitForExistence(timeout: 6), "Button missing at step \(i)")
            btn.tap()
            waitForTooltip(title: allSteps[i + 1].title, timeout: 8)
        }
    }

    // MARK: - Initial Appearance

    func test_initialStep_showsCorrectContent() {
        assertStep(allSteps[0])
    }

    func test_initialStep_backButtonIsHidden() {
        waitForTooltip(title: allSteps[0].title)
        XCTAssertFalse(backButton.exists)
    }

    func test_initialStep_skipButtonIsVisible() {
        waitForTooltip(title: allSteps[0].title)
        XCTAssertTrue(skipButton.exists)
    }

    // MARK: - Forward Navigation

    func test_tapNext_advancesToSecondStep() {
        waitForTooltip(title: allSteps[0].title)
        nextButton.tap()
        assertStep(allSteps[1])
    }

    func test_fullForwardNavigation_visitsEveryStep() {
        for (index, step) in allSteps.enumerated() {
            waitForTooltip(title: step.title, timeout: 8)
            assertStep(step)

            if !step.isLast {
                nextButton.tap()
            }

            // After the last step verify finish is available
            if index == allSteps.count - 1 {
                XCTAssertTrue(finishButton.exists)
            }
        }
    }

    // MARK: - Back Navigation

    func test_secondStep_showsBackButton() {
        advanceTo(stepIndex: 1)
        XCTAssertTrue(backButton.exists)
    }

    func test_tapBack_returnsToPreviousStep() {
        advanceTo(stepIndex: 1)
        backButton.tap()
        assertStep(allSteps[0])
    }

    func test_tapBack_fromCarouselStep_returnsToPreviousCarouselStep() {
        // Navigate to step 2 ("Another Deal", promo-6)
        advanceTo(stepIndex: 2)
        assertStep(allSteps[2])

        // Go back to step 1 ("Special Offer", promo-3)
        backButton.tap()
        assertStep(allSteps[1])
    }

    func test_tapBack_fromSecondStep_returnsToWelcome() {
        // This was the original bug — "welcome" needs scroll steps
        advanceTo(stepIndex: 1)
        assertStep(allSteps[1])

        backButton.tap()
        waitForTooltip(title: "Welcome!", timeout: 8)
        assertStep(allSteps[0])
    }

    func test_backAndForward_roundTrip() {
        // Forward to step 2
        advanceTo(stepIndex: 2)
        assertStep(allSteps[2])

        // Back to step 1
        backButton.tap()
        waitForTooltip(title: allSteps[1].title, timeout: 8)
        assertStep(allSteps[1])

        // Forward again to step 2
        nextButton.tap()
        waitForTooltip(title: allSteps[2].title, timeout: 8)
        assertStep(allSteps[2])
    }

    // MARK: - Skip / Dismiss

    func test_tapSkip_dismissesOverlay() {
        waitForTooltip(title: allSteps[0].title)
        skipButton.tap()
        waitForNonExistence(tooltipTitle)
    }

    func test_tapSkip_onMiddleStep_dismissesOverlay() {
        advanceTo(stepIndex: 2)
        assertStep(allSteps[2])

        skipButton.tap()
        waitForNonExistence(tooltipTitle)
    }

    // MARK: - Finish

    func test_lastStep_showsFinishButton() {
        advanceTo(stepIndex: allSteps.count - 1)
        assertStep(allSteps.last!)
    }

    func test_tapFinish_dismissesOverlay() {
        advanceTo(stepIndex: allSteps.count - 1)
        XCTAssertTrue(finishButton.waitForExistence(timeout: 5))
        finishButton.tap()
        waitForNonExistence(tooltipTitle)
    }

    // MARK: - Step Indicator

    func test_stepIndicator_updatesOnEachStep() {
        for (index, step) in allSteps.enumerated() {
            waitForTooltip(title: step.title, timeout: 8)

            XCTAssertTrue(stepIndicator.exists)
            XCTAssertEqual(
                stepIndicator.label,
                "\(index + 1) of \(allSteps.count)",
                "Step indicator wrong at step \(index)"
            )

            if !step.isLast {
                nextButton.tap()
            }
        }
    }

    func test_stepIndicator_updatesOnBack() {
        advanceTo(stepIndex: 2)
        XCTAssertEqual(stepIndicator.label, "3 of 5")

        backButton.tap()
        waitForTooltip(title: allSteps[1].title, timeout: 8)
        XCTAssertEqual(stepIndicator.label, "2 of 5")
    }

    // MARK: - Carousel Steps

    func test_carouselStep_tooltipAppearsAfterScroll() {
        // Step 1 → "Special Offer" requires scrolling main + carousel to page 3
        advanceTo(stepIndex: 1)
        assertStep(allSteps[1])
    }

    func test_collectionCarouselStep_tooltipAppears() {
        // Step 3 → "Collection Item" requires scrolling main + collection carousel to page 2
        advanceTo(stepIndex: 3)
        assertStep(allSteps[3])
    }

    // MARK: - Full End-to-End

    func test_completeFlow_startToFinish() {
        // Walk every step forward and dismiss
        for step in allSteps {
            waitForTooltip(title: step.title, timeout: 8)

            if step.isLast {
                finishButton.tap()
            } else {
                nextButton.tap()
            }
        }

        // Overlay should be gone
        waitForNonExistence(tooltipTitle)
    }

    func test_completeFlow_forwardThenBackToStart() {
        // Go to last step
        advanceTo(stepIndex: allSteps.count - 1)
        assertStep(allSteps.last!)

        // Walk all the way back
        for i in stride(from: allSteps.count - 1, through: 1, by: -1) {
            backButton.tap()
            waitForTooltip(title: allSteps[i - 1].title, timeout: 8)
            assertStep(allSteps[i - 1])
        }

        // Should be back at first step
        assertStep(allSteps[0])
    }
}
