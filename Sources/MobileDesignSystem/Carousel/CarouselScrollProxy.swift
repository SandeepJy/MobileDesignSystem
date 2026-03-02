
import SwiftUI

/// A handle that allows external systems (e.g. coachmarks) to programmatically
/// scroll a carousel to a specific page.
///
/// Each carousel instance vends a proxy through the `.onCarouselProxyAvailable`
/// modifier. The proxy is valid for the lifetime of the carousel view.
///
/// Consumers do not create instances directly — the carousel produces them.
@MainActor
public final class CarouselScrollProxy: ObservableObject {

    /// Closure that performs the actual scroll. Provided by the carousel
    /// that creates this proxy.
    internal var scrollToPage: ((_ page: Int, _ animated: Bool) -> Void)?

    /// The number of items currently in the carousel. Kept in sync by the
    /// carousel on every `updateUIView`.
    @Published public private(set) var itemCount: Int = 0

    /// The currently centered page index. Updated by the carousel's scroll
    /// delegate and by programmatic scrolls.
    @Published public private(set) var currentPage: Int = 0

    public init() {}

    /// Scrolls the carousel so that the item at `page` is centered.
    ///
    /// Out-of-range values are clamped silently.
    ///
    /// - Parameters:
    ///   - page: The zero-based index of the target item.
    ///   - animated: Whether the scroll animates. Defaults to `true`.
    public func scrollTo(page: Int, animated: Bool = true) {
        let clamped = max(0, min(page, itemCount - 1))
        scrollToPage?(clamped, animated)
    }

    // MARK: - Internal setters called by the carousel

    internal func update(currentPage: Int, itemCount: Int) {
            // Capture current values to compare against *after* dispatch,
            // avoiding unnecessary publish cycles.
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
