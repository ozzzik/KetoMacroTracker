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

    var body: some Scene {
        WindowGroup {
            if shouldShowMigration() {
                DataMigrationView()
            } else if shouldShowTutorial() {
                TutorialView(tutorialManager: tutorialManager)
            } else if shouldShowGuidedTour() {
                ContentView()
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
                    .environmentObject(tutorialManager)
                    .environmentObject(guidedTourManager)
                    .onAppear {
                        // Start guided tour after a brief delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            guidedTourManager.startTour()
                        }
                    }
            } else {
                ContentView()
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
                    .environmentObject(tutorialManager)
                    .environmentObject(guidedTourManager)
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
    
    private func shouldShowGuidedTour() -> Bool {
        return tutorialManager.hasCompletedTutorial && !guidedTourManager.hasCompletedTour
    }
}
