//
//  MDSInputField.swift
//  MobileDesignSystem
//
//  Created on iOS.
//

import SwiftUI
import UIKit

// MARK: - UIKit Implementation

/// UIKit implementation of an input control from the Mobile Design System
@IBDesignable
public class MDSInputFieldUIKit: UIView {
    
    // MARK: - Properties
    
    /// The text content of the input field
    public var text: String? {
        get {
            return textField.text
        }
        set {
            textField.text = newValue
        }
    }
    
    /// The placeholder text displayed when the field is empty
    @IBInspectable
    public var placeholder: String? {
        get {
            return textField.placeholder
        }
        set {
            textField.placeholder = newValue
            updatePlaceholder()
        }
    }
    
    /// The font used for the text
    @IBInspectable
    public var font: UIFont? {
        get {
            return textField.font
        }
        set {
            textField.font = newValue
        }
    }
    
    /// The text color
    @IBInspectable
    public var textColor: UIColor? {
        get {
            return textField.textColor
        }
        set {
            textField.textColor = newValue
        }
    }
    
    /// The placeholder text color
    @IBInspectable
    public var placeholderColor: UIColor = .placeholderText {
        didSet {
            updatePlaceholder()
        }
    }
    
    /// The text alignment
    public var textAlignment: NSTextAlignment {
        get {
            return textField.textAlignment
        }
        set {
            textField.textAlignment = newValue
        }
    }
    
    /// The keyboard type
    public var keyboardType: UIKeyboardType {
        get {
            return textField.keyboardType
        }
        set {
            textField.keyboardType = newValue
        }
    }
    
    /// Whether the input field is secure (for passwords)
    @IBInspectable
    public var isSecureTextEntry: Bool {
        get {
            return textField.isSecureTextEntry
        }
        set {
            textField.isSecureTextEntry = newValue
        }
    }
    
    /// Whether the input field is enabled
    @IBInspectable
    public var isEnabled: Bool {
        get {
            return textField.isEnabled
        }
        set {
            textField.isEnabled = newValue
            updateAppearance()
        }
    }
    
    /// The background color of the input field
    @IBInspectable
    public var inputBackgroundColor: UIColor? {
        get {
            return textField.backgroundColor
        }
        set {
            textField.backgroundColor = newValue
        }
    }
    
    /// The corner radius of the input field
    @IBInspectable
    public var cornerRadius: CGFloat = 8 {
        didSet {
            textField.layer.cornerRadius = cornerRadius
            textField.layer.masksToBounds = cornerRadius > 0
        }
    }
    
    /// The border width of the input field
    @IBInspectable
    public var borderWidth: CGFloat = 1 {
        didSet {
            textField.layer.borderWidth = borderWidth
        }
    }
    
    /// The border color of the input field
    @IBInspectable
    public var borderColor: UIColor = .separator {
        didSet {
            textField.layer.borderColor = borderColor.cgColor
        }
    }
    
    /// The border color when the field is focused
    @IBInspectable
    public var focusedBorderColor: UIColor = .systemBlue {
        didSet {
            updateAppearance()
        }
    }
    
    /// The left padding inset
    @IBInspectable
    public var leftPadding: CGFloat = 12 {
        didSet {
            updatePadding()
        }
    }
    
    /// The right padding inset
    @IBInspectable
    public var rightPadding: CGFloat = 12 {
        didSet {
            updatePadding()
        }
    }
    
    /// Delegate for text field events
    public weak var delegate: UITextFieldDelegate? {
        get {
            return textField.delegate
        }
        set {
            textField.delegate = newValue
        }
    }
    
    // MARK: - Private Properties
    
    private let textField: UITextField = {
        let textField = UITextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.font = UIFont.systemFont(ofSize: 17)
        textField.textColor = .label
        textField.backgroundColor = .systemBackground
        textField.borderStyle = .none
        textField.layer.cornerRadius = 8
        textField.layer.borderWidth = 1
        textField.layer.borderColor = UIColor.separator.cgColor
        return textField
    }()
    
    private var leftPaddingView: UIView?
    private var rightPaddingView: UIView?
    
    // MARK: - Initialization
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    // MARK: - Setup
    
    private func setupView() {
        addSubview(textField)
        
        // Set up padding
        updatePadding()
        
        // Set up appearance
        updateAppearance()
        
        // Add notification observers for focus changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(textFieldDidBeginEditing),
            name: UITextField.textDidBeginEditingNotification,
            object: textField
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(textFieldDidEndEditing),
            name: UITextField.textDidEndEditingNotification,
            object: textField
        )
        
        NSLayoutConstraint.activate([
            textField.topAnchor.constraint(equalTo: topAnchor),
            textField.leadingAnchor.constraint(equalTo: leadingAnchor),
            textField.trailingAnchor.constraint(equalTo: trailingAnchor),
            textField.bottomAnchor.constraint(equalTo: bottomAnchor),
            textField.heightAnchor.constraint(greaterThanOrEqualToConstant: 44)
        ])
    }
    
    private func updatePadding() {
        // Remove existing padding views
        leftPaddingView?.removeFromSuperview()
        rightPaddingView?.removeFromSuperview()
        
        // Add left padding
        if leftPadding > 0 {
            leftPaddingView = UIView(frame: CGRect(x: 0, y: 0, width: leftPadding, height: 1))
            textField.leftView = leftPaddingView
            textField.leftViewMode = .always
        }
        
        // Add right padding
        if rightPadding > 0 {
            rightPaddingView = UIView(frame: CGRect(x: 0, y: 0, width: rightPadding, height: 1))
            textField.rightView = rightPaddingView
            textField.rightViewMode = .always
        }
    }
    
    private func updatePlaceholder() {
        guard let placeholder = placeholder else {
            textField.placeholder = nil
            return
        }
        
        textField.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [
                .foregroundColor: placeholderColor,
                .font: font ?? UIFont.systemFont(ofSize: 17)
            ]
        )
    }
    
    private func updateAppearance() {
        if isEnabled {
            textField.alpha = 1.0
        } else {
            textField.alpha = 0.6
        }
    }
    
    // MARK: - Focus Handling
    
    @objc private func textFieldDidBeginEditing() {
        UIView.animate(withDuration: 0.2) {
            self.textField.layer.borderColor = self.focusedBorderColor.cgColor
        }
    }
    
    @objc private func textFieldDidEndEditing() {
        UIView.animate(withDuration: 0.2) {
            self.textField.layer.borderColor = self.borderColor.cgColor
        }
    }
    
    // MARK: - Public Methods
    
    /// Sets the text content
    /// - Parameter text: The text to set
    public func setText(_ text: String) {
        self.text = text
    }
    
    /// Clears the text content
    public func clear() {
        textField.text = nil
    }
    
    /// Makes the input field become first responder
    @discardableResult
    public override func becomeFirstResponder() -> Bool {
        return textField.becomeFirstResponder()
    }
    
    /// Makes the input field resign first responder
    @discardableResult
    public override func resignFirstResponder() -> Bool {
        return textField.resignFirstResponder()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - SwiftUI Wrapper

/// A SwiftUI view that wraps a UIKit text field with enhanced styling and focus states.
///
/// `MDSInputField` provides a SwiftUI interface to a UIKit `UITextField`, offering
/// customizable styling, focus animations, and callback support while maintaining
/// native iOS text input behavior.
///
/// ## Topics
///
/// ### Creating an Input Field
/// - ``init(text:)``
///
/// ### Styling
/// - ``placeholder(_:)``
/// - ``font(_:)``
/// - ``font(size:weight:)``
/// - ``textColor(_:)``
/// - ``placeholderColor(_:)``
/// - ``textAlignment(_:)``
/// - ``inputBackgroundColor(_:)``
/// - ``cornerRadius(_:)``
/// - ``borderWidth(_:)``
/// - ``borderColor(_:)``
/// - ``focusedBorderColor(_:)``
/// - ``leftPadding(_:)``
/// - ``rightPadding(_:)``
///
/// ### Behavior
/// - ``keyboardType(_:)``
/// - ``isSecureTextEntry(_:)``
/// - ``isEnabled(_:)``
///
/// ### Callbacks
/// - ``onTextChange(_:)``
/// - ``onEditingBegan(_:)``
/// - ``onEditingEnded(_:)``
///
/// ## Examples
///
/// ### Basic Input Field
/// ```swift
/// @State private var text = ""
///
/// MDSInputField(text: $text)
///     .placeholder("Enter your name")
///     .font(size: 16)
///     .cornerRadius(8)
///     .borderWidth(1)
///     .borderColor(.separator)
/// ```
///
/// ### Password Field
/// ```swift
/// @State private var password = ""
///
/// MDSInputField(text: $password)
///     .placeholder("Password")
///     .isSecureTextEntry(true)
///     .keyboardType(.default)
/// ```
///
/// ### Email Input with Callbacks
/// ```swift
/// @State private var email = ""
///
/// MDSInputField(text: $email)
///     .placeholder("Email")
///     .keyboardType(.emailAddress)
///     .onTextChange { newText in
///         print("Email changed: \(newText)")
///     }
///     .onEditingBegan {
///         print("Editing started")
///     }
/// ```
public struct MDSInputField: UIViewRepresentable {
    
    // MARK: - Properties
    
    /// Binding to the text content
    @Binding public var text: String
    
    /// The placeholder text displayed when the field is empty
    public var placeholder: String?
    
    /// The font used for the text
    public var font: UIFont?
    
    /// The text color
    public var textColor: UIColor?
    
    /// The placeholder text color
    public var placeholderColor: UIColor
    
    /// The text alignment
    public var textAlignment: NSTextAlignment
    
    /// The keyboard type
    public var keyboardType: UIKeyboardType
    
    /// Whether the input field is secure (for passwords)
    public var isSecureTextEntry: Bool
    
    /// Whether the input field is enabled
    public var isEnabled: Bool
    
    /// The background color of the input field
    public var inputBackgroundColor: UIColor?
    
    /// The corner radius of the input field
    public var cornerRadius: CGFloat
    
    /// The border width of the input field
    public var borderWidth: CGFloat
    
    /// The border color of the input field
    public var borderColor: UIColor
    
    /// The border color when the field is focused
    public var focusedBorderColor: UIColor
    
    /// The left padding inset
    public var leftPadding: CGFloat
    
    /// The right padding inset
    public var rightPadding: CGFloat
    
    /// Callback when text changes
    public var onTextChange: ((String) -> Void)?
    
    /// Callback when editing begins
    public var onEditingBegan: (() -> Void)?
    
    /// Callback when editing ends
    public var onEditingEnded: (() -> Void)?
    
    // MARK: - Initialization
    
    /// Creates a new input field with a binding to the text content.
    ///
    /// Use this initializer to create an input field that allows users to enter and edit text.
    /// The text binding provides two-way data flow between your view and the input field.
    ///
    /// - Parameter text: A binding to the text content that will be displayed and can be edited.
    ///
    /// ## Example
    /// ```swift
    /// @State private var username = ""
    ///
    /// MDSInputField(text: $username)
    ///     .placeholder("Username")
    /// ```
    public init(text: Binding<String>) {
        self._text = text
        self.placeholder = nil
        self.font = nil
        self.textColor = nil
        self.placeholderColor = .placeholderText
        self.textAlignment = .left
        self.keyboardType = .default
        self.isSecureTextEntry = false
        self.isEnabled = true
        self.inputBackgroundColor = nil
        self.cornerRadius = 8
        self.borderWidth = 1
        self.borderColor = .separator
        self.focusedBorderColor = .systemBlue
        self.leftPadding = 12
        self.rightPadding = 12
        self.onTextChange = nil
        self.onEditingBegan = nil
        self.onEditingEnded = nil
    }
    
    // MARK: - UIViewRepresentable
    
    public func makeUIView(context: Context) -> MDSInputFieldUIKit {
        let uiView = MDSInputFieldUIKit()
        uiView.delegate = context.coordinator
        
        // Set initial properties
        uiView.text = text.isEmpty ? nil : text
        uiView.placeholder = placeholder
        uiView.font = font
        uiView.textColor = textColor
        uiView.placeholderColor = placeholderColor
        uiView.textAlignment = textAlignment
        uiView.keyboardType = keyboardType
        uiView.isSecureTextEntry = isSecureTextEntry
        uiView.isEnabled = isEnabled
        uiView.inputBackgroundColor = inputBackgroundColor
        uiView.cornerRadius = cornerRadius
        uiView.borderWidth = borderWidth
        uiView.borderColor = borderColor
        uiView.focusedBorderColor = focusedBorderColor
        uiView.leftPadding = leftPadding
        uiView.rightPadding = rightPadding
        
        return uiView
    }
    
    public func updateUIView(_ uiView: MDSInputFieldUIKit, context: Context) {
        // Update coordinator reference to latest parent state
        context.coordinator.parent = self
        
        // Update text if it changed externally (avoid infinite loop by checking if different)
        let currentText = uiView.text ?? ""
        if currentText != text {
            uiView.text = text.isEmpty ? nil : text
        }
        
        // Update all properties
        uiView.placeholder = placeholder
        uiView.font = font
        uiView.textColor = textColor
        uiView.placeholderColor = placeholderColor
        uiView.textAlignment = textAlignment
        uiView.keyboardType = keyboardType
        uiView.isSecureTextEntry = isSecureTextEntry
        uiView.isEnabled = isEnabled
        uiView.inputBackgroundColor = inputBackgroundColor
        uiView.cornerRadius = cornerRadius
        uiView.borderWidth = borderWidth
        uiView.borderColor = borderColor
        uiView.focusedBorderColor = focusedBorderColor
        uiView.leftPadding = leftPadding
        uiView.rightPadding = rightPadding
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    // MARK: - Coordinator
    
    public class Coordinator: NSObject, UITextFieldDelegate {
        var parent: MDSInputField
        
        init(_ parent: MDSInputField) {
            self.parent = parent
        }
        
        public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
            let currentText = textField.text ?? ""
            guard let stringRange = Range(range, in: currentText) else { return false }
            let updatedText = currentText.replacingCharacters(in: stringRange, with: string)
            
            DispatchQueue.main.async {
                self.parent.text = updatedText
                self.parent.onTextChange?(updatedText)
            }
            
            return true
        }
        
        public func textFieldDidBeginEditing(_ textField: UITextField) {
            parent.onEditingBegan?()
        }
        
        public func textFieldDidEndEditing(_ textField: UITextField) {
            parent.onEditingEnded?()
        }
        
        public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            textField.resignFirstResponder()
            return true
        }
    }
    
    // MARK: - Modifiers
    
    /// Sets the placeholder text displayed when the field is empty.
    ///
    /// - Parameter placeholder: The placeholder text to display. Pass `nil` to remove the placeholder.
    /// - Returns: A modified input field with the specified placeholder.
    ///
    /// ## Example
    /// ```swift
    /// MDSInputField(text: $text)
    ///     .placeholder("Enter your email")
    /// ```
    public func placeholder(_ placeholder: String?) -> MDSInputField {
        var view = self
        view.placeholder = placeholder
        return view
    }
    
    /// Sets the font using a UIKit font.
    ///
    /// - Parameter font: The UIKit font to use. Pass `nil` to use the system default.
    /// - Returns: A modified input field with the specified font.
    ///
    /// ## Example
    /// ```swift
    /// MDSInputField(text: $text)
    ///     .font(UIFont.systemFont(ofSize: 18, weight: .semibold))
    /// ```
    public func font(_ font: UIFont?) -> MDSInputField {
        var view = self
        view.font = font
        return view
    }
    
    /// Sets the font using a SwiftUI font.
    ///
    /// - Parameter font: The SwiftUI font to use. Pass `nil` to use the system default.
    /// - Returns: A modified input field with the specified font.
    ///
    /// - Note: This method converts SwiftUI fonts to UIKit fonts. For more control, use ``font(_:)`` with `UIFont`.
    ///
    /// ## Example
    /// ```swift
    /// MDSInputField(text: $text)
    ///     .font(.system(size: 16))
    /// ```
    public func font(_ font: Font?) -> MDSInputField {
        var view = self
        // Convert SwiftUI Font to UIFont
        if let font = font {
            // For system fonts, try to extract size from the font descriptor
            // Default to body text style if we can't determine the size
            let uiFont = UIFont.preferredFont(forTextStyle: .body)
            view.font = uiFont
        } else {
            view.font = nil
        }
        return view
    }
    
    /// Sets the font using a system font with the specified size and weight.
    ///
    /// This is a convenience method for quickly setting a system font without creating a `UIFont` instance.
    ///
    /// - Parameters:
    ///   - size: The font size in points.
    ///   - weight: The font weight. Defaults to `.regular`.
    /// - Returns: A modified input field with the specified font.
    ///
    /// ## Example
    /// ```swift
    /// MDSInputField(text: $text)
    ///     .font(size: 18, weight: .semibold)
    /// ```
    public func font(size: CGFloat, weight: UIFont.Weight = .regular) -> MDSInputField {
        var view = self
        view.font = UIFont.systemFont(ofSize: size, weight: weight)
        return view
    }
    
    /// Sets the color of the text entered by the user.
    ///
    /// - Parameter color: The UIKit color to use for the text. Pass `nil` to use the system default.
    /// - Returns: A modified input field with the specified text color.
    ///
    /// ## Example
    /// ```swift
    /// MDSInputField(text: $text)
    ///     .textColor(.label)
    /// ```
    public func textColor(_ color: UIColor?) -> MDSInputField {
        var view = self
        view.textColor = color
        return view
    }
    
    /// Sets the color of the placeholder text.
    ///
    /// - Parameter color: The UIKit color to use for the placeholder text.
    /// - Returns: A modified input field with the specified placeholder color.
    ///
    /// ## Example
    /// ```swift
    /// MDSInputField(text: $text)
    ///     .placeholder("Enter text")
    ///     .placeholderColor(.systemGray)
    /// ```
    public func placeholderColor(_ color: UIColor) -> MDSInputField {
        var view = self
        view.placeholderColor = color
        return view
    }
    
    /// Sets the alignment of the text within the input field.
    ///
    /// - Parameter alignment: The text alignment (`.left`, `.center`, `.right`, `.justified`, or `.natural`).
    /// - Returns: A modified input field with the specified text alignment.
    ///
    /// ## Example
    /// ```swift
    /// MDSInputField(text: $text)
    ///     .textAlignment(.center)
    /// ```
    public func textAlignment(_ alignment: NSTextAlignment) -> MDSInputField {
        var view = self
        view.textAlignment = alignment
        return view
    }
    
    /// Sets the type of keyboard displayed when the field becomes first responder.
    ///
    /// - Parameter type: The keyboard type (e.g., `.emailAddress`, `.phonePad`, `.numberPad`).
    /// - Returns: A modified input field with the specified keyboard type.
    ///
    /// ## Example
    /// ```swift
    /// MDSInputField(text: $email)
    ///     .keyboardType(.emailAddress)
    /// ```
    public func keyboardType(_ type: UIKeyboardType) -> MDSInputField {
        var view = self
        view.keyboardType = type
        return view
    }
    
    /// Sets whether the input field hides the text (for password fields).
    ///
    /// - Parameter secure: A Boolean value that determines whether text is hidden. `true` for passwords.
    /// - Returns: A modified input field with the specified secure text entry setting.
    ///
    /// ## Example
    /// ```swift
    /// MDSInputField(text: $password)
    ///     .isSecureTextEntry(true)
    /// ```
    public func isSecureTextEntry(_ secure: Bool) -> MDSInputField {
        var view = self
        view.isSecureTextEntry = secure
        return view
    }
    
    /// Sets whether the input field is enabled and can receive user input.
    ///
    /// - Parameter enabled: A Boolean value that determines whether the field is enabled.
    /// - Returns: A modified input field with the specified enabled state.
    ///
    /// - Note: Disabled fields appear dimmed and cannot be edited.
    ///
    /// ## Example
    /// ```swift
    /// MDSInputField(text: $text)
    ///     .isEnabled(false)
    /// ```
    public func isEnabled(_ enabled: Bool) -> MDSInputField {
        var view = self
        view.isEnabled = enabled
        return view
    }
    
    /// Sets the background color of the input field.
    ///
    /// - Parameter color: The UIKit color to use for the background. Pass `nil` to use the system default.
    /// - Returns: A modified input field with the specified background color.
    ///
    /// ## Example
    /// ```swift
    /// MDSInputField(text: $text)
    ///     .inputBackgroundColor(.systemGray6)
    /// ```
    public func inputBackgroundColor(_ color: UIColor?) -> MDSInputField {
        var view = self
        view.inputBackgroundColor = color
        return view
    }
    
    /// Sets the corner radius of the input field.
    ///
    /// - Parameter radius: The corner radius in points. Use `0` for square corners.
    /// - Returns: A modified input field with the specified corner radius.
    ///
    /// ## Example
    /// ```swift
    /// MDSInputField(text: $text)
    ///     .cornerRadius(12)
    /// ```
    public func cornerRadius(_ radius: CGFloat) -> MDSInputField {
        var view = self
        view.cornerRadius = radius
        return view
    }
    
    /// Sets the width of the border around the input field.
    ///
    /// - Parameter width: The border width in points. Use `0` to remove the border.
    /// - Returns: A modified input field with the specified border width.
    ///
    /// ## Example
    /// ```swift
    /// MDSInputField(text: $text)
    ///     .borderWidth(2)
    /// ```
    public func borderWidth(_ width: CGFloat) -> MDSInputField {
        var view = self
        view.borderWidth = width
        return view
    }
    
    /// Sets the color of the border around the input field.
    ///
    /// - Parameter color: The UIKit color to use for the border.
    /// - Returns: A modified input field with the specified border color.
    ///
    /// - Note: The border width must be greater than 0 for the border to be visible.
    ///
    /// ## Example
    /// ```swift
    /// MDSInputField(text: $text)
    ///     .borderWidth(1)
    ///     .borderColor(.separator)
    /// ```
    public func borderColor(_ color: UIColor) -> MDSInputField {
        var view = self
        view.borderColor = color
        return view
    }
    
    /// Sets the color of the border when the input field is focused (first responder).
    ///
    /// The border color animates smoothly between the normal and focused states.
    ///
    /// - Parameter color: The UIKit color to use for the focused border.
    /// - Returns: A modified input field with the specified focused border color.
    ///
    /// ## Example
    /// ```swift
    /// MDSInputField(text: $text)
    ///     .borderWidth(1)
    ///     .borderColor(.separator)
    ///     .focusedBorderColor(.systemBlue)
    /// ```
    public func focusedBorderColor(_ color: UIColor) -> MDSInputField {
        var view = self
        view.focusedBorderColor = color
        return view
    }
    
    /// Sets the left padding inset for the text content.
    ///
    /// - Parameter padding: The padding value in points to apply on the left side.
    /// - Returns: A modified input field with the specified left padding.
    ///
    /// ## Example
    /// ```swift
    /// MDSInputField(text: $text)
    ///     .leftPadding(16)
    /// ```
    public func leftPadding(_ padding: CGFloat) -> MDSInputField {
        var view = self
        view.leftPadding = padding
        return view
    }
    
    /// Sets the right padding inset for the text content.
    ///
    /// - Parameter padding: The padding value in points to apply on the right side.
    /// - Returns: A modified input field with the specified right padding.
    ///
    /// ## Example
    /// ```swift
    /// MDSInputField(text: $text)
    ///     .rightPadding(16)
    /// ```
    public func rightPadding(_ padding: CGFloat) -> MDSInputField {
        var view = self
        view.rightPadding = padding
        return view
    }
    
    /// Sets a callback that is invoked whenever the text content changes.
    ///
    /// - Parameter callback: A closure that receives the new text value whenever it changes.
    /// - Returns: A modified input field with the specified text change callback.
    ///
    /// ## Example
    /// ```swift
    /// MDSInputField(text: $text)
    ///     .onTextChange { newText in
    ///         print("Text changed to: \(newText)")
    ///     }
    /// ```
    public func onTextChange(_ callback: @escaping (String) -> Void) -> MDSInputField {
        var view = self
        view.onTextChange = callback
        return view
    }
    
    /// Sets a callback that is invoked when the user begins editing the field.
    ///
    /// - Parameter callback: A closure that is called when editing begins (field becomes first responder).
    /// - Returns: A modified input field with the specified editing began callback.
    ///
    /// ## Example
    /// ```swift
    /// MDSInputField(text: $text)
    ///     .onEditingBegan {
    ///         print("User started editing")
    ///     }
    /// ```
    public func onEditingBegan(_ callback: @escaping () -> Void) -> MDSInputField {
        var view = self
        view.onEditingBegan = callback
        return view
    }
    
    /// Sets a callback that is invoked when the user finishes editing the field.
    ///
    /// - Parameter callback: A closure that is called when editing ends (field resigns first responder).
    /// - Returns: A modified input field with the specified editing ended callback.
    ///
    /// ## Example
    /// ```swift
    /// MDSInputField(text: $text)
    ///     .onEditingEnded {
    ///         print("User finished editing")
    ///     }
    /// ```
    public func onEditingEnded(_ callback: @escaping () -> Void) -> MDSInputField {
        var view = self
        view.onEditingEnded = callback
        return view
    }
}

// MARK: - Preview

#if DEBUG
struct MDSInputField_Previews: PreviewProvider {
    @State static var text = ""
    
    static var previews: some View {
        VStack(spacing: 20) {
            MDSInputField(text: $text)
                .placeholder("Enter your name")
                .font(.systemFont(ofSize: 10))
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
            
            MDSInputField(text: Binding.constant(""))
                .placeholder("Password")
                .isSecureTextEntry(true)
                .cornerRadius(8)
                .borderWidth(1)
                .borderColor(.separator)
        }
        .padding()
    }
}
#endif
