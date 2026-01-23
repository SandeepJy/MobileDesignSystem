# Getting Started with MobileDesignSystem

Learn how to integrate and use MobileDesignSystem in your iOS application.

## Installation

### Swift Package Manager

Add MobileDesignSystem to your project using Swift Package Manager:

1. In Xcode, select **File** → **Add Packages...**
2. Enter the repository URL: `https://github.com/yourusername/MobileDesignSystem.git`
3. Select the version you want to use
4. Add the package to your target

Alternatively, add it to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/yourusername/MobileDesignSystem.git", from: "1.0.0")
]
```

## Basic Usage

### Import the Module

```swift
import SwiftUI
import MobileDesignSystem
```

### Using MDSTextView

Create an editable text view:

```swift
@State private var notes = ""

MDSTextView(text: $notes, isEditable: true)
    .font(.system(size: 16))
    .cornerRadius(8)
    .borderWidth(1)
    .borderColor(.gray)
```

Create a static text view:

```swift
MDSTextView(text: "This is read-only text")
    .font(.system(size: 16))
    .textColor(.secondary)
```

### Using MDSInputField

Create a basic input field:

```swift
@State private var username = ""

MDSInputField(text: $username)
    .placeholder("Enter your username")
    .font(size: 16)
    .cornerRadius(8)
    .borderWidth(1)
    .borderColor(.separator)
```

Create a password field:

```swift
@State private var password = ""

MDSInputField(text: $password)
    .placeholder("Password")
    .isSecureTextEntry(true)
    .cornerRadius(8)
```

## Next Steps

- Explore the component documentation: ``MDSTextView``, ``MDSInputField``
- Check out the examples: <doc:Examples>
- Learn about customization options in the component guides
