import SwiftUI
import MobileDesignSystem

struct CoachmarkExamplesView: View {
    @State private var showBasicCoachmarks = false
    @State private var showScrollCoachmarks = false
    @State private var showCustomCoachmarks = false
    @State private var showNoExitCoachmarks = false
    @State private var coachmarkLog: [String] = []
    
    var body: some View {
        MDSCoachmarkScrollContainer {
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
                    
                    Text("A simple 4-step sequence with default styling. All elements are visible on screen.")
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
                    
                    Text("This tour highlights elements that are off-screen. The coachmark automatically scrolls each target into view.")
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
                    
                    Text("Custom colors, labels, and rich tip content.")
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
                
                // MARK: - Content Between (forces scrolling)
                
                VStack(spacing: 16) {
                    Text("📋 More Content Area")
                        .font(.title3)
                        .bold()
                    
                    ForEach(0..<6) { index in
                        HStack {
                            Image(systemName: "doc.text.fill")
                                .foregroundColor(.blue)
                            Text("Document \(index + 1)")
                                .font(.body)
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
                
                // MARK: - Mandatory Tour (No Exit) — placed far down to test scrolling
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("Mandatory Tour (No Skip)")
                        .font(.title2)
                        .bold()
                    
                    Text("Users must complete all steps. The exit button is hidden. This section is placed far down to test scroll behavior.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
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
                
                // MARK: - Scroll Target at the Bottom
                
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
                    
                    Text("This element is at the very bottom of the scrollable content. The scroll-aware coachmark tour will automatically scroll here.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 16) {
                        ActionChip(icon: "square.and.arrow.up", label: "Share", color: .blue)
                            .coachmarkAnchor("scroll-share")
                        
                        ActionChip(icon: "bookmark.fill", label: "Save", color: .orange)
                            .coachmarkAnchor("scroll-save")
                        
                        ActionChip(icon: "trash", label: "Delete", color: .red)
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
                            HStack(alignment: .top) {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(.blue)
                                    .font(.caption)
                                Text(entry)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
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
                    .shadow(color: .black.opacity(0.05), radius: 5)
                }
                
                Spacer(minLength: 40)
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        
        // MARK: - Coachmark Overlays
        
        .coachmarkOverlay(
            isPresented: $showBasicCoachmarks,
            items: basicCoachmarkItems,
            onFinished: {
                coachmarkLog.append("Basic tour completed ✅")
            },
            onSkipped: { step in
                coachmarkLog.append("Basic tour skipped at step \(step + 1) ⏭")
            }
        )
        .coachmarkOverlay(
            isPresented: $showScrollCoachmarks,
            configuration: scrollConfiguration,
            items: scrollCoachmarkItems,
            onFinished: {
                coachmarkLog.append("Scroll tour completed ✅")
            },
            onSkipped: { step in
                coachmarkLog.append("Scroll tour skipped at step \(step + 1) ⏭")
            }
        )
        .coachmarkOverlay(
            isPresented: $showCustomCoachmarks,
            configuration: customConfiguration,
            items: customCoachmarkItems,
            onFinished: {
                coachmarkLog.append("Custom tour completed ✅")
            },
            onSkipped: { step in
                coachmarkLog.append("Custom tour skipped at step \(step + 1) ⏭")
            }
        )
        .coachmarkOverlay(
            isPresented: $showNoExitCoachmarks,
            configuration: mandatoryConfiguration,
            items: mandatoryCoachmarkItems,
            onFinished: {
                coachmarkLog.append("Mandatory tour completed ✅")
            }
        )
    }
    
    // MARK: - Basic Items
    
    private var basicCoachmarkItems: [AnyMDSCoachmarkItem] {
        [
            AnyMDSCoachmarkItem(MDSCoachmarkItem(id: "basic-start") {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Welcome! 👋")
                        .font(.headline)
                    Text("This button starts the coachmark tour. Let's explore the features below.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }),
            AnyMDSCoachmarkItem(MDSCoachmarkItem(id: "basic-search") {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Search")
                        .font(.headline)
                    Text("Quickly find what you need across the entire app.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }),
            AnyMDSCoachmarkItem(MDSCoachmarkItem(id: "basic-favorites") {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Favorites")
                        .font(.headline)
                    Text("Save items you love for quick access later.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }),
            AnyMDSCoachmarkItem(MDSCoachmarkItem(id: "basic-settings") {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Settings")
                        .font(.headline)
                    Text("Customize your experience in the settings panel.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            })
        ]
    }
    
    // MARK: - Scroll Configuration & Items
    
    private var scrollConfiguration: MDSCoachmarkConfiguration {
        var config = MDSCoachmarkConfiguration()
        config.accentColor = .teal
        config.spotlightBorderColor = .teal
        config.spotlightBorderWidth = 2
        config.spotlightPadding = 6
        config.scrollAnchor = .center
        config.scrollSettleDelay = 0.5
        return config
    }
    
    private var scrollCoachmarkItems: [AnyMDSCoachmarkItem] {
        [
            AnyMDSCoachmarkItem(MDSCoachmarkItem(id: "scroll-start") {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Scroll Tour Begins")
                        .font(.headline)
                    Text("This tour highlights elements throughout the page, including ones off-screen. Watch the automatic scrolling!")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }),
            AnyMDSCoachmarkItem(MDSCoachmarkItem(id: "scroll-bottom") {
                VStack(alignment: .leading, spacing: 4) {
                    Text("⬇️ Auto-Scrolled Here!")
                        .font(.headline)
                    Text("This element was below the fold. The coachmark scrolled the page to bring it into view.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }),
            AnyMDSCoachmarkItem(MDSCoachmarkItem(id: "scroll-share") {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Share Content")
                        .font(.headline)
                    Text("Tap Share to send this content to friends and colleagues.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }),
            AnyMDSCoachmarkItem(MDSCoachmarkItem(id: "scroll-save") {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Save For Later")
                        .font(.headline)
                    Text("Bookmark this item to find it easily in your saved collection.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }),
            AnyMDSCoachmarkItem(MDSCoachmarkItem(id: "basic-start") {
                VStack(alignment: .leading, spacing: 4) {
                    Text("⬆️ Scrolled Back Up!")
                        .font(.headline)
                    Text("We scrolled back to the top to highlight this button. The coachmark handles bi-directional scrolling.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            })
        ]
    }
    
    // MARK: - Custom Configuration & Items
    
    private var customConfiguration: MDSCoachmarkConfiguration {
        var config = MDSCoachmarkConfiguration()
        config.accentColor = .purple
        config.overlayColor = Color.purple.opacity(0.4)
        config.exitButtonLabel = "Skip All"
        config.nextButtonLabel = "Continue"
        config.finishButtonLabel = "Got It!"
        config.backButtonLabel = "Prev"
        config.spotlightBorderColor = .purple
        config.spotlightBorderWidth = 2
        config.spotlightCornerRadius = 12
        config.spotlightPadding = 8
        return config
    }
    
    private var customCoachmarkItems: [AnyMDSCoachmarkItem] {
        [
            AnyMDSCoachmarkItem(MDSCoachmarkItem(id: "custom-start") {
                HStack(spacing: 12) {
                    Image(systemName: "sparkles")
                        .font(.title)
                        .foregroundColor(.purple)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Custom Tour")
                            .font(.headline)
                        Text("This tour uses custom purple styling.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }),
            AnyMDSCoachmarkItem(MDSCoachmarkItem(id: "custom-profile") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your Profile")
                        .font(.headline)
                    Text("Tap your avatar to view and edit your profile information.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                        Text("Profile 90% complete")
                            .font(.caption2)
                            .foregroundColor(.green)
                    }
                }
            }),
            AnyMDSCoachmarkItem(MDSCoachmarkItem(id: "custom-notifications") {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("🔔 Notifications")
                            .font(.headline)
                        Spacer()
                        Text("3 new")
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.orange)
                            .cornerRadius(8)
                    }
                    Text("Stay updated with the latest activity and alerts.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            })
        ]
    }
    
    // MARK: - Mandatory Configuration & Items
    
    private var mandatoryConfiguration: MDSCoachmarkConfiguration {
        var config = MDSCoachmarkConfiguration()
        config.showExitButton = false
        config.showBackButton = false
        config.accentColor = .green
        config.nextButtonLabel = "Next →"
        config.finishButtonLabel = "All Done!"
        config.overlayColor = Color.black.opacity(0.6)
        config.spotlightPadding = 6
        return config
    }
    
    private var mandatoryCoachmarkItems: [AnyMDSCoachmarkItem] {
        [
            AnyMDSCoachmarkItem(MDSCoachmarkItem(id: "mandatory-step1") {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Step 1: Get Started")
                        .font(.headline)
                    Text("This is a mandatory tour. You must view all steps to proceed.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }),
            AnyMDSCoachmarkItem(MDSCoachmarkItem(id: "mandatory-step2") {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Step 2: Your Tasks")
                        .font(.headline)
                    Text("Track all your pending tasks here.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }),
            AnyMDSCoachmarkItem(MDSCoachmarkItem(id: "mandatory-step3") {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Step 3: Completed")
                        .font(.headline)
                    Text("View your completed tasks and celebrate! 🎉")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            })
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
