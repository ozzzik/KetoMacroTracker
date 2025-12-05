//
//  APIUsageStatsView.swift
//  Keto Macro Tracker
//
//  View to display API usage statistics
//

import SwiftUI

struct APIUsageStatsView: View {
    @StateObject private var usageTracker = APIUsageTracker.shared
    @State private var stats: APIUsageStats?
    @State private var showingExport = false
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    if let stats = stats {
                        // Summary Card
                        AppCard {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Usage Summary (Last 24 Hours)")
                                    .font(AppTypography.title3)
                                    .foregroundColor(AppColors.text)
                                
                                VStack(spacing: 12) {
                                    APIUsageStatRow(
                                        label: "USDA Requests",
                                        value: "\(stats.totalUSDARequests)",
                                        color: .blue
                                    )
                                    
                                    APIUsageStatRow(
                                        label: "Successful",
                                        value: "\(stats.successfulUSDARequests)",
                                        color: .green
                                    )
                                    
                                    APIUsageStatRow(
                                        label: "Failed",
                                        value: "\(stats.failedUSDARequests)",
                                        color: .red
                                    )
                                    
                                    APIUsageStatRow(
                                        label: "Success Rate",
                                        value: "\(String(format: "%.1f", stats.successRate * 100))%",
                                        color: stats.successRate > 0.9 ? .green : stats.successRate > 0.7 ? .orange : .red
                                    )
                                    
                                    Divider()
                                    
                                    APIUsageStatRow(
                                        label: "Rate Limit Events",
                                        value: "\(stats.rateLimitEvents)",
                                        color: stats.rateLimitEvents > 0 ? .red : .green
                                    )
                                    
                                    APIUsageStatRow(
                                        label: "OpenFoodFacts Requests",
                                        value: "\(stats.totalOpenFoodFactsRequests)",
                                        color: .purple
                                    )
                                    
                                    if let avgTime = stats.averageResponseTime {
                                        APIUsageStatRow(
                                            label: "Avg Response Time",
                                            value: String(format: "%.2fs", avgTime),
                                            color: .gray
                                        )
                                    }
                                }
                            }
                        }
                        
                        // Rate Limit Warning
                        if stats.rateLimitEvents > 0 {
                            AppCard {
                                HStack(spacing: 12) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(.orange)
                                        .font(.title2)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Rate Limit Reached")
                                            .font(AppTypography.headline)
                                            .foregroundColor(AppColors.text)
                                        
                                        Text("The USDA API rate limit (1000 requests/hour) was reached \(stats.rateLimitEvents) time(s). The app automatically fell back to OpenFoodFacts.")
                                            .font(AppTypography.caption)
                                            .foregroundColor(AppColors.secondaryText)
                                    }
                                }
                            }
                        }
                        
                        // Export Button
                        Button(action: {
                            showingExport = true
                        }) {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                Text("Export Usage Data")
                            }
                            .font(AppTypography.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(AppColors.primary)
                            .cornerRadius(12)
                        }
                        .sheet(isPresented: $showingExport) {
                            APIUsageShareSheet(activityItems: [usageTracker.exportUsageData()])
                        }
                    } else {
                        Text("No usage data available")
                            .foregroundColor(AppColors.secondaryText)
                            .padding()
                    }
                }
                .padding()
            }
            .navigationTitle("API Usage Statistics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadStats()
            }
        }
    }
    
    private func loadStats() {
        stats = usageTracker.getUsageStats()
    }
}

struct APIUsageStatRow: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Text(label)
                .font(AppTypography.body)
                .foregroundColor(AppColors.text)
            
            Spacer()
            
            Text(value)
                .font(AppTypography.headline)
                .foregroundColor(color)
        }
    }
}

struct APIUsageShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

