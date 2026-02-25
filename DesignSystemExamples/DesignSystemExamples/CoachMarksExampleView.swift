import SwiftUI
import MobileDesignSystem

struct CoachmarkExamplesView: View {
    @State private var showBasicCoachmarks = false
    @State private var showScrollCoachmarks = false
    @State private var showCustomCoachmarks = false
    @State private var showNoExitCoachmarks = false
    @State private var coachmarkLog: [String] = []
    
    @StateObject private var scrollCoordinator = MDSCoachmarkScrollCoordinator()
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 24) {
                    Text("MDSCoachmark Examples")
                        .font(.largeTitle)
                        .bold()
                        .padding(.top)
                    
                    // MARK: - Basic Coachmark Example
                    
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Basic Coachmark Tour")
                            .font(.title2)
                            .bold()
                        
                        Text("A simple 4-step sequence with default styling.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Button {
                            showBasicCoachmarks = true
                        } label: {
                            Label("Start Basic Tour", systemImage: "play.fill")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(12)
                        }
                        .coachmarkAnchor("basic-start")
                        
                        HStack(spacing: 16) {
                            FeatureCard(icon: "magnifyingglass", title: "Search", color: .orange)
                                .coachmarkAnchor("basic-search")
                            
                            FeatureCard(icon: "heart.fill", title: "Favorites", color: .pink)
                                .coachmarkAnchor("basic-favorites")
                        }
                        
                        FeatureCard(icon: "gearshape.fill", title: "Settings", color: .gray)
                            .coachmarkAnchor("basic-settings")
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.05), radius: 5)
                    
                    // MARK: - Scroll-Aware Coachmark Example
                    
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Scroll-Aware Tour")
                            .font(.title2)
                            .bold()
                        
                        Text("This tour highlights elements that are off-screen.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Button {
                            showScrollCoachmarks = true
                        } label: {
                            Label("Start Scroll Tour", systemImage: "arrow.up.and.down")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.teal)
                                .cornerRadius(12)
                        }
                        .coachmarkAnchor("scroll-start")
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.05), radius: 5)
                    
                    // MARK: - Custom Styled Coachmark Example
                    
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Custom Styled Tour")
                            .font(.title2)
                            .bold()
                        
                        Text("Custom colors and appearance.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Button {
                            showCustomCoachmarks = true
                        } label: {
                            Label("Start Custom Tour", systemImage: "paintbrush.fill")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.purple)
                                .cornerRadius(12)
                        }
                        .coachmarkAnchor("custom-start")
                        
                        HStack(spacing: 12) {
                            ProfileBadge(name: "Alice", color: .purple)
                                .coachmarkAnchor("custom-profile")
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Alice Johnson")
                                    .font(.headline)
                                Text("Premium Member")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "bell.badge.fill")
                                .font(.title2)
                                .foregroundColor(.orange)
                                .coachmarkAnchor("custom-notifications")
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.05), radius: 5)
                    
                    // MARK: - Spacer Content
                    
                    VStack(spacing: 16) {
                        Text("📋 More Content Area")
                            .font(.title3)
                            .bold()
                        
                        ForEach(0..<6) { index in
                            HStack {
                                Image(systemName: "doc.text.fill")
                                    .foregroundColor(.blue)
                                Text("Document \(index + 1)")
                                Spacer()
                                Text("Updated today")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.05), radius: 5)
                    
                    // MARK: - Mandatory Tour
                    
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Mandatory Tour")
                            .font(.title2)
                            .bold()
                        
                        Button {
                            showNoExitCoachmarks = true
                        } label: {
                            Label("Start Mandatory Tour", systemImage: "lock.fill")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .cornerRadius(12)
                        }
                        .coachmarkAnchor("mandatory-step1")
                        
                        HStack(spacing: 16) {
                            StatBox(value: "42", label: "Tasks", color: .blue)
                                .coachmarkAnchor("mandatory-step2")
                            
                            StatBox(value: "12", label: "Done", color: .green)
                                .coachmarkAnchor("mandatory-step3")
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.05), radius: 5)
                    
                    // MARK: - Bottom Section
                    
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "arrow.down.circle.fill")
                                .font(.title)
                                .foregroundColor(.teal)
                            Text("Bottom Feature")
                                .font(.title2)
                                .bold()
                        }
                        .coachmarkAnchor("scroll-bottom")
                        
                        HStack(spacing: 16) {
                            ActionChip(icon: "square.and.arrow.up", label: "Share", color: .blue)
                                .coachmarkAnchor("scroll-share")
                            
                            ActionChip(icon: "bookmark.fill", label: "Save", color: .orange)
                                .coachmarkAnchor("scroll-save")
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.05), radius: 5)
                    
                    // MARK: - Event Log
                    
                    if !coachmarkLog.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Event Log")
                                .font(.title2)
                                .bold()
                            
                            ForEach(Array(coachmarkLog.enumerated()), id: \.offset) { _, entry in
                                Text(entry)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Button("Clear Log") {
                                coachmarkLog.removeAll()
                            }
                            .font(.caption)
                            .foregroundColor(.red)
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                    }
                    
                    Spacer(minLength: 40)
                }
                .padding()
            }
            .coachmarkScrollProxy("main", proxy: proxy, coordinator: scrollCoordinator)
        }
        .background(Color(.systemGroupedBackground))
        
        // MARK: - Coachmark Overlays
        
        .coachmarkOverlay(
            isPresented: $showBasicCoachmarks,
            items: basicCoachmarkItems,
            scrollCoordinator: scrollCoordinator,
            onFinished: { coachmarkLog.append("Basic tour completed ✅") },
            onSkipped: { step in coachmarkLog.append("Basic tour skipped at step \(step + 1)") }
        )
        .coachmarkOverlay(
            isPresented: $showScrollCoachmarks,
            configuration: scrollConfiguration,
            items: scrollCoachmarkItems,
            scrollCoordinator: scrollCoordinator,
            onFinished: { coachmarkLog.append("Scroll tour completed ✅") },
            onSkipped: { step in coachmarkLog.append("Scroll tour skipped at step \(step + 1)") }
        )
        .coachmarkOverlay(
            isPresented: $showCustomCoachmarks,
            configuration: customConfiguration,
            items: customCoachmarkItems,
            scrollCoordinator: scrollCoordinator,
            onFinished: { coachmarkLog.append("Custom tour completed ✅") },
            onSkipped: { step in coachmarkLog.append("Custom tour skipped at step \(step + 1)") }
        )
        .coachmarkOverlay(
            isPresented: $showNoExitCoachmarks,
            configuration: mandatoryConfiguration,
            items: mandatoryCoachmarkItems,
            scrollCoordinator: scrollCoordinator,
            onFinished: { coachmarkLog.append("Mandatory tour completed ✅") }
        )
    }
    
    // MARK: - Coachmark Items (Clean and Simple!)
    
    private var basicCoachmarkItems: [MDSCoachmarkItem] {
        [
            MDSCoachmarkItem(
                id: "basic-start",
                title: "Welcome! 👋",
                description: "This button starts the coachmark tour. Let's explore the features.",
                iconName: "hand.wave.fill",
                iconColor: .orange
            ),
            MDSCoachmarkItem(
                id: "basic-search",
                title: "Search",
                description: "Quickly find what you need across the entire app.",
                iconName: "magnifyingglass",
                iconColor: .orange
            ),
            MDSCoachmarkItem(
                id: "basic-favorites",
                title: "Favorites",
                description: "Save items you love for quick access later.",
                iconName: "heart.fill",
                iconColor: .pink
            ),
            MDSCoachmarkItem(
                id: "basic-settings",
                title: "Settings",
                description: "Customize your experience in the settings panel.",
                iconName: "gearshape.fill",
                iconColor: .gray
            )
        ]
    }
    
    private var scrollConfiguration: MDSCoachmarkConfiguration {
        var config = MDSCoachmarkConfiguration()
        config.accentColor = .teal
        config.defaultIconColor = .teal
        config.spotlightBorderColor = .teal
        config.spotlightBorderWidth = 2
        config.spotlightPadding = 6
        config.scrollAnchor = .center
        config.scrollSettleDelay = 0.5
        return config
    }
    
    private var scrollCoachmarkItems: [MDSCoachmarkItem] {
        [
            MDSCoachmarkItem(
                id: "scroll-start",
                title: "Scroll Tour Begins",
                description: "Watch the automatic scrolling as we navigate through the page!",
                iconName: "arrow.up.and.down.circle.fill"
            ),
            MDSCoachmarkItem(
                id: "scroll-bottom",
                title: "Auto-Scrolled Here!",
                description: "This element was below the fold. The coachmark scrolled to bring it into view.",
                iconName: "arrow.down.circle.fill"
            ),
            MDSCoachmarkItem(
                id: "scroll-share",
                title: "Share Content",
                description: "Tap Share to send this content to friends and colleagues.",
                iconName: "square.and.arrow.up"
            ),
            MDSCoachmarkItem(
                id: "scroll-save",
                title: "Save For Later",
                description: "Bookmark this item to find it easily in your saved collection.",
                iconName: "bookmark.fill"
            ),
            MDSCoachmarkItem(
                id: "basic-start",
                title: "Scrolled Back Up!",
                description: "We scrolled back to the top. Bi-directional scrolling works seamlessly.",
                iconName: "arrow.up.circle.fill"
            )
        ]
    }
    
    private var customConfiguration: MDSCoachmarkConfiguration {
        var config = MDSCoachmarkConfiguration()
        config.accentColor = .purple
        config.defaultIconColor = .purple
        config.overlayColor = Color.purple.opacity(0.4)
        config.exitButtonLabel = "Skip All"
        config.nextButtonLabel = "Continue"
        config.finishButtonLabel = "Got It!"
        config.backButtonLabel = "Prev"
        config.spotlightBorderColor = .purple
        config.spotlightBorderWidth = 2
        config.spotlightCornerRadius = 12
        config.spotlightPadding = 8
        config.tipLayoutStyle = .vertical
        return config
    }
    
    private var customCoachmarkItems: [MDSCoachmarkItem] {
        [
            MDSCoachmarkItem(
                id: "custom-start",
                title: "Custom Tour",
                description: "This tour uses custom purple styling with vertical layout.",
                iconName: "sparkles",
                iconColor: .purple
            ),
            MDSCoachmarkItem(
                id: "custom-profile",
                title: "Your Profile",
                description: "Tap your avatar to view and edit your profile information.",
                iconName: "person.circle.fill",
                iconColor: .purple
            ),
            MDSCoachmarkItem(
                id: "custom-notifications",
                title: "Notifications",
                description: "Stay updated with the latest activity and alerts.",
                iconName: "bell.badge.fill",
                iconColor: .orange
            )
        ]
    }
    
    private var mandatoryConfiguration: MDSCoachmarkConfiguration {
        var config = MDSCoachmarkConfiguration()
        config.showExitButton = false
        config.showBackButton = false
        config.accentColor = .green
        config.defaultIconColor = .green
        config.nextButtonLabel = "Next →"
        config.finishButtonLabel = "All Done!"
        config.overlayColor = Color.black.opacity(0.6)
        config.spotlightPadding = 6
        return config
    }
    
    private var mandatoryCoachmarkItems: [MDSCoachmarkItem] {
        [
            MDSCoachmarkItem(
                id: "mandatory-step1",
                title: "Step 1: Get Started",
                description: "This is a mandatory tour. You must view all steps to proceed.",
                iconName: "1.circle.fill"
            ),
            MDSCoachmarkItem(
                id: "mandatory-step2",
                title: "Step 2: Your Tasks",
                description: "Track all your pending tasks here.",
                iconName: "2.circle.fill"
            ),
            MDSCoachmarkItem(
                id: "mandatory-step3",
                title: "Step 3: Completed",
                description: "View your completed tasks and celebrate! 🎉",
                iconName: "3.circle.fill"
            )
        ]
    }
}

// MARK: - Helper Views

private struct FeatureCard: View {
    let icon: String
    let title: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.white)
                .frame(width: 44, height: 44)
                .background(color)
                .cornerRadius(10)
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

private struct ProfileBadge: View {
    let name: String
    let color: Color
    
    var body: some View {
        Text(String(name.prefix(1)))
            .font(.title2.bold())
            .foregroundColor(.white)
            .frame(width: 48, height: 48)
            .background(color)
            .clipShape(Circle())
    }
}

private struct StatBox: View {
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title.bold())
                .foregroundColor(color)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

private struct ActionChip: View {
    let icon: String
    let label: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
            Text(label)
                .font(.caption)
                .fontWeight(.medium)
        }
        .foregroundColor(color)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(color.opacity(0.12))
        .cornerRadius(16)
    }
}

#Preview {
    CoachmarkExamplesView()
}
