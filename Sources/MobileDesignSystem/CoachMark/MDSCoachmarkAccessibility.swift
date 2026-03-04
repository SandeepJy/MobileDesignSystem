import Foundation

/// Accessibility identifiers for the coachmark overlay, used by UI tests.
///
/// These match the `.accessibilityIdentifier` values applied to elements
/// inside ``MDSCoachmarkTipContentView`` and the overlay container.
///
/// ```swift
/// // In a UI test:
/// let title = app.staticTexts[MDSCoachmarkAccessibility.title]
/// XCTAssertTrue(title.waitForExistence(timeout: 5))
/// ```
public enum MDSCoachmarkAccessibility {
    public static let overlay       = "mds_coachmark_overlay"
    public static let title         = "mds_coachmark_title"
    public static let description   = "mds_coachmark_description"
    public static let nextButton    = "mds_coachmark_next"
    public static let backButton    = "mds_coachmark_back"
    public static let skipButton    = "mds_coachmark_skip"
    public static let finishButton  = "mds_coachmark_finish"
    public static let stepIndicator = "mds_coachmark_step_indicator"
}
