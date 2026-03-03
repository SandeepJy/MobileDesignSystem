import SwiftUI

public extension View {

    func coachmarkAnchor(_ id: String) -> some View {
        self
            .id(id)
            .anchorPreference(
                key: MDSCoachmarkAnchorPreferenceKey.self,
                value: .bounds
            ) { [id: $0] }
    }

    /// Registers a SwiftUI `ScrollViewProxy` with the coachmark coordinator.
    ///
    /// Internally wraps the proxy in a ``ScrollViewProxyAdapter`` and registers
    /// it through the unified ``MDSCoachmarkScrollable`` path.
    func coachmarkScrollProxy(
        _ name: String,
        proxy: ScrollViewProxy,
        coordinator: MDSCoachmarkScrollCoordinator
    ) -> some View {
        let adapter = ScrollViewProxyAdapter(proxy: proxy)
        let containerID = MDSCoachmarkScrollCoordinator.defaultContainerID(for: name)
        return self
            .id(containerID)
            .onAppear {
                coordinator.register(name, scrollable: adapter)
            }
            .onDisappear {
                coordinator.unregister(name)
            }
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
