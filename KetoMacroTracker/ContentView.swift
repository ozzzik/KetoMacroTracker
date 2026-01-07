//
//  ContentView.swift
//  KetoMacroTracker
//
//  Created by Oz Hardoon on 9/27/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var foodLogManager = FoodLogManager.shared
    @StateObject private var quickAddManager = QuickAddManager()
    @StateObject private var demoManager = DemoModeManager.shared
    @StateObject private var onboardingManager = OnboardingManager.shared
    @StateObject private var dashboardTutorialManager = DashboardTutorialManager.shared
    @State private var selectedTab = 0
    @Environment(\.scenePhase) private var scenePhase
    
    init() {
        // Initialize data migration manager to ensure data persistence across updates
        _ = DataMigrationManager.shared
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardTodayView()
                .environmentObject(quickAddManager)
                .tag(0)
                .tabItem {
                    Label("Today", systemImage: "calendar")
                }
            
            InsightsView()
                .tag(1)
                .tabItem {
                    Label("Insights", systemImage: "chart.bar.fill")
                }
            
            QuickMealsView()
                .tag(2)
                .tabItem {
                    Label("Meals", systemImage: "fork.knife")
                }
            
            HistoryView()
                .tag(3)
                .tabItem {
                    Label("History", systemImage: "chart.line.uptrend.xyaxis")
                }
            
            ProfileView()
                .tag(4)
                .tabItem {
                    Label("Profile", systemImage: "person.circle")
                }
        }
        .environmentObject(foodLogManager)
        .environmentObject(quickAddManager)
        .overlay {
            OnboardingOverlayView(selectedTab: $selectedTab)
        }
        .overlay {
            DemoOverlayView(selectedTab: $selectedTab)
        }
        .onChange(of: demoManager.targetTab) { oldTab, newTab in
            // Navigate to the appropriate tab when demo step changes
            if let tab = newTab, tab != oldTab {
                DispatchQueue.main.async {
                    selectedTab = tab
                }
            }
        }
        .onChange(of: dashboardTutorialManager.shouldNavigateToDashboard) { _, shouldNavigate in
            if shouldNavigate {
                selectedTab = 0 // Navigate to dashboard tab
            }
        }
        .onAppear {
            // Start onboarding if this is first launch
            if !onboardingManager.hasCompletedOnboarding {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    onboardingManager.startOnboarding()
                }
            }
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            // Save data when app goes to background or becomes inactive
            if newPhase == .background || newPhase == .inactive {
                print("💾 App going to background, saving all data...")
                
                // Save on main thread to ensure @Published properties are accessible
                Task { @MainActor in
                    foodLogManager.saveTodaysFoods()
                    quickAddManager.saveQuickAddItems()
                    
                    // Force immediate write to disk
                    UserDefaults.standard.synchronize()
                    print("✅ All data saved successfully")
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}