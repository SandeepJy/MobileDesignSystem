
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
            
            CoachmarkTestRoot()
                .tabItem {
                    Label("Coachmark", systemImage: "questionmark.circle")
                }
                .tag(3)
        }
    }
}

struct ContentView2: View {
    @StateObject var scrollCoordinator = MDSCoachmarkScrollCoordinator()
    @State var showTour = false

    @Namespace var topID
    @Namespace var bottomID
        
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                Button("Scroll to Bottom") {
                    withAnimation {
                        proxy.scrollTo("febottom")
                    }
                }
                .id(topID)
                
                LazyVStack(spacing: 0) {
                    Text("Lazy Loaded List")
                        .font(.title.bold())
                        .padding(.horizontal, 16)
                        .coachmarkAnchor("t3-title")
                    
                    ForEach(0..<1500) { i in
                        LazyListRow(index: i)
                            .padding(.horizontal, 16)
                            .coachmarkAnchor("t3-row-\(i)")
                    }
                    
                    Text("Under foreach")
                        .id("febottom")
                }
                
                Button("Top") {
                    withAnimation {
                        proxy.scrollTo(topID)
                    }
                }
                .id(bottomID)
            }
        }
        
    }
    func color(fraction: Double) -> Color {
        Color(red: fraction, green: 1 - fraction, blue: 0.5)
    }
}


struct CardView2: View {
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
