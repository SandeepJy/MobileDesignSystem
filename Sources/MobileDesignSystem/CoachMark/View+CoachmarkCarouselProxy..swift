import SwiftUI

// MARK: - Scrollable Proxy Registration Modifiers

public extension View {
    
    func coachmarkAnchor(_ id: String) -> some View {
            self
                .id(id)
                .anchorPreference(
                    key: MDSCoachmarkAnchorPreferenceKey.self,
                    value: .bounds
                ) { [id: $0] }
        }

    /// Registers any ``CoachmarkScrollableProxy`` conformer with the
    /// coachmark coordinator and applies a deterministic `.id()` so parent
    /// proxies can scroll this container into view.
    ///
    /// This is the **generic entry point**. The convenience modifiers
    /// ``coachmarkScrollProxy(_:proxy:coordinator:)`` and
    /// ``coachmarkCarouselProxy(_:proxy:coordinator:)`` call through to this.
    ///
    /// ### Custom containers
    ///
    /// ```swift
    /// MyCustomPager(items: items) { … }
    ///     .coachmarkScrollableProxy(
    ///         "my-pager",
    ///         proxy: myPagerProxy,    // conforms to CoachmarkScrollableProxy
    ///         coordinator: coordinator
    ///     )
    /// ```
    ///
    /// - Parameters:
    ///   - name: A unique name for this scrollable container.
    ///     Referenced by ``MDSCoachmarkScrollStep/proxy``.
    ///   - proxy: A value conforming to ``CoachmarkScrollableProxy``.
    ///   - coordinator: The shared ``MDSCoachmarkScrollCoordinator``.
    /// - Returns: A view with the proxy registered and a deterministic
    ///   identity applied.
    func coachmarkScrollableProxy(
        _ name: String,
        proxy: any CoachmarkScrollableProxy,
        coordinator: MDSCoachmarkScrollCoordinator
    ) -> some View {
        let containerID = MDSCoachmarkScrollCoordinator.defaultContainerID(for: name)
        return self
            .id(containerID)
            .onAppear  { coordinator.register(name, proxy: proxy) }
            .onDisappear { coordinator.unregister(name) }
    }

    /// Convenience: registers a SwiftUI `ScrollViewProxy` with the
    /// coachmark coordinator.
    ///
    /// Wraps the proxy in a ``ScrollViewCoachmarkProxy`` automatically.
    ///
    /// ```swift
    /// ScrollViewReader { proxy in
    ///     ScrollView { /* … */ }
    ///         .coachmarkScrollProxy("main", proxy: proxy, coordinator: coordinator)
    /// }
    /// ```
    func coachmarkScrollProxy(
        _ name: String,
        proxy: ScrollViewProxy,
        coordinator: MDSCoachmarkScrollCoordinator
    ) -> some View {
        coachmarkScrollableProxy(
            name,
            proxy: ScrollViewCoachmarkProxy(proxy),
            coordinator: coordinator
        )
    }

    /// Convenience: registers a ``CarouselScrollProxy`` with the
    /// coachmark coordinator.
    ///
    /// ```swift
    /// SnappingCarousel(items: promos, currentIndex: $page,
    ///                  scrollProxy: carouselProxy) { … }
    ///     .coachmarkCarouselProxy("promos", proxy: carouselProxy,
    ///                             coordinator: coordinator)
    /// ```
    func coachmarkCarouselProxy(
        _ name: String,
        proxy: CarouselScrollProxy,
        coordinator: MDSCoachmarkScrollCoordinator
    ) -> some View {
        coachmarkScrollableProxy(name, proxy: proxy, coordinator: coordinator)
    }
    
    func coachmarkParent(_ id: String) -> some View {
        self.id(id)
    }

    func coachmarkOverlay(
        isPresented: Binding<Bool>,
        configuration: MDSCoachmarkConfiguration = MDSCoachmarkConfiguration(),
        items: [MDSCoachmarkItem],
        scrollCoordinator: MDSCoachmarkScrollCoordinator? = nil,
        onFinished: (() -> Void)? = nil,
        onSkipped: ((Int) -> Void)? = nil
    ) -> some View {
        self.modifier(
            MDSCoachmarkOverlayModifier(
                isPresented: isPresented,
                items: items,
                configuration: configuration,
                scrollCoordinator: scrollCoordinator,
                onFinished: onFinished,
                onSkipped: onSkipped
            )
        )
    }
}
