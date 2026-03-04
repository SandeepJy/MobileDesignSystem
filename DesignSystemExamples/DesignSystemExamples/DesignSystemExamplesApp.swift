//
//  DesignSystemExamplesApp.swift
//  DesignSystemExamples
//
//  Created by owner on 2026-01-22.
//

import SwiftUI

@main
struct DesignSystemExamplesApp: App {
    let arguments = ProcessInfo.processInfo.arguments
    
    var body: some Scene {
        WindowGroup {
            if CommandLine.arguments.contains("--ui-testing-coachmarks") {
                CarouselDemoView()
            } else {
                ContentView()
            }
        }
    }
}
