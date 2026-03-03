import SwiftUI

extension View {

    /// Registers any ``MDSCoachmarkScrollable`` with the coachmark coordinator
    /// and applies a deterministic `.id()` so parent scroll proxies can scroll
    /// this container into view.
    ///
    /// This is the **universal** registration modifier. It works for carousels,
    /// paging controllers, or any custom scrollable container.
    ///
    /// ```swift
    /// SnappingCarousel(items: promos, currentIndex: $page,
    ///                  scrollProxy: carouselProxy) { promo in
    ///     PromoCard(promo: promo)
    /// }
    /// .coachmarkScrollableProxy(
    ///     "promos",
    ///     scrollable: carouselProxy,
    ///     coordinator: scrollCoordinator
    /// )
    /// ```
    ///
    /// - Parameters:
    ///   - name: A unique name for this scrollable's scroll capability.
    ///   - scrollable: The ``MDSCoachmarkScrollable`` to register.
    ///   - coordinator: The shared ``MDSCoachmarkScrollCoordinator``.
    public func coachmarkScrollableProxy(
        _ name: String,
        scrollable: MDSCoachmarkScrollable,
        coordinator: MDSCoachmarkScrollCoordinator
    ) -> some View {
        let containerID = MDSCoachmarkScrollCoordinator.defaultContainerID(for: name)
        return self
            .id(containerID)
            .onAppear {
                coordinator.register(name, scrollable: scrollable)
            }
            .onDisappear {
                coordinator.unregister(name)
            }
    }

    /// Convenience: registers a ``CarouselScrollProxy`` with the coachmark coordinator.
    ///
    /// Equivalent to `.coachmarkScrollableProxy(name, scrollable: proxy, coordinator: coordinator)`.
    public func coachmarkCarouselProxy(
        _ name: String,
        proxy: CarouselScrollProxy,
        coordinator: MDSCoachmarkScrollCoordinator
    ) -> some View {
        coachmarkScrollableProxy(name, scrollable: proxy, coordinator: coordinator)
    }
}
