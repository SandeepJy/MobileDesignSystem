//
//  CombinedExamplesView.swift
//  MobileDesignSystemExampleApp
//
//  Created on iOS.
//

import SwiftUI
import MobileDesignSystem

struct CombinedExamplesView: View {
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var message = "Enter your message here..."
    @State private var notes = ""
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("Combined Examples")
                    .font(.largeTitle)
                    .bold()
                    .padding(.top)
                
                // Contact Form Example
                VStack(alignment: .leading, spacing: 16) {
                    Text("Contact Form")
                        .font(.title2)
                        .bold()
                    
                    VStack(spacing: 12) {
                        MDSInputField(text: $firstName)
                            .placeholder("First Name")
                            .font(.systemFont(ofSize: 16))
                            .cornerRadius(8)
                            .borderWidth(1)
                            .borderColor(.separator)
                            .focusedBorderColor(.systemBlue)
                            .leftPadding(12)
                            .rightPadding(12)
                        
                        MDSInputField(text: $lastName)
                            .placeholder("Last Name")
                            .font(.systemFont(ofSize: 16))
                            .cornerRadius(8)
                            .borderWidth(1)
                            .borderColor(.separator)
                            .focusedBorderColor(.systemBlue)
                            .leftPadding(12)
                            .rightPadding(12)
                        
                        MDSInputField(text: $email)
                            .placeholder("Email Address")
                            .keyboardType(.emailAddress)
                            .font(.systemFont(ofSize: 16))
                            .cornerRadius(8)
                            .borderWidth(1)
                            .borderColor(.separator)
                            .focusedBorderColor(.systemBlue)
                            .leftPadding(12)
                            .rightPadding(12)
                        
                        MDSTextView(text: $message, isEditable: true)
                            .font(.system(size: 16))
                            .textColor(.blue)
                            .cornerRadius(8)
                            .borderWidth(1)
                            .borderColor(.blue)
                            .textViewBackgroundColor(.secondary)
                            .padding(8)
                            .frame(minHeight: 120)
                    }
                    
                    if !firstName.isEmpty || !lastName.isEmpty || !email.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Form Preview:")
                                .font(.headline)
                            Text("Name: \(firstName) \(lastName)")
                                .font(.caption)
                            Text("Email: \(email)")
                                .font(.caption)
                            Text("Message: \(message)")
                                .font(.caption)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
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

extension Color {
    static var systemBlue: Color {
        Color(uiColor: .systemBlue)
    }
}

#Preview {
    CombinedExamplesView()
}
