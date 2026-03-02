import SwiftUI
import UIKit

// MARK: - Public API: SnappingCarousel

/// A horizontally-scrolling, snap-to-card carousel built on UIKit's UIScrollView.
/// Compatible with iOS 15+. Shows a sneak peek of adjacent cards.
///
/// Usage:
/// ```swift
/// SnappingCarousel(items: items, currentIndex: $currentIndex) { item in
///     MyCardView(item: item)
/// }
/// .withPageIndicator()
/// ```
public struct SnappingCarousel<Content: View, Item: Identifiable>: View {

    private let items: [Item]
    private let cardSpacing: CGFloat
    private let peekAmount: CGFloat
    @Binding private var currentIndex: Int
    private let content: (Item) -> Content

    /// Optional proxy for coachmark integration.
    private let scrollProxy: CarouselScrollProxy?

    var pageIndicatorConfig: CarouselPageIndicatorConfiguration?

    @State private var measuredHeight: CGFloat = 0

    public init(
        items: [Item],
        cardSpacing: CGFloat = 16,
        peekAmount: CGFloat = 24,
        currentIndex: Binding<Int>,
        scrollProxy: CarouselScrollProxy? = nil,
        @ViewBuilder content: @escaping (Item) -> Content
    ) {
        self.items = items
        self.cardSpacing = cardSpacing
        self.peekAmount = peekAmount
        self._currentIndex = currentIndex
        self.scrollProxy = scrollProxy
        self.content = content
    }

    public var body: some View {
        VStack(spacing: 0) {
            ZStack {
                measurementLayer
                    .frame(height: 0)
                    .hidden()

                if measuredHeight > 0 {
                    CarouselUIViewRepresentable(
                        items: items,
                        cardSpacing: cardSpacing,
                        peekAmount: peekAmount,
                        fixedHeight: measuredHeight,
                        currentIndex: $currentIndex,
                        scrollProxy: scrollProxy,
                        content: content
                    )
                    .frame(height: measuredHeight)
                }
            }

            if let config = pageIndicatorConfig, items.count > 1 {
                PageIndicatorView(
                    numberOfPages: items.count,
                    currentPage: $currentIndex,
                    configuration: config
                )
                .padding(.top, config.topPadding)
            }
        }
    }

    /// Renders all cards off-screen to determine the tallest card height,
    /// which is then used as the fixed height for the carousel.
    private var measurementLayer: some View {
        ZStack {
            GeometryReader { proxy in
                let cardWidth = proxy.size.width - (2 * peekAmount) - cardSpacing

                ZStack {
                    ForEach(items) { item in
                        content(item)
                            .frame(width: max(cardWidth, 0))
                            .fixedSize(horizontal: false, vertical: true)
                            .background(
                                GeometryReader { cardGeometry in
                                    Color.clear
                                        .preference(
                                            key: CardHeightPreferenceKey.self,
                                            value: cardGeometry.size.height
                                        )
                                }
                            )
                    }
                }
            }
        }
        .onPreferenceChange(CardHeightPreferenceKey.self) { tallest in
            if tallest > 0 {
                measuredHeight = tallest
            }
        }
    }
}

// MARK: - Modifier: withPageIndicator

extension SnappingCarousel {

    /// Attaches a built-in page indicator beneath the carousel.
    public func withPageIndicator(
        _ configuration: CarouselPageIndicatorConfiguration = .init()
    ) -> Self {
        var copy = self
        copy.pageIndicatorConfig = configuration
        return copy
    }
}

// MARK: - Page Indicator Configuration

/// Controls the appearance of the carousel's built-in page indicator.
public struct CarouselPageIndicatorConfiguration: Sendable {

    public let activeColor: Color
    public let inactiveColor: Color
    public let dotSize: CGFloat
    public let activeDotWidth: CGFloat
    public let spacing: CGFloat
    public let topPadding: CGFloat

    public init(
        activeColor: Color = .primary,
        inactiveColor: Color = .primary.opacity(0.25),
        dotSize: CGFloat = 8,
        activeDotWidth: CGFloat = 24,
        spacing: CGFloat = 8,
        topPadding: CGFloat = 16
    ) {
        self.activeColor = activeColor
        self.inactiveColor = inactiveColor
        self.dotSize = dotSize
        self.activeDotWidth = activeDotWidth
        self.spacing = spacing
        self.topPadding = topPadding
    }
}

// MARK: - Page Indicator View

private struct PageIndicatorView: View {
    let numberOfPages: Int
    @Binding var currentPage: Int
    let configuration: CarouselPageIndicatorConfiguration

    var body: some View {
        HStack(spacing: configuration.spacing) {
            ForEach(0..<numberOfPages, id: \.self) { index in
                Capsule()
                    .fill(
                        index == currentPage
                            ? configuration.activeColor
                            : configuration.inactiveColor
                    )
                    .frame(
                        width: index == currentPage
                            ? configuration.activeDotWidth
                            : configuration.dotSize,
                        height: configuration.dotSize
                    )
                    .animation(.easeInOut(duration: 0.25), value: currentPage)
            }
        }
    }
}

// MARK: - Height Preference Key

private struct CardHeightPreferenceKey: PreferenceKey {
    static let defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

// MARK: - UIViewRepresentable Bridge

private struct CarouselUIViewRepresentable<Content: View, Item: Identifiable>: UIViewRepresentable {
    let items: [Item]
    let cardSpacing: CGFloat
    let peekAmount: CGFloat
    let fixedHeight: CGFloat
    @Binding var currentIndex: Int
    let scrollProxy: CarouselScrollProxy?
    let content: (Item) -> Content

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.delegate = context.coordinator
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.decelerationRate = .fast
        scrollView.clipsToBounds = false
        scrollView.isPagingEnabled = false
        scrollView.alwaysBounceVertical = false

        let containerView = UIView()
        containerView.tag = ContainerTag.value
        containerView.clipsToBounds = false
        scrollView.addSubview(containerView)

        return scrollView
    }

    func updateUIView(_ scrollView: UIScrollView, context: Context) {
        guard let containerView = scrollView.viewWithTag(ContainerTag.value) else { return }

        let scrollViewWidth: CGFloat = {
            let w = scrollView.bounds.width
            return w > 0 ? w : UIScreen.main.bounds.width
        }()

        let computedCardWidth = scrollViewWidth - (2 * peekAmount) - cardSpacing
        let totalCardWidth = computedCardWidth + cardSpacing

        context.coordinator.totalCardWidth = totalCardWidth
        context.coordinator.itemCount = items.count
        context.coordinator.scrollProxy = scrollProxy

        let totalContentWidth = CGFloat(items.count) * totalCardWidth
            - cardSpacing
            + (2 * peekAmount)

        containerView.frame = CGRect(
            x: 0, y: 0,
            width: totalContentWidth, height: fixedHeight
        )
        scrollView.contentSize = CGSize(
            width: totalContentWidth, height: fixedHeight
        )

        // Keep external proxy in sync.
        scrollProxy?.update(currentPage: currentIndex, itemCount: items.count)

        // Wire the proxy's scroll closure.
        scrollProxy?.scrollToPage = { [weak coordinator = context.coordinator] page, animated in
            guard let coordinator else { return }
            let clamped = max(0, min(page, coordinator.itemCount - 1))
            let targetOffset = CGFloat(clamped) * coordinator.totalCardWidth
            scrollView.setContentOffset(
                CGPoint(x: targetOffset, y: 0),
                animated: animated
            )
            DispatchQueue.main.async {
                coordinator.parent.currentIndex = clamped
                coordinator.scrollProxy?.update(
                    currentPage: clamped,
                    itemCount: coordinator.itemCount
                )
            }
        }

        // Rebuild or update cells (existing logic).
        let needsRebuild = containerView.subviews.count != items.count

        if needsRebuild {
            containerView.subviews.forEach { $0.removeFromSuperview() }
            context.coordinator.hostedControllers.removeAll()

            for (index, item) in items.enumerated() {
                let hostingController = UIHostingController(
                    rootView: CardWrapperView(
                        content: content(item),
                        cardWidth: computedCardWidth,
                        fixedHeight: fixedHeight
                    )
                )
                hostingController.view.backgroundColor = .clear
                hostingController.view.clipsToBounds = false

                let xPosition = peekAmount + CGFloat(index) * totalCardWidth
                hostingController.view.frame = CGRect(
                    x: xPosition, y: 0,
                    width: computedCardWidth, height: fixedHeight
                )

                containerView.addSubview(hostingController.view)
                context.coordinator.hostedControllers.append(hostingController)
            }
        } else {
            for (index, controller) in context.coordinator.hostedControllers.enumerated() {
                let xPosition = peekAmount + CGFloat(index) * totalCardWidth
                controller.view.frame = CGRect(
                    x: xPosition, y: 0,
                    width: computedCardWidth, height: fixedHeight
                )
                controller.rootView = CardWrapperView(
                    content: content(items[index]),
                    cardWidth: computedCardWidth,
                    fixedHeight: fixedHeight
                )
            }
        }

        if !context.coordinator.hasPerformedInitialScroll && !items.isEmpty {
            let clampedIndex = min(max(currentIndex, 0), items.count - 1)
            let targetOffset = CGFloat(clampedIndex) * totalCardWidth
            scrollView.setContentOffset(
                CGPoint(x: targetOffset, y: 0),
                animated: false
            )
            context.coordinator.hasPerformedInitialScroll = true
        }

        if context.coordinator.hasPerformedInitialScroll,
           !context.coordinator.isDragging {
            let clampedIndex = min(max(currentIndex, 0), items.count - 1)
            let expectedOffset = CGFloat(clampedIndex) * totalCardWidth
            let currentOffset = scrollView.contentOffset.x

            if abs(currentOffset - expectedOffset) > 1 {
                scrollView.setContentOffset(
                    CGPoint(x: expectedOffset, y: 0),
                    animated: true
                )
            }
        }
    }

    // MARK: - Coordinator

    final class Coordinator: NSObject, UIScrollViewDelegate {
        var parent: CarouselUIViewRepresentable
        var totalCardWidth: CGFloat = 0
        var itemCount: Int = 0
        var hasPerformedInitialScroll = false
        var isDragging = false
        var hostedControllers: [UIHostingController<CardWrapperView<Content>>] = []
        var scrollProxy: CarouselScrollProxy?

        init(parent: CarouselUIViewRepresentable) {
            self.parent = parent
        }

        func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
            isDragging = true
        }

        func scrollViewWillEndDragging(
            _ scrollView: UIScrollView,
            withVelocity velocity: CGPoint,
            targetContentOffset: UnsafeMutablePointer<CGPoint>
        ) {
            guard totalCardWidth > 0, itemCount > 0 else { return }

            let targetX = targetContentOffset.pointee.x
            var nearestIndex = round(targetX / totalCardWidth)

            let velocityThreshold: CGFloat = 0.3
            if velocity.x > velocityThreshold {
                nearestIndex = ceil(targetX / totalCardWidth)
            } else if velocity.x < -velocityThreshold {
                nearestIndex = floor(targetX / totalCardWidth)
            }

            nearestIndex = max(0, min(nearestIndex, CGFloat(itemCount - 1)))

            targetContentOffset.pointee = CGPoint(
                x: nearestIndex * totalCardWidth,
                y: 0
            )

            let page = Int(nearestIndex)
            DispatchQueue.main.async { [weak self] in
                self?.parent.currentIndex = page
                self?.scrollProxy?.update(
                    currentPage: page,
                    itemCount: self?.itemCount ?? 0
                )
            }
        }

        func scrollViewDidEndDragging(
            _ scrollView: UIScrollView,
            willDecelerate decelerate: Bool
        ) {
            if !decelerate { isDragging = false }
        }

        func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
            isDragging = false
        }
    }
}
// MARK: - Card Wrapper View

private struct CardWrapperView<Content: View>: View {
    let content: Content
    let cardWidth: CGFloat
    let fixedHeight: CGFloat

    var body: some View {
        content
            .frame(width: cardWidth, height: fixedHeight)
    }
}

// MARK: - Container Tag

private enum ContainerTag {
    static let value = 9_817_234
}
