import SwiftUI

struct ViewThatFitsExamples: View {
    @State private var longText = "This is a very long text that might not fit in a single line and will need to be truncated or wrapped depending on the available space."
    @State private var shortText = "Short text"
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                Text("ViewThatFits Examples")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top)
                
                // Example 1: Adaptive Layout - Horizontal vs Vertical
                example1_AdaptiveLayout()
                
                // Example 2: Truncation Detection
                example2_TruncationDetection()
                
                // Example 3: Button Styles Based on Space
                example3_AdaptiveButton()
                
                // Example 4: Navigation Layout
                example4_NavigationLayout()
                
                // Example 5: Card Layout Adaptation
                example5_CardLayout()
                
                // Example 6: Text Size Adaptation
                example6_TextSizeAdaptation()
                
                // Example 7: Icon + Text Layout
                example7_IconTextLayout()
            }
            .padding()
        }
    }
    
    // MARK: - Example 1: Adaptive Layout (Horizontal vs Vertical)
    func example1_AdaptiveLayout() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Example 1: Adaptive Layout")
                .font(.headline)
                .foregroundColor(.blue)
            
            Text("Chooses horizontal layout if space allows, otherwise vertical")
                .font(.caption)
                .foregroundColor(.secondary)
            
            ViewThatFits {
                // Try horizontal layout first
                HStack(spacing: 16) {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                    Text("Horizontal Layout")
                    Text("Fits!")
                        .foregroundColor(.green)
                }
                
                // Fallback to vertical layout
                VStack(spacing: 8) {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                    Text("Vertical Layout")
                    Text("Fits!")
                        .foregroundColor(.green)
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
        }
    }
    
    // MARK: - Example 2: Truncation Detection
    func example2_TruncationDetection() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Example 2: Truncation Detection")
                .font(.headline)
                .foregroundColor(.blue)
            
            Text("Shows full text if it fits, otherwise truncated version")
                .font(.caption)
                .foregroundColor(.secondary)
            
            ViewThatFits {
                // Try full text first
                Text(longText)
                    .lineLimit(nil)
                
                // Fallback to truncated text
                Text(longText)
                    .lineLimit(2)
                    .truncationMode(.tail)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
        }
    }
    
    // MARK: - Example 3: Adaptive Button
    func example3_AdaptiveButton() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Example 3: Adaptive Button")
                .font(.headline)
                .foregroundColor(.blue)
            
            Text("Full button with icon + text, or icon-only if space is limited")
                .font(.caption)
                .foregroundColor(.secondary)
            
            ViewThatFits(in: .horizontal) {
                // Full button with icon and text
                Button(action: {}) {
                    HStack {
                        Image(systemName: "heart.fill")
                        Text("Like")
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)
                
                // Compact icon-only button
                Button(action: {}) {
                    Image(systemName: "heart.fill")
                        .padding(8)
                }
                .buttonStyle(.borderedProminent)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    // MARK: - Example 4: Navigation Layout
    func example4_NavigationLayout() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Example 4: Navigation Layout")
                .font(.headline)
                .foregroundColor(.blue)
            
            Text("Horizontal tabs if space allows, otherwise vertical list")
                .font(.caption)
                .foregroundColor(.secondary)
            
            ViewThatFits {
                // Horizontal tabs
                HStack(spacing: 12) {
                    ForEach(["Home", "Search", "Profile"], id: \.self) { item in
                        Button(item) {}
                            .buttonStyle(.bordered)
                    }
                }
                
                // Vertical list
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(["Home", "Search", "Profile"], id: \.self) { item in
                        Button(item) {}
                            .buttonStyle(.bordered)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
        }
    }
    
    // MARK: - Example 5: Card Layout Adaptation
    func example5_CardLayout() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Example 5: Card Layout")
                .font(.headline)
                .foregroundColor(.blue)
            
            Text("Wide card with side-by-side content, or stacked if narrow")
                .font(.caption)
                .foregroundColor(.secondary)
            
            ViewThatFits {
                // Wide layout: image on left, text on right
                HStack(alignment: .top, spacing: 16) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.blue.opacity(0.3))
                        .frame(width: 80, height: 80)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Card Title")
                            .font(.headline)
                        Text("This is the card description that explains what this card is about.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Narrow layout: stacked
                VStack(alignment: .leading, spacing: 12) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.blue.opacity(0.3))
                        .frame(height: 120)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Card Title")
                            .font(.headline)
                        Text("This is the card description that explains what this card is about.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
        }
    }
    
    // MARK: - Example 6: Text Size Adaptation
    func example6_TextSizeAdaptation() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Example 6: Text Size Adaptation")
                .font(.headline)
                .foregroundColor(.blue)
            
            Text("Larger text if space allows, smaller text as fallback")
                .font(.caption)
                .foregroundColor(.secondary)
            
            ViewThatFits {
                // Large text
                Text("Adaptive Text Size")
                    .font(.title)
                    .fontWeight(.bold)
                
                // Medium text
                Text("Adaptive Text Size")
                    .font(.title3)
                    .fontWeight(.bold)
                
                // Small text
                Text("Adaptive Text Size")
                    .font(.headline)
                    .fontWeight(.bold)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
        }
    }
    
    // MARK: - Example 7: Icon + Text Layout
    func example7_IconTextLayout() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Example 7: Icon + Text Layout")
                .font(.headline)
                .foregroundColor(.blue)
            
            Text("Icon and text side-by-side, or icon above text")
                .font(.caption)
                .foregroundColor(.secondary)
            
            ViewThatFits(in: .horizontal) {
                // Horizontal: icon and text side by side
                HStack(spacing: 8) {
                    Image(systemName: "bell.fill")
                        .foregroundColor(.orange)
                    Text("Notifications")
                }
                
                // Vertical: icon above text
                VStack(spacing: 4) {
                    Image(systemName: "bell.fill")
                        .foregroundColor(.orange)
                    Text("Notifications")
                        .font(.caption)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
        }
    }
}

// MARK: - Preview
struct ViewThatFitsExamples_Previews: PreviewProvider {
    static var previews: some View {
        ViewThatFitsExamples()
    }
}
