import SwiftUI

extension MDSCoachmarkScrollCoordinator {

    /// Registers a ``CarouselScrollProxy`` so that coachmark scroll steps can
    /// target a carousel by name and page index.
    ///
    /// Call this from `.onAppear` of the view that owns the carousel, or use
    /// the convenience modifier ``SwiftUI/View/coachmarkCarouselProxy(_:proxy:page:coordinator:)``.
    ///
    /// When the coachmark system fires a step whose `proxy` matches `name`,
    /// it will:
    /// 1. Scroll the carousel to the page encoded in the step's `carouselPage`.
    /// 2. After the carousel settles, the next step (or the final anchor scroll)
    ///    proceeds.
    ///
    /// - Parameters:
    ///   - name: A unique name for this carousel proxy. Referenced by
    ///     ``MDSCoachmarkScrollStep/proxy``.
    ///   - carouselProxy: The proxy vended by the carousel.
    public func registerCarousel(
        _ name: String,
        proxy carouselProxy: CarouselScrollProxy
    ) {
        register(name) { targetID, _ in
            // The targetID for carousel steps encodes the page index as a string.
            // See `scrollSequentially` target resolution: for intermediate steps
            // the coordinator passes either an explicit parentID or the auto-inferred
            // container ID; for the *last* step it passes the coachmark item's own ID.
            //
            // When the coordinator fires this action, it cannot know the carousel's
            // internal structure. Instead, the *consumer* sets `carouselPage` on the
            // scroll step, and the step stores it. The coordinator always calls
            // `scrollAction(resolvedTarget, anchor)`, but for carousel proxies we
            // ignore `targetID` and use the page stored on the proxy itself.
            //
            // This means the page must be set *before* the coordinator fires.
            // `scrollSequentially` is updated to do this (see below).
            //
            // However, as a fallback, if the targetID is a valid integer we use it.
            if let page = Int(targetID) {
                carouselProxy.scrollTo(page: page, animated: true)
            }
        }
    }
}
