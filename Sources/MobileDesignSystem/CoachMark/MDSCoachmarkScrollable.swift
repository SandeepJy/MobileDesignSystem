import SwiftUI

// MARK: - Protocol

/// A type that can programmatically scroll to bring a child view or page
/// into its visible viewport.
///
/// Conforming types register themselves with ``MDSCoachmarkScrollCoordinator``
/// so that the coachmark system can orchestrate multi-level scroll sequences
/// across any combination of scroll containers — `ScrollView`, carousels,
/// paging controllers, etc.
///
/// ## Conforming to MDSCoachmarkScrollable
///
/// Implement ``scrollToTarget(_:anchor:animated:)`` to handle the actual
/// scroll operation. The `target` parameter carries a ``ScrollTarget`` that
/// describes *what* to scroll to:
///
/// - `.viewID(_:)` — scroll a child view with the given string identity
///   into the viewport (typical for `ScrollViewReader`).
/// - `.page(_:)` — scroll to a zero-based page index (typical for carousels
///   and paging containers).
///
/// ```swift
/// extension MyPagingController: MDSCoachmarkScrollable {
///     func scrollToTarget(_ target: ScrollTarget, anchor: UnitPoint, animated: Bool) {
///         switch target {
///         case .viewID(let id):
///             // not supported — ignore or log
///             break
///         case .page(let index):
///             setCurrentPage(index, animated: animated)
///         }
///     }
/// }
/// ```
@MainActor
public protocol MDSCoachmarkScrollable: AnyObject {

    /// Scrolls the container so that the described target is visible.
    ///
    /// - Parameters:
    ///   - target: What to scroll to — either a named view or a page index.
    ///   - anchor: The alignment point within the viewport (e.g. `.center`, `.top`).
    ///   - animated: Whether the scroll should animate.
    func scrollToTarget(_ target: ScrollTarget, anchor: UnitPoint, animated: Bool)
}

// MARK: - ScrollTarget

/// Describes the destination of a programmatic scroll operation.
///
/// Used by ``MDSCoachmarkScrollable/scrollToTarget(_:anchor:animated:)``
/// to communicate *what* the container should scroll to.
public enum ScrollTarget: Equatable, Sendable {

    /// Scroll a child view with the given string identifier into the viewport.
    ///
    /// This corresponds to calling `ScrollViewProxy.scrollTo(_:anchor:)` in a
    /// SwiftUI `ScrollViewReader`.
    case viewID(String)

    /// Scroll to a zero-based page index.
    ///
    /// This corresponds to programmatically scrolling a carousel or paging
    /// controller to the given page.
    case page(Int)
}
