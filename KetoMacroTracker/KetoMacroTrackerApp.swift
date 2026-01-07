//
//  KetoMacroTrackerApp.swift
//  KetoMacroTracker
//
//  Created by Oz Hardoon on 9/27/25.
//

import SwiftUI

@main
struct KetoMacroTrackerApp: App {
    let persistenceController = PersistenceController.shared
    @StateObject private var migrator = CrossAppDataMigrator()
    @StateObject private var tutorialManager = TutorialManager()
    @StateObject private var guidedTourManager = GuidedTourManager()
    @StateObject private var subscriptionManager = SubscriptionManager.shared

    var body: some Scene {
        WindowGroup {
            if shouldShowMigration() {
                DataMigrationView()
            } else if shouldShowTutorial() {
                TutorialView(tutorialManager: tutorialManager)
            } else {
                ContentView()
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
                    .environmentObject(tutorialManager)
                    .environmentObject(guidedTourManager)
                    .environmentObject(subscriptionManager)
            }
        }
    }
    
    private func shouldShowMigration() -> Bool {
        // Check if this is the first launch after updating bundle ID
        let migrationKey = "hasShownMigration"
        let hasShownMigration = UserDefaults.standard.bool(forKey: migrationKey)
        
        if !hasShownMigration {
            // Mark that we've shown the migration screen
            UserDefaults.standard.set(true, forKey: migrationKey)
            return true
        }
        
        return false
    }
    
    private func shouldShowTutorial() -> Bool {
        return !tutorialManager.hasCompletedTutorial
    }
}
