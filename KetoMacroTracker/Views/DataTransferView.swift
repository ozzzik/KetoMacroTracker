//
//  DataTransferView.swift
//  KetoMacroTracker
//
//  Created by Oz Hardoon on 1/11/25.
//

import SwiftUI
import UIKit

struct DataTransferView: View {
    @StateObject private var migrator = CrossAppDataMigrator()
    @State private var importText = ""
    @State private var showRestartAlert = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 60))
                        .foregroundColor(AppColors.primary)
                    
                    Text("Transfer Data Between Apps")
                        .font(AppTypography.largeTitle)
                        .foregroundColor(AppColors.text)
                    
                    Text("If you have data in your old app version, you can transfer it here.")
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                    
                    #if targetEnvironment(simulator)
                    Text("Note: Paste functionality may not work in iOS Simulator. Use a real device for testing data transfer.")
                        .font(AppTypography.caption)
                        .foregroundColor(.orange)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                    #endif
                }
                
                // Current App Data Summary
                VStack(alignment: .leading, spacing: 12) {
                    Text("Current App Data:")
                        .font(AppTypography.title3)
                        .foregroundColor(AppColors.text)
                    
                    ScrollView {
                        Text(migrator.getDataSummary())
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.secondaryText)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(height: 120)
                    .background(AppColors.secondaryBackground)
                    .cornerRadius(8)
                }
                .padding(.horizontal, 32)
                
                // Import Section
                VStack(spacing: 16) {
                    Text("Import Data from Old App:")
                        .font(AppTypography.title3)
                        .foregroundColor(AppColors.text)
                    
                    ZStack(alignment: .topLeading) {
                        TextEditor(text: $importText)
                            .frame(height: 120)
                            .background(AppColors.secondaryBackground)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(AppColors.border, lineWidth: 1)
                            )
                        
                        if importText.isEmpty {
                            Text("Paste your export code here...")
                                .foregroundColor(AppColors.secondaryText)
                                .padding(.top, 8)
                                .padding(.leading, 4)
                                .allowsHitTesting(false)
                        }
                    }
                    
                    HStack(spacing: 12) {
                        Button(action: {
                            pasteFromClipboard()
                        }) {
                            Text("Paste")
                                .font(AppTypography.headline)
                                .foregroundColor(AppColors.primary)
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                                .background(AppColors.primary.opacity(0.1))
                                .cornerRadius(8)
                        }
                        
                        Button(action: {
                            importData()
                        }) {
                            Text("Import Data")
                                .font(AppTypography.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                                .background(AppColors.primary)
                                .cornerRadius(8)
                        }
                        .disabled(importText.isEmpty)
                    }
                }
                .padding(.horizontal, 32)
                
                Spacer()
            }
            .padding(.top, 32)
            .background(AppColors.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Import Successful!", isPresented: $showRestartAlert) {
                Button("Close App") {
                    // Close the app so user can restart it
                    exit(0)
                }
                Button("Later") {
                    dismiss()
                }
            } message: {
                Text("Data has been imported successfully! Please close and reopen the app to see your imported data.")
            }
        }
    }
    
    private func pasteFromClipboard() {
        #if targetEnvironment(simulator)
        // Simulator pasteboard access is limited
        importText = "Paste functionality not available in iOS Simulator. Please use a real device or manually type the export code."
        #else
        if let clipboardText = UIPasteboard.general.string {
            importText = clipboardText
        }
        #endif
    }
    
    private func importData() {
        guard !importText.isEmpty else { return }
        
        print("🔄 Import button tapped")
        print("🔄 Import text: \(importText.prefix(100))...")
        
        // Import the data using the migrator
        let success = migrator.importMigratedData(importText)
        
        if success {
            // Show restart alert
            showRestartAlert = true
        } else {
            // Show error message
            migrator.migrationStatus = .failed("Failed to import data. Please check the export code and try again.")
        }
    }
}

#Preview {
    DataTransferView()
}