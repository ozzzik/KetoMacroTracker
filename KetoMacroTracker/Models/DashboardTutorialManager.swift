//
//  DashboardTutorialManager.swift
//  Keto Macro Tracker
//
//  Manager for the dashboard tutorial overlay
//

import Foundation
import SwiftUI

class DashboardTutorialManager: ObservableObject {
    static let shared = DashboardTutorialManager()
    
    @Published var isShowing = false
    @Published var shouldNavigateToDashboard = false
    
    private init() {}
    
    func show() {
        shouldNavigateToDashboard = true
        // Small delay to allow navigation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.isShowing = true
            self.shouldNavigateToDashboard = false
        }
    }
    
    func hide() {
        isShowing = false
    }
}

