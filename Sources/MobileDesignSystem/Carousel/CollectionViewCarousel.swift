// Sources/YourLibrary/Carousel/CarouselLayoutConfiguration.swift

import UIKit
import SwiftUI

/// Geometry and visual behavior for a carousel.
public struct CarouselLayoutConfiguration: Sendable, Hashable {

    /// Horizontal gap between adjacent items.
    public var itemSpacing: CGFloat

    /// Visible width of neighboring items on each side.
    /// Set `0` for a full-width pager.
    public var peekAmount: CGFloat

    /// Vertical inset applied to the scrolling content.
    public var verticalInset: CGFloat

    /// Scale applied to off-center items. `1.0` disables scaling.
    public var sideItemScale: CGFloat

    /// Alpha applied to off-center items. `1.0` disables dimming.
    public var sideItemAlpha: CGFloat

    public init(
        itemSpacing: CGFloat = 16,
        peekAmount: CGFloat = 32,
        verticalInset: CGFloat = 0,
        sideItemScale: CGFloat = 0.9,
        sideItemAlpha: CGFloat = 0.6
    ) {
        self.itemSpacing = itemSpacing
        self.peekAmount = peekAmount
        self.verticalInset = verticalInset
        self.sideItemScale = sideItemScale
        self.sideItemAlpha = sideItemAlpha
    }

    /// Full-width paging behavior with no transforms.
    public static let paging = CarouselLayoutConfiguration(
        itemSpacing: 0,
        peekAmount: 0,
        sideItemScale: 1,
        sideItemAlpha: 1
    )
}


/// Horizontal flow layout that snaps items to center and scales/dims
/// off-center items based on their distance from the viewport midpoint.
@MainActor
internal final class CarouselFlowLayout: UICollectionViewFlowLayout {

    private let config: CarouselLayoutConfiguration

    init(configuration: CarouselLayoutConfiguration) {
        self.config = configuration
        super.init()
        scrollDirection = .horizontal
        minimumLineSpacing = configuration.itemSpacing
        minimumInteritemSpacing = 0
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    // MARK: Preparation

    override func prepare() {
        super.prepare()
        guard let collectionView else { return }

        let viewportWidth  = collectionView.bounds.width
        let viewportHeight = collectionView.bounds.height

        // Item width fills the viewport minus the peek region on both sides.
        let width  = max(0, viewportWidth - (config.peekAmount + config.itemSpacing) * 2)
        let height = max(0, viewportHeight - config.verticalInset * 2)
        itemSize = CGSize(width: width, height: height)

        // Horizontal insets center the first and last items.
        let horizontalInset = (viewportWidth - width) / 2
        sectionInset = UIEdgeInsets(
            top: config.verticalInset,
            left: horizontalInset,
            bottom: config.verticalInset,
            right: horizontalInset
        )
    }

    // MARK: Invalidation

    /// Recompute transforms on every scroll tick.
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool { true }

    // MARK: Attribute transforms

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard
            let original = super.layoutAttributesForElements(in: rect),
            let collectionView
        else { return nil }

        // Copy to avoid mutating cached instances vended by super.
        let copied = original.compactMap { $0.copy() as? UICollectionViewLayoutAttributes }
        let centerX = collectionView.contentOffset.x + collectionView.bounds.width / 2
        for attr in copied { applyTransform(to: attr, viewportCenterX: centerX) }
        return copied
    }

    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard
            let attr = super.layoutAttributesForItem(at: indexPath)?.copy() as? UICollectionViewLayoutAttributes,
            let collectionView
        else { return nil }

        let centerX = collectionView.contentOffset.x + collectionView.bounds.width / 2
        applyTransform(to: attr, viewportCenterX: centerX)
        return attr
    }

    private func applyTransform(to attr: UICollectionViewLayoutAttributes, viewportCenterX: CGFloat) {
        let maxDistance = itemSize.width + minimumLineSpacing
        guard maxDistance > 0 else { return }

        let distance   = abs(attr.center.x - viewportCenterX)
        let normalized = min(distance / maxDistance, 1)

        let scale = 1 - normalized * (1 - config.sideItemScale)
        let alpha = 1 - normalized * (1 - config.sideItemAlpha)

        attr.transform = CGAffineTransform(scaleX: scale, y: scale)
        attr.alpha = alpha
        // Keep the centered item visually on top during overlap.
        attr.zIndex = Int((1 - normalized) * 10)
    }

    // MARK: Snapping

    override func targetContentOffset(
        forProposedContentOffset proposedContentOffset: CGPoint,
        withScrollingVelocity velocity: CGPoint
    ) -> CGPoint {
        let pageWidth = itemSize.width + minimumLineSpacing
        guard let collectionView, pageWidth > 0 else { return proposedContentOffset }

        // Convert current offset to a fractional page index.
        let approxPage = collectionView.contentOffset.x / pageWidth

        // Bias toward swipe direction; fall back to nearest on slow drags.
        let speedThreshold: CGFloat = 0.3
        let targetPage: CGFloat
        if velocity.x > speedThreshold       { targetPage = ceil(approxPage)  }
        else if velocity.x < -speedThreshold { targetPage = floor(approxPage) }
        else                                 { targetPage = round(approxPage) }

        // Clamp to valid range.
        let maxPage = max(0, CGFloat(collectionView.numberOfItems(inSection: 0) - 1))
        let clamped = min(max(targetPage, 0), maxPage)

        return CGPoint(x: clamped * pageWidth, y: proposedContentOffset.y)
    }
}

/// Collection view cell that embeds an arbitrary SwiftUI view.
/// Uses a single hosting controller whose `rootView` is swapped on reuse
/// to avoid repeated add/remove of child view controllers.
@MainActor
internal final class CarouselHostingCell: UICollectionViewCell {

    static let reuseIdentifier = "CarouselHostingCell"

    private let hosting = UIHostingController(rootView: AnyView(EmptyView()))

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        hosting.view.backgroundColor = .clear
        hosting.view.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(hosting.view)

        NSLayoutConstraint.activate([
            hosting.view.topAnchor.constraint(equalTo: contentView.topAnchor),
            hosting.view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            hosting.view.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            hosting.view.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    /// Replaces the embedded SwiftUI view.
    func set(view: AnyView) {
        hosting.rootView = view
        hosting.view.invalidateIntrinsicContentSize()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        hosting.rootView = AnyView(EmptyView())
    }
}

/// A horizontally scrolling, center-snapping carousel that reveals a portion
/// of neighboring items on either side.
///
/// ```swift
/// CarouselView(items: photos, currentPage: $page) { photo in
///     PhotoCard(photo: photo)
/// }
/// .frame(height: 280)
/// ```
@MainActor
public struct CollectionCarouselView<Item, Content>: UIViewRepresentable
where Item: Identifiable, Item.ID: Hashable & Sendable, Content: View {

    public typealias UIViewType = UICollectionView

    private let items: [Item]
    private let configuration: CarouselLayoutConfiguration
    private let currentPage: Binding<Int>?
    private let content: (Item) -> Content

    /// Optional proxy that external systems can use to scroll the carousel
    /// programmatically. When non-nil, the carousel keeps it in sync.
    private let scrollProxy: CarouselScrollProxy?

    /// Creates a carousel with a two-way page binding.
    public init(
        items: [Item],
        currentPage: Binding<Int>,
        configuration: CarouselLayoutConfiguration = .init(),
        scrollProxy: CarouselScrollProxy? = nil,
        @ViewBuilder content: @escaping (Item) -> Content
    ) {
        self.items = items
        self.currentPage = currentPage
        self.configuration = configuration
        self.scrollProxy = scrollProxy
        self.content = content
    }

    /// Creates an uncontrolled carousel that manages its own page state.
    public init(
        items: [Item],
        configuration: CarouselLayoutConfiguration = .init(),
        scrollProxy: CarouselScrollProxy? = nil,
        @ViewBuilder content: @escaping (Item) -> Content
    ) {
        self.items = items
        self.currentPage = nil
        self.configuration = configuration
        self.scrollProxy = scrollProxy
        self.content = content
    }

    public func makeCoordinator() -> Coordinator { Coordinator() }

    public func makeUIView(context: Context) -> UICollectionView {
        let coordinator = context.coordinator

        let layout = CarouselFlowLayout(configuration: configuration)
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.showsHorizontalScrollIndicator = false
        cv.showsVerticalScrollIndicator = false
        cv.decelerationRate = .fast
        cv.alwaysBounceHorizontal = true
        cv.contentInsetAdjustmentBehavior = .never
        cv.clipsToBounds = false
        cv.delegate = coordinator

        cv.register(
            CarouselHostingCell.self,
            forCellWithReuseIdentifier: CarouselHostingCell.reuseIdentifier
        )

        let dataSource = UICollectionViewDiffableDataSource<Int, Item.ID>(collectionView: cv) {
            [weak coordinator] collectionView, indexPath, _ in
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: CarouselHostingCell.reuseIdentifier,
                for: indexPath
            ) as! CarouselHostingCell

            if let coordinator,
               let builder = coordinator.contentBuilder,
               let item = coordinator.items[safe: indexPath.item] {
                cell.set(view: builder(item))
            }
            return cell
        }

        coordinator.dataSource = dataSource
        coordinator.layout = layout
        return cv
    }

    public func updateUIView(_ collectionView: UICollectionView, context: Context) {
        let coordinator = context.coordinator

        coordinator.items = items
        coordinator.contentBuilder = { item in AnyView(content(item)) }
        coordinator.currentPage = currentPage
        coordinator.scrollProxy = scrollProxy

        // Diff and apply.
        var snapshot = NSDiffableDataSourceSnapshot<Int, Item.ID>()
        snapshot.appendSections([0])
        snapshot.appendItems(items.map(\.id), toSection: 0)
        coordinator.dataSource?.apply(
            snapshot,
            animatingDifferences: coordinator.hasAppliedInitialSnapshot
        )
        coordinator.hasAppliedInitialSnapshot = true

        // Keep the external proxy in sync.
        scrollProxy?.update(currentPage: coordinator.lastKnownPage, itemCount: items.count)

        // Wire the proxy's scroll closure to the collection view.
        scrollProxy?.scrollToPage = { [weak coordinator] page, animated in
            guard let coordinator else { return }
            coordinator.isUpdatingFromSwiftUI = true
            defer { coordinator.isUpdatingFromSwiftUI = false }
            let offset = coordinator.contentOffset(for: page, in: collectionView)
            collectionView.setContentOffset(offset, animated: animated)
            coordinator.lastKnownPage = page
            coordinator.currentPage?.wrappedValue = page
            coordinator.scrollProxy?.update(currentPage: page, itemCount: coordinator.items.count)
        }

        // Reconcile page position from the binding.
        guard let desired = currentPage?.wrappedValue,
              desired != coordinator.lastKnownPage else { return }

        coordinator.isUpdatingFromSwiftUI = true
        defer { coordinator.isUpdatingFromSwiftUI = false }

        let offset = coordinator.contentOffset(for: desired, in: collectionView)
        collectionView.setContentOffset(offset, animated: true)
        coordinator.lastKnownPage = desired
    }

    // MARK: - Coordinator

    @MainActor
    public final class Coordinator: NSObject, UICollectionViewDelegate {

        fileprivate var items: [Item] = []
        fileprivate var contentBuilder: ((Item) -> AnyView)?
        fileprivate var currentPage: Binding<Int>?
        fileprivate var scrollProxy: CarouselScrollProxy?

        fileprivate var dataSource: UICollectionViewDiffableDataSource<Int, Item.ID>?
        fileprivate weak var layout: CarouselFlowLayout?

        fileprivate var hasAppliedInitialSnapshot = false
        fileprivate var lastKnownPage = 0
        fileprivate var isUpdatingFromSwiftUI = false

        fileprivate func contentOffset(for page: Int, in collectionView: UICollectionView) -> CGPoint {
            collectionView.layoutIfNeeded()
            let itemWidth  = layout?.itemSize.width ?? 0
            let spacing    = layout?.minimumLineSpacing ?? 0
            let pageWidth  = itemWidth + spacing
            let maxOffset  = max(0, collectionView.contentSize.width - collectionView.bounds.width)
            let rawOffset  = CGFloat(page) * pageWidth
            return CGPoint(x: min(max(0, rawOffset), maxOffset), y: 0)
        }

        public func scrollViewDidScroll(_ scrollView: UIScrollView) {
            guard !isUpdatingFromSwiftUI, let layout else { return }

            let pageWidth = layout.itemSize.width + layout.minimumLineSpacing
            guard pageWidth > 0, !items.isEmpty else { return }

            let page    = Int(round(scrollView.contentOffset.x / pageWidth))
            let clamped = max(0, min(page, items.count - 1))

            if clamped != lastKnownPage {
                lastKnownPage = clamped
                currentPage?.wrappedValue = clamped
                scrollProxy?.update(currentPage: clamped, itemCount: items.count)
            }
        }
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
