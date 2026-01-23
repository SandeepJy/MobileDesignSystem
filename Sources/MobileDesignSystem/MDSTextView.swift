//
//  MDSTextView.swift
//  MobileDesignSystem
//
//  Created on iOS.
//

import SwiftUI

/// A SwiftUI text view component from the Mobile Design System.
///
/// `MDSTextView` provides a customizable text view that supports both editable and read-only text display.
/// It can display plain text or attributed text with various styling options.
///
/// ## Topics
///
/// ### Creating a Text View
/// - ``init(text:isEditable:)``
/// - ``init(text:)``
/// - ``init(attributedText:)``
///
/// ### Styling
/// - ``font(_:)``
/// - ``textColor(_:)``
/// - ``textAlignment(_:)``
/// - ``textViewBackgroundColor(_:)``
/// - ``cornerRadius(_:)``
/// - ``borderWidth(_:)``
/// - ``borderColor(_:)``
/// - ``padding(_:)``
///
/// ### Behavior
/// - ``scrollEnabled(_:)``
///
/// ## Examples
///
/// ### Editable Text View
/// ```swift
/// @State private var text = "Enter your text here"
///
/// MDSTextView(text: $text, isEditable: true)
///     .font(.system(size: 16))
///     .textColor(.primary)
///     .cornerRadius(8)
///     .borderWidth(1)
///     .borderColor(.gray)
/// ```
///
/// ### Static Text View
/// ```swift
/// MDSTextView(text: "This is read-only text")
///     .font(.system(size: 16))
///     .textColor(.secondary)
/// ```
///
/// ### Attributed Text View
/// ```swift
/// var attributedString = AttributedString("Styled text")
/// attributedString.foregroundColor = .blue
///
/// MDSTextView(attributedText: attributedString)
///     .cornerRadius(8)
/// ```
public struct MDSTextView: View {
    
    // MARK: - Properties
    
    /// The text content displayed in the text view
    @Binding private var text: String
    
    /// The attributed text content displayed in the text view (for non-editable mode)
    private var attributedText: AttributedString?
    
    /// The font used for the text
    private var font: Font?
    
    /// The text color
    private var textColor: Color?
    
    /// The text alignment
    private var textAlignment: TextAlignment
    
    /// Whether the text view is editable
    private var isEditable: Bool
    
    /// Whether the text view is scrollable
    private var isScrollEnabled: Bool
    
    /// The background color of the text view
    private var textViewBackgroundColor: Color?
    
    /// The corner radius of the text view
    private var cornerRadius: CGFloat
    
    /// The border width of the text view
    private var borderWidth: CGFloat
    
    /// The border color of the text view
    private var borderColor: Color?
    
    /// The padding inset
    private var padding: CGFloat
    
    // MARK: - Initialization
    
    /// Creates a new editable text view with a binding to the text content.
    ///
    /// Use this initializer when you need a text view that users can edit. The text binding
    /// allows you to read and write the text content.
    ///
    /// - Parameters:
    ///   - text: A binding to the text content that will be displayed and can be edited.
    ///   - isEditable: A Boolean value that determines whether the text view is editable.
    ///     Defaults to `true`.
    ///
    /// ## Example
    /// ```swift
    /// @State private var notes = ""
    ///
    /// MDSTextView(text: $notes, isEditable: true)
    ///     .frame(minHeight: 200)
    /// ```
    public init(
        text: Binding<String>,
        isEditable: Bool = true
    ) {
        self._text = text
        self.isEditable = isEditable
        self.attributedText = nil
        self.font = nil
        self.textColor = nil
        self.textAlignment = .leading
        self.isScrollEnabled = true
        self.textViewBackgroundColor = nil
        self.cornerRadius = 0
        self.borderWidth = 0
        self.borderColor = nil
        self.padding = 8
    }
    
    /// Creates a new read-only text view with static text content.
    ///
    /// Use this initializer when you want to display text that cannot be edited by the user.
    /// The text view will automatically be set to non-editable mode.
    ///
    /// - Parameter text: The static text content to display. This text cannot be modified.
    ///
    /// ## Example
    /// ```swift
    /// MDSTextView(text: "This is read-only text")
    ///     .font(.system(size: 16))
    ///     .textColor(.secondary)
    /// ```
    public init(text: String) {
        self._text = Binding(
            get: { text },
            set: { _ in }
        )
        self.isEditable = false
        self.attributedText = nil
        self.font = nil
        self.textColor = nil
        self.textAlignment = .leading
        self.isScrollEnabled = true
        self.textViewBackgroundColor = nil
        self.cornerRadius = 0
        self.borderWidth = 0
        self.borderColor = nil
        self.padding = 8
    }
    
    /// Creates a new read-only text view with attributed text content.
    ///
    /// Use this initializer when you want to display text with rich formatting, such as
    /// different colors, fonts, or styles. The text view will automatically be set to
    /// non-editable mode.
    ///
    /// - Parameter attributedText: The attributed text content to display with formatting.
    ///
    /// ## Example
    /// ```swift
    /// var attributedString = AttributedString("Hello, ")
    /// var world = AttributedString("World!")
    /// world.foregroundColor = .blue
    /// world.font = .system(size: 18, weight: .bold)
    /// attributedString.append(world)
    ///
    /// MDSTextView(attributedText: attributedString)
    /// ```
    public init(attributedText: AttributedString) {
        let textString = String(attributedText.characters)
        self._text = Binding(
            get: { textString },
            set: { _ in }
        )
        self.attributedText = attributedText
        self.isEditable = false
        self.font = nil
        self.textColor = nil
        self.textAlignment = .leading
        self.isScrollEnabled = true
        self.textViewBackgroundColor = nil
        self.cornerRadius = 0
        self.borderWidth = 0
        self.borderColor = nil
        self.padding = 8
    }
    
    // MARK: - Body
    
    public var body: some View {
        Group {
            if isEditable {
                editableTextView
            } else if let attributedText = attributedText {
                nonEditableAttributedTextView(attributedText)
            } else {
                nonEditableTextView
            }
        }
        .padding(padding)
        .background(textViewBackgroundColor)
        .cornerRadius(cornerRadius)
        .overlay(
            Group {
                if borderWidth > 0 {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(borderColor ?? .clear, lineWidth: borderWidth)
                }
            }
        )
    }
    
    // MARK: - View Builders
    
    @ViewBuilder
    private var editableTextView: some View {
        if isScrollEnabled {
            ScrollView {
                TextEditor(text: $text)
                    .frame(minHeight: 100)
                    .multilineTextAlignment(textAlignment)
                    .font(font)
                    .foregroundColor(textColor)
            }
        } else {
            TextEditor(text: $text)
                .frame(minHeight: 100)
                .multilineTextAlignment(textAlignment)
                .font(font)
                .foregroundColor(textColor)
        }
    }
    
    @ViewBuilder
    private var nonEditableTextView: some View {
        if isScrollEnabled {
            ScrollView {
                Text(text)
                    .frame(maxWidth: .infinity, alignment: alignment)
                    .border(.red)
                    .multilineTextAlignment(textAlignment)
            }
        } else {
            Text(text)
                .frame(maxWidth: .infinity, alignment: alignment)
                .multilineTextAlignment(textAlignment)
        }
    }
    
    @ViewBuilder
    private func nonEditableAttributedTextView(_ attributedText: AttributedString) -> some View {
        if isScrollEnabled {
            ScrollView {
                Text(attributedText)
                    .frame(maxWidth: .infinity, alignment: alignment)
                    .multilineTextAlignment(textAlignment)
            }
        } else {
            Text(attributedText)
                .frame(maxWidth: .infinity, alignment: alignment)
                .multilineTextAlignment(textAlignment)
        }
    }
    
    private var alignment: Alignment {
        switch textAlignment {
        case .leading:
            return .leading
        case .center:
            return .center
        case .trailing:
            return .trailing
        }
    }
    
    // MARK: - Modifiers
    
    /// Sets the font used to display the text.
    ///
    /// - Parameter font: The SwiftUI font to use. Pass `nil` to use the system default.
    /// - Returns: A modified text view with the specified font.
    ///
    /// ## Example
    /// ```swift
    /// MDSTextView(text: $text)
    ///     .font(.system(size: 18, weight: .semibold))
    /// ```
    public func font(_ font: Font?) -> MDSTextView {
        var view = self
        view.font = font
        return view
    }
    
    /// Sets the color of the text.
    ///
    /// - Parameter color: The SwiftUI color to use for the text. Pass `nil` to use the system default.
    /// - Returns: A modified text view with the specified text color.
    ///
    /// ## Example
    /// ```swift
    /// MDSTextView(text: $text)
    ///     .textColor(.blue)
    /// ```
    public func textColor(_ color: Color?) -> MDSTextView {
        var view = self
        view.textColor = color
        return view
    }
    
    /// Sets the alignment of the text within the text view.
    ///
    /// - Parameter alignment: The text alignment to apply (`.leading`, `.center`, or `.trailing`).
    /// - Returns: A modified text view with the specified text alignment.
    ///
    /// ## Example
    /// ```swift
    /// MDSTextView(text: $text)
    ///     .textAlignment(.center)
    /// ```
    public func textAlignment(_ alignment: TextAlignment) -> MDSTextView {
        var view = self
        view.textAlignment = alignment
        return view
    }
    
    /// Sets whether the text view allows scrolling when content exceeds the view bounds.
    ///
    /// - Parameter enabled: A Boolean value that determines whether scrolling is enabled.
    ///   Defaults to `true`.
    /// - Returns: A modified text view with the specified scroll behavior.
    ///
    /// - Note: When scrolling is disabled, the text view will expand to fit all content.
    ///
    /// ## Example
    /// ```swift
    /// MDSTextView(text: "Short text")
    ///     .scrollEnabled(false)
    /// ```
    public func scrollEnabled(_ enabled: Bool) -> MDSTextView {
        var view = self
        view.isScrollEnabled = enabled
        return view
    }
    
    /// Sets the background color of the text view.
    ///
    /// - Parameter color: The SwiftUI color to use for the background. Pass `nil` to use the system default.
    /// - Returns: A modified text view with the specified background color.
    ///
    /// ## Example
    /// ```swift
    /// MDSTextView(text: $text)
    ///     .textViewBackgroundColor(Color(.systemGray6))
    /// ```
    public func textViewBackgroundColor(_ color: Color?) -> MDSTextView {
        var view = self
        view.textViewBackgroundColor = color
        return view
    }
    
    /// Sets the corner radius of the text view.
    ///
    /// - Parameter radius: The corner radius in points. Use `0` for square corners.
    /// - Returns: A modified text view with the specified corner radius.
    ///
    /// ## Example
    /// ```swift
    /// MDSTextView(text: $text)
    ///     .cornerRadius(12)
    /// ```
    public func cornerRadius(_ radius: CGFloat) -> MDSTextView {
        var view = self
        view.cornerRadius = radius
        return view
    }
    
    /// Sets the width of the border around the text view.
    ///
    /// - Parameter width: The border width in points. Use `0` to remove the border.
    /// - Returns: A modified text view with the specified border width.
    ///
    /// ## Example
    /// ```swift
    /// MDSTextView(text: $text)
    ///     .borderWidth(2)
    /// ```
    public func borderWidth(_ width: CGFloat) -> MDSTextView {
        var view = self
        view.borderWidth = width
        return view
    }
    
    /// Sets the color of the border around the text view.
    ///
    /// - Parameter color: The SwiftUI color to use for the border. Pass `nil` to use a clear border.
    /// - Returns: A modified text view with the specified border color.
    ///
    /// - Note: The border width must be greater than 0 for the border to be visible.
    ///
    /// ## Example
    /// ```swift
    /// MDSTextView(text: $text)
    ///     .borderWidth(1)
    ///     .borderColor(.gray)
    /// ```
    public func borderColor(_ color: Color?) -> MDSTextView {
        var view = self
        view.borderColor = color
        return view
    }
    
    /// Sets the padding around the text content within the text view.
    ///
    /// - Parameter padding: The padding value in points to apply on all sides.
    /// - Returns: A modified text view with the specified padding.
    ///
    /// ## Example
    /// ```swift
    /// MDSTextView(text: $text)
    ///     .padding(12)
    /// ```
    public func padding(_ padding: CGFloat) -> MDSTextView {
        var view = self
        view.padding = padding
        return view
    }
}

// MARK: - Preview

#if DEBUG
struct MDSTextView_Previews: PreviewProvider {
    @State static var editableText = "Editable text view"
    @State static var staticText = "Static text view"
    
    static var previews: some View {
        VStack(spacing: 20) {
            MDSTextView(text: $editableText, isEditable: true)
                .cornerRadius(8)
                .borderWidth(1)
                .borderColor(.gray)
                .padding(12)
            
            MDSTextView(text: staticText)
                .textColor(.blue)
                .cornerRadius(8)
                .borderWidth(1)
                .borderColor(.gray)
                .padding(12)
        }
        .padding()
    }
}
#endif
