
import SwiftUI

extension View {

    /// Registers a ``CarouselScrollProxy`` with the coachmark coordinator and
    /// applies a deterministic `.id()` so parent scroll proxies can scroll this
    /// carousel into view.
    ///
    /// Apply this modifier to (or immediately around) the carousel view:
    ///
    /// ```swift
    /// SnappingCarousel(items: promos, currentIndex: $page) { promo in
    ///     PromoCard(promo: promo)
    /// }
    /// .coachmarkCarouselProxy(
    ///     "promos",
    ///     proxy: carouselProxy,
    ///     coordinator: scrollCoordinator
    /// )
    /// ```
    ///
    /// Then reference the name in a carousel scroll step:
    ///
    /// ```swift
    /// MDSCoachmarkItem(
    ///     id: "promo-card-3",
    ///     title: "Special Offer",
    ///     scrollSteps: [
    ///         .init(proxy: "main"),
    ///         .init(carouselProxy: "promos", page: 3)
    ///     ]
    /// )
    /// ```
    ///
    /// - Parameters:
    ///   - name: A unique name for this carousel's scroll capability.
    ///     Referenced by ``MDSCoachmarkScrollStep/proxy`` in carousel steps.
    ///   - proxy: The ``CarouselScrollProxy`` produced by the carousel.
    ///   - coordinator: The shared ``MDSCoachmarkScrollCoordinator``.
    /// - Returns: A view with the proxy registered and a deterministic identity applied.
    public func coachmarkCarouselProxy(
        _ name: String,
        proxy: CarouselScrollProxy,
        coordinator: MDSCoachmarkScrollCoordinator
    ) -> some View {
        let containerID = MDSCoachmarkScrollCoordinator.defaultContainerID(for: name)
        return self
            .id(containerID)
            .onAppear {
                coordinator.registerCarousel(name, proxy: proxy)
            }
            .onDisappear {
                coordinator.unregister(name)
            }
    }
}
