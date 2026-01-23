//
//  InputFieldExamplesView.swift
//  MobileDesignSystemExampleApp
//
//  Created on iOS.
//

import SwiftUI
import MobileDesignSystem

struct InputFieldExamplesView: View {
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var phoneNumber = ""
    @State private var disabledField = "Disabled field"
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("MDSInputField Examples")
                    .font(.largeTitle)
                    .bold()
                    .padding(.top)
                
                // Basic Input Field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Basic Input Field")
                        .font(.headline)
                    
                    MDSInputField(text: $name)
                        .placeholder("Enter your name")
                        .font(.system(size: 16))
                        .textColor(.label)
                        .cornerRadius(8)
                        .borderWidth(1)
                        .borderColor(.separator)
                        .focusedBorderColor(.systemBlue)
                        .leftPadding(12)
                        .rightPadding(12)
                        .onTextChange { newText in
                            print("Name changed: \(newText)")
                        }
                    
                    if !name.isEmpty {
                        Text("You entered: \(name)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.05), radius: 5)
                
                // Email Input Field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Email Input Field")
                        .font(.headline)
                    
                    MDSInputField(text: $email)
                        .placeholder("Enter your email")
                        .keyboardType(.emailAddress)
                        .font(.system(size: 16))
                        .cornerRadius(8)
                        .borderWidth(1)
                        .borderColor(.separator)
                        .focusedBorderColor(.systemBlue)
                        .leftPadding(12)
                        .rightPadding(12)
                        .onEditingBegan {
                            print("Email editing began")
                        }
                        .onEditingEnded {
                            print("Email editing ended")
                        }
                    
                    if !email.isEmpty {
                        Text("Email: \(email)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.05), radius: 5)
                
                // Password Input Field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Password Input Field")
                        .font(.headline)
                    
                    MDSInputField(text: $password)
                        .placeholder("Enter your password")
                        .isSecureTextEntry(true)
                        .font(.system(size: 16))
                        .cornerRadius(8)
                        .borderWidth(1)
                        .borderColor(.separator)
                        .focusedBorderColor(.systemBlue)
                        .leftPadding(12)
                        .rightPadding(12)
                    
                    if !password.isEmpty {
                        Text("Password length: \(password.count) characters")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.05), radius: 5)
                
                // Phone Number Input Field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Phone Number Input Field")
                        .font(.headline)
                    
                    MDSInputField(text: $phoneNumber)
                        .placeholder("Enter phone number")
                        .keyboardType(.phonePad)
                        .font(.system(size: 16))
                        .cornerRadius(8)
                        .borderWidth(1)
                        .borderColor(.separator)
                        .focusedBorderColor(.systemBlue)
                        .leftPadding(12)
                        .rightPadding(12)
                    
                    if !phoneNumber.isEmpty {
                        Text("Phone: \(phoneNumber)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.05), radius: 5)
                
                // Disabled Input Field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Disabled Input Field")
                        .font(.headline)
                    
                    MDSInputField(text: $disabledField)
                        .placeholder("This field is disabled")
                        .isEnabled(false)
                        .font(.system(size: 16))
                        .cornerRadius(8)
                        .borderWidth(1)
                        .borderColor(.separator)
                        .leftPadding(12)
                        .rightPadding(12)
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.05), radius: 5)
                
                // Custom Styled Input Field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Custom Styled Input Field")
                        .font(.headline)
                    
                    MDSInputField(text: $name)
                        .placeholder("Custom styling")
                        .font(.system(size: 18, weight: .medium))
                        .textColor(.systemBlue)
                        .placeholderColor(.systemGray)
                        .textAlignment(.center)
                        .cornerRadius(12)
                        .borderWidth(2)
                        .borderColor(.systemBlue)
                        .focusedBorderColor(.systemPurple)
                        .inputBackgroundColor(.systemGray6)
                        .leftPadding(16)
                        .rightPadding(16)
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
    InputFieldExamplesView()
}
