//
//  DataMigrationView.swift
//  KetoMacroTracker
//
//  Created by Oz Hardoon on 1/11/25.
//

import SwiftUI
import UIKit

struct DataMigrationView: View {
    @StateObject private var migrator = CrossAppDataMigrator()
    @State private var showMainApp = false
    
    var body: some View {
        ZStack {
            // Background
            Color(AppColors.background)
                .ignoresSafeArea()
            
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 60))
                        .foregroundColor(AppColors.primary)
                    
                    Text("Welcome Back!")
                        .font(AppTypography.largeTitle)
                        .foregroundColor(AppColors.text)
                    
                    Text("We're checking for your existing data...")
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                
                // Migration Status
                VStack(spacing: 16) {
                    // Progress Bar
                    if migrator.migrationStatus == .inProgress {
                        ProgressView(value: migrator.migrationProgress)
                            .progressViewStyle(LinearProgressViewStyle(tint: AppColors.primary))
                            .frame(height: 8)
                            .cornerRadius(4)
                    }
                    
                    // Status Message
                    Text(migrator.migrationMessage)
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.text)
                        .multilineTextAlignment(.center)
                        .animation(.easeInOut, value: migrator.migrationMessage)
                    
                    // Debug Button (temporary)
                    Button(action: {
                        debugUserDefaults()
                    }) {
                        Text("Debug: Check UserDefaults")
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.secondaryText)
                    }
                }
                .padding(.horizontal, 32)
                
                // Action Buttons
                VStack(spacing: 16) {
                    switch migrator.migrationStatus {
                    case .notStarted:
                        Button(action: {
                            migrator.checkAndMigrateData()
                        }) {
                            HStack {
                                Image(systemName: "arrow.clockwise")
                                Text("Check for Data")
                            }
                            .font(AppTypography.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(AppColors.primary)
                            .cornerRadius(12)
                        }
                        .padding(.horizontal, 32)
                        
                    case .inProgress:
                        Button(action: {
                            // Migration in progress, disable button
                        }) {
                            HStack {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                                Text("Migrating...")
                            }
                            .font(AppTypography.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(AppColors.primary.opacity(0.6))
                            .cornerRadius(12)
                        }
                        .disabled(true)
                        .padding(.horizontal, 32)
                        
                    case .completed:
                        VStack(spacing: 16) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.green)
                            
                            Text("Migration Complete!")
                                .font(AppTypography.title2)
                                .foregroundColor(AppColors.text)
                            
                            Button(action: {
                                showMainApp = true
                            }) {
                                Text("Continue to App")
                                    .font(AppTypography.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(AppColors.primary)
                                    .cornerRadius(12)
                            }
                            .padding(.horizontal, 32)
                        }
                        
                    case .failed(let error):
                        VStack(spacing: 16) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.orange)
                            
                            Text("Migration Failed")
                                .font(AppTypography.title2)
                                .foregroundColor(AppColors.text)
                            
                            Text(error)
                                .font(AppTypography.caption)
                                .foregroundColor(AppColors.secondaryText)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                            
                            HStack(spacing: 16) {
                                Button(action: {
                                    migrator.resetMigrationStatus()
                                }) {
                                    Text("Try Again")
                                        .font(AppTypography.headline)
                                        .foregroundColor(AppColors.primary)
                                        .frame(height: 44)
                                        .frame(maxWidth: .infinity)
                                        .background(AppColors.primary.opacity(0.1))
                                        .cornerRadius(8)
                                }
                                
                                Button(action: {
                                    showMainApp = true
                                }) {
                                    Text("Skip Migration")
                                        .font(AppTypography.headline)
                                        .foregroundColor(.white)
                                        .frame(height: 44)
                                        .frame(maxWidth: .infinity)
                                        .background(AppColors.primary)
                                        .cornerRadius(8)
                                }
                            }
                            .padding(.horizontal, 32)
                        }
                        
                    case .noDataFound:
                        VStack(spacing: 16) {
                            Image(systemName: "doc.text.magnifyingglass")
                                .font(.system(size: 50))
                                .foregroundColor(AppColors.secondaryText)
                            
                            Text("No Previous Data Found")
                                .font(AppTypography.title2)
                                .foregroundColor(AppColors.text)
                            
                            Text("We didn't find any existing data. You can start fresh with a new profile and begin tracking your macros!")
                                .font(AppTypography.body)
                                .foregroundColor(AppColors.secondaryText)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                            
                            VStack(spacing: 12) {
                        Button(action: {
                            showMainApp = true
                        }) {
                            Text("Continue to App")
                                .font(AppTypography.headline)
                                .foregroundColor(AppColors.primary)
                                .frame(height: 44)
                                .frame(maxWidth: .infinity)
                                .background(AppColors.primary.opacity(0.1))
                                .cornerRadius(8)
                        }
                                
                                Button(action: {
                                    showMainApp = true
                                }) {
                                    Text("Start Fresh")
                                        .font(AppTypography.headline)
                                        .foregroundColor(.white)
                                        .frame(height: 44)
                                        .frame(maxWidth: .infinity)
                                        .background(AppColors.primary)
                                        .cornerRadius(8)
                                }
                            }
                            .padding(.horizontal, 32)
                        }
                    }
                }
                
                Spacer()
            }
        }
        .fullScreenCover(isPresented: $showMainApp) {
            // This will show the main app content
            ContentView()
        }
        .onAppear {
            // Automatically start checking for data when the view appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                migrator.checkAndMigrateData()
            }
        }
    }
    
    private func debugUserDefaults() {
        let allKeys = UserDefaults.standard.dictionaryRepresentation().keys
        print("🔍 DEBUG: All UserDefaults keys:")
        for key in Array(allKeys).sorted() {
            print("  - \(key)")
        }
        
        // Check specific keys we're looking for
        let dataKeys = ["UserProfile", "QuickAddItems", "FoodLogData", "HistoricalData", "HistoricalFoodLogData", "AppSettings", "LastSavedDate", "AppDataVersion"]
        print("🔍 DEBUG: Checking specific data keys:")
        for key in dataKeys {
            if let data = UserDefaults.standard.data(forKey: key) {
                print("  ✅ \(key): \(data.count) bytes")
            } else {
                print("  ❌ \(key): No data")
            }
        }
        
        // Show alert with results
        let alert = UIAlertController(
            title: "UserDefaults Debug",
            message: "Check the console for detailed output. Found \(allKeys.count) total keys.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(alert, animated: true)
        }
    }
    
}

#Preview {
    DataMigrationView()
}
