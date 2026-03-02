import SwiftUI
import MobileDesignSystem

struct PromoCard: Identifiable, Sendable {
    let id: Int
    let title: String
}


struct CardView3: View {
    let index: Int
    var body: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(cardColor)
            .frame(width: 160, height: 200)
            .overlay {
                VStack(spacing: 8) {
                    Image(systemName: cardIcon).font(.system(size: 28)).foregroundColor(.white)
                    Text("Card \(index)").font(.headline).foregroundColor(.white)
                    Text("Item #\(index)").font(.caption).foregroundColor(.white.opacity(0.8))
                }
            }
            .shadow(color: .black.opacity(0.12), radius: 6, x: 0, y: 3)
    }
    private var cardColor: Color {
        [.blue,.purple,.teal,.orange,.pink,.green,.indigo,.red,.cyan,.brown][index % 10]
    }
    private var cardIcon: String {
        ["square.fill","circle.fill","triangle.fill","diamond.fill","star.fill",
         "heart.fill","hexagon.fill","pentagon.fill","cloud.fill","leaf.fill"][index % 10]
    }
}

struct CarouselDemoView: View {
    @State private var showCoachmarks = false
    @State private var carouselPage = 0
    @State private var ccviewindex = 0

    @StateObject private var scrollCoordinator = MDSCoachmarkScrollCoordinator()
    @StateObject private var carouselProxy = CarouselScrollProxy()
    @StateObject private var carouselProxyCC = CarouselScrollProxy()

    private let promos = (0..<8).map { PromoCard(id: $0, title: "Promo \($0)") }

    var body: some View {
        ScrollViewReader { mainProxy in
            ScrollView {
                VStack(spacing: 24) {
                    Text("Welcome")
                        .font(.largeTitle)
                        .coachmarkAnchor("welcome")

                    Text("Some filler content")
                        .padding(.vertical, 100)

                    // The carousel, with coachmark anchors on individual cards.
                    SnappingCarousel(
                        items: promos,
                        currentIndex: $carouselPage,
                        scrollProxy: carouselProxy
                    ) { promo in
                        CardView3(index: Int.random(in: 1...5))
                             .coachmarkAnchor("promo-\(promo.id)")
                    }
                    .frame(height: 200)
                    .coachmarkCarouselProxy(
                        "promos",
                        proxy: carouselProxy,
                        coordinator: scrollCoordinator
                    )

                    Text("More content below")
                        .padding(.vertical, 200)
                        .coachmarkAnchor("bottom-section")
                    
                    CollectionCarouselView(items: promos, currentPage: $ccviewindex) { item in
                        CardView3(index: Int.random(in: 1...5))
                             .coachmarkAnchor("collectionview-\(item.id)")
                    }
                    .coachmarkCarouselProxy(
                        "collection",
                        proxy: carouselProxyCC,
                        coordinator: scrollCoordinator
                    )
                }
            }
            .coachmarkScrollProxy("main", proxy: mainProxy, coordinator: scrollCoordinator)
        }
        .coachmarkOverlay(
            isPresented: $showCoachmarks,
            items: [
                MDSCoachmarkItem(
                    id: "welcome",
                    title: "Welcome!",
                    description: "This is the top of the page."
                ),
                MDSCoachmarkItem(
                    id: "promo-3",
                    title: "Special Offer",
                    description: "Check out this promotion.",
                    scrollSteps: [
                        // First: outer ScrollView scrolls the carousel into view.
                        .init(proxy: "main"),
                        // Then: carousel scrolls to page 3.
                        .init(carouselProxy: "promos", page: 3)
                    ]
                ),
                MDSCoachmarkItem(
                    id: "promo-6",
                    title: "Another Deal",
                    description: "Swipe to find more.",
                    scrollSteps: [
                        .init(proxy: "main"),
                        .init(carouselProxy: "promos", page: 6)
                    ]
                ),
                MDSCoachmarkItem(
                    id: "collectionview-2",
                    title: "Another Deal",
                    description: "Swipe to find more.",
                    scrollSteps: [
                        .init(proxy: "main"),
                        .init(carouselProxy: "promos", page: 6)
                    ]
                ),
                MDSCoachmarkItem(
                    id: "bottom-section",
                    title: "Footer",
                    description: "That's everything!",
                    scrollSteps: [
                        .init(proxy: "main")
                    ]
                )
            ],
            scrollCoordinator: scrollCoordinator
        )
        .onAppear { showCoachmarks = true }
    }
}
