# MobileDesignSystem

A Swift Package providing reusable UI components for iOS applications.

## Components

### MDSTextView

A simple SwiftUI text view component with customizable styling options.

**Features:**
- Customizable text, font, and colors
- Editable and scrollable options
- Support for attributed text
- Border and corner radius customization
- SwiftUI modifier-based API

**Usage:**

**Editable Text View:**
```swift
import SwiftUI
import MobileDesignSystem

struct ContentView: View {
    @State private var text = "Hello, World!"
    
    var body: some View {
        MDSTextView(text: $text, isEditable: true)
            .font(.system(size: 16))
            .textColor(.primary)
            .cornerRadius(8)
            .borderWidth(1)
            .borderColor(.gray)
            .padding(12)
    }
}
```

**Static Text View:**
```swift
MDSTextView(text: "Hello, World!")
    .font(.system(size: 16))
    .textColor(.blue)
    .cornerRadius(8)
    .borderWidth(1)
    .borderColor(.gray)
```

**With Attributed Text:**
```swift
var attributedString = AttributedString("Hello, World!")
attributedString.foregroundColor = .blue

MDSTextView(attributedText: attributedString)
    .cornerRadius(8)
    .padding(12)
```

### MDSInputField

A SwiftUI view that wraps a UIKit input control with enhanced styling and focus states. Uses UIKit under the hood for native text field behavior.

**Features:**
- Placeholder text with custom color
- Customizable padding (left and right)
- Focus state with animated border color change
- Keyboard type configuration
- Secure text entry support
- Enabled/disabled states
- Border and corner radius customization
- Text change callbacks
- Editing begin/end callbacks

**Usage:**

**Basic Input Field:**
```swift
import SwiftUI
import MobileDesignSystem

struct ContentView: View {
    @State private var text = ""
    
    var body: some View {
        MDSInputField(text: $text)
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
                print("Text changed: \(newText)")
            }
    }
}
```

**Password Field:**
```swift
@State private var password = ""

MDSInputField(text: $password)
    .placeholder("Password")
    .isSecureTextEntry(true)
    .keyboardType(.default)
    .cornerRadius(8)
    .borderWidth(1)
    .borderColor(.separator)
```

**With Callbacks:**
```swift
MDSInputField(text: $text)
    .placeholder("Email")
    .keyboardType(.emailAddress)
    .onEditingBegan {
        print("Editing began")
    }
    .onEditingEnded {
        print("Editing ended")
    }
    .onTextChange { newText in
        // Handle text changes
    }
```

## Installation

### Swift Package Manager

Add the following to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/yourusername/MobileDesignSystem.git", from: "1.0.0")
]
```

Or add it through Xcode:
1. File → Add Packages...
2. Enter the repository URL
3. Select the version you want to use

## Example App

An example application demonstrating the usage of both components is included in the `ExampleApp` directory. The example app includes:

- **Input Field Examples**: Various input field configurations including email, password, phone number, and custom styling
- **Text View Examples**: Editable, static, and attributed text views with different configurations
- **Combined Examples**: Real-world use cases like contact forms, notes app, and login forms

To run the example app:

1. Open the `MobileDesignSystem` package in Xcode
2. Create a new iOS App target or use the example app files as reference
3. Add `MobileDesignSystem` as a dependency
4. Build and run

See `ExampleApp/README.md` for detailed instructions.

## Requirements

- iOS 13.0+
- Swift 5.9+

## License

[Add your license here]
