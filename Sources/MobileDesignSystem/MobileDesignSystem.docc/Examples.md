# Examples

Complete examples demonstrating how to use MobileDesignSystem components.

## MDSTextView Examples

### Editable Text View with Styling

```swift
import SwiftUI
import MobileDesignSystem

struct NotesView: View {
    @State private var notes = ""
    
    var body: some View {
        MDSTextView(text: $notes, isEditable: true)
            .font(.system(size: 16))
            .textColor(.primary)
            .cornerRadius(12)
            .borderWidth(2)
            .borderColor(.blue)
            .textViewBackgroundColor(Color(.systemGray6))
            .padding(12)
            .frame(minHeight: 200)
            .scrollEnabled(true)
    }
}
```

### Attributed Text View

```swift
import SwiftUI
import MobileDesignSystem

struct StyledTextView: View {
    var body: some View {
        var attributedString = AttributedString("Hello, ")
        var world = AttributedString("World!")
        world.foregroundColor = .blue
        world.font = .system(size: 20, weight: .bold)
        attributedString.append(world)
        
        return MDSTextView(attributedText: attributedString)
            .cornerRadius(8)
            .padding()
    }
}
```

## MDSInputField Examples

### Login Form

```swift
import SwiftUI
import MobileDesignSystem

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    
    var body: some View {
        VStack(spacing: 16) {
            MDSInputField(text: $email)
                .placeholder("Email")
                .keyboardType(.emailAddress)
                .font(size: 16)
                .cornerRadius(8)
                .borderWidth(1)
                .borderColor(.separator)
                .focusedBorderColor(.systemBlue)
                .onTextChange { newEmail in
                    print("Email: \(newEmail)")
                }
            
            MDSInputField(text: $password)
                .placeholder("Password")
                .isSecureTextEntry(true)
                .font(size: 16)
                .cornerRadius(8)
                .borderWidth(1)
                .borderColor(.separator)
                .focusedBorderColor(.systemBlue)
            
            Button("Login") {
                // Handle login
            }
            .disabled(email.isEmpty || password.isEmpty)
        }
        .padding()
    }
}
```

### Form with Validation

```swift
import SwiftUI
import MobileDesignSystem

struct ContactFormView: View {
    @State private var name = ""
    @State private var email = ""
    @State private var phone = ""
    
    var body: some View {
        Form {
            Section("Contact Information") {
                MDSInputField(text: $name)
                    .placeholder("Full Name")
                    .font(size: 16)
                    .onTextChange { newName in
                        // Validate name
                    }
                
                MDSInputField(text: $email)
                    .placeholder("Email Address")
                    .keyboardType(.emailAddress)
                    .font(size: 16)
                    .onEditingEnded {
                        // Validate email format
                    }
                
                MDSInputField(text: $phone)
                    .placeholder("Phone Number")
                    .keyboardType(.phonePad)
                    .font(size: 16)
            }
        }
    }
}
```

### Custom Styled Input Field

```swift
import SwiftUI
import MobileDesignSystem

struct CustomInputView: View {
    @State private var text = ""
    
    var body: some View {
        MDSInputField(text: $text)
            .placeholder("Custom styled field")
            .font(size: 18, weight: .semibold)
            .textColor(.systemBlue)
            .placeholderColor(.systemGray)
            .textAlignment(.center)
            .cornerRadius(16)
            .borderWidth(2)
            .borderColor(.systemBlue)
            .focusedBorderColor(.systemPurple)
            .inputBackgroundColor(.systemGray6)
            .leftPadding(20)
            .rightPadding(20)
    }
}
```

## Combined Example

### Notes App Interface

```swift
import SwiftUI
import MobileDesignSystem

struct NotesAppView: View {
    @State private var title = ""
    @State private var content = ""
    
    var body: some View {
        VStack(spacing: 16) {
            MDSInputField(text: $title)
                .placeholder("Note Title")
                .font(size: 20, weight: .bold)
                .cornerRadius(8)
                .borderWidth(1)
                .borderColor(.separator)
            
            MDSTextView(text: $content, isEditable: true)
                .font(.system(size: 16))
                .cornerRadius(8)
                .borderWidth(1)
                .borderColor(.separator)
                .frame(minHeight: 300)
                .scrollEnabled(true)
            
            if !content.isEmpty {
                Text("\(content.count) characters")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
    }
}
```
