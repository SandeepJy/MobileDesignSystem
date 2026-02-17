import SwiftUI
import MobileDesignSystem

// MARK: - Shared Components (unchanged)

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
    @StateObject var coordinator = MDSCoachmarkScrollCoordinator()
    @State var showTour = false

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    tourButton
                    Text("Welcome Section").font(.title.bold()).coachmarkAnchor("t1-welcome")
                    PlaceholderBlock(height: 150, color: .blue, label: "Banner").coachmarkAnchor("t1-banner")
                    PlaceholderBlock(height: 300, color: .green, label: "Content")
                    StatsCard(title: "Users", value: "1,248", icon: "person.2.fill", color: .blue).coachmarkAnchor("t1-stats")
                    PlaceholderBlock(height: 400, color: .orange, label: "Large Section")
                    Text("Bottom Feature").font(.headline).coachmarkAnchor("t1-bottom").padding(.vertical, 20)
                    PlaceholderBlock(height: 200, color: .purple, label: "Footer").coachmarkAnchor("t1-footer")
                }
                .padding(.horizontal, 16).padding(.bottom, 40)
            }
            .coachmarkScrollProxy("main", proxy: proxy, coordinator: coordinator)
        }
        .coachmarkOverlay(
            isPresented: $showTour,
            items: [
                MDSCoachmarkItem(id: "t1-welcome", title: "Welcome", description: "Top of page.", iconName: "hand.wave.fill", iconColor: .orange),
                MDSCoachmarkItem(id: "t1-banner", title: "Banner", description: "Main banner.", iconName: "photo.fill", iconColor: .blue,
                                 scrollSteps: [.init(proxy: "main")]),
                MDSCoachmarkItem(id: "t1-stats", title: "Stats", description: "Key metrics.", iconName: "chart.bar.fill", iconColor: .green,
                                 scrollSteps: [.init(proxy: "main")]),
                MDSCoachmarkItem(id: "t1-bottom", title: "Bottom", description: "Scrolled way down.", iconName: "arrow.down.circle.fill", iconColor: .purple,
                                 scrollSteps: [.init(proxy: "main")]),
                MDSCoachmarkItem(id: "t1-footer", title: "Footer", description: "Very bottom.", iconName: "checkmark.circle.fill", iconColor: .teal,
                                 scrollSteps: [.init(proxy: "main")])
            ],
            scrollCoordinator: coordinator
        )
        .navigationTitle("Test 1: Basic Vertical")
        .toolbar { tourButton }
    }

    @ViewBuilder var tourButton: some View {
        Button("Start Tour") { showTour = true }
            .padding(.horizontal, 16).padding(.vertical, 8)
            .background(Color.blue).foregroundColor(.white).cornerRadius(8)
    }
}

// MARK: - Test 2: Horizontal Carousels (non-lazy, no parent needed)

struct Test2_HorizontalCarousel: View {
    @StateObject var coordinator = MDSCoachmarkScrollCoordinator()
    @State var showTour = false

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    tourButton
                    Text("Featured Cards").font(.title.bold()).coachmarkAnchor("t2-title")

                    // Carousel 1 — always rendered (not lazy), so no .coachmarkParent needed
                    ScrollViewReader { cp in
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(0..<10) { i in
                                    CardView(index: i).coachmarkAnchor("t2-card-\(i)")
                                }
                            }.padding(.horizontal, 16)
                        }
                        .coachmarkScrollProxy("carousel1", proxy: cp, coordinator: coordinator)
                    }

                    PlaceholderBlock(height: 600, color: .blue, label: "Large Section")

                    Text("More Cards").font(.title2.bold()).coachmarkAnchor("t2-more-title")

                    // Carousel 2
                    ScrollViewReader { cp2 in
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(0..<10) { i in
                                    CardView(index: i + 10).coachmarkAnchor("t2-card2-\(i + 10)")
                                }
                            }.padding(.horizontal, 16)
                        }
                        .coachmarkScrollProxy("carousel2", proxy: cp2, coordinator: coordinator)
                    }

                    PlaceholderBlock(height: 200, color: .green, label: "Footer").coachmarkAnchor("t2-footer")
                }
                .padding(.bottom, 40)
            }
            .coachmarkScrollProxy("main", proxy: proxy, coordinator: coordinator)
        }
        .coachmarkOverlay(
            isPresented: $showTour,
            items: [
                MDSCoachmarkItem(id: "t2-title", title: "Featured", description: "Card collection."),
                MDSCoachmarkItem(id: "t2-card-0", title: "First Card", description: "First in top carousel.", iconName: "square.fill", iconColor: .blue,
                                 scrollSteps: [.init(proxy: "main"), .init(proxy: "carousel1")]),
                MDSCoachmarkItem(id: "t2-card-7", title: "Card 7", description: "Scrolled to card 7.", iconName: "diamond.fill", iconColor: .orange,
                                 scrollSteps: [.init(proxy: "main"), .init(proxy: "carousel1")]),
                MDSCoachmarkItem(id: "t2-more-title", title: "More Cards", description: "Second section.", iconName: "rectangle.fill", iconColor: .purple,
                                 scrollSteps: [.init(proxy: "main")]),
                MDSCoachmarkItem(id: "t2-card2-15", title: "Card 15", description: "Deep in carousel 2.", iconName: "heart.fill", iconColor: .pink,
                                 scrollSteps: [.init(proxy: "main"), .init(proxy: "carousel2")]),
                MDSCoachmarkItem(id: "t2-footer", title: "Done!", description: "All done.", iconName: "checkmark.fill", iconColor: .green,
                                 scrollSteps: [.init(proxy: "main")])
            ],
            scrollCoordinator: coordinator
        )
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
    @StateObject var coordinator = MDSCoachmarkScrollCoordinator()
    @State var showTour = false

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    tourButton.padding(.horizontal, 16)
                    Text("Lazy Loaded List").font(.title.bold())
                        .padding(.horizontal, 16).coachmarkAnchor("t3-title")
                    ForEach(0..<50) { i in
                        LazyListRow(index: i).padding(.horizontal, 16).coachmarkAnchor("t3-row-\(i)")
                    }
                }
                .padding(.bottom, 40)
            }
            .coachmarkScrollProxy("main", proxy: proxy, coordinator: coordinator)
        }
        .coachmarkOverlay(
            isPresented: $showTour,
            items: [
                MDSCoachmarkItem(id: "t3-title", title: "Lazy List", description: "50 rows.", iconName: "list.bullet.fill", iconColor: .blue),
                MDSCoachmarkItem(id: "t3-row-0", title: "First", iconName: "arrow.up.circle.fill", iconColor: .green,
                                 scrollSteps: [.init(proxy: "main")]),
                MDSCoachmarkItem(id: "t3-row-10", title: "Row 10", iconName: "arrow.down.circle.fill", iconColor: .orange,
                                 scrollSteps: [.init(proxy: "main")]),
                MDSCoachmarkItem(id: "t3-row-25", title: "Row 25", iconName: "arrow.down.circle.fill", iconColor: .purple,
                                 scrollSteps: [.init(proxy: "main")]),
                MDSCoachmarkItem(id: "t3-row-40", title: "Row 40", iconName: "arrow.down.circle.fill", iconColor: .red,
                                 scrollSteps: [.init(proxy: "main")]),
                MDSCoachmarkItem(id: "t3-row-49", title: "Last", iconName: "checkmark.circle.fill", iconColor: .teal,
                                 scrollSteps: [.init(proxy: "main")])
            ],
            scrollCoordinator: coordinator
        )
        .navigationTitle("Test 3: LazyVStack")
        .toolbar { tourButton }
    }

    @ViewBuilder var tourButton: some View {
        Button("Start Tour") { showTour = true }
            .padding(.horizontal, 16).padding(.vertical, 8)
            .background(Color.blue).foregroundColor(.white).cornerRadius(8)
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - Test 4: LazyVStack + Embedded Carousels  (THE FIX)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

struct Test4_LazyWithCarousels: View {
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
                        .coachmarkAnchor("t4-title")

                    ForEach(0..<40, id: \.self) { i in
                        if carouselPositions.contains(i) {
                            // ┌────────────────────────────────────────────┐
                            // │ .coachmarkParent gives this ForEach child  │
                            // │ a deterministic .id() that the MAIN proxy  │
                            // │ can scroll to — even before the carousel   │
                            // │ inside has rendered.                       │
                            // └────────────────────────────────────────────┘
                            carouselSection(at: i)
                                .coachmarkParent("t4-carousel-\(i)-parent")
                        } else {
                            LazyListRow(index: i)
                                .padding(.horizontal, 16)
                                .coachmarkAnchor("t4-row-\(i)")
                        }
                    }
                }
                .padding(.bottom, 40)
            }
            .coachmarkScrollProxy("main", proxy: proxy, coordinator: coordinator)
        }
        .coachmarkOverlay(
            isPresented: $showTour,
            items: [
                // No scrolling needed — already visible
                MDSCoachmarkItem(
                    id: "t4-title",
                    title: "Mixed Layout",
                    description: "Lazy rows with carousels scattered in.",
                    iconName: "square.grid.2x2.fill", iconColor: .blue
                ),

                // Simple main-only scroll
                MDSCoachmarkItem(
                    id: "t4-row-2",
                    title: "Row 2",
                    description: "An early lazy row.",
                    iconName: "list.bullet", iconColor: .green,
                    scrollSteps: [
                        .init(proxy: "main")
                    ]
                ),

                // Two-step: main → carousel parent, then carousel → card
                MDSCoachmarkItem(
                    id: "t4-carousel-5-card-3",
                    title: "Carousel Card",
                    description: "Card 3 inside carousel at position 5.",
                    iconName: "square.fill", iconColor: .orange,
                    scrollSteps: [
                        .init(proxy: "main", parentID: "t4-carousel-5-parent"),
                        .init(proxy: "t4-carousel-5")
                    ]
                ),

                // Back to a simple row
                MDSCoachmarkItem(
                    id: "t4-row-10",
                    title: "Row 10",
                    description: "Between the first and second carousels.",
                    iconName: "list.bullet", iconColor: .purple,
                    scrollSteps: [
                        .init(proxy: "main")
                    ]
                ),

                // THE PREVIOUSLY BROKEN STEP — now works because:
                // 1. "main" scrolls to "t4-carousel-15-parent" (deterministic .id)
                // 2. LazyVStack renders carousel-15 → onAppear registers proxy
                // 3. Coordinator polls until "t4-carousel-15" proxy appears
                // 4. "t4-carousel-15" scrolls to "t4-carousel-15-card-6"
                MDSCoachmarkItem(
                    id: "t4-carousel-15-card-6",
                    title: "Deep Carousel Card",
                    description: "Card 6 in the second carousel (position 15).",
                    iconName: "heart.fill", iconColor: .pink,
                    scrollSteps: [
                        .init(proxy: "main", parentID: "t4-carousel-15-parent"),
                        .init(proxy: "t4-carousel-15")
                    ]
                ),

                MDSCoachmarkItem(
                    id: "t4-row-25",
                    title: "Row 25",
                    description: "Well past the second carousel.",
                    iconName: "list.bullet", iconColor: .indigo,
                    scrollSteps: [
                        .init(proxy: "main")
                    ]
                ),

                MDSCoachmarkItem(
                    id: "t4-carousel-30-card-5",
                    title: "Last Carousel",
                    description: "Card 5 in the deepest carousel.",
                    iconName: "star.fill", iconColor: .yellow,
                    scrollSteps: [
                        .init(proxy: "main", parentID: "t4-carousel-30-parent"),
                        .init(proxy: "t4-carousel-30")
                    ]
                ),

                MDSCoachmarkItem(
                    id: "t4-row-39",
                    title: "Final Row",
                    description: "The last lazy row.",
                    iconName: "checkmark.circle.fill", iconColor: .teal,
                    scrollSteps: [
                        .init(proxy: "main")
                    ]
                )
            ],
            scrollCoordinator: coordinator
        )
        .navigationTitle("Test 4: Lazy + Carousels")
        .toolbar { tourButton }
    }

    // ── Carousel section ──
    // Only registers .coachmarkScrollProxy (the action).
    // The .coachmarkParent (deterministic .id) is on the CALLER in the ForEach.
    @ViewBuilder
    private func carouselSection(at position: Int) -> some View {
        let proxyName = "t4-carousel-\(position)"

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
                                .coachmarkAnchor("\(proxyName)-card-\(i)")
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
    @StateObject var coordinator = MDSCoachmarkScrollCoordinator()
    @State var showTour = false

    var body: some View {
        ScrollViewReader { mainProxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    tourButton

                    Text("Deep Nesting Test").font(.title.bold())
                        .padding(.horizontal, 16).coachmarkAnchor("t5-title")

                    PlaceholderBlock(height: 500, color: .blue, label: "Spacer")
                        .padding(.horizontal, 16)

                    Text("Nested Section").font(.headline)
                        .padding(.horizontal, 16).coachmarkAnchor("t5-nested-title")

                    // Level 2 — vertical inner scroll
                    ScrollViewReader { innerProxy in
                        ScrollView(.vertical) {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Inner Vertical Scroll").font(.subheadline.bold())
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 16)
                                    .coachmarkAnchor("t5-inner-title")

                                PlaceholderBlock(height: 300, color: .green, label: "Inner spacer")
                                    .padding(.horizontal, 16)

                                Text("Carousel Inside Inner Scroll").font(.subheadline)
                                    .foregroundColor(.secondary).padding(.horizontal, 16)

                                // Level 3 — horizontal carousel
                                ScrollViewReader { deepProxy in
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 12) {
                                            ForEach(0..<10) { i in
                                                CardView(index: i + 20)
                                                    .coachmarkAnchor("t5-deep-card-\(i)")
                                            }
                                        }.padding(.horizontal, 16)
                                    }
                                    .coachmarkScrollProxy("deepCarousel", proxy: deepProxy, coordinator: coordinator)
                                }

                                PlaceholderBlock(height: 200, color: .purple, label: "More inner content")
                                    .padding(.horizontal, 16).coachmarkAnchor("t5-inner-bottom")
                            }
                            .padding(.vertical, 12)
                        }
                        .frame(height: 500)
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(12)
                        .coachmarkScrollProxy("innerVertical", proxy: innerProxy, coordinator: coordinator)
                    }
                    .padding(.horizontal, 16)

                    PlaceholderBlock(height: 300, color: .orange, label: "After nested")
                        .padding(.horizontal, 16).coachmarkAnchor("t5-after-nested")

                    Text("End of Page").font(.headline)
                        .padding(.horizontal, 16).coachmarkAnchor("t5-end")
                }
                .padding(.bottom, 40)
            }
            .coachmarkScrollProxy("main", proxy: mainProxy, coordinator: coordinator)
        }
        .coachmarkOverlay(
            isPresented: $showTour,
            items: [
                MDSCoachmarkItem(id: "t5-title", title: "Deep Nesting", description: "3 levels of scrolling.", iconName: "square.layers.fill", iconColor: .blue),
                MDSCoachmarkItem(id: "t5-nested-title", title: "Nested Section", iconName: "arrow.down.circle.fill", iconColor: .green,
                                 scrollSteps: [.init(proxy: "main")]),
                MDSCoachmarkItem(id: "t5-inner-title", title: "Inner Scroll", iconName: "square.fill", iconColor: .teal,
                                 scrollSteps: [.init(proxy: "main"), .init(proxy: "innerVertical")]),

                // 3-level scroll: main → innerVertical → deepCarousel → card
                MDSCoachmarkItem(id: "t5-deep-card-0", title: "Deep Card 0", description: "First card in deeply nested carousel.",
                                 iconName: "diamond.fill", iconColor: .orange,
                                 scrollSteps: [.init(proxy: "main"), .init(proxy: "innerVertical"), .init(proxy: "deepCarousel")]),
                MDSCoachmarkItem(id: "t5-deep-card-7", title: "Deep Card 7", description: "Scrolled horizontally 3 levels deep.",
                                 iconName: "star.fill", iconColor: .yellow,
                                 scrollSteps: [.init(proxy: "main"), .init(proxy: "innerVertical"), .init(proxy: "deepCarousel")]),

                MDSCoachmarkItem(id: "t5-inner-bottom", title: "Inner Bottom", iconName: "arrow.down.to.line", iconColor: .purple,
                                 scrollSteps: [.init(proxy: "main"), .init(proxy: "innerVertical")]),

                MDSCoachmarkItem(id: "t5-after-nested", title: "After Nested", iconName: "arrow.up.circle.fill", iconColor: .indigo,
                                 scrollSteps: [.init(proxy: "main")]),
                
                MDSCoachmarkItem(id: "t5-end", title: "Complete!", iconName: "checkmark.circle.fill", iconColor: .green,
                                 scrollSteps: [.init(proxy: "main")])
            ],
            scrollCoordinator: coordinator
        )
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
                                .coachmarkAnchor("t6-followers")
                            StatsCard(title: "Posts", value: "148", icon: "square.grid.2x2.fill", color: .purple)
                                .coachmarkAnchor("t6-posts")
                        }
                        .padding(.horizontal, 16).padding(.top, 12)

                        Text("Featured").font(.subheadline.bold()).foregroundColor(.secondary)
                            .padding(.horizontal, 16).padding(.top, 16)

                        ScrollViewReader { cp in
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(0..<10) { i in
                                        CardView(index: i + 30).coachmarkAnchor("t6-featured-\(i)")
                                    }
                                }.padding(.horizontal, 16)
                            }
                            .coachmarkScrollProxy("t6-carousel", proxy: cp, coordinator: coordinator)
                        }
                        .padding(.top, 8)
                    } header: {
                        VStack(spacing: 0) {
                            tourButton.padding(.horizontal, 16).padding(.top, 12)
                            Text("My Profile").font(.title.bold())
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 16).padding(.top, 8)
                                .coachmarkAnchor("t6-header")
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
                            .padding(.vertical, 10).coachmarkAnchor("t6-categories")
                            Divider()
                        }
                        .background(Color(UIColor.systemBackground))
                    }

                    ForEach(0..<30) { i in
                        LazyListRow(index: i + 100)
                            .padding(.horizontal, 16).padding(.top, 8)
                            .coachmarkAnchor("t6-row-\(i)")
                    }
                }
                .padding(.bottom, 40)
            }
            .coachmarkScrollProxy("main", proxy: proxy, coordinator: coordinator)
        }
        .coachmarkOverlay(
            isPresented: $showTour,
            items: [
                MDSCoachmarkItem(id: "t6-header", title: "Profile Header", iconName: "person.circle.fill", iconColor: .blue),
                MDSCoachmarkItem(id: "t6-categories", title: "Categories", iconName: "tag.fill", iconColor: .purple,
                                 scrollSteps: [.init(proxy: "main")]),
                MDSCoachmarkItem(id: "t6-followers", title: "Followers", iconName: "person.2.fill", iconColor: .blue,
                                 scrollSteps: [.init(proxy: "main")]),
                MDSCoachmarkItem(id: "t6-featured-0", title: "First Featured", iconName: "star.fill", iconColor: .yellow,
                                 scrollSteps: [.init(proxy: "main"), .init(proxy: "t6-carousel")]),
                MDSCoachmarkItem(id: "t6-featured-8", title: "Featured 8", iconName: "diamond.fill", iconColor: .orange,
                                 scrollSteps: [.init(proxy: "main"), .init(proxy: "t6-carousel")]),
                MDSCoachmarkItem(id: "t6-row-5", title: "List Item", iconName: "list.bullet.fill", iconColor: .green,
                                 scrollSteps: [.init(proxy: "main")]),
                MDSCoachmarkItem(id: "t6-row-20", title: "Deep Item", iconName: "arrow.down.circle.fill", iconColor: .indigo,
                                 scrollSteps: [.init(proxy: "main")]),
                MDSCoachmarkItem(id: "t6-row-29", title: "Last Item", iconName: "checkmark.circle.fill", iconColor: .teal,
                                 scrollSteps: [.init(proxy: "main")])
            ],
            scrollCoordinator: coordinator
        )
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
    @StateObject var coordinator = MDSCoachmarkScrollCoordinator()
    @State var showTour = false

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    tourButton
                    Text("App Store Style").font(.title.bold())
                        .padding(.horizontal, 16).coachmarkAnchor("t7-title")

                    carouselSection(label: "🔥 Trending", proxyName: "t7-trending", startIndex: 0, anchorPrefix: "t7-trending")
                    PlaceholderBlock(height: 400, color: .blue, label: "Banner").padding(.horizontal, 16).coachmarkAnchor("t7-banner")
                    carouselSection(label: "⭐ Top Rated", proxyName: "t7-toprated", startIndex: 10, anchorPrefix: "t7-toprated")
                    PlaceholderBlock(height: 500, color: .green, label: "Ad Block").padding(.horizontal, 16)
                    carouselSection(label: "🆕 New", proxyName: "t7-new", startIndex: 20, anchorPrefix: "t7-new")
                    PlaceholderBlock(height: 300, color: .purple, label: "Newsletter").padding(.horizontal, 16)
                    carouselSection(label: "💎 Premium", proxyName: "t7-premium", startIndex: 30, anchorPrefix: "t7-premium")
                    Text("That's all!").font(.headline).padding(.horizontal, 16).padding(.vertical, 20).coachmarkAnchor("t7-end")
                }
                .padding(.bottom, 40)
            }
            .coachmarkScrollProxy("main", proxy: proxy, coordinator: coordinator)
        }
        .coachmarkOverlay(
            isPresented: $showTour,
            items: [
                MDSCoachmarkItem(id: "t7-title", title: "App Store", iconName: "square.grid.2x2.fill", iconColor: .blue),
                MDSCoachmarkItem(id: "t7-trending-card-5", title: "Trending #5", iconName: "flame.fill", iconColor: .red,
                                 scrollSteps: [.init(proxy: "main"), .init(proxy: "t7-trending")]),
                MDSCoachmarkItem(id: "t7-banner", title: "Banner", iconName: "megaphone.fill", iconColor: .orange,
                                 scrollSteps: [.init(proxy: "main")]),
                MDSCoachmarkItem(id: "t7-toprated-card-6", title: "Top Rated #6", iconName: "star.fill", iconColor: .yellow,
                                 scrollSteps: [.init(proxy: "main"), .init(proxy: "t7-toprated")]),
                MDSCoachmarkItem(id: "t7-new-card-3", title: "New #3", iconName: "plus.circle.fill", iconColor: .green,
                                 scrollSteps: [.init(proxy: "main"), .init(proxy: "t7-new")]),
                MDSCoachmarkItem(id: "t7-premium-card-7", title: "Premium #7", iconName: "diamond.fill", iconColor: .purple,
                                 scrollSteps: [.init(proxy: "main"), .init(proxy: "t7-premium")]),
                MDSCoachmarkItem(id: "t7-end", title: "Complete!", iconName: "checkmark.circle.fill", iconColor: .teal,
                                 scrollSteps: [.init(proxy: "main")])
            ],
            scrollCoordinator: coordinator
        )
        .navigationTitle("Test 7: Multi Carousel")
        .toolbar { tourButton }
    }

    @ViewBuilder
    private func carouselSection(label: String, proxyName: String, startIndex: Int, anchorPrefix: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label).font(.subheadline.bold()).foregroundColor(.secondary).padding(.horizontal, 16)
            ScrollViewReader { cp in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(0..<8) { i in
                            CardView(index: startIndex + i).coachmarkAnchor("\(anchorPrefix)-card-\(i)")
                        }
                    }.padding(.horizontal, 16)
                }
                .coachmarkScrollProxy(proxyName, proxy: cp, coordinator: coordinator)
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
    @StateObject var coordinator = MDSCoachmarkScrollCoordinator()
    @State var showTour = false

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Text("⚡ Very Top").font(.title.bold())
                        .padding(.horizontal, 16).padding(.top, 8).coachmarkAnchor("t8-very-top")
                    tourButton.padding(.horizontal, 16).padding(.top, 8)
                    Divider().coachmarkAnchor("t8-divider")
                    PlaceholderBlock(height: 100, color: .blue, label: "Small").padding(.horizontal, 16).padding(.top, 12)
                    PlaceholderBlock(height: 1200, color: .green, label: "Massive (1200pt)")
                        .padding(.horizontal, 16).padding(.top, 12).coachmarkAnchor("t8-massive")
                    Text("🏁 After Massive").font(.headline)
                        .padding(.horizontal, 16).padding(.top, 12).coachmarkAnchor("t8-after-massive")
                    PlaceholderBlock(height: 800, color: .orange, label: "Another big").padding(.horizontal, 16).padding(.top, 12)

                    Text("Bottom Carousel").font(.subheadline.bold()).foregroundColor(.secondary)
                        .padding(.horizontal, 16).padding(.top, 20)
                    ScrollViewReader { bcp in
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(0..<10) { i in
                                    CardView(index: i + 40).coachmarkAnchor("t8-bottom-card-\(i)")
                                }
                            }.padding(.horizontal, 16)
                        }
                        .coachmarkScrollProxy("t8-bottomCarousel", proxy: bcp, coordinator: coordinator)
                    }
                    .padding(.top, 8)

                    Text("🏆 The Very Last Item").font(.title2.bold()).foregroundColor(.green)
                        .frame(maxWidth: .infinity).padding(.vertical, 40).coachmarkAnchor("t8-very-bottom")
                }
                .padding(.bottom, 40)
            }
            .coachmarkScrollProxy("main", proxy: proxy, coordinator: coordinator)
        }
        .coachmarkOverlay(
            isPresented: $showTour,
            items: [
                MDSCoachmarkItem(id: "t8-very-top", title: "Very Top", iconName: "arrow.up.to.line", iconColor: .blue),
                MDSCoachmarkItem(id: "t8-divider", title: "Divider", description: "Zero-height edge case.", iconName: "minus", iconColor: .gray,
                                 scrollSteps: [.init(proxy: "main")]),
                MDSCoachmarkItem(id: "t8-massive", title: "Massive Block", iconName: "square.fill", iconColor: .green,
                                 scrollSteps: [.init(proxy: "main")]),
                MDSCoachmarkItem(id: "t8-after-massive", title: "After Massive", iconName: "flag.fill", iconColor: .red,
                                 scrollSteps: [.init(proxy: "main")]),
                MDSCoachmarkItem(id: "t8-bottom-card-0", title: "Bottom Card 0", iconName: "square.fill", iconColor: .orange,
                                 scrollSteps: [.init(proxy: "main"), .init(proxy: "t8-bottomCarousel")]),
                MDSCoachmarkItem(id: "t8-bottom-card-9", title: "Bottom Card 9", iconName: "star.fill", iconColor: .yellow,
                                 scrollSteps: [.init(proxy: "main"), .init(proxy: "t8-bottomCarousel")]),
                MDSCoachmarkItem(id: "t8-very-bottom", title: "Very Bottom", iconName: "trophy.fill", iconColor: .green,
                                 scrollSteps: [.init(proxy: "main")])
            ],
            scrollCoordinator: coordinator
        )
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
