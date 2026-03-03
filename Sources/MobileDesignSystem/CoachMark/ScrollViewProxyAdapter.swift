import SwiftUI

/// Bridges SwiftUI's `ScrollViewProxy` to the ``MDSCoachmarkScrollable`` protocol.
///
/// Created automatically by the `.coachmarkScrollProxy(_:proxy:coordinator:)` modifier.
/// You do not need to instantiate this type directly.
@MainActor
public final class ScrollViewProxyAdapter: MDSCoachmarkScrollable {

    private let proxy: ScrollViewProxy

    public init(proxy: ScrollViewProxy) {
        self.proxy = proxy
    }

    public func scrollToTarget(_ target: ScrollTarget, anchor: UnitPoint, animated: Bool) {
        switch target {
        case .viewID(let id):
            if animated {
                withAnimation(.easeInOut(duration: 0.3)) {
                    proxy.scrollTo(id, anchor: anchor)
                }
            } else {
                proxy.scrollTo(id, anchor: anchor)
            }
        case .page:
            // ScrollViewProxy doesn't support page-based scrolling.
            // Silently ignore — this is not an error; it just means
            // the step was misconfigured.
            break
        }
    }
}
