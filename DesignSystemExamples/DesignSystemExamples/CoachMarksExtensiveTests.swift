import SwiftUI
import MobileDesignSystem

// MARK: - Card View (reusable)

struct CardView: View {
   let index: Int
   
   var body: some View {
       RoundedRectangle(cornerRadius: 12)
           .fill(cardColor)
           .frame(width: 160, height: 200)
           .overlay {
               VStack(spacing: 8) {
                   Image(systemName: cardIcon)
                       .font(.system(size: 28))
                       .foregroundColor(.white)
                   Text("Card \(index)")
                       .font(.headline)
                       .foregroundColor(.white)
                   Text("Item #\(index)")
                       .font(.caption)
                       .foregroundColor(.white.opacity(0.8))
               }
           }
           .shadow(color: .black.opacity(0.12), radius: 6, x: 0, y: 3)
   }
   
   private var cardColor: Color {
       let colors: [Color] = [.blue, .purple, .teal, .orange, .pink, .green, .indigo, .red, .cyan, .brown]
       return colors[index % colors.count]
   }
   
   private var cardIcon: String {
       let icons = ["square.fill", "circle.fill", "triangle.fill", "diamond.fill", "star.fill",
                    "heart.fill", "hexagon.fill", "pentagon.fill", "cloud.fill", "leaf.fill"]
       return icons[index % icons.count]
   }
}

// MARK: - Section Header

struct SectionHeader: View {
   let title: String
   let subtitle: String?
   
   init(_ title: String, subtitle: String? = nil) {
       self.title = title
       self.subtitle = subtitle
   }
   
   var body: some View {
       VStack(alignment: .leading, spacing: 4) {
           Text(title)
               .font(.title2.bold())
               .foregroundColor(.primary)
           if let sub = subtitle {
               Text(sub)
                   .font(.caption)
                   .foregroundColor(.secondary)
           }
       }
       .padding(.top, 8)
   }
}

// MARK: - Lazy List Row

struct LazyListRow: View {
   let index: Int
   
   var body: some View {
       HStack(spacing: 14) {
           Circle()
               .fill(rowColor)
               .frame(width: 44, height: 44)
               .overlay {
                   Text("\(index)")
                       .font(.headline.bold())
                       .foregroundColor(.white)
               }
           
           VStack(alignment: .leading, spacing: 3) {
               Text("Lazy Item \(index)")
                   .font(.subheadline.bold())
                   .foregroundColor(.primary)
               Text("This is lazy-loaded row number \(index)")
                   .font(.caption)
                   .foregroundColor(.secondary)
           }
           
           Spacer()
           
           Image(systemName: "chevron.right")
               .font(.caption)
               .foregroundColor(.secondary)
       }
       .padding(.vertical, 10)
       .padding(.horizontal, 16)
       .background(Color(UIColor.systemBackground))
       .cornerRadius(10)
       .shadow(color: .black.opacity(0.06), radius: 3, x: 0, y: 2)
   }
   
   private var rowColor: Color {
       let colors: [Color] = [.blue, .green, .orange, .purple, .red, .teal, .pink, .indigo, .cyan, .brown]
       return colors[index % colors.count]
   }
}

// MARK: - Nested Horizontal Carousel Row

struct NestedCarouselRow: View {
   let label: String
   let startIndex: Int
   let coordinator: MDSCoachmarkScrollCoordinator
   let proxyName: String
   
   var body: some View {
       VStack(alignment: .leading, spacing: 8) {
           Text(label)
               .font(.subheadline.bold())
               .foregroundColor(.secondary)
               .padding(.horizontal, 16)
           
           ScrollViewReader { proxy in
               ScrollView(.horizontal, showsIndicators: false) {
                   HStack(spacing: 12) {
                       ForEach(0..<8) { i in
                           let globalIndex = startIndex + i
                           CardView(index: globalIndex)
                               .coachmarkAnchor("nested-card-\(globalIndex)")
                       }
                   }
                   .padding(.horizontal, 16)
               }
               .coachmarkScrollProxy(proxyName, proxy: proxy, coordinator: coordinator)
           }
       }
   }
}

// MARK: - Stats Card

struct StatsCard: View {
   let title: String
   let value: String
   let icon: String
   let color: Color
   
   var body: some View {
       VStack(spacing: 8) {
           HStack {
               Image(systemName: icon)
                   .font(.system(size: 18))
                   .foregroundColor(color)
               Spacer()
               Text(value)
                   .font(.title2.bold())
                   .foregroundColor(.primary)
           }
           
           Text(title)
               .font(.caption)
               .foregroundColor(.secondary)
               .frame(maxWidth: .infinity, alignment: .leading)
       }
       .padding(14)
       .background(Color(UIColor.systemBackground))
       .cornerRadius(12)
       .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
   }
}

// MARK: - Placeholder Block

struct PlaceholderBlock: View {
   let height: CGFloat
   let color: Color
   let label: String
   
   var body: some View {
       RoundedRectangle(cornerRadius: 8)
           .fill(color.opacity(0.15))
           .overlay {
               Text(label)
                   .font(.caption)
                   .foregroundColor(color)
           }
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
                   
                   Text("Welcome Section")
                       .font(.title.bold())
                       .coachmarkAnchor("t1-welcome")
                   
                   PlaceholderBlock(height: 150, color: .blue, label: "Banner Area")
                       .coachmarkAnchor("t1-banner")
                   
                   PlaceholderBlock(height: 300, color: .green, label: "Content Area")
                   
                   StatsCard(title: "Total Users", value: "1,248", icon: "person.2.fill", color: .blue)
                       .coachmarkAnchor("t1-stats")
                   
                   PlaceholderBlock(height: 400, color: .orange, label: "Large Section")
                   
                   Text("Bottom Feature")
                       .font(.headline)
                       .coachmarkAnchor("t1-bottom")
                       .padding(.vertical, 20)
                   
                   PlaceholderBlock(height: 200, color: .purple, label: "Footer Area")
                       .coachmarkAnchor("t1-footer")
                   
               }
               .padding(.horizontal, 16)
               .padding(.bottom, 40)
           }
           .coachmarkScrollProxy("main", proxy: proxy, coordinator: coordinator)
       }
       .coachmarkOverlay(
           isPresented: $showTour,
           items: [
               MDSCoachmarkItem(id: "t1-welcome", title: "Welcome", description: "This is the top of the page.", iconName: "hand.wave.fill", iconColor: .orange),
               MDSCoachmarkItem(id: "t1-banner", title: "Banner", description: "Your main banner image goes here.", iconName: "photo.fill", iconColor: .blue, scrollProxies: ["main"]),
               MDSCoachmarkItem(id: "t1-stats", title: "Stats", description: "Key metrics at a glance.", iconName: "chart.bar.fill", iconColor: .green, scrollProxies: ["main"]),
               MDSCoachmarkItem(id: "t1-bottom", title: "Bottom Feature", description: "Scrolled way down to find this.", iconName: "arrow.down.circle.fill", iconColor: .purple, scrollProxies: ["main"]),
               MDSCoachmarkItem(id: "t1-footer", title: "Footer", description: "The very bottom of the page.", iconName: "checkmark.circle.fill", iconColor: .teal, scrollProxies: ["main"])
           ],
           scrollCoordinator: coordinator
       )
       .navigationTitle("Test 1: Basic Vertical")
       .toolbar { tourButton }
   }
   
   @ViewBuilder
   var tourButton: some View {
       Button("Start Tour") { showTour = true }
           .padding(.horizontal, 16)
           .padding(.vertical, 8)
           .background(Color.blue)
           .foregroundColor(.white)
           .cornerRadius(8)
   }
}

// MARK: - Test 2: Horizontal Carousel (Nested Scroll)

struct Test2_HorizontalCarousel: View {
   @StateObject var coordinator = MDSCoachmarkScrollCoordinator()
   @State var showTour = false
   
   var body: some View {
       ScrollViewReader { proxy in
           ScrollView {
               VStack(alignment: .leading, spacing: 20) {
                   tourButton
                   
                   Text("Featured Cards")
                       .font(.title.bold())
                       .coachmarkAnchor("t2-title")
                   
                   // First carousel
                   ScrollViewReader { carouselProxy in
                       ScrollView(.horizontal, showsIndicators: false) {
                           HStack(spacing: 12) {
                               ForEach(0..<10) { i in
                                   CardView(index: i)
                                       .coachmarkAnchor("t2-card-\(i)")
                               }
                           }
                           .padding(.horizontal, 16)
                       }
                       .coachmarkScrollProxy("carousel1", proxy: carouselProxy, coordinator: coordinator)
                   }
                   
                   PlaceholderBlock(height: 600, color: .blue, label: "Large Section Between Carousels")
                   
                   Text("More Cards")
                       .font(.title2.bold())
                       .coachmarkAnchor("t2-more-title")
                   
                   // Second carousel
                   ScrollViewReader { carousel2Proxy in
                       ScrollView(.horizontal, showsIndicators: false) {
                           HStack(spacing: 12) {
                               ForEach(0..<10) { i in
                                   CardView(index: i + 10)
                                       .coachmarkAnchor("t2-card2-\(i + 10)")
                               }
                           }
                           .padding(.horizontal, 16)
                       }
                       .coachmarkScrollProxy("carousel2", proxy: carousel2Proxy, coordinator: coordinator)
                   }
                   
                   PlaceholderBlock(height: 200, color: .green, label: "Footer")
                       .coachmarkAnchor("t2-footer")
               }
               .padding(.bottom, 40)
           }
           .coachmarkScrollProxy("main", proxy: proxy, coordinator: coordinator)
       }
       .coachmarkOverlay(
           isPresented: $showTour,
           items: [
               MDSCoachmarkItem(id: "t2-title", title: "Featured", description: "Browse the featured card collection.", iconName: "star.fill", iconColor: .yellow),
               MDSCoachmarkItem(id: "t2-card-0", title: "First Card", description: "The first card in the top carousel.", iconName: "square.fill", iconColor: .blue, scrollProxies: ["main", "carousel1"]),
               MDSCoachmarkItem(id: "t2-card-7", title: "Card 7", description: "Scrolled horizontally to card 7.", iconName: "diamond.fill", iconColor: .orange, scrollProxies: ["main", "carousel1"]),
               MDSCoachmarkItem(id: "t2-more-title", title: "More Cards", description: "A second carousel section.", iconName: "rectangle.fill", iconColor: .purple, scrollProxies: ["main"]),
               MDSCoachmarkItem(id: "t2-card2-15", title: "Card 15", description: "Deep in the second carousel.", iconName: "heart.fill", iconColor: .pink, scrollProxies: ["main", "carousel2"]),
               MDSCoachmarkItem(id: "t2-footer", title: "Done!", description: "You've seen everything.", iconName: "checkmark.fill", iconColor: .green, scrollProxies: ["main"])
           ],
           scrollCoordinator: coordinator
       )
       .navigationTitle("Test 2: Carousel")
       .toolbar { tourButton }
   }
   
   @ViewBuilder
   var tourButton: some View {
       Button("Start Tour") { showTour = true }
           .padding(.horizontal, 16)
           .padding(.vertical, 8)
           .background(Color.blue)
           .foregroundColor(.white)
           .cornerRadius(8)
   }
}

// MARK: - Test 3: LazyVStack

struct Test3_LazyVStack: View {
   @StateObject var coordinator = MDSCoachmarkScrollCoordinator()
   @State var showTour = false
   
   var body: some View {
       ScrollViewReader { proxy in
           ScrollView {
               LazyVStack(alignment: .leading, spacing: 12, pinnedViews: []) {
                   tourButton
                       .padding(.horizontal, 16)
                   
                   Text("Lazy Loaded List")
                       .font(.title.bold())
                       .padding(.horizontal, 16)
                       .coachmarkAnchor("t3-title")
                   
                   ForEach(0..<50) { i in
                       LazyListRow(index: i)
                           .padding(.horizontal, 16)
                           .coachmarkAnchor("t3-row-\(i)")
                   }
               }
               .padding(.bottom, 40)
           }
           .coachmarkScrollProxy("main", proxy: proxy, coordinator: coordinator)
       }
       .coachmarkOverlay(
           isPresented: $showTour,
           items: [
               MDSCoachmarkItem(id: "t3-title", title: "Lazy List", description: "50 rows loaded lazily as you scroll.", iconName: "list.bullet.fill", iconColor: .blue),
               MDSCoachmarkItem(id: "t3-row-0", title: "First Row", description: "Row 0 at the very top.", iconName: "arrow.up.circle.fill", iconColor: .green, scrollProxies: ["main"]),
               MDSCoachmarkItem(id: "t3-row-10", title: "Row 10", description: "Scrolled down to row 10.", iconName: "arrow.down.circle.fill", iconColor: .orange, scrollProxies: ["main"]),
               MDSCoachmarkItem(id: "t3-row-25", title: "Row 25", description: "Halfway through the list.", iconName: "arrow.down.circle.fill", iconColor: .purple, scrollProxies: ["main"]),
               MDSCoachmarkItem(id: "t3-row-40", title: "Row 40", description: "Near the bottom — lazily loaded.", iconName: "arrow.down.circle.fill", iconColor: .red, scrollProxies: ["main"]),
               MDSCoachmarkItem(id: "t3-row-49", title: "Last Row", description: "Row 49 — the very last item.", iconName: "checkmark.circle.fill", iconColor: .teal, scrollProxies: ["main"])
           ],
           scrollCoordinator: coordinator
       )
       .navigationTitle("Test 3: LazyVStack")
       .toolbar { tourButton }
   }
   
   @ViewBuilder
   var tourButton: some View {
       Button("Start Tour") { showTour = true }
           .padding(.horizontal, 16)
           .padding(.vertical, 8)
           .background(Color.blue)
           .foregroundColor(.white)
           .cornerRadius(8)
   }
}

// MARK: - Test 4: LazyVStack with Embedded Carousels

struct Test4_LazyWithCarousels: View {
   @StateObject var coordinator = MDSCoachmarkScrollCoordinator()
   @State var showTour = false
   
   /// Carousel sections appear at specific lazy-row positions
   private let carouselPositions: Set<Int> = [5, 15, 30]
   
   var body: some View {
       ScrollViewReader { proxy in
          ScrollView {
              LazyVStack(alignment: .leading, spacing: 14) {
                  tourButton
                      .padding(.horizontal, 16)

                  Text("Mixed Lazy + Carousel")
                      .font(.title.bold())
                      .padding(.horizontal, 16)
                      .coachmarkAnchor("t4-title")

                  ForEach(0..<40) { i in
                      if carouselPositions.contains(i) {
                          carouselSection(at: i)
                      } else {
                          LazyListRow(index: i)
                              .padding(.horizontal, 16)
                              .coachmarkAnchor("t4-row-\(i)")
                      }
                  }
              }
              .padding(.bottom, 40)
              // ↓ Collect ALL proxy preferences from the entire subtree
              .collectCoachmarkProxies(into: coordinator)
          }
          // ↓ Main proxy still registered via preference
          .coachmarkScrollProxy("main", proxy: proxy, coordinator: coordinator)
      }
       .coachmarkOverlay(
           isPresented: $showTour,
           items: [
               MDSCoachmarkItem(id: "t4-title", title: "Mixed Layout", description: "Lazy rows with carousels scattered in.", iconName: "square.grid.2x2.fill", iconColor: .blue),
               MDSCoachmarkItem(id: "t4-row-2", title: "Row 2", description: "An early lazy row.", iconName: "list.bullet", iconColor: .green, scrollProxies: ["main"]),
               MDSCoachmarkItem(id: "t4-carousel-5-card-3", title: "Carousel Card", description: "Card 3 inside the first embedded carousel at position 5.", iconName: "square.fill", iconColor: .orange, scrollProxies: ["main", "t4-carousel-5"]),
               MDSCoachmarkItem(id: "t4-row-10", title: "Row 10", description: "A row between the first and second carousels.", iconName: "list.bullet", iconColor: .purple, scrollProxies: ["main"]),
               MDSCoachmarkItem(id: "t4-carousel-15-card-6", title: "Deep Carousel Card", description: "Card 6 in the second carousel (position 15).", iconName: "heart.fill", iconColor: .pink, scrollProxies: ["main", "t4-carousel-15"]),
               MDSCoachmarkItem(id: "t4-row-25", title: "Row 25", description: "Well past the second carousel.", iconName: "list.bullet", iconColor: .indigo, scrollProxies: ["main"]),
               MDSCoachmarkItem(id: "t4-carousel-30-card-5", title: "Last Carousel", description: "Card 5 in the deepest carousel.", iconName: "star.fill", iconColor: .yellow, scrollProxies: ["main", "t4-carousel-30"]),
               MDSCoachmarkItem(id: "t4-row-39", title: "Final Row", description: "The last lazy row in the list.", iconName: "checkmark.circle.fill", iconColor: .teal, scrollProxies: ["main"])
           ],
           scrollCoordinator: coordinator
       )
       .navigationTitle("Test 4: Lazy + Carousels")
       .toolbar { tourButton }
   }
   
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
                // ↓ Now emits a preference — no onAppear needed
                .coachmarkScrollProxy(proxyName, proxy: carouselProxy, coordinator: coordinator)
            }
        }
        .padding(.vertical, 8)
    }
   
   @ViewBuilder
   var tourButton: some View {
       Button("Start Tour") { showTour = true }
           .padding(.horizontal, 16)
           .padding(.vertical, 8)
           .background(Color.blue)
           .foregroundColor(.white)
           .cornerRadius(8)
   }
}

// MARK: - Test 5: Deeply Nested (3 Levels)

struct Test5_DeepNesting: View {
   @StateObject var coordinator = MDSCoachmarkScrollCoordinator()
   @State var showTour = false
   
   var body: some View {
       ScrollViewReader { mainProxy in
           ScrollView {
               VStack(alignment: .leading, spacing: 20) {
                   tourButton
                   
                   Text("Deep Nesting Test")
                       .font(.title.bold())
                       .padding(.horizontal, 16)
                       .coachmarkAnchor("t5-title")
                   
                   PlaceholderBlock(height: 500, color: .blue, label: "Spacer to push content down")
                       .padding(.horizontal, 16)
                   
                   // Level 2: A vertical inner scroll containing a horizontal carousel
                   Text("Nested Section")
                       .font(.headline)
                       .padding(.horizontal, 16)
                       .coachmarkAnchor("t5-nested-title")
                   
                   ScrollViewReader { verticalInnerProxy in
                       ScrollView(.vertical) {
                           VStack(alignment: .leading, spacing: 16) {
                               Text("Inner Vertical Scroll")
                                   .font(.subheadline.bold())
                                   .foregroundColor(.secondary)
                                   .padding(.horizontal, 16)
                                   .coachmarkAnchor("t5-inner-title")
                               
                               PlaceholderBlock(height: 300, color: .green, label: "Inner spacer")
                                   .padding(.horizontal, 16)
                               
                               Text("Carousel Inside Inner Scroll")
                                   .font(.subheadline)
                                   .foregroundColor(.secondary)
                                   .padding(.horizontal, 16)
                               
                               // Level 3: Horizontal carousel inside the vertical inner scroll
                               ScrollViewReader { deepCarouselProxy in
                                   ScrollView(.horizontal, showsIndicators: false) {
                                       HStack(spacing: 12) {
                                           ForEach(0..<10) { i in
                                               CardView(index: i + 20)
                                                   .coachmarkAnchor("t5-deep-card-\(i)")
                                           }
                                       }
                                       .padding(.horizontal, 16)
                                   }
                                   .coachmarkScrollProxy("deepCarousel", proxy: deepCarouselProxy, coordinator: coordinator)
                               }
                               
                               PlaceholderBlock(height: 200, color: .purple, label: "More inner content")
                                   .padding(.horizontal, 16)
                                   .coachmarkAnchor("t5-inner-bottom")
                           }
                           .padding(.vertical, 12)
                       }
                       .frame(height: 500)
                       .background(Color(UIColor.systemGray6))
                       .cornerRadius(12)
                       .coachmarkScrollProxy("innerVertical", proxy: verticalInnerProxy, coordinator: coordinator)
                   }
                   .padding(.horizontal, 16)
                   
                   PlaceholderBlock(height: 300, color: .orange, label: "Content after nested section")
                       .padding(.horizontal, 16)
                       .coachmarkAnchor("t5-after-nested")
                   
                   Text("End of Page")
                       .font(.headline)
                       .padding(.horizontal, 16)
                       .coachmarkAnchor("t5-end")
               }
               .padding(.bottom, 40)
           }
           .coachmarkScrollProxy("main", proxy: mainProxy, coordinator: coordinator)
       }
       .coachmarkOverlay(
           isPresented: $showTour,
           items: [
               MDSCoachmarkItem(id: "t5-title", title: "Deep Nesting", description: "This test has 3 levels of scrolling.", iconName: "square.layers.fill", iconColor: .blue),
               MDSCoachmarkItem(id: "t5-nested-title", title: "Nested Section", description: "A vertically scrollable container lives below.", iconName: "arrow.down.circle.fill", iconColor: .green, scrollProxies: ["main"]),
               MDSCoachmarkItem(id: "t5-inner-title", title: "Inner Scroll", description: "Inside the nested vertical scroll.", iconName: "square.fill", iconColor: .teal, scrollProxies: ["main", "innerVertical"]),
               MDSCoachmarkItem(id: "t5-deep-card-0", title: "Deep Card 0", description: "First card in the deeply nested carousel.", iconName: "diamond.fill", iconColor: .orange, scrollProxies: ["main", "innerVertical", "deepCarousel"]),
               MDSCoachmarkItem(id: "t5-deep-card-7", title: "Deep Card 7", description: "Card 7 — scrolled horizontally inside the nested vertical scroll.", iconName: "star.fill", iconColor: .yellow, scrollProxies: ["main", "innerVertical", "deepCarousel"]),
               MDSCoachmarkItem(id: "t5-inner-bottom", title: "Inner Bottom", description: "Bottom of the inner vertical scroll.", iconName: "arrow.down.to.line", iconColor: .purple, scrollProxies: ["main", "innerVertical"]),
               MDSCoachmarkItem(id: "t5-after-nested", title: "After Nested", description: "Back in the main scroll.", iconName: "arrow.up.circle.fill", iconColor: .indigo, scrollProxies: ["main"]),
               MDSCoachmarkItem(id: "t5-end", title: "Complete!", description: "Deep nesting tour finished.", iconName: "checkmark.circle.fill", iconColor: .green, scrollProxies: ["main"])
           ],
           scrollCoordinator: coordinator
       )
       .navigationTitle("Test 5: Deep Nesting")
       .toolbar { tourButton }
   }
   
   @ViewBuilder
   var tourButton: some View {
       Button("Start Tour") { showTour = true }
           .padding(.horizontal, 16)
           .padding(.vertical, 8)
           .background(Color.blue)
           .foregroundColor(.white)
           .cornerRadius(8)
   }
}

// MARK: - Test 6: LazyVStack with Pinned Header + Carousel

struct Test6_PinnedHeaderLazy: View {
   @StateObject var coordinator = MDSCoachmarkScrollCoordinator()
   @State var showTour = false
   
   private let categories = ["All", "Popular", "New", "Trending", "Classic"]
   
   var body: some View {
       ScrollViewReader { proxy in
           ScrollView {
               LazyVStack(alignment: .leading, spacing: 0, pinnedViews: [.sectionHeaders]) {
                   
                   Section {
                       // Stats row
                       HStack(spacing: 12) {
                           StatsCard(title: "Followers", value: "2.4K", icon: "person.2.fill", color: .blue)
                               .coachmarkAnchor("t6-followers")
                           StatsCard(title: "Posts", value: "148", icon: "square.grid.2x2.fill", color: .purple)
                               .coachmarkAnchor("t6-posts")
                       }
                       .padding(.horizontal, 16)
                       .padding(.top, 12)
                       
                       // Carousel
                       Text("Featured")
                           .font(.subheadline.bold())
                           .foregroundColor(.secondary)
                           .padding(.horizontal, 16)
                           .padding(.top, 16)
                       
                       ScrollViewReader { carouselProxy in
                           ScrollView(.horizontal, showsIndicators: false) {
                               HStack(spacing: 12) {
                                   ForEach(0..<10) { i in
                                       CardView(index: i + 30)
                                           .coachmarkAnchor("t6-featured-\(i)")
                                   }
                               }
                               .padding(.horizontal, 16)
                           }
                           .coachmarkScrollProxy("t6-carousel", proxy: carouselProxy, coordinator: coordinator)
                       }
                       .padding(.top, 8)
                       
                   } header: {
                       VStack(spacing: 0) {
                           tourButton
                               .padding(.horizontal, 16)
                               .padding(.top, 12)
                           
                           Text("My Profile")
                               .font(.title.bold())
                               .frame(maxWidth: .infinity, alignment: .leading)
                               .padding(.horizontal, 16)
                               .padding(.top, 8)
                               .coachmarkAnchor("t6-header")
                           
                           // Category pills (pinned)
                           ScrollView(.horizontal, showsIndicators: false) {
                               HStack(spacing: 8) {
                                   ForEach(categories, id: \.self) { cat in
                                       Text(cat)
                                           .font(.caption.bold())
                                           .padding(.horizontal, 12)
                                           .padding(.vertical, 6)
                                           .background(cat == "All" ? Color.blue : Color(UIColor.systemGray5))
                                           .foregroundColor(cat == "All" ? .white : .primary)
                                           .cornerRadius(20)
                                   }
                               }
                               .padding(.horizontal, 16)
                           }
                           .padding(.vertical, 10)
                           .coachmarkAnchor("t6-categories")
                           
                           Divider()
                       }
                       .background(Color(UIColor.systemBackground))
                   }
                   
                   // Lazy list below
                   ForEach(0..<30) { i in
                       LazyListRow(index: i + 100)
                           .padding(.horizontal, 16)
                           .padding(.top, 8)
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
               MDSCoachmarkItem(id: "t6-header", title: "Profile Header", description: "Your pinned profile header.", iconName: "person.circle.fill", iconColor: .blue),
               MDSCoachmarkItem(id: "t6-categories", title: "Categories", description: "Filter by category using these pills.", iconName: "tag.fill", iconColor: .purple, scrollProxies: ["main"]),
               MDSCoachmarkItem(id: "t6-followers", title: "Followers", description: "Your follower count.", iconName: "person.2.fill", iconColor: .blue, scrollProxies: ["main"]),
               MDSCoachmarkItem(id: "t6-featured-0", title: "First Featured", description: "The first card in your featured carousel.", iconName: "star.fill", iconColor: .yellow, scrollProxies: ["main", "t6-carousel"]),
               MDSCoachmarkItem(id: "t6-featured-8", title: "Featured Card 8", description: "Scrolled to card 8 in the carousel.", iconName: "diamond.fill", iconColor: .orange, scrollProxies: ["main", "t6-carousel"]),
               MDSCoachmarkItem(id: "t6-row-5", title: "List Item", description: "Lazy rows below the carousel.", iconName: "list.bullet.fill", iconColor: .green, scrollProxies: ["main"]),
               MDSCoachmarkItem(id: "t6-row-20", title: "Deep List Item", description: "Row 20 in the lazy list.", iconName: "arrow.down.circle.fill", iconColor: .indigo, scrollProxies: ["main"]),
               MDSCoachmarkItem(id: "t6-row-29", title: "Last Item", description: "The final row.", iconName: "checkmark.circle.fill", iconColor: .teal, scrollProxies: ["main"])
           ],
           scrollCoordinator: coordinator
       )
       .navigationTitle("Test 6: Pinned Header")
       .toolbar { tourButton }
   }
   
   @ViewBuilder
   var tourButton: some View {
       Button("Start Tour") { showTour = true }
           .padding(.horizontal, 16)
           .padding(.vertical, 8)
           .background(Color.blue)
           .foregroundColor(.white)
           .cornerRadius(8)
   }
}

// MARK: - Test 7: Multiple Carousels with Large Gaps

struct Test7_MultipleCarouselsLargeGaps: View {
   @StateObject var coordinator = MDSCoachmarkScrollCoordinator()
   @State var showTour = false
   
   var body: some View {
       ScrollViewReader { proxy in
           ScrollView {
               VStack(alignment: .leading, spacing: 24) {
                   tourButton
                   
                   Text("App Store Style")
                       .font(.title.bold())
                       .padding(.horizontal, 16)
                       .coachmarkAnchor("t7-title")
                   
                   // Carousel A
                   carouselSection(
                       label: "🔥 Trending Now",
                       proxyName: "t7-trending",
                       startIndex: 0,
                       anchorPrefix: "t7-trending"
                   )
                   
                   PlaceholderBlock(height: 400, color: .blue, label: "Promoted Banner")
                       .padding(.horizontal, 16)
                       .coachmarkAnchor("t7-banner")
                   
                   // Carousel B
                   carouselSection(
                       label: "⭐ Top Rated",
                       proxyName: "t7-toprated",
                       startIndex: 10,
                       anchorPrefix: "t7-toprated"
                   )
                   
                   PlaceholderBlock(height: 500, color: .green, label: "Large Ad Block")
                       .padding(.horizontal, 16)
                   
                   // Carousel C
                   carouselSection(
                       label: "🆕 New Arrivals",
                       proxyName: "t7-new",
                       startIndex: 20,
                       anchorPrefix: "t7-new"
                   )
                   
                   PlaceholderBlock(height: 300, color: .purple, label: "Newsletter Signup")
                       .padding(.horizontal, 16)
                   
                   // Carousel D
                   carouselSection(
                       label: "💎 Premium Picks",
                       proxyName: "t7-premium",
                       startIndex: 30,
                       anchorPrefix: "t7-premium"
                   )
                   
                   Text("That's all folks!")
                       .font(.headline)
                       .padding(.horizontal, 16)
                       .padding(.vertical, 20)
                       .coachmarkAnchor("t7-end")
               }
               .padding(.bottom, 40)
           }
           .coachmarkScrollProxy("main", proxy: proxy, coordinator: coordinator)
       }
       .coachmarkOverlay(
           isPresented: $showTour,
           items: [
               MDSCoachmarkItem(id: "t7-title", title: "App Store", description: "Multiple carousels with large gaps between them.", iconName: "square.grid.2x2.fill", iconColor: .blue),
               MDSCoachmarkItem(id: "t7-trending-card-5", title: "Trending #5", description: "Card 5 in the Trending carousel.", iconName: "flame.fill", iconColor: .red, scrollProxies: ["main", "t7-trending"]),
               MDSCoachmarkItem(id: "t7-banner", title: "Banner Ad", description: "A large promoted banner.", iconName: "megaphone.fill", iconColor: .orange, scrollProxies: ["main"]),
               MDSCoachmarkItem(id: "t7-toprated-card-6", title: "Top Rated #6", description: "Card 6 in Top Rated.", iconName: "star.fill", iconColor: .yellow, scrollProxies: ["main", "t7-toprated"]),
               MDSCoachmarkItem(id: "t7-new-card-3", title: "New #3", description: "Card 3 in New Arrivals.", iconName: "plus.circle.fill", iconColor: .green, scrollProxies: ["main", "t7-new"]),
               MDSCoachmarkItem(id: "t7-premium-card-7", title: "Premium #7", description: "Card 7 in Premium Picks.", iconName: "diamond.fill", iconColor: .purple, scrollProxies: ["main", "t7-premium"]),
               MDSCoachmarkItem(id: "t7-end", title: "Complete!", description: "Tour of all carousels done.", iconName: "checkmark.circle.fill", iconColor: .teal, scrollProxies: ["main"])
           ],
           scrollCoordinator: coordinator
       )
       .navigationTitle("Test 7: Multi Carousel")
       .toolbar { tourButton }
   }
   
   @ViewBuilder
   private func carouselSection(
       label: String,
       proxyName: String,
       startIndex: Int,
       anchorPrefix: String
   ) -> some View {
       VStack(alignment: .leading, spacing: 8) {
           Text(label)
               .font(.subheadline.bold())
               .foregroundColor(.secondary)
               .padding(.horizontal, 16)
           
           ScrollViewReader { carouselProxy in
               ScrollView(.horizontal, showsIndicators: false) {
                   HStack(spacing: 12) {
                       ForEach(0..<8) { i in
                           CardView(index: startIndex + i)
                               .coachmarkAnchor("\(anchorPrefix)-card-\(i)")
                       }
                   }
                   .padding(.horizontal, 16)
               }
               .coachmarkScrollProxy(proxyName, proxy: carouselProxy, coordinator: coordinator)
           }
       }
   }
   
   @ViewBuilder
   var tourButton: some View {
       Button("Start Tour") { showTour = true }
           .padding(.horizontal, 16)
           .padding(.vertical, 8)
           .background(Color.blue)
           .foregroundColor(.white)
           .cornerRadius(8)
   }
}

// MARK: - Test 8: Edge Cases (items at very top, very bottom, zero-height spacers)

struct Test8_EdgeCases: View {
   @StateObject var coordinator = MDSCoachmarkScrollCoordinator()
   @State var showTour = false
   
   var body: some View {
       ScrollViewReader { proxy in
           ScrollView {
               VStack(alignment: .leading, spacing: 0) {
                   // Item at the very top — no scroll needed
                   Text("⚡ Very Top")
                       .font(.title.bold())
                       .padding(.horizontal, 16)
                       .padding(.top, 8)
                       .coachmarkAnchor("t8-very-top")
                   
                   tourButton
                       .padding(.horizontal, 16)
                       .padding(.top, 8)
                   
                   // Zero-height divider (shouldn't break anything)
                   Divider()
                       .coachmarkAnchor("t8-divider")
                   
                   PlaceholderBlock(height: 100, color: .blue, label: "Small block")
                       .padding(.horizontal, 16)
                       .padding(.top, 12)
                   
                   // Very tall single block
                   PlaceholderBlock(height: 1200, color: .green, label: "Massive block (1200pt)")
                       .padding(.horizontal, 16)
                       .padding(.top, 12)
                       .coachmarkAnchor("t8-massive")
                   
                   // Item immediately after massive block
                   Text("🏁 Right After Massive")
                       .font(.headline)
                       .padding(.horizontal, 16)
                       .padding(.top, 12)
                       .coachmarkAnchor("t8-after-massive")
                   
                   // Another tall block
                   PlaceholderBlock(height: 800, color: .orange, label: "Another big block")
                       .padding(.horizontal, 16)
                       .padding(.top, 12)
                   
                   // Carousel at the very bottom
                   Text("Bottom Carousel")
                       .font(.subheadline.bold())
                       .foregroundColor(.secondary)
                       .padding(.horizontal, 16)
                       .padding(.top, 20)
                   
                   ScrollViewReader { bottomCarouselProxy in
                       ScrollView(.horizontal, showsIndicators: false) {
                           HStack(spacing: 12) {
                               ForEach(0..<10) { i in
                                   CardView(index: i + 40)
                                       .coachmarkAnchor("t8-bottom-card-\(i)")
                               }
                           }
                           .padding(.horizontal, 16)
                       }
                       .coachmarkScrollProxy("t8-bottomCarousel", proxy: bottomCarouselProxy, coordinator: coordinator)
                   }
                   .padding(.top, 8)
                   
                   // Very last item
                   Text("🏆 The Very Last Item")
                       .font(.title2.bold())
                       .foregroundColor(.green)
                       .frame(maxWidth: .infinity)
                       .padding(.vertical, 40)
                       .coachmarkAnchor("t8-very-bottom")
               }
               .padding(.bottom, 40)
           }
           .coachmarkScrollProxy("main", proxy: proxy, coordinator: coordinator)
       }
       .coachmarkOverlay(
           isPresented: $showTour,
           items: [
               MDSCoachmarkItem(id: "t8-very-top", title: "Very Top", description: "The first item — no scrolling needed.", iconName: "arrow.up.to.line", iconColor: .blue),
               MDSCoachmarkItem(id: "t8-divider", title: "Divider", description: "A zero-height divider. Edge case!", iconName: "minus", iconColor: .gray, scrollProxies: ["main"]),
               MDSCoachmarkItem(id: "t8-massive", title: "Massive Block", description: "A 1200pt tall block.", iconName: "square.fill", iconColor: .green, scrollProxies: ["main"]),
               MDSCoachmarkItem(id: "t8-after-massive", title: "After Massive", description: "Right below the huge block.", iconName: "flag.fill", iconColor: .red, scrollProxies: ["main"]),
               MDSCoachmarkItem(id: "t8-bottom-card-0", title: "Bottom Card 0", description: "First card in the bottom carousel.", iconName: "square.fill", iconColor: .orange, scrollProxies: ["main", "t8-bottomCarousel"]),
               MDSCoachmarkItem(id: "t8-bottom-card-9", title: "Bottom Card 9", description: "Last card in bottom carousel.", iconName: "star.fill", iconColor: .yellow, scrollProxies: ["main", "t8-bottomCarousel"]),
               MDSCoachmarkItem(id: "t8-very-bottom", title: "Very Bottom", description: "The absolute last item on the page.", iconName: "trophy.fill", iconColor: .green, scrollProxies: ["main"])
           ],
           scrollCoordinator: coordinator
       )
       .navigationTitle("Test 8: Edge Cases")
       .toolbar { tourButton }
   }
   
   @ViewBuilder
   var tourButton: some View {
       Button("Start Tour") { showTour = true }
           .padding(.horizontal, 16)
           .padding(.vertical, 8)
           .background(Color.blue)
           .foregroundColor(.white)
           .cornerRadius(8)
   }
}

// MARK: - Test Navigation Root

struct CoachmarkTestRoot: View {
   var body: some View {
       NavigationView {
           List {
               Section("Basic") {
                   NavigationLink("Test 1: Basic Vertical Scroll", destination: Test1_BasicVerticalScroll())
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

// MARK: - Preview Entry

#Preview {
   CoachmarkTestRoot()
}
