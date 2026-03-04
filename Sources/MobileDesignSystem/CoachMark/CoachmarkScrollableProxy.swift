import SwiftUI

// MARK: - CoachmarkScrollableProxy

/// A protocol that any scrollable container can adopt to participate in
/// coachmark-driven programmatic scroll sequences.
///
/// Conformers register themselves with an ``MDSCoachmarkScrollCoordinator``
/// under a unique name. When the coachmark system needs to bring a target
/// into view inside that container, it calls the appropriate method.
///
/// Two scroll models are supported:
///
/// - **ID-based** — the container scrolls to bring a child view (identified
///   by a string) into the visible viewport. Used by SwiftUI `ScrollView`
///   via `ScrollViewReader`.
///
/// - **Page-based** — the container scrolls to a zero-based item index.
///   Used by carousels, pagers, and similar indexed containers.
///
/// Conformers implement only the methods relevant to their scroll model.
/// Both methods provide default no-op implementations.
///
/// ## Built-in Conformers
///
/// | Type | Scroll Model |
/// |---|---|
/// | ``ScrollViewCoachmarkProxy`` | ID-based (wraps `ScrollViewProxy`) |
/// | ``CarouselScrollProxy`` | Page-based |
///
/// ## Custom Conformance
///
/// Any scrollable container can participate by adopting this protocol:
///
/// ```swift
/// final class MyPagerProxy: CoachmarkScrollableProxy {
///     weak var pager: UIPageViewController?
///
///     func scrollTo(page: Int, animated: Bool) {
///         // drive your pager to the given page
///     }
/// }
///
/// // Register:
/// .coachmarkScrollableProxy("my-pager", proxy: pagerProxy, coordinator: coordinator)
/// ```
@MainActor
public protocol CoachmarkScrollableProxy {

    /// Scrolls the container to reveal the child view identified by `id`.
    ///
    /// The default implementation is a no-op. Override in containers that
    /// support ID-based scrolling (e.g. `ScrollViewProxy`).
    ///
    /// - Parameters:
    ///   - id: The string identifier of the target view
    ///     (matching a `.coachmarkAnchor(_:)` value).
    ///   - anchor: The alignment point within the viewport.
    func scrollTo(id: String, anchor: UnitPoint)

    /// Scrolls the container to the specified page or item index.
    ///
    /// The default implementation is a no-op. Override in containers that
    /// support index-based scrolling (e.g. carousels, pagers).
    ///
    /// - Parameters:
    ///   - page: The zero-based index of the target item.
    ///   - animated: Whether the scroll should animate.
    func scrollTo(page: Int, animated: Bool)
}

// Default no-op implementations so conformers only implement what they need.
extension CoachmarkScrollableProxy {
    public func scrollTo(id: String, anchor: UnitPoint) {}
    public func scrollTo(page: Int, animated: Bool) {}
}

// MARK: - ScrollViewCoachmarkProxy

/// An adapter that wraps SwiftUI's `ScrollViewProxy` to conform to
/// ``CoachmarkScrollableProxy``.
///
/// You rarely create this directly — the `.coachmarkScrollProxy(_:proxy:coordinator:)`
/// view modifier builds one automatically.
///
/// ```swift
/// ScrollViewReader { proxy in
///     ScrollView { /* … */ }
///         .coachmarkScrollProxy("main", proxy: proxy, coordinator: coordinator)
/// }
/// ```
@MainActor
public final class ScrollViewCoachmarkProxy: CoachmarkScrollableProxy {

    private let proxy: ScrollViewProxy

    /// Wraps a SwiftUI `ScrollViewProxy`.
    ///
    /// - Parameter proxy: The proxy provided by `ScrollViewReader`.
    public init(_ proxy: ScrollViewProxy) {
        self.proxy = proxy
    }

    public func scrollTo(id: String, anchor: UnitPoint) {
        proxy.scrollTo(id, anchor: anchor)
    }
}
