//
//  ProfileView.swift
//  Keto Macro Tracker
//
//  Created by Oz Hardoon on 9/27/25.
//

import SwiftUI

struct ProfileView: View {
    @StateObject private var profileManager = ProfileManager.shared
    @EnvironmentObject var tutorialManager: TutorialManager
    @EnvironmentObject var guidedTourManager: GuidedTourManager
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @EnvironmentObject var adManager: AdManager
    @State private var showingEditProfile = false
    @State private var showingDatabaseSettings = false
    @State private var showingAchievements = false
    @StateObject private var dashboardTutorialManager = DashboardTutorialManager.shared
    @State private var showingDataExport = false
    @State private var showingNotificationSettings = false
    @State private var showingHealthIntegration = false
    @State private var showingTutorial = false
    @State private var showingAPIUsageStats = false
    @State private var showingHeartHealthGoals = false
    // @State private var showingDataImport = false
    
    // Current profile data from ProfileManager
    private var currentProfile: UserProfile {
        profileManager.profile
    }
    
    private let activityLevels = ["Sedentary", "Lightly Active", "Moderately Active", "Very Active", "Extremely Active"]
    private let goals = ["Lose Fat", "Maintain Weight", "Gain Weight"]
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ScrollView {
                    VStack(spacing: 24) {
                    // Ads: Watch ad for ad-free rest of day
                    if !adManager.isAdFreeForRestOfDay {
                        AppCard {
                            VStack(spacing: 12) {
                                HStack {
                                    Image(systemName: "play.rectangle.fill")
                                        .foregroundColor(AppColors.accent)
                                        .font(.title2)
                                    Text("Ad-free experience")
                                        .font(AppTypography.title3)
                                        .foregroundColor(AppColors.text)
                                    Spacer()
                                }
                                Button(action: {
                                    if adManager.isAdReady {
                                        let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene
                                        adManager.showRewardedInterstitial(from: scene)
                                    } else {
                                        Task { await adManager.loadRewardedInterstitial() }
                                    }
                                }) {
                                    HStack {
                                        Image(systemName: "play.circle.fill")
                                        Text(adManager.isAdReady ? "Watch ad for ad-free rest of day" : adManager.isLoading ? "Loading ad…" : "Tap to load ad")
                                            .fontWeight(.medium)
                                    }
                                    .font(.subheadline)
                                    .foregroundColor(adManager.isAdReady ? AppColors.primary : AppColors.secondaryText)
                                }
                            }
                        }
                    }
                    
                    // Profile Information
                    AppCard {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Profile Information")
                                .font(AppTypography.title3)
                                .foregroundColor(AppColors.text)
                            
                            VStack(spacing: 12) {
                                ProfileInfoRow(
                                    title: "Weight",
                                    value: "\(Int(currentProfile.weight)) lbs",
                                    icon: "scalemass",
                                    color: AppColors.primary
                                )
                                
                                ProfileInfoRow(
                                    title: "Height",
                                    value: "\(Int(currentProfile.height)) cm",
                                    icon: "ruler",
                                    color: AppColors.primary
                                )
                                
                                ProfileInfoRow(
                                    title: "Age",
                                    value: "\(currentProfile.age) years",
                                    icon: "calendar",
                                    color: AppColors.primary
                                )
                                
                                ProfileInfoRow(
                                    title: "Activity Level",
                                    value: currentProfile.activityLevel,
                                    icon: "figure.walk",
                                    color: AppColors.primary
                                )
                                
                                ProfileInfoRow(
                                    title: "Goal",
                                    value: currentProfile.goal,
                                    icon: "target",
                                    color: AppColors.primary
                                )
                            }
                        }
                    }
                    
                    // Macro Goals
                    AppCard {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Daily Macro Goals")
                                .font(AppTypography.title3)
                                .foregroundColor(AppColors.text)
                            
                            let macroGoals = calculateMacroGoals(profile: currentProfile)
                                
                                VStack(spacing: 12) {
                                    MacroGoalRow(
                                        title: "Protein",
                                        value: "\(Int(macroGoals.protein))g",
                                        color: AppColors.protein
                                    )
                                    
                                    MacroGoalRow(
                                        title: "Net Carbs",
                                        value: "\(Int(macroGoals.carbs))g",
                                        color: AppColors.carbs
                                    )
                                    
                                    MacroGoalRow(
                                        title: "Fat",
                                        value: "\(Int(macroGoals.fat))g",
                                        color: AppColors.fat
                                    )
                                    
                                    MacroGoalRow(
                                        title: "Calories",
                                        value: "\(Int(macroGoals.calories)) kcal",
                                        color: AppColors.calories
                                    )
                                }
                            }
                        }
                    }
                    
                    // Heart Health Goals
                    AppCard {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("Heart Health Goals")
                                    .font(AppTypography.title3)
                                    .foregroundColor(AppColors.text)
                                
                                Spacer()
                                
                                Button(action: {
                                    showingHeartHealthGoals = true
                                }) {
                                    Image(systemName: "pencil")
                                        .foregroundColor(AppColors.primary)
                                        .font(.caption)
                                }
                            }
                            
                            VStack(spacing: 12) {
                                MacroGoalRow(
                                    title: "Cholesterol",
                                    value: "\(Int(currentProfile.cholesterolGoal ?? 300.0))mg",
                                    color: AppColors.cholesterol
                                )
                                
                                MacroGoalRow(
                                    title: "Saturated Fat",
                                    value: "\(String(format: "%.1f", currentProfile.saturatedFatGoal ?? 20.0))g",
                                    color: AppColors.saturatedFat
                                )
                            }
                        }
                    }
                    
                    // Edit Profile Button
                    AppButton(action: {
                        showingEditProfile = true
                    }) {
                        HStack {
                            Image(systemName: "pencil")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Edit Profile")
                                .font(AppTypography.headline)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    
                    // Database Settings Section
                    AppCard {
                        VStack(spacing: 16) {
                            Text("Database Settings")
                                .font(AppTypography.title3)
                                .foregroundColor(AppColors.text)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Button(action: {
                                showingDatabaseSettings = true
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "globe")
                                        .foregroundColor(AppColors.primary)
                                        .font(.title3)
                                    
                                    Text("Configure Food Databases")
                                        .font(AppTypography.body)
                                        .foregroundColor(AppColors.text)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(AppColors.secondaryText)
                                        .font(.caption)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(AppColors.primary.opacity(0.1))
                                .cornerRadius(8)
                            }
                            
                            Text("Choose your country and food databases for better search results")
                                .font(AppTypography.caption)
                                .foregroundColor(AppColors.secondaryText)
                                .multilineTextAlignment(.center)
                        }
                    }
                    
                    // Achievements Section
                    AppCard {
                        VStack(spacing: 16) {
                            Text("Achievements")
                                .font(AppTypography.title3)
                                .foregroundColor(AppColors.text)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Button(action: {
                                showingAchievements = true
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "trophy.fill")
                                        .foregroundColor(.yellow)
                                        .font(.title3)
                                    
                                    Text("View Achievements")
                                        .font(AppTypography.body)
                                        .foregroundColor(AppColors.text)
                                    
                                    Spacer()
                                    
                                    Text("\(AchievementManager.shared.unlockedAchievements.count)")
                                        .font(AppTypography.headline)
                                        .foregroundColor(AppColors.primary)
                                    
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(AppColors.secondaryText)
                                        .font(.caption)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.yellow.opacity(0.1))
                                .cornerRadius(8)
                            }
                            
                            Text("Unlock badges by reaching your goals and maintaining streaks")
                                .font(AppTypography.caption)
                                .foregroundColor(AppColors.secondaryText)
                                .multilineTextAlignment(.center)
                        }
                    }
                    
                    // Notifications Section
                    AppCard {
                        VStack(spacing: 16) {
                            Text("Notifications")
                                .font(AppTypography.title3)
                                .foregroundColor(AppColors.text)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Button(action: {
                                showingNotificationSettings = true
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "bell.fill")
                                        .foregroundColor(AppColors.primary)
                                        .font(.title3)
                                    
                                    Text("Notification Settings")
                                        .font(AppTypography.body)
                                        .foregroundColor(AppColors.text)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(AppColors.secondaryText)
                                        .font(.caption)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(AppColors.primary.opacity(0.1))
                                .cornerRadius(8)
                            }
                            
                            Text("Set up meal reminders, hydration alerts, and progress notifications")
                                .font(AppTypography.caption)
                                .foregroundColor(AppColors.secondaryText)
                                .multilineTextAlignment(.center)
                        }
                    }
                    
                    // HealthKit Integration Section
                    AppCard {
                        VStack(spacing: 16) {
                            HStack {
                                Text("HealthKit Integration")
                                    .font(AppTypography.title3)
                                    .foregroundColor(AppColors.text)
                                
                                Spacer()
                                
                                // HealthKit badge
                                HStack(spacing: 4) {
                                    Image(systemName: "heart.fill")
                                        .font(.caption)
                                    Text("HealthKit")
                                        .font(AppTypography.caption)
                                        .fontWeight(.semibold)
                                }
                                .foregroundColor(.red)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(6)
                            }
                            
                            Button(action: {
                                showingHealthIntegration = true
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "heart.fill")
                                        .foregroundColor(.red)
                                        .font(.title3)
                                    
                                    Text("Manage HealthKit Integration")
                                        .font(AppTypography.body)
                                        .foregroundColor(AppColors.text)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(AppColors.secondaryText)
                                        .font(.caption)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(8)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("This app uses HealthKit to:")
                                    .font(AppTypography.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(AppColors.text)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "arrow.down.circle.fill")
                                            .font(.caption2)
                                            .foregroundColor(.blue)
                                        Text("Read: Weight, body fat, lean body mass")
                                            .font(AppTypography.caption)
                                            .foregroundColor(AppColors.secondaryText)
                                    }
                                    
                                    HStack(spacing: 6) {
                                        Image(systemName: "arrow.up.circle.fill")
                                            .font(.caption2)
                                            .foregroundColor(.green)
                                        Text("Write: Protein, carbs, fat, calories, water")
                                            .font(AppTypography.caption)
                                            .foregroundColor(AppColors.secondaryText)
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 4)
                        }
                    }
                    
                    // Data Export Section
                    AppCard {
                        VStack(spacing: 16) {
                            Text("Data Export")
                                .font(AppTypography.title3)
                                .foregroundColor(AppColors.text)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Button(action: {
                                showingDataExport = true
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "square.and.arrow.up")
                                        .foregroundColor(AppColors.primary)
                                        .font(.title3)
                                    
                                    Text("Export Data")
                                        .font(AppTypography.body)
                                        .foregroundColor(AppColors.text)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(AppColors.secondaryText)
                                        .font(.caption)
                                }
                                .frame(maxWidth: .infinity)
                            }
                            
                            Button(action: {
                                showingAPIUsageStats = true
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "chart.bar.fill")
                                        .foregroundColor(AppColors.accent)
                                        .font(.title3)
                                    
                                    Text("API Usage Statistics")
                                        .font(AppTypography.body)
                                        .foregroundColor(AppColors.text)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(AppColors.secondaryText)
                                        .font(.caption)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(AppColors.primary.opacity(0.1))
                                .cornerRadius(8)
                            }
                            
                            Text("Export your data as CSV files for backup or analysis")
                                .font(AppTypography.caption)
                                .foregroundColor(AppColors.secondaryText)
                                .multilineTextAlignment(.center)
                        }
                    }
                    
                    // Tutorial Section
                    AppCard {
                        VStack(spacing: 16) {
                            Text("Tutorial")
                                .font(AppTypography.title3)
                                .foregroundColor(AppColors.text)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            VStack(spacing: 12) {
                                // Initial Tutorial Button
                                Button(action: {
                                    showingTutorial = true
                                }) {
                                    HStack(spacing: 12) {
                                        Image(systemName: "book.fill")
                                            .foregroundColor(AppColors.primary)
                                            .font(.title3)
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Getting Started Tutorial")
                                                .font(AppTypography.body)
                                                .foregroundColor(AppColors.text)
                                            
                                            Text("Learn the basics of keto tracking")
                                                .font(AppTypography.caption)
                                                .foregroundColor(AppColors.secondaryText)
                                        }
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(AppColors.secondaryText)
                                            .font(.caption)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(AppColors.primary.opacity(0.1))
                                    .cornerRadius(8)
                                }
                                
                                // Dashboard Tutorial Button
                                Button(action: {
                                    dashboardTutorialManager.show()
                                }) {
                                    HStack(spacing: 12) {
                                        Image(systemName: "questionmark.circle.fill")
                                            .foregroundColor(AppColors.accent)
                                            .font(.title3)
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("How to Use the App")
                                                .font(AppTypography.body)
                                                .foregroundColor(AppColors.text)
                                            
                                            Text("Step-by-step guide on the main screen")
                                                .font(AppTypography.caption)
                                                .foregroundColor(AppColors.secondaryText)
                                        }
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(AppColors.secondaryText)
                                            .font(.caption)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(AppColors.accent.opacity(0.1))
                                    .cornerRadius(8)
                                }
                                
                                // Meals Tutorial Button
                                Button(action: {
                                    MealsTutorialManager.shared.show()
                                }) {
                                    HStack(spacing: 12) {
                                        Image(systemName: "fork.knife.circle.fill")
                                            .foregroundColor(AppColors.primary)
                                            .font(.title3)
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Meals Page Tutorial")
                                                .font(AppTypography.body)
                                                .foregroundColor(AppColors.text)
                                            
                                            Text("Learn about meal suggestions, templates & macro fit")
                                                .font(AppTypography.caption)
                                                .foregroundColor(AppColors.secondaryText)
                                        }
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(AppColors.secondaryText)
                                            .font(.caption)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(AppColors.primary.opacity(0.1))
                                    .cornerRadius(8)
                                }
                            }
                        }
                    }
                    
                    // About Section
                    AppCard {
                        VStack(spacing: 16) {
                            Text("About")
                                .font(AppTypography.title3)
                                .foregroundColor(AppColors.text)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            VStack(spacing: 12) {
                                // App Version
                                HStack(spacing: 12) {
                                    Image(systemName: "info.circle.fill")
                                        .foregroundColor(AppColors.primary)
                                        .font(.title3)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Version")
                                            .font(AppTypography.body)
                                            .foregroundColor(AppColors.text)
                                        
                                        Text(appVersion)
                                            .font(AppTypography.caption)
                                            .foregroundColor(AppColors.secondaryText)
                                    }
                                    
                                    Spacer()
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                
                                Divider()
                                
                                // Privacy Policy Link
                                Link(destination: URL(string: "https://ozzzik.github.io/KetoMacroTracker/privacy-policy.html")!) {
                                    HStack(spacing: 12) {
                                        Image(systemName: "lock.shield.fill")
                                            .foregroundColor(AppColors.primary)
                                            .font(.title3)
                                        
                                        Text("Privacy Policy")
                                            .font(AppTypography.body)
                                            .foregroundColor(AppColors.text)
                                        
                                        Spacer()
                                        
                                        Image(systemName: "arrow.up.right.square")
                                            .foregroundColor(AppColors.secondaryText)
                                            .font(.caption)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                }
                                
                                Divider()
                                
                                // Terms of Use (EULA) Link
                                Link(destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!) {
                                    HStack(spacing: 12) {
                                        Image(systemName: "doc.text.fill")
                                            .foregroundColor(AppColors.primary)
                                            .font(.title3)
                                        
                                        Text("Terms of Use (EULA)")
                                            .font(AppTypography.body)
                                            .foregroundColor(AppColors.text)
                                        
                                        Spacer()
                                        
                                        Image(systemName: "arrow.up.right.square")
                                            .foregroundColor(AppColors.secondaryText)
                                            .font(.caption)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                }
                            }
                        }
                    }
                    
                    // Data Transfer Section (Hidden for now)
                    /*
                    AppCard {
                        VStack(spacing: 16) {
                            Text("Data Transfer")
                                .font(AppTypography.title3)
                                .foregroundColor(AppColors.text)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            HStack(spacing: 12) {
                                // Export Button
                                Button(action: {
                                    showingDataExport = true
                                }) {
                                    VStack(spacing: 8) {
                                        Image(systemName: "square.and.arrow.up")
                                            .foregroundColor(AppColors.primary)
                                            .font(.title2)
                                        
                                        Text("Export")
                                            .font(AppTypography.caption)
                                            .foregroundColor(AppColors.text)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(AppColors.primary.opacity(0.1))
                                    .cornerRadius(8)
                                }
                                
                                // Import Button
                                Button(action: {
                                    showingDataImport = true
                                }) {
                                    VStack(spacing: 8) {
                                        Image(systemName: "square.and.arrow.down")
                                            .foregroundColor(AppColors.accent)
                                            .font(.title2)
                                        
                                        Text("Import")
                                            .font(AppTypography.caption)
                                            .foregroundColor(AppColors.text)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(AppColors.accent.opacity(0.1))
                                    .cornerRadius(8)
                                }
                            }
                            
                            Text("Export: Generate a code to transfer your data\nImport: Paste a code to restore your data")
                                .font(AppTypography.caption)
                                .foregroundColor(AppColors.secondaryText)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                    }
                    */
                    
                    Spacer(minLength: 32)
                }
                    .padding(.horizontal, geometry.size.width > 768 ? 32 : 16)
                    .padding(.top, 16)
                }
                .background(AppColors.background)
            }
            .navigationTitle("Profile")
            .adaptiveSheet(isPresented: $showingEditProfile) {
                EditProfileView(profileManager: profileManager) {
                    showingEditProfile = false
                }
            }
            .adaptiveSheet(isPresented: $showingHeartHealthGoals) {
                HeartHealthGoalsView(profileManager: profileManager) {
                    showingHeartHealthGoals = false
                }
            }
            .adaptiveSheet(isPresented: $showingDatabaseSettings) {
                DatabaseSettingsView()
            }
            .adaptiveSheet(isPresented: $showingAchievements) {
                AchievementsView()
            }
            .adaptiveSheet(isPresented: $showingDataExport) {
                DataExportView()
            }
            .adaptiveSheet(isPresented: $showingNotificationSettings) {
                NotificationSettingsView()
            }
            .adaptiveSheet(isPresented: $showingAPIUsageStats) {
                APIUsageStatsView()
            }
            .fullScreenCover(isPresented: $showingTutorial) {
                TutorialView(tutorialManager: tutorialManager)
            }
            .adaptiveSheet(isPresented: $showingHealthIntegration) {
                HealthIntegrationView()
                    .environmentObject(subscriptionManager)
            }
            // .sheet(isPresented: $showingDataImport) {
            //     DataTransferView()
            // }
        }
    }
    
    // MARK: - App Version
    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
    
    // Uses shared calculateMacroGoals function from Utils/MacroCalculations.swift

// MARK: - Helper Views
struct ProfileInfoRow: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)
            
            Text(title)
                .font(AppTypography.body)
                .foregroundColor(AppColors.text)
            
            Spacer()
            
            Text(value)
                .font(AppTypography.body)
                .fontWeight(.semibold)
                .foregroundColor(AppColors.secondaryText)
        }
    }
}

struct MacroGoalRow: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
            
            Text(title)
                .font(AppTypography.body)
                .foregroundColor(AppColors.text)
            
            Spacer()
            
            Text(value)
                .font(AppTypography.body)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(TutorialManager())
        .environmentObject(GuidedTourManager())
        .environmentObject(SubscriptionManager.shared)
        .environmentObject(AdManager.shared)
}
