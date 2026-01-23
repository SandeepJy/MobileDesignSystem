//
//  TextViewExamplesView.swift
//  MobileDesignSystemExampleApp
//
//  Created on iOS.
//

import SwiftUI
import MobileDesignSystem

struct TextViewExamplesView: View {
    @State private var editableText = "This is an editable text view. You can type multiple lines of text here and it will scroll if needed."
    @State private var staticText = "This is a static, non-editable text view. It displays text but cannot be edited by the user."
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("MDSTextView Examples")
                    .font(.largeTitle)
                    .bold()
                    .padding(.top)
                
                // Editable Text View
                VStack(alignment: .leading, spacing: 8) {
                    Text("Editable Text View")
                        .font(.headline)
                    
                    MDSTextView(text: $editableText, isEditable: true)
                        .font(.system(size: 16))
                        .textColor(Color(.label))
                        .cornerRadius(8)
                        .borderWidth(1)
                        .borderColor(Color(.separator))
                        .textViewBackgroundColor(Color(.systemBackground))
                        .padding(8)
                        .frame(minHeight: 120)
                       
                    
                    Text("Character count: \(editableText.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.05), radius: 5)
                
                // Static Text View
                VStack(alignment: .leading, spacing: 8) {
                    Text("Static Text View")
                        .font(.headline)
                    
                    MDSTextView(text: staticText)
                        .font(.system(size: 16))
                        .textColor(Color(.label))
                        .cornerRadius(8)
                        .borderWidth(1)
                        .borderColor(Color(.separator))
                        .textViewBackgroundColor(Color(.systemBackground))
                        .padding(8)
                        
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.05), radius: 5)
                
                // Attributed Text View
                VStack(alignment: .leading, spacing: 8) {
                    Text("Attributed Text View")
                        .font(.headline)
                    
                    let attributedString: AttributedString = {
                        var attr = AttributedString("This is ")
                        attr.foregroundColor = .primary
                        
                        var boldText = AttributedString("bold")
                        boldText.foregroundColor = .blue
                        boldText.font = .system(size: 16, weight: .bold)
                        
                        var italicText = AttributedString(" and italic")
                        italicText.foregroundColor = .purple
                        italicText.font = .system(size: 16, weight: .regular)
                        
                        attr.append(boldText)
                        attr.append(italicText)
                        attr.append(AttributedString(" text!"))
                        
                        return attr
                    }()
                    
                    MDSTextView(attributedText: attributedString)
                        .cornerRadius(8)
                        .borderWidth(1)
                        .borderColor(Color(.separator))
                        .textViewBackgroundColor(Color(.systemBackground))
                        .padding(8)
                        .scrollEnabled(true)
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.05), radius: 5)
                
                // Custom Styled Text View
                VStack(alignment: .leading, spacing: 8) {
                    Text("Custom Styled Text View")
                        .font(.headline)
                    
                    MDSTextView(text: $editableText, isEditable: true)
                        .font(.system(size: 18, weight: .medium))
                        .textColor(Color(.systemBlue))
                        .cornerRadius(12)
                        .borderWidth(2)
                        .borderColor(Color(.systemBlue))
                        .textViewBackgroundColor(Color(.systemGray6))
                        .padding(12)
                        .frame(minHeight: 150)
                        
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.05), radius: 5)
                
                // Non-scrollable Text View
                VStack(alignment: .leading, spacing: 8) {
                    Text("Non-scrollable Text View")
                        .font(.headline)
                    
                    MDSTextView(text: "This is a short text that doesn't need scrolling. It will display all content without a scroll view.")
                        .font(.system(size: 16))
                        .textColor(Color(.label))
                        .cornerRadius(8)
                        .borderWidth(1)
                        .borderColor(Color(.separator))
                        .textViewBackgroundColor(Color(.systemBackground))
                        .padding(8)
                        
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.05), radius: 5)
                
                // Centered Text View
                VStack(alignment: .leading, spacing: 8) {
                    Text("Centered Text View")
                        .font(.headline)
                    
                    MDSTextView(text: "This text is centered.")
                        .font(.system(size: 16))
                        .textColor(Color(.label))
                        .textAlignment(.center)
                        .cornerRadius(8)
                        .borderWidth(1)
                        .borderColor(Color(.separator))
                        .textViewBackgroundColor(Color(.systemBackground))
                        .padding(8)
                        .scrollEnabled(false)
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.05), radius: 5)
                
                Spacer(minLength: 20)
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }
}

#Preview {
    TextViewExamplesView()
}
