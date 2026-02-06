
import SwiftUI
import MobileDesignSystem

struct ContentView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            InputFieldExamplesView()
                .tabItem {
                    Label("Input Field", systemImage: "textfield")
                }
                .tag(0)
            
            TextViewExamplesView()
                .tabItem {
                    Label("Text View", systemImage: "text.alignleft")
                }
                .tag(1)
            
            CombinedExamplesView()
                .tabItem {
                    Label("Combined", systemImage: "square.grid.2x2")
                }
                .tag(2)
            
            CoachmarkExamplesView()
                .tabItem {
                    Label("Coachmark", systemImage: "questionmark.circle")
                }
                .tag(3)
        }
    }
}

struct ContentView1: View {
    @StateObject var scrollCoordinator = MDSCoachmarkScrollCoordinator()
    @State  var showTour = false
    @ViewBuilder
    var body: some View {
        
        ScrollViewReader { mainProxy in
            ScrollView {
                VStack {
                    Text("Header").coachmarkAnchor("header")
                    Button("Start Tour") {
                        showTour = true
                    }
                    // Nested horizontal scroll
                    ScrollViewReader { carouselProxy in
                        ScrollView(.horizontal) {
                            HStack {
                                ForEach(0..<10) { i in
                                    CardView(index: i)
                                        .coachmarkAnchor("card-\(i)")
                                }
                            }
                        }
                        .coachmarkScrollProxy("carousel", proxy: carouselProxy, coordinator: scrollCoordinator)
                    }
                    
                    Text("Footer").coachmarkAnchor("footer")
                }
            }
            .coachmarkScrollProxy("main", proxy: mainProxy, coordinator: scrollCoordinator)
        }
        .coachmarkOverlay(
            isPresented: $showTour,
            items: [
                MDSCoachmarkItem(
                    id: "header",
                    title: "Header",
                    description: "This is the header.",
                    iconName: "heart.fill",
                    iconColor: .pink
                ),
                MDSCoachmarkItem(
                    id: "card-5",
                    title: "Card 5",
                    description: "This is card 5 in the horizontal scroll.",
                    iconName: "pencil",
                    iconColor: .blue,
                    scrollProxies: ["main", "carousel"]
                ),
                MDSCoachmarkItem(
                    id: "footer",
                    title: "Footer",
                    description: "This is a footer.",
                    iconName: "checkmark",
                    iconColor: .blue,
                    scrollProxies: ["main"]
                )
            ],
            scrollCoordinator: scrollCoordinator
        )
    }
}

struct CardView: View {
    let index: Int
    var body: some View {
        VStack {
            Text("Hello, World! \(index)" )
                .padding()
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .border(.blue)
        .frame(width: 200, height: 200)
    }
}


#Preview {
    ContentView()
}
