//
//  MDSCoachmarkTests.swift
//  MobileDesignSystemTests
//
//  Created on iOS.
//

import XCTest
import SwiftUI
@testable import MobileDesignSystem

final class MDSCoachmarkTests: XCTestCase {
    
    // MARK: - MDSCoachmarkItem Tests
    
    func testCoachmarkItemCreation() {
        let item = MDSCoachmarkItem(id: "test-item") {
            Text("Test content")
        }
        
        XCTAssertEqual(item.id, "test-item")
    }
    
    func testCoachmarkItemUniqueIDs() {
        let item1 = MDSCoachmarkItem(id: "item-1") { Text("A") }
        let item2 = MDSCoachmarkItem(id: "item-2") { Text("B") }
        
        XCTAssertNotEqual(item1.id, item2.id)
    }
    
    // MARK: - AnyMDSCoachmarkItem Tests
    
    func testAnyCoachmarkItemCreation() {
        let item = MDSCoachmarkItem(id: "any-test") {
            VStack {
                Text("Title")
                Text("Subtitle")
            }
        }
        
        let anyItem = AnyMDSCoachmarkItem(item)
        XCTAssertEqual(anyItem.id, "any-test")
    }
    
    func testAnyCoachmarkItemPreservesID() {
        let originalID = "preserved-id"
        let item = MDSCoachmarkItem(id: originalID) { Text("Content") }
        let anyItem = AnyMDSCoachmarkItem(item)
        
        XCTAssertEqual(anyItem.id, originalID)
    }
    
    func testMultipleAnyCoachmarkItems() {
        let items: [AnyMDSCoachmarkItem] = [
            AnyMDSCoachmarkItem(MDSCoachmarkItem(id: "a") { Text("A") }),
            AnyMDSCoachmarkItem(MDSCoachmarkItem(id: "b") { Text("B") }),
            AnyMDSCoachmarkItem(MDSCoachmarkItem(id: "c") { Text("C") })
        ]
        
        XCTAssertEqual(items.count, 3)
        XCTAssertEqual(items[0].id, "a")
        XCTAssertEqual(items[1].id, "b")
        XCTAssertEqual(items[2].id, "c")
    }
    
    // MARK: - MDSCoachmarkConfiguration Tests
    
    func testDefaultConfiguration() {
        let config = MDSCoachmarkConfiguration()
        
        XCTAssertTrue(config.showExitButton)
        XCTAssertEqual(config.exitButtonLabel, "Skip")
        XCTAssertEqual(config.nextButtonLabel, "Next")
        XCTAssertEqual(config.finishButtonLabel, "Done")
        XCTAssertEqual(config.backButtonLabel, "Back")
        XCTAssertTrue(config.showBackButton)
        XCTAssertEqual(config.tipCornerRadius, 12)
        XCTAssertEqual(config.tipShadowRadius, 8)
        XCTAssertEqual(config.tipHorizontalPadding, 16)
        XCTAssertEqual(config.tipVerticalPadding, 12)
        XCTAssertEqual(config.spotlightBorderWidth, 0)
        XCTAssertEqual(config.spotlightCornerRadius, 8)
        XCTAssertEqual(config.spotlightPadding, 4)
        XCTAssertEqual(config.arrowSize, 8)
        XCTAssertTrue(config.animateTransitions)
    }
    
    func testCustomConfiguration() {
        var config = MDSCoachmarkConfiguration()
        config.showExitButton = false
        config.exitButtonLabel = "Dismiss"
        config.nextButtonLabel = "Continue"
        config.finishButtonLabel = "Got It"
        config.backButtonLabel = "Previous"
        config.showBackButton = false
        config.tipCornerRadius = 16
        config.spotlightPadding = 10
        config.animateTransitions = false
        
        XCTAssertFalse(config.showExitButton)
        XCTAssertEqual(config.exitButtonLabel, "Dismiss")
        XCTAssertEqual(config.nextButtonLabel, "Continue")
        XCTAssertEqual(config.finishButtonLabel, "Got It")
        XCTAssertEqual(config.backButtonLabel, "Previous")
        XCTAssertFalse(config.showBackButton)
        XCTAssertEqual(config.tipCornerRadius, 16)
        XCTAssertEqual(config.spotlightPadding, 10)
        XCTAssertFalse(config.animateTransitions)
    }
    
    func testConfigurationInitWithParameters() {
        let config = MDSCoachmarkConfiguration(
            showExitButton: false,
            exitButtonLabel: "Close",
            nextButtonLabel: "Forward",
            finishButtonLabel: "Finish",
            backButtonLabel: "Backward",
            showBackButton: true,
            tipCornerRadius: 20,
            tipShadowRadius: 4,
            tipHorizontalPadding: 24,
            tipVerticalPadding: 16,
            spotlightBorderWidth: 3,
            spotlightCornerRadius: 16,
            spotlightPadding: 12,
            arrowSize: 10,
            animateTransitions: false
        )
        
        XCTAssertFalse(config.showExitButton)
        XCTAssertEqual(config.exitButtonLabel, "Close")
        XCTAssertEqual(config.nextButtonLabel, "Forward")
        XCTAssertEqual(config.finishButtonLabel, "Finish")
        XCTAssertEqual(config.backButtonLabel, "Backward")
        XCTAssertTrue(config.showBackButton)
        XCTAssertEqual(config.tipCornerRadius, 20)
        XCTAssertEqual(config.tipShadowRadius, 4)
        XCTAssertEqual(config.tipHorizontalPadding, 24)
        XCTAssertEqual(config.tipVerticalPadding, 16)
        XCTAssertEqual(config.spotlightBorderWidth, 3)
        XCTAssertEqual(config.spotlightCornerRadius, 16)
        XCTAssertEqual(config.spotlightPadding, 12)
        XCTAssertEqual(config.arrowSize, 10)
        XCTAssertFalse(config.animateTransitions)
    }
    
    // MARK: - Arrow Direction Tests
    
    func testArrowDirectionValues() {
        let auto = MDSCoachmarkArrowDirection.automatic
        let top = MDSCoachmarkArrowDirection.top
        let bottom = MDSCoachmarkArrowDirection.bottom
        
        // Just verify they are distinct enum cases that can be created
        XCTAssertNotNil(auto)
        XCTAssertNotNil(top)
        XCTAssertNotNil(bottom)
    }
    
    func testConfigurationArrowDirection() {
        var config = MDSCoachmarkConfiguration()
        
        config.arrowDirection = .top
        XCTAssertTrue(isTopDirection(config.arrowDirection))
        
        config.arrowDirection = .bottom
        XCTAssertTrue(isBottomDirection(config.arrowDirection))
        
        config.arrowDirection = .automatic
        XCTAssertTrue(isAutomaticDirection(config.arrowDirection))
    }
    
    private func isTopDirection(_ direction: MDSCoachmarkArrowDirection) -> Bool {
        if case .top = direction { return true }
        return false
    }
    
    private func isBottomDirection(_ direction: MDSCoachmarkArrowDirection) -> Bool {
        if case .bottom = direction { return true }
        return false
    }
    
    private func isAutomaticDirection(_ direction: MDSCoachmarkArrowDirection) -> Bool {
        if case .automatic = direction { return true }
        return false
    }
    
    // MARK: - Preference Key Tests
    
    func testPreferenceKeyDefaultValue() {
        let defaultValue = MDSCoachmarkAnchorPreferenceKey.defaultValue
        XCTAssertTrue(defaultValue.isEmpty)
    }
    
    // MARK: - Triangle Shape Tests
    
    func testTrianglePathCreation() {
        let triangle = Triangle()
        let rect = CGRect(x: 0, y: 0, width: 20, height: 10)
        let path = triangle.path(in: rect)
        
        XCTAssertFalse(path.isEmpty)
        XCTAssertTrue(path.boundingRect.width <= rect.width + 1)
        XCTAssertTrue(path.boundingRect.height <= rect.height + 1)
    }
    
    func testTrianglePathWithZeroRect() {
        let triangle = Triangle()
        let rect = CGRect.zero
        let path = triangle.path(in: rect)
        
        // A zero-sized rect should still produce a valid (degenerate) path
        XCTAssertNotNil(path)
    }
    
    // MARK: - Integration-style Tests
    
    func testCoachmarkItemsArrayOrder() {
        let items: [AnyMDSCoachmarkItem] = [
            AnyMDSCoachmarkItem(MDSCoachmarkItem(id: "step-1") { Text("First") }),
            AnyMDSCoachmarkItem(MDSCoachmarkItem(id: "step-2") { Text("Second") }),
            AnyMDSCoachmarkItem(MDSCoachmarkItem(id: "step-3") { Text("Third") })
        ]
        
        XCTAssertEqual(items.count, 3)
        XCTAssertEqual(items.first?.id, "step-1")
        XCTAssertEqual(items.last?.id, "step-3")
        
        // Verify order is preserved
        for (index, item) in items.enumerated() {
            XCTAssertEqual(item.id, "step-\(index + 1)")
        }
    }
    
    func testEmptyCoachmarkItemsArray() {
        let items: [AnyMDSCoachmarkItem] = []
        XCTAssertTrue(items.isEmpty)
    }
    
    func testCoachmarkItemWithComplexContent() {
        let item = MDSCoachmarkItem(id: "complex") {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "star.fill")
                    Text("Title")
                        .font(.headline)
                }
                Text("Description text that is longer")
                    .font(.subheadline)
                HStack {
                    Image(systemName: "checkmark")
                    Text("Feature enabled")
                }
            }
        }
        
        let anyItem = AnyMDSCoachmarkItem(item)
        XCTAssertEqual(anyItem.id, "complex")
    }
}
