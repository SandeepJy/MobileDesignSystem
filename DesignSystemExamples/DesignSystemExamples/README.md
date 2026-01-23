# MobileDesignSystem Example App

This example application demonstrates how to use the MobileDesignSystem library components in a SwiftUI application.

## Features

The example app includes three main sections:

### 1. Input Field Examples (`InputFieldExamplesView`)
- Basic input field
- Email input field with keyboard type
- Password input field with secure text entry
- Phone number input field
- Disabled input field
- Custom styled input field

### 2. Text View Examples (`TextViewExamplesView`)
- Editable text view
- Static text view
- Attributed text view with formatting
- Custom styled text view
- Non-scrollable text view
- Centered text view

### 3. Combined Examples (`CombinedExamplesView`)
- Contact form with multiple input fields and text view
- Notes app interface
- Login form example

## Running the Example App

### Option 1: Using Xcode

1. Open the `MobileDesignSystem` package in Xcode
2. Create a new iOS App target:
   - File → New → Target
   - Choose "App" template
   - Name it "MobileDesignSystemExampleApp"
3. Add the example app files to the new target
4. Add `MobileDesignSystem` as a dependency to the example app target
5. Build and run

### Option 2: Using Swift Package Manager

The example app files are provided as reference implementations. To use them:

1. Create a new Xcode project (iOS App)
2. Add `MobileDesignSystem` as a local package dependency
3. Copy the example app files into your project
4. Build and run

## Code Examples

### Basic Input Field Usage

```swift
@State private var text = ""

MDSInputField(text: $text)
    .placeholder("Enter text")
    .cornerRadius(8)
    .borderWidth(1)
    .borderColor(.separator)
    .focusedBorderColor(.systemBlue)
```

### Basic Text View Usage

```swift
@State private var text = ""

MDSTextView(text: $text, isEditable: true)
    .font(.system(size: 16))
    .cornerRadius(8)
    .borderWidth(1)
    .borderColor(.separator)
```

## Requirements

- iOS 13.0+
- Swift 5.9+
- Xcode 14.0+

## Notes

- The example app demonstrates various styling options and use cases
- All components are fully interactive and demonstrate real-world usage patterns
- The app uses a tab-based navigation to organize different examples
