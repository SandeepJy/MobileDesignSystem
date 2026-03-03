import SwiftUI

/// A handle that allows external systems (e.g. coachmarks) to programmatically
/// scroll a carousel to a specific page.
///
/// Conforms to ``MDSCoachmarkScrollable`` so it can be registered directly
/// with ``MDSCoachmarkScrollCoordinator``.
@MainActor
public final class CarouselScrollProxy: ObservableObject, MDSCoachmarkScrollable {

    /// Closure that performs the actual scroll. Provided by the carousel
    /// that creates this proxy.
    internal var scrollToPage: ((_ page: Int, _ animated: Bool) -> Void)?

    /// The number of items currently in the carousel.
    @Published public private(set) var itemCount: Int = 0

    /// The currently centered page index.
    @Published public private(set) var currentPage: Int = 0

    public init() {}

    /// Scrolls the carousel so that the item at `page` is centered.
    ///
    /// Out-of-range values are clamped silently.
    public func scrollTo(page: Int, animated: Bool = true) {
        let clamped = max(0, min(page, itemCount - 1))
        scrollToPage?(clamped, animated)
    }

    // MARK: - MDSCoachmarkScrollable

    public func scrollToTarget(_ target: ScrollTarget, anchor: UnitPoint, animated: Bool) {
        switch target {
        case .page(let index):
            scrollTo(page: index, animated: animated)
        case .viewID:
            // Carousels don't support arbitrary view-ID scrolling.
            break
        }
    }

    // MARK: - Internal setters called by the carousel

    internal func update(currentPage: Int, itemCount: Int) {
        let needsItemCountUpdate = self.itemCount != itemCount
        let needsPageUpdate = self.currentPage != currentPage

        guard needsItemCountUpdate || needsPageUpdate else { return }

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            if needsItemCountUpdate { self.itemCount = itemCount }
            if needsPageUpdate { self.currentPage = currentPage }
        }
    }
}
