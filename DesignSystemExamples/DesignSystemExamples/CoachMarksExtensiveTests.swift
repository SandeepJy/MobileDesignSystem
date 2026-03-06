import SwiftUI
import MobileDesignSystem

// MARK: - Shared Components

struct CardView: View {
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

struct LazyListRow: View {
    let index: Int
    var body: some View {
        HStack(spacing: 14) {
            Circle().fill(rowColor).frame(width: 44, height: 44)
                .overlay { Text("\(index)").font(.headline.bold()).foregroundColor(.white) }
            VStack(alignment: .leading, spacing: 3) {
                Text("Lazy Item \(index)").font(.subheadline.bold())
                Text("This is lazy-loaded row number \(index)").font(.caption).foregroundColor(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right").font(.caption).foregroundColor(.secondary)
        }
        .padding(.vertical, 10).padding(.horizontal, 16)
        .background(Color(UIColor.systemBackground))
        .cornerRadius(10)
        .shadow(color: .black.opacity(0.06), radius: 3, x: 0, y: 2)
    }
    private var rowColor: Color {
        [.blue,.green,.orange,.purple,.red,.teal,.pink,.indigo,.cyan,.brown][index % 10]
    }
}

struct StatsCard: View {
    let title: String; let value: String; let icon: String; let color: Color
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon).font(.system(size: 18)).foregroundColor(color)
                Spacer()
                Text(value).font(.title2.bold())
            }
            Text(title).font(.caption).foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14).background(Color(UIColor.systemBackground))
        .cornerRadius(12).shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
    }
}

struct PlaceholderBlock: View {
    let height: CGFloat; let color: Color; let label: String
    var body: some View {
        RoundedRectangle(cornerRadius: 8).fill(color.opacity(0.15))
            .overlay { Text(label).font(.caption).foregroundColor(color) }
            .frame(height: height)
    }
}

// MARK: - Test 1: Basic Vertical Scroll

struct Test1_BasicVerticalScroll: View {

    enum Anchor: String {
        case welcome = "t1-welcome"
        case banner  = "t1-banner"
        case stats   = "t1-stats"
        case bottom  = "t1-bottom"
        case footer  = "t1-footer"
    }

    enum Proxy: String {
        case main
    }

    enum Step: CaseIterable {
        case welcome, banner, stats, bottom, footer

        var coachmarkItem: MDSCoachmarkItem {
            switch self {
            case .welcome:
                return .init(id: Anchor.welcome.rawValue, title: "Welcome", description: "Top of page.",
                             iconName: "hand.wave.fill", iconColor: .orange)
            case .banner:
                return .init(id: Anchor.banner.rawValue, title: "Banner", description: "Main banner.",
                             iconName: "photo.fill", iconColor: .blue,
                             scrollSteps: [.init(proxy: Proxy.main.rawValue)])
            case .stats:
                return .init(id: Anchor.stats.rawValue, title: "Stats", description: "Key metrics.",
                             iconName: "chart.bar.fill", iconColor: .green,
                             scrollSteps: [.init(proxy: Proxy.main.rawValue)])
            case .bottom:
                return .init(id: Anchor.bottom.rawValue, title: "Bottom", description: "Scrolled way down.",
                             iconName: "arrow.down.circle.fill", iconColor: .purple,
                             scrollSteps: [.init(proxy: Proxy.main.rawValue)])
            case .footer:
                return .init(id: Anchor.footer.rawValue, title: "Footer", description: "Very bottom.",
                             iconName: "checkmark.circle.fill", iconColor: .teal,
                             scrollSteps: [.init(proxy: Proxy.main.rawValue)])
            }
        }

        static var allItems: [MDSCoachmarkItem] { allCases.map(\.coachmarkItem) }
    }

    @StateObject var coordinator = MDSCoachmarkScrollCoordinator()
    @State var showTour = false

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    tourButton
                    Text("Welcome Section").font(.title.bold())
                        .coachmarkAnchor(Anchor.welcome.rawValue)
                    PlaceholderBlock(height: 150, color: .blue, label: "Banner")
                        .coachmarkAnchor(Anchor.banner.rawValue)
                    PlaceholderBlock(height: 300, color: .green, label: "Content")
                    StatsCard(title: "Users", value: "1,248", icon: "person.2.fill", color: .blue)
                        .coachmarkAnchor(Anchor.stats.rawValue)
                    PlaceholderBlock(height: 400, color: .orange, label: "Large Section")
                    Text("Bottom Feature").font(.headline)
                        .coachmarkAnchor(Anchor.bottom.rawValue).padding(.vertical, 20)
                    PlaceholderBlock(height: 200, color: .purple, label: "Footer")
                        .coachmarkAnchor(Anchor.footer.rawValue)
                }
                .padding(.horizontal, 16).padding(.bottom, 40)
            }
            .coachmarkScrollProxy(Proxy.main.rawValue, proxy: proxy, coordinator: coordinator)
        }
        .coachmarkOverlay(isPresented: $showTour, items: Step.allItems, scrollCoordinator: coordinator)
        .navigationTitle("Test 1: Basic Vertical")
        .toolbar { tourButton }
    }

    @ViewBuilder var tourButton: some View {
        Button("Start Tour") { showTour = true }
            .padding(.horizontal, 16).padding(.vertical, 8)
            .background(Color.blue).foregroundColor(.white).cornerRadius(8)
    }
}

// MARK: - Test 2: Horizontal Carousels

struct Test2_HorizontalCarousel: View {

    enum Anchor: String {
        case title     = "t2-title"
        case moreTitle = "t2-more-title"
        case footer    = "t2-footer"

        static func card(_ index: Int) -> String { "t2-card-\(index)" }
        static func card2(_ index: Int) -> String { "t2-card2-\(index)" }
    }

    enum Proxy: String {
        case main
        case carousel1
        case carousel2
    }

    enum Step: CaseIterable {
        case title, firstCard, card7, moreTitle, card15, footer

        var coachmarkItem: MDSCoachmarkItem {
            let mainStep: [MDSCoachmarkScrollStep] = [.init(proxy: Proxy.main.rawValue)]
            switch self {
            case .title:
                return .init(id: Anchor.title.rawValue, title: "Featured", description: "Card collection.")
            case .firstCard:
                return .init(id: Anchor.card(0), title: "First Card", description: "First in top carousel.",
                             iconName: "square.fill", iconColor: .blue,
                             scrollSteps: mainStep + [.init(proxy: Proxy.carousel1.rawValue)])
            case .card7:
                return .init(id: Anchor.card(7), title: "Card 7", description: "Scrolled to card 7.",
                             iconName: "diamond.fill", iconColor: .orange,
                             scrollSteps: mainStep + [.init(proxy: Proxy.carousel1.rawValue)])
            case .moreTitle:
                return .init(id: Anchor.moreTitle.rawValue, title: "More Cards", description: "Second section.",
                             iconName: "rectangle.fill", iconColor: .purple,
                             scrollSteps: mainStep)
            case .card15:
                return .init(id: Anchor.card2(15), title: "Card 15", description: "Deep in carousel 2.",
                             iconName: "heart.fill", iconColor: .pink,
                             scrollSteps: mainStep + [.init(proxy: Proxy.carousel2.rawValue)])
            case .footer:
                return .init(id: Anchor.footer.rawValue, title: "Done!", description: "All done.",
                             iconName: "checkmark.fill", iconColor: .green,
                             scrollSteps: mainStep)
            }
        }

        static var allItems: [MDSCoachmarkItem] { allCases.map(\.coachmarkItem) }
    }

    @StateObject var coordinator = MDSCoachmarkScrollCoordinator()
    @State var showTour = false

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    tourButton
                    Text("Featured Cards").font(.title.bold())
                        .coachmarkAnchor(Anchor.title.rawValue)

                    ScrollViewReader { cp in
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(0..<10) { i in
                                    CardView(index: i).coachmarkAnchor(Anchor.card(i))
                                }
                            }.padding(.horizontal, 16)
                        }
                        .coachmarkScrollProxy(Proxy.carousel1.rawValue, proxy: cp, coordinator: coordinator)
                    }

                    PlaceholderBlock(height: 600, color: .blue, label: "Large Section")

                    Text("More Cards").font(.title2.bold())
                        .coachmarkAnchor(Anchor.moreTitle.rawValue)

                    ScrollViewReader { cp2 in
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(0..<10) { i in
                                    CardView(index: i + 10).coachmarkAnchor(Anchor.card2(i + 10))
                                }
                            }.padding(.horizontal, 16)
                        }
                        .coachmarkScrollProxy(Proxy.carousel2.rawValue, proxy: cp2, coordinator: coordinator)
                    }

                    PlaceholderBlock(height: 200, color: .green, label: "Footer")
                        .coachmarkAnchor(Anchor.footer.rawValue)
                }
                .padding(.bottom, 40)
            }
            .coachmarkScrollProxy(Proxy.main.rawValue, proxy: proxy, coordinator: coordinator)
        }
        .coachmarkOverlay(isPresented: $showTour, items: Step.allItems, scrollCoordinator: coordinator)
        .navigationTitle("Test 2: Carousel")
        .toolbar { tourButton }
    }

    @ViewBuilder var tourButton: some View {
        Button("Start Tour") { showTour = true }
            .padding(.horizontal, 16).padding(.vertical, 8)
            .background(Color.blue).foregroundColor(.white).cornerRadius(8)
    }
}

// MARK: - Test 3: LazyVStack

struct Test3_LazyVStack: View {

    enum Anchor: String {
        case title = "t3-title"

        static func row(_ index: Int) -> String { "t3-row-\(index)" }
    }

    enum Proxy: String {
        case main
    }

    enum Step: CaseIterable {
        case title, row0, row10, row25, row40, row49

        var coachmarkItem: MDSCoachmarkItem {
            let mainStep: [MDSCoachmarkScrollStep] = [.init(proxy: Proxy.main.rawValue)]
            switch self {
            case .title:
                return .init(id: Anchor.title.rawValue, title: "Lazy List", description: "50 rows.",
                             iconName: "list.bullet.fill", iconColor: .blue)
            case .row0:
                return .init(id: Anchor.row(0), title: "First",
                             iconName: "arrow.up.circle.fill", iconColor: .green, scrollSteps: mainStep)
            case .row10:
                return .init(id: Anchor.row(10), title: "Row 10",
                             iconName: "arrow.down.circle.fill", iconColor: .orange, scrollSteps: mainStep)
            case .row25:
                return .init(id: Anchor.row(25), title: "Row 25",
                             iconName: "arrow.down.circle.fill", iconColor: .purple, scrollSteps: mainStep)
            case .row40:
                return .init(id: Anchor.row(40), title: "Row 40",
                             iconName: "arrow.down.circle.fill", iconColor: .red, scrollSteps: mainStep)
            case .row49:
                return .init(id: Anchor.row(49), title: "Last",
                             iconName: "checkmark.circle.fill", iconColor: .teal, scrollSteps: mainStep)
            }
        }

        static var allItems: [MDSCoachmarkItem] { allCases.map(\.coachmarkItem) }
    }

    @StateObject var coordinator = MDSCoachmarkScrollCoordinator()
    @State var showTour = false

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    tourButton.padding(.horizontal, 16)
                    Text("Lazy Loaded List").font(.title.bold())
                        .padding(.horizontal, 16).coachmarkAnchor(Anchor.title.rawValue)
                    ForEach(0..<50) { i in
                        LazyListRow(index: i).padding(.horizontal, 16)
                            .coachmarkAnchor(Anchor.row(i))
                    }
                }
                .padding(.bottom, 40)
            }
            .coachmarkScrollProxy(Proxy.main.rawValue, proxy: proxy, coordinator: coordinator)
        }
        .coachmarkOverlay(isPresented: $showTour, items: Step.allItems, scrollCoordinator: coordinator)
        .navigationTitle("Test 3: LazyVStack")
        .toolbar { tourButton }
    }

    @ViewBuilder var tourButton: some View {
        Button("Start Tour") { showTour = true }
            .padding(.horizontal, 16).padding(.vertical, 8)
            .background(Color.blue).foregroundColor(.white).cornerRadius(8)
    }
}

// MARK: - Test 4: LazyVStack + Embedded Carousels

struct Test4_LazyWithCarousels: View {

    enum Anchor: String {
        case title = "t4-title"

        static func row(_ index: Int) -> String { "t4-row-\(index)" }
        static func carouselParent(_ position: Int) -> String { "t4-carousel-\(position)-parent" }
        static func carouselCard(_ position: Int, card: Int) -> String { "t4-carousel-\(position)-card-\(card)" }
    }

    enum Proxy: String {
        case main

        static func carousel(_ position: Int) -> String { "t4-carousel-\(position)" }
    }

    enum Step: CaseIterable {
        case title, row2, carousel5card3, row10, carousel15card6, row25, carousel30card5, row39

        var coachmarkItem: MDSCoachmarkItem {
            let mainStep: [MDSCoachmarkScrollStep] = [.init(proxy: Proxy.main.rawValue)]
            switch self {
            case .title:
                return .init(id: Anchor.title.rawValue, title: "Mixed Layout",
                             description: "Lazy rows with carousels scattered in.",
                             iconName: "square.grid.2x2.fill", iconColor: .blue)
            case .row2:
                return .init(id: Anchor.row(2), title: "Row 2", description: "An early lazy row.",
                             iconName: "list.bullet", iconColor: .green, scrollSteps: mainStep)
            case .carousel5card3:
                return .init(id: Anchor.carouselCard(5, card: 3), title: "Carousel Card",
                             description: "Card 3 inside carousel at position 5.",
                             iconName: "square.fill", iconColor: .orange,
                             scrollSteps: [.init(proxy: Proxy.main.rawValue, parentID: Anchor.carouselParent(5)),
                                           .init(proxy: Proxy.carousel(5))])
            case .row10:
                return .init(id: Anchor.row(10), title: "Row 10",
                             description: "Between the first and second carousels.",
                             iconName: "list.bullet", iconColor: .purple, scrollSteps: mainStep)
            case .carousel15card6:
                return .init(id: Anchor.carouselCard(15, card: 6), title: "Deep Carousel Card",
                             description: "Card 6 in the second carousel (position 15).",
                             iconName: "heart.fill", iconColor: .pink,
                             scrollSteps: [.init(proxy: Proxy.main.rawValue, parentID: Anchor.carouselParent(15)),
                                           .init(proxy: Proxy.carousel(15))])
            case .row25:
                return .init(id: Anchor.row(25), title: "Row 25",
                             description: "Well past the second carousel.",
                             iconName: "list.bullet", iconColor: .indigo, scrollSteps: mainStep)
            case .carousel30card5:
                return .init(id: Anchor.carouselCard(30, card: 5), title: "Last Carousel",
                             description: "Card 5 in the deepest carousel.",
                             iconName: "star.fill", iconColor: .yellow,
                             scrollSteps: [.init(proxy: Proxy.main.rawValue, parentID: Anchor.carouselParent(30)),
                                           .init(proxy: Proxy.carousel(30))])
            case .row39:
                return .init(id: Anchor.row(39), title: "Final Row",
                             description: "The last lazy row.",
                             iconName: "checkmark.circle.fill", iconColor: .teal, scrollSteps: mainStep)
            }
        }

        static var allItems: [MDSCoachmarkItem] { allCases.map(\.coachmarkItem) }
    }

    @StateObject var coordinator = MDSCoachmarkScrollCoordinator()
    @State var showTour = false

    private let carouselPositions: Set<Int> = [5, 15, 30]

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 14) {
                    tourButton.padding(.horizontal, 16)

                    Text("Mixed Lazy + Carousel")
                        .font(.title.bold())
                        .padding(.horizontal, 16)
                        .coachmarkAnchor(Anchor.title.rawValue)

                    ForEach(0..<40, id: \.self) { i in
                        if carouselPositions.contains(i) {
                            carouselSection(at: i)
                                .coachmarkParent(Anchor.carouselParent(i))
                        } else {
                            LazyListRow(index: i)
                                .padding(.horizontal, 16)
                                .coachmarkAnchor(Anchor.row(i))
                        }
                    }
                }
                .padding(.bottom, 40)
            }
            .coachmarkScrollProxy(Proxy.main.rawValue, proxy: proxy, coordinator: coordinator)
        }
        .coachmarkOverlay(isPresented: $showTour, items: Step.allItems, scrollCoordinator: coordinator)
        .navigationTitle("Test 4: Lazy + Carousels")
        .toolbar { tourButton }
    }

    @ViewBuilder
    private func carouselSection(at position: Int) -> some View {
        let proxyName = Proxy.carousel(position)

        VStack(alignment: .leading, spacing: 8) {
            Text("── Carousel at position \(position) ──")
                .font(.caption.bold())
                .foregroundColor(.secondary)
                .padding(.horizontal, 16)

            ScrollViewReader { carouselProxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(0..<8) { i in
                            CardView(index: i)
                                .coachmarkAnchor(Anchor.carouselCard(position, card: i))
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .coachmarkScrollProxy(proxyName, proxy: carouselProxy, coordinator: coordinator)
            }
        }
        .padding(.vertical, 8)
    }

    @ViewBuilder var tourButton: some View {
        Button("Start Tour") { showTour = true }
            .padding(.horizontal, 16).padding(.vertical, 8)
            .background(Color.blue).foregroundColor(.white).cornerRadius(8)
    }
}

// MARK: - Test 5: Deep Nesting (3 Levels)

struct Test5_DeepNesting: View {

    enum Anchor: String {
        case title       = "t5-title"
        case nestedTitle = "t5-nested-title"
        case innerTitle  = "t5-inner-title"
        case innerBottom = "t5-inner-bottom"
        case afterNested = "t5-after-nested"
        case end         = "t5-end"

        static func deepCard(_ index: Int) -> String { "t5-deep-card-\(index)" }
    }

    enum Proxy: String {
        case main
        case innerVertical
        case deepCarousel
    }

    enum Step: CaseIterable {
        case title, nestedTitle, innerTitle, deepCard0, deepCard7, innerBottom, afterNested, end

        var coachmarkItem: MDSCoachmarkItem {
            let mainStep: [MDSCoachmarkScrollStep] = [.init(proxy: Proxy.main.rawValue)]
            let innerStep: [MDSCoachmarkScrollStep] = mainStep + [.init(proxy: Proxy.innerVertical.rawValue)]
            let deepStep: [MDSCoachmarkScrollStep] = innerStep + [.init(proxy: Proxy.deepCarousel.rawValue)]

            switch self {
            case .title:
                return .init(id: Anchor.title.rawValue, title: "Deep Nesting",
                             description: "3 levels of scrolling.",
                             iconName: "square.layers.fill", iconColor: .blue)
            case .nestedTitle:
                return .init(id: Anchor.nestedTitle.rawValue, title: "Nested Section",
                             iconName: "arrow.down.circle.fill", iconColor: .green, scrollSteps: mainStep)
            case .innerTitle:
                return .init(id: Anchor.innerTitle.rawValue, title: "Inner Scroll",
                             iconName: "square.fill", iconColor: .teal, scrollSteps: innerStep)
            case .deepCard0:
                return .init(id: Anchor.deepCard(0), title: "Deep Card 0",
                             description: "First card in deeply nested carousel.",
                             iconName: "diamond.fill", iconColor: .orange, scrollSteps: deepStep)
            case .deepCard7:
                return .init(id: Anchor.deepCard(7), title: "Deep Card 7",
                             description: "Scrolled horizontally 3 levels deep.",
                             iconName: "star.fill", iconColor: .yellow, scrollSteps: deepStep)
            case .innerBottom:
                return .init(id: Anchor.innerBottom.rawValue, title: "Inner Bottom",
                             iconName: "arrow.down.to.line", iconColor: .purple, scrollSteps: innerStep)
            case .afterNested:
                return .init(id: Anchor.afterNested.rawValue, title: "After Nested",
                             iconName: "arrow.up.circle.fill", iconColor: .indigo, scrollSteps: mainStep)
            case .end:
                return .init(id: Anchor.end.rawValue, title: "Complete!",
                             iconName: "checkmark.circle.fill", iconColor: .green, scrollSteps: mainStep)
            }
        }

        static var allItems: [MDSCoachmarkItem] { allCases.map(\.coachmarkItem) }
    }

    @StateObject var coordinator = MDSCoachmarkScrollCoordinator()
    @State var showTour = false

    var body: some View {
        ScrollViewReader { mainProxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    tourButton

                    Text("Deep Nesting Test").font(.title.bold())
                        .padding(.horizontal, 16).coachmarkAnchor(Anchor.title.rawValue)

                    PlaceholderBlock(height: 500, color: .blue, label: "Spacer")
                        .padding(.horizontal, 16)

                    Text("Nested Section").font(.headline)
                        .padding(.horizontal, 16).coachmarkAnchor(Anchor.nestedTitle.rawValue)

                    ScrollViewReader { innerProxy in
                        ScrollView(.vertical) {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Inner Vertical Scroll").font(.subheadline.bold())
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 16)
                                    .coachmarkAnchor(Anchor.innerTitle.rawValue)

                                PlaceholderBlock(height: 300, color: .green, label: "Inner spacer")
                                    .padding(.horizontal, 16)

                                Text("Carousel Inside Inner Scroll").font(.subheadline)
                                    .foregroundColor(.secondary).padding(.horizontal, 16)

                                ScrollViewReader { deepProxy in
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 12) {
                                            ForEach(0..<10) { i in
                                                CardView(index: i + 20)
                                                    .coachmarkAnchor(Anchor.deepCard(i))
                                            }
                                        }.padding(.horizontal, 16)
                                    }
                                    .coachmarkScrollProxy(Proxy.deepCarousel.rawValue, proxy: deepProxy, coordinator: coordinator)
                                }

                                PlaceholderBlock(height: 200, color: .purple, label: "More inner content")
                                    .padding(.horizontal, 16).coachmarkAnchor(Anchor.innerBottom.rawValue)
                            }
                            .padding(.vertical, 12)
                        }
                        .frame(height: 500)
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(12)
                        .coachmarkScrollProxy(Proxy.innerVertical.rawValue, proxy: innerProxy, coordinator: coordinator)
                    }
                    .padding(.horizontal, 16)

                    PlaceholderBlock(height: 300, color: .orange, label: "After nested")
                        .padding(.horizontal, 16).coachmarkAnchor(Anchor.afterNested.rawValue)

                    Text("End of Page").font(.headline)
                        .padding(.horizontal, 16).coachmarkAnchor(Anchor.end.rawValue)
                }
                .padding(.bottom, 40)
            }
            .coachmarkScrollProxy(Proxy.main.rawValue, proxy: mainProxy, coordinator: coordinator)
        }
        .coachmarkOverlay(isPresented: $showTour, items: Step.allItems, scrollCoordinator: coordinator)
        .navigationTitle("Test 5: Deep Nesting")
        .toolbar { tourButton }
    }

    @ViewBuilder var tourButton: some View {
        Button("Start Tour") { showTour = true }
            .padding(.horizontal, 16).padding(.vertical, 8)
            .background(Color.blue).foregroundColor(.white).cornerRadius(8)
    }
}

// MARK: - Test 6: Pinned Header + Carousel

struct Test6_PinnedHeaderLazy: View {

    enum Anchor: String {
        case header     = "t6-header"
        case categories = "t6-categories"
        case followers  = "t6-followers"
        case posts      = "t6-posts"

        static func featured(_ index: Int) -> String { "t6-featured-\(index)" }
        static func row(_ index: Int) -> String { "t6-row-\(index)" }
    }

    enum Proxy: String {
        case main
        case carousel = "t6-carousel"
    }

    enum Step: CaseIterable {
        case header, categories, followers, featured0, featured8, row5, row20, row29

        var coachmarkItem: MDSCoachmarkItem {
            let mainStep: [MDSCoachmarkScrollStep] = [.init(proxy: Proxy.main.rawValue)]
            switch self {
            case .header:
                return .init(id: Anchor.header.rawValue, title: "Profile Header",
                             iconName: "person.circle.fill", iconColor: .blue)
            case .categories:
                return .init(id: Anchor.categories.rawValue, title: "Categories",
                             iconName: "tag.fill", iconColor: .purple, scrollSteps: mainStep)
            case .followers:
                return .init(id: Anchor.followers.rawValue, title: "Followers",
                             iconName: "person.2.fill", iconColor: .blue, scrollSteps: mainStep)
            case .featured0:
                return .init(id: Anchor.featured(0), title: "First Featured",
                             iconName: "star.fill", iconColor: .yellow,
                             scrollSteps: mainStep + [.init(proxy: Proxy.carousel.rawValue)])
            case .featured8:
                return .init(id: Anchor.featured(8), title: "Featured 8",
                             iconName: "diamond.fill", iconColor: .orange,
                             scrollSteps: mainStep + [.init(proxy: Proxy.carousel.rawValue)])
            case .row5:
                return .init(id: Anchor.row(5), title: "List Item",
                             iconName: "list.bullet.fill", iconColor: .green, scrollSteps: mainStep)
            case .row20:
                return .init(id: Anchor.row(20), title: "Deep Item",
                             iconName: "arrow.down.circle.fill", iconColor: .indigo, scrollSteps: mainStep)
            case .row29:
                return .init(id: Anchor.row(29), title: "Last Item",
                             iconName: "checkmark.circle.fill", iconColor: .teal, scrollSteps: mainStep)
            }
        }

        static var allItems: [MDSCoachmarkItem] { allCases.map(\.coachmarkItem) }
    }

    @StateObject var coordinator = MDSCoachmarkScrollCoordinator()
    @State var showTour = false
    private let categories = ["All", "Popular", "New", "Trending", "Classic"]

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0, pinnedViews: [.sectionHeaders]) {
                    Section {
                        HStack(spacing: 12) {
                            StatsCard(title: "Followers", value: "2.4K", icon: "person.2.fill", color: .blue)
                                .coachmarkAnchor(Anchor.followers.rawValue)
                            StatsCard(title: "Posts", value: "148", icon: "square.grid.2x2.fill", color: .purple)
                                .coachmarkAnchor(Anchor.posts.rawValue)
                        }
                        .padding(.horizontal, 16).padding(.top, 12)

                        Text("Featured").font(.subheadline.bold()).foregroundColor(.secondary)
                            .padding(.horizontal, 16).padding(.top, 16)

                        ScrollViewReader { cp in
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(0..<10) { i in
                                        CardView(index: i + 30).coachmarkAnchor(Anchor.featured(i))
                                    }
                                }.padding(.horizontal, 16)
                            }
                            .coachmarkScrollProxy(Proxy.carousel.rawValue, proxy: cp, coordinator: coordinator)
                        }
                        .padding(.top, 8)
                    } header: {
                        VStack(spacing: 0) {
                            tourButton.padding(.horizontal, 16).padding(.top, 12)
                            Text("My Profile").font(.title.bold())
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 16).padding(.top, 8)
                                .coachmarkAnchor(Anchor.header.rawValue)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(categories, id: \.self) { cat in
                                        Text(cat).font(.caption.bold())
                                            .padding(.horizontal, 12).padding(.vertical, 6)
                                            .background(cat == "All" ? Color.blue : Color(UIColor.systemGray5))
                                            .foregroundColor(cat == "All" ? .white : .primary)
                                            .cornerRadius(20)
                                    }
                                }.padding(.horizontal, 16)
                            }
                            .padding(.vertical, 10).coachmarkAnchor(Anchor.categories.rawValue)
                            Divider()
                        }
                        .background(Color(UIColor.systemBackground))
                    }

                    ForEach(0..<30) { i in
                        LazyListRow(index: i + 100)
                            .padding(.horizontal, 16).padding(.top, 8)
                            .coachmarkAnchor(Anchor.row(i))
                    }
                }
                .padding(.bottom, 40)
            }
            .coachmarkScrollProxy(Proxy.main.rawValue, proxy: proxy, coordinator: coordinator)
        }
        .coachmarkOverlay(isPresented: $showTour, items: Step.allItems, scrollCoordinator: coordinator)
        .navigationTitle("Test 6: Pinned Header")
        .toolbar { tourButton }
    }

    @ViewBuilder var tourButton: some View {
        Button("Start Tour") { showTour = true }
            .padding(.horizontal, 16).padding(.vertical, 8)
            .background(Color.blue).foregroundColor(.white).cornerRadius(8)
    }
}

// MARK: - Test 7: Multiple Carousels + Large Gaps

struct Test7_MultipleCarouselsLargeGaps: View {

    enum Anchor: String {
        case title  = "t7-title"
        case banner = "t7-banner"
        case end    = "t7-end"

        static func card(section: String, index: Int) -> String { "t7-\(section)-card-\(index)" }
    }

    enum Proxy: String {
        case main
        case trending = "t7-trending"
        case topRated = "t7-toprated"
        case new      = "t7-new"
        case premium  = "t7-premium"
    }

    enum Step: CaseIterable {
        case title, trending5, banner, topRated6, new3, premium7, end

        var coachmarkItem: MDSCoachmarkItem {
            let mainStep: [MDSCoachmarkScrollStep] = [.init(proxy: Proxy.main.rawValue)]
            switch self {
            case .title:
                return .init(id: Anchor.title.rawValue, title: "App Store",
                             iconName: "square.grid.2x2.fill", iconColor: .blue)
            case .trending5:
                return .init(id: Anchor.card(section: "trending", index: 5), title: "Trending #5",
                             iconName: "flame.fill", iconColor: .red,
                             scrollSteps: mainStep + [.init(proxy: Proxy.trending.rawValue)])
            case .banner:
                return .init(id: Anchor.banner.rawValue, title: "Banner",
                             iconName: "megaphone.fill", iconColor: .orange, scrollSteps: mainStep)
            case .topRated6:
                return .init(id: Anchor.card(section: "toprated", index: 6), title: "Top Rated #6",
                             iconName: "star.fill", iconColor: .yellow,
                             scrollSteps: mainStep + [.init(proxy: Proxy.topRated.rawValue)])
            case .new3:
                return .init(id: Anchor.card(section: "new", index: 3), title: "New #3",
                             iconName: "plus.circle.fill", iconColor: .green,
                             scrollSteps: mainStep + [.init(proxy: Proxy.new.rawValue)])
            case .premium7:
                return .init(id: Anchor.card(section: "premium", index: 7), title: "Premium #7",
                             iconName: "diamond.fill", iconColor: .purple,
                             scrollSteps: mainStep + [.init(proxy: Proxy.premium.rawValue)])
            case .end:
                return .init(id: Anchor.end.rawValue, title: "Complete!",
                             iconName: "checkmark.circle.fill", iconColor: .teal, scrollSteps: mainStep)
            }
        }

        static var allItems: [MDSCoachmarkItem] { allCases.map(\.coachmarkItem) }
    }

    @StateObject var coordinator = MDSCoachmarkScrollCoordinator()
    @State var showTour = false

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    tourButton
                    Text("App Store Style").font(.title.bold())
                        .padding(.horizontal, 16).coachmarkAnchor(Anchor.title.rawValue)

                    carouselSection(label: "🔥 Trending", proxy: .trending, startIndex: 0, sectionKey: "trending")
                    PlaceholderBlock(height: 400, color: .blue, label: "Banner")
                        .padding(.horizontal, 16).coachmarkAnchor(Anchor.banner.rawValue)
                    carouselSection(label: "⭐ Top Rated", proxy: .topRated, startIndex: 10, sectionKey: "toprated")
                    PlaceholderBlock(height: 500, color: .green, label: "Ad Block").padding(.horizontal, 16)
                    carouselSection(label: "🆕 New", proxy: .new, startIndex: 20, sectionKey: "new")
                    PlaceholderBlock(height: 300, color: .purple, label: "Newsletter").padding(.horizontal, 16)
                    carouselSection(label: "💎 Premium", proxy: .premium, startIndex: 30, sectionKey: "premium")
                    Text("That's all!").font(.headline)
                        .padding(.horizontal, 16).padding(.vertical, 20)
                        .coachmarkAnchor(Anchor.end.rawValue)
                }
                .padding(.bottom, 40)
            }
            .coachmarkScrollProxy(Proxy.main.rawValue, proxy: proxy, coordinator: coordinator)
        }
        .coachmarkOverlay(isPresented: $showTour, items: Step.allItems, scrollCoordinator: coordinator)
        .navigationTitle("Test 7: Multi Carousel")
        .toolbar { tourButton }
    }

    @ViewBuilder
    private func carouselSection(label: String, proxy: Proxy, startIndex: Int, sectionKey: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label).font(.subheadline.bold()).foregroundColor(.secondary).padding(.horizontal, 16)
            ScrollViewReader { cp in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(0..<8) { i in
                            CardView(index: startIndex + i)
                                .coachmarkAnchor(Anchor.card(section: sectionKey, index: i))
                        }
                    }.padding(.horizontal, 16)
                }
                .coachmarkScrollProxy(proxy.rawValue, proxy: cp, coordinator: coordinator)
            }
        }
    }

    @ViewBuilder var tourButton: some View {
        Button("Start Tour") { showTour = true }
            .padding(.horizontal, 16).padding(.vertical, 8)
            .background(Color.blue).foregroundColor(.white).cornerRadius(8)
    }
}

// MARK: - Test 8: Edge Cases

struct Test8_EdgeCases: View {

    enum Anchor: String {
        case veryTop      = "t8-very-top"
        case divider      = "t8-divider"
        case massive      = "t8-massive"
        case afterMassive = "t8-after-massive"
        case veryBottom   = "t8-very-bottom"

        static func bottomCard(_ index: Int) -> String { "t8-bottom-card-\(index)" }
    }

    enum Proxy: String {
        case main
        case bottomCarousel = "t8-bottomCarousel"
    }

    enum Step: CaseIterable {
        case veryTop, divider, massive, afterMassive, bottomCard0, bottomCard9, veryBottom

        var coachmarkItem: MDSCoachmarkItem {
            let mainStep: [MDSCoachmarkScrollStep] = [.init(proxy: Proxy.main.rawValue)]
            switch self {
            case .veryTop:
                return .init(id: Anchor.veryTop.rawValue, title: "Very Top",
                             iconName: "arrow.up.to.line", iconColor: .blue)
            case .divider:
                return .init(id: Anchor.divider.rawValue, title: "Divider",
                             description: "Zero-height edge case.",
                             iconName: "minus", iconColor: .gray, scrollSteps: mainStep)
            case .massive:
                return .init(id: Anchor.massive.rawValue, title: "Massive Block",
                             iconName: "square.fill", iconColor: .green, scrollSteps: mainStep)
            case .afterMassive:
                return .init(id: Anchor.afterMassive.rawValue, title: "After Massive",
                             iconName: "flag.fill", iconColor: .red, scrollSteps: mainStep)
            case .bottomCard0:
                return .init(id: Anchor.bottomCard(0), title: "Bottom Card 0",
                             iconName: "square.fill", iconColor: .orange,
                             scrollSteps: mainStep + [.init(proxy: Proxy.bottomCarousel.rawValue)])
            case .bottomCard9:
                return .init(id: Anchor.bottomCard(9), title: "Bottom Card 9",
                             iconName: "star.fill", iconColor: .yellow,
                             scrollSteps: mainStep + [.init(proxy: Proxy.bottomCarousel.rawValue)])
            case .veryBottom:
                return .init(id: Anchor.veryBottom.rawValue, title: "Very Bottom",
                             iconName: "trophy.fill", iconColor: .green, scrollSteps: mainStep)
            }
        }

        static var allItems: [MDSCoachmarkItem] { allCases.map(\.coachmarkItem) }
    }

    @StateObject var coordinator = MDSCoachmarkScrollCoordinator()
    @State var showTour = false

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Text("⚡ Very Top").font(.title.bold())
                        .padding(.horizontal, 16).padding(.top, 8)
                        .coachmarkAnchor(Anchor.veryTop.rawValue)
                    tourButton.padding(.horizontal, 16).padding(.top, 8)
                    Divider().coachmarkAnchor(Anchor.divider.rawValue)
                    PlaceholderBlock(height: 100, color: .blue, label: "Small")
                        .padding(.horizontal, 16).padding(.top, 12)
                    PlaceholderBlock(height: 1200, color: .green, label: "Massive (1200pt)")
                        .padding(.horizontal, 16).padding(.top, 12)
                        .coachmarkAnchor(Anchor.massive.rawValue)
                    Text("🏁 After Massive").font(.headline)
                        .padding(.horizontal, 16).padding(.top, 12)
                        .coachmarkAnchor(Anchor.afterMassive.rawValue)
                    PlaceholderBlock(height: 800, color: .orange, label: "Another big")
                        .padding(.horizontal, 16).padding(.top, 12)

                    Text("Bottom Carousel").font(.subheadline.bold()).foregroundColor(.secondary)
                        .padding(.horizontal, 16).padding(.top, 20)
                    ScrollViewReader { bcp in
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(0..<10) { i in
                                    CardView(index: i + 40).coachmarkAnchor(Anchor.bottomCard(i))
                                }
                            }.padding(.horizontal, 16)
                        }
                        .coachmarkScrollProxy(Proxy.bottomCarousel.rawValue, proxy: bcp, coordinator: coordinator)
                    }
                    .padding(.top, 8)

                    Text("🏆 The Very Last Item").font(.title2.bold()).foregroundColor(.green)
                        .frame(maxWidth: .infinity).padding(.vertical, 40)
                        .coachmarkAnchor(Anchor.veryBottom.rawValue)
                }
                .padding(.bottom, 40)
            }
            .coachmarkScrollProxy(Proxy.main.rawValue, proxy: proxy, coordinator: coordinator)
        }
        .coachmarkOverlay(isPresented: $showTour, items: Step.allItems, scrollCoordinator: coordinator)
        .navigationTitle("Test 8: Edge Cases")
        .toolbar { tourButton }
    }

    @ViewBuilder var tourButton: some View {
        Button("Start Tour") { showTour = true }
            .padding(.horizontal, 16).padding(.vertical, 8)
            .background(Color.blue).foregroundColor(.white).cornerRadius(8)
    }
}

// MARK: - Navigation Root

struct CoachmarkTestRoot: View {
    var body: some View {
        NavigationView {
            List {
                Section("Basic") {
                    NavigationLink("Test 1: Basic Vertical", destination: Test1_BasicVerticalScroll())
                    NavigationLink("Test 3: LazyVStack (50 rows)", destination: Test3_LazyVStack())
                }
                Section("Nested Scrolls") {
                    NavigationLink("Test 2: Horizontal Carousels", destination: Test2_HorizontalCarousel())
                    NavigationLink("Test 7: Multi Carousel + Large Gaps", destination: Test7_MultipleCarouselsLargeGaps())
                }
                Section("Lazy + Nested") {
                    NavigationLink("Test 4: LazyVStack + Embedded Carousels", destination: Test4_LazyWithCarousels())
                    NavigationLink("Test 6: Pinned Header + Carousel", destination: Test6_PinnedHeaderLazy())
                }
                Section("Advanced") {
                    NavigationLink("Test 5: Deep Nesting (3 Levels)", destination: Test5_DeepNesting())
                    NavigationLink("Test 8: Edge Cases", destination: Test8_EdgeCases())
                }
            }
            .navigationTitle("Coachmark Tests")
        }
    }
}
