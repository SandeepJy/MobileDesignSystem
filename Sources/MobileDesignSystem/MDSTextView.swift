//
//  MDSTextView.swift
//  MobileDesignSystem
//
//  Created on iOS.
//

import SwiftUI

/// A simple text view component from the Mobile Design System
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
    
    /// Initializes a new MDSTextView with a binding to text
    /// - Parameters:
    ///   - text: Binding to the text content
    ///   - isEditable: Whether the text view is editable (default: true)
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
    
    /// Initializes a new MDSTextView with static text
    /// - Parameter text: The text content to display
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
    
    /// Initializes a new MDSTextView with attributed text
    /// - Parameter attributedText: The attributed text content to display
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
    
    /// Sets the font for the text view
    public func font(_ font: Font?) -> MDSTextView {
        var view = self
        view.font = font
        return view
    }
    
    /// Sets the text color
    public func textColor(_ color: Color?) -> MDSTextView {
        var view = self
        view.textColor = color
        return view
    }
    
    /// Sets the text alignment
    public func textAlignment(_ alignment: TextAlignment) -> MDSTextView {
        var view = self
        view.textAlignment = alignment
        return view
    }
    
    /// Sets whether the text view is scrollable
    public func scrollEnabled(_ enabled: Bool) -> MDSTextView {
        var view = self
        view.isScrollEnabled = enabled
        return view
    }
    
    /// Sets the background color
    public func textViewBackgroundColor(_ color: Color?) -> MDSTextView {
        var view = self
        view.textViewBackgroundColor = color
        return view
    }
    
    /// Sets the corner radius
    public func cornerRadius(_ radius: CGFloat) -> MDSTextView {
        var view = self
        view.cornerRadius = radius
        return view
    }
    
    /// Sets the border width
    public func borderWidth(_ width: CGFloat) -> MDSTextView {
        var view = self
        view.borderWidth = width
        return view
    }
    
    /// Sets the border color
    public func borderColor(_ color: Color?) -> MDSTextView {
        var view = self
        view.borderColor = color
        return view
    }
    
    /// Sets the padding
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
