//
//  BarcodeHistoryView.swift
//  Keto Macro Tracker
//
//  View for displaying barcode scan history
//

import SwiftUI

struct BarcodeHistoryView: View {
    @ObservedObject var barcodeHistoryManager: BarcodeHistoryManager
    @Environment(\.dismiss) var dismiss
    
    let onFoodSelected: (USDAFood) -> Void
    
    @State private var searchText = ""
    
    private var filteredHistory: [BarcodeHistoryItem] {
        if searchText.isEmpty {
            return barcodeHistoryManager.history
        } else {
            return barcodeHistoryManager.history.filter {
                $0.foodName.localizedCaseInsensitiveContains(searchText) ||
                $0.barcode.contains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(AppColors.secondaryText)
                    
                    TextField("Search history...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                }
                .padding()
                .background(AppColors.secondaryBackground)
                .cornerRadius(10)
                .padding()
                
                // History list
                if filteredHistory.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "barcode.viewfinder")
                            .font(.system(size: 48))
                            .foregroundColor(AppColors.secondaryText)
                        
                        Text(searchText.isEmpty ? "No Barcode History" : "No Results")
                            .font(AppTypography.title3)
                            .foregroundColor(AppColors.text)
                        
                        Text(searchText.isEmpty ? 
                             "Scan barcodes to see them here" :
                             "Try a different search term")
                            .font(AppTypography.body)
                            .foregroundColor(AppColors.secondaryText)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                } else {
                    List(filteredHistory) { item in
                        Button(action: {
                            onFoodSelected(item.food)
                            dismiss()
                        }) {
                            BarcodeHistoryRow(item: item)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            .navigationTitle("Barcode History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if !barcodeHistoryManager.history.isEmpty {
                        Button("Clear") {
                            barcodeHistoryManager.clearHistory()
                        }
                        .foregroundColor(.red)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct BarcodeHistoryRow: View {
    let item: BarcodeHistoryItem
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "barcode")
                .foregroundColor(AppColors.primary)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.foodName)
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.text)
                
                HStack {
                    Text(item.barcode)
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.secondaryText)
                    
                    Text("•")
                        .foregroundColor(AppColors.secondaryText)
                    
                    Text(formatDate(item.dateScanned))
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.secondaryText)
                }
            }
            
            Spacer()
            
            HStack(spacing: 8) {
                nutritionBadge("C", value: String(format: "%.1f", item.food.netCarbs), color: AppColors.carbs)
                nutritionBadge("P", value: String(format: "%.1f", item.food.protein), color: AppColors.protein)
            }
        }
        .padding(.vertical, 8)
    }
    
    private func nutritionBadge(_ label: String, value: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundColor(AppColors.secondaryText)
            
            Text(value)
                .font(.caption2)
                .foregroundColor(color)
                .fontWeight(.semibold)
        }
        .frame(minWidth: 24)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        if Calendar.current.isDateInToday(date) {
            formatter.timeStyle = .short
            return formatter.string(from: date)
        } else if Calendar.current.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            formatter.dateStyle = .short
            return formatter.string(from: date)
        }
    }
}

#Preview {
    BarcodeHistoryView(
        barcodeHistoryManager: BarcodeHistoryManager.shared,
        onFoodSelected: { _ in }
    )
}

