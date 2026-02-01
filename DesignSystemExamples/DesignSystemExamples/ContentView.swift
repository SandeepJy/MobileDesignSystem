
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

#Preview {
    ContentView()
}
