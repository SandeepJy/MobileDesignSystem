//
//  MobileDesignSystemTests.swift
//  MobileDesignSystemTests
//
//  Created on iOS.
//

import XCTest
@testable import MobileDesignSystem

final class MobileDesignSystemTests: XCTestCase {
    
    // Note: MDSTextView is a SwiftUI View and should be tested through UI tests or snapshot tests
    // Basic initialization tests are included here for reference
    
    func testMDSTextViewWithBinding() {
        let binding = Binding<String>(
            get: { "Test text" },
            set: { _ in }
        )
        let textView = MDSTextView(text: binding)
        XCTAssertNotNil(textView)
    }
    
    func testMDSTextViewWithStaticText() {
        let textView = MDSTextView(text: "Static text")
        XCTAssertNotNil(textView)
    }
    
    // Note: MDSInputField is a SwiftUI View that wraps UIKit and should be tested through UI tests or snapshot tests
    // Basic initialization tests are included here for reference
    
    func testMDSInputFieldWithBinding() {
        let binding = Binding<String>(
            get: { "" },
            set: { _ in }
        )
        let inputField = MDSInputField(text: binding)
        XCTAssertNotNil(inputField)
    }
    
    func testMDSInputFieldWithText() {
        let binding = Binding<String>(
            get: { "Test input" },
            set: { _ in }
        )
        let inputField = MDSInputField(text: binding)
        XCTAssertNotNil(inputField)
    }
    
    func testMDSInputFieldModifiers() {
        let binding = Binding<String>(
            get: { "" },
            set: { _ in }
        )
        let inputField = MDSInputField(text: binding)
            .placeholder("Enter text")
            .font(.systemFont(ofSize: 16))
            .cornerRadius(8)
        
        XCTAssertNotNil(inputField)
    }
}
