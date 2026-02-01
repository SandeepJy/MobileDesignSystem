//
//  MobileDesignSystem.swift
//  MobileDesignSystem
//
//  Created on iOS.
//

import Foundation

/// Mobile Design System - A collection of reusable UI components for iOS applications.
///
/// The Mobile Design System provides a set of SwiftUI components that follow consistent
/// design patterns and can be easily customized to match your app's design language.
///
/// ## Components
///
/// ### MDSTextView
/// A SwiftUI text view component that supports both editable and read-only text display
/// with customizable styling options.
///
/// ### MDSInputField
/// A SwiftUI view that wraps a UIKit text field, providing enhanced styling, focus states,
/// and callback support while maintaining native iOS text input behavior.
///
/// ## Getting Started
///
/// Add MobileDesignSystem to your project using Swift Package Manager:
///
/// ```swift
/// dependencies: [
///     .package(url: "https://github.com/yourusername/MobileDesignSystem.git", from: "1.0.0")
/// ]
/// ```
///
/// Then import the module in your SwiftUI views:
///
/// ```swift
/// import SwiftUI
/// import MobileDesignSystem
/// ```
///
/// ## Requirements
///
/// - iOS 15.0+
/// - Swift 5.9+
/// - Xcode 14.0+
public struct MobileDesignSystem {
    
    /// The current version of the Mobile Design System.
    ///
    /// This version string follows semantic versioning (major.minor.patch).
    public static let version = "1.1.0"
    
    private init() {}
}
