//
//  DataExportView.swift
//  KetoMacroTracker
//
//  Created by Oz Hardoon on 1/11/25.
//

import SwiftUI

struct DataExportView: View {
    @StateObject private var migrator = CrossAppDataMigrator()
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    private let exportManager = DataExportManager.shared
    @State private var exportCode = ""
    @State private var showingShareSheet = false
    @State private var showingCopyAlert = false
    @State private var selectedExportType: ExportType = .dailySummary
    @State private var exportDays: Int = 30
    @State private var csvData: String = ""
    
    enum ExportType {
        case dailySummary
        case foodLog
        case fastingHistory
        case allData
        case migrationCode
    }
    
    @Environment(\.dismiss) var dismiss
    
    private var isPremium: Bool {
        subscriptionManager.isPremiumActive
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 60))
                        .foregroundColor(AppColors.primary)
                    
                    Text("Export Your Data")
                        .font(AppTypography.largeTitle)
                        .foregroundColor(AppColors.text)
                    
                    Text("Generate a code to transfer your data to the new app version.")
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                
                // Current Data Summary
                VStack(alignment: .leading, spacing: 12) {
                    Text("Your Data:")
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
                
                // Export Type Selector
                VStack(alignment: .leading, spacing: 12) {
                    Text("Export Type")
                        .font(AppTypography.title3)
                        .foregroundColor(AppColors.text)
                    
                    Picker("Export Type", selection: $selectedExportType) {
                        Text("Daily Summary (CSV)").tag(ExportType.dailySummary)
                        Text("Food Log (CSV)").tag(ExportType.foodLog)
                        Text("Fasting History (CSV)").tag(ExportType.fastingHistory)
                        Text("All Data (CSV)").tag(ExportType.allData)
                        Text("Migration Code").tag(ExportType.migrationCode)
                    }
                    .pickerStyle(MenuPickerStyle())
                    .onChange(of: selectedExportType) {
                        csvData = ""
                    }
                    
                    if selectedExportType != .migrationCode && selectedExportType != .allData {
                        Stepper("Days: \(exportDays)", value: $exportDays, in: 7...365, step: 7)
                            .font(AppTypography.body)
                    }
                }
                .padding(.horizontal, 32)
                
                // Export Section
                VStack(spacing: 16) {
                    Button(action: {
                        generateExport()
                    }) {
                        HStack {
                            Image(systemName: selectedExportType == .migrationCode ? "arrow.clockwise" : "doc.text")
                            Text(selectedExportType == .migrationCode ? "Generate Export Code" : "Generate CSV Export")
                        }
                        .font(AppTypography.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(AppColors.primary)
                        .cornerRadius(12)
                    }
                    
                    if !exportCode.isEmpty || !csvData.isEmpty {
                        VStack(spacing: 12) {
                            Text(selectedExportType == .migrationCode ? "Export Code Generated!" : "CSV Export Generated!")
                                .font(AppTypography.title3)
                                .foregroundColor(AppColors.text)
                            
                            Text(selectedExportType == .migrationCode ? 
                                 "Copy this code and paste it into your new app:" :
                                 "Share or save this CSV file:")
                                .font(AppTypography.body)
                                .foregroundColor(AppColors.secondaryText)
                                .multilineTextAlignment(.center)
                            
                            ScrollView {
                                Text(selectedExportType == .migrationCode ? exportCode : csvData)
                                    .font(.system(.caption, design: selectedExportType == .migrationCode ? .monospaced : .default))
                                    .foregroundColor(AppColors.text)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(12)
                            }
                            .frame(height: 200)
                            .background(AppColors.secondaryBackground)
                            .cornerRadius(8)
                            
                            HStack(spacing: 16) {
                                if selectedExportType == .migrationCode {
                                    Button(action: {
                                        copyToClipboard()
                                    }) {
                                        HStack {
                                            Image(systemName: "doc.on.doc")
                                            Text("Copy Code")
                                        }
                                        .font(AppTypography.headline)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 44)
                                        .background(AppColors.primary)
                                        .cornerRadius(8)
                                    }
                                }
                                
                                Button(action: {
                                    showingShareSheet = true
                                }) {
                                    HStack {
                                        Image(systemName: "square.and.arrow.up")
                                        Text(selectedExportType == .migrationCode ? "Share" : "Share CSV")
                                    }
                                    .font(AppTypography.headline)
                                    .foregroundColor(selectedExportType == .migrationCode ? AppColors.primary : .white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 44)
                                    .background(selectedExportType == .migrationCode ? AppColors.primary.opacity(0.1) : AppColors.primary)
                                    .cornerRadius(8)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 32)
                
                Spacer(minLength: 50)
                }
                .padding(.top, 32)
                .padding(.bottom, 50)
            }
            .background(AppColors.background)
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("Export Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                let shareItems: [Any] = selectedExportType == .migrationCode ? 
                    [exportCode] : 
                    [csvData]
                ShareSheet(items: shareItems)
            }
            .alert("Copied to Clipboard", isPresented: $showingCopyAlert) {
                Button("OK") { }
            } message: {
                Text("The export code has been copied to your clipboard. You can now paste it into your new app.")
            }
        }
    }
    
    private func generateExport() {
        switch selectedExportType {
        case .dailySummary:
            csvData = exportManager.exportDailyData(days: exportDays)
            exportCode = ""
        case .foodLog:
            csvData = exportManager.exportFoodLog(days: exportDays)
            exportCode = ""
        case .fastingHistory:
            csvData = exportManager.exportFastingHistory()
            exportCode = ""
        case .allData:
            csvData = exportManager.exportAllData()
            exportCode = ""
        case .migrationCode:
            if let code = migrator.exportDataForMigration() {
                exportCode = code
            } else {
                exportCode = "No data found to export."
            }
            csvData = ""
        }
    }
    
    private func copyToClipboard() {
        UIPasteboard.general.string = exportCode
        showingCopyAlert = true
    }
}

// Share sheet for iOS
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        // For iPad - set popover source
        if let popover = controller.popoverPresentationController {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                popover.sourceView = window
                popover.sourceRect = CGRect(x: window.bounds.midX, y: window.bounds.midY, width: 0, height: 0)
                popover.permittedArrowDirections = []
            }
        }
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    DataExportView()
        .environmentObject(SubscriptionManager.shared)
}
