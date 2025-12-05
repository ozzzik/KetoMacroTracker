//
//  SubscriptionView.swift
//  Keto Macro Tracker
//
//  Created by Oz Hardoon on 9/27/25.
//

import SwiftUI
import StoreKit

struct SubscriptionView: View {
    @Environment(\.dismiss) var dismiss
    @State private var isLoading = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ScrollView {
                    VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.yellow)
                        
                        Text("KetoMacroTracker Premium")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(AppColors.text)
                            .multilineTextAlignment(.center)
                        
                        Text("Unlock advanced features and take your keto journey to the next level")
                            .font(.body)
                            .foregroundColor(AppColors.secondaryText)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    
                    // Features List
                    VStack(spacing: 20) {
                        FeatureRow(
                            icon: "infinity",
                            title: "Unlimited Food Logging",
                            description: "Log unlimited foods without restrictions"
                        )
                        
                        FeatureRow(
                            icon: "chart.line.uptrend.xyaxis",
                            title: "Advanced Analytics",
                            description: "Detailed insights and progress tracking"
                        )
                        
                        FeatureRow(
                            icon: "square.and.arrow.down",
                            title: "Export & Backup",
                            description: "Export your data and create backups"
                        )
                        
                        FeatureRow(
                            icon: "person.2.fill",
                            title: "Multiple Profiles",
                            description: "Track multiple family members"
                        )
                        
                        FeatureRow(
                            icon: "bell.fill",
                            title: "Smart Reminders",
                            description: "Custom reminders for meals and hydration"
                        )
                        
                        FeatureRow(
                            icon: "heart.fill",
                            title: "Priority Support",
                            description: "Get help when you need it most"
                        )
                    }
                    .padding(.horizontal)
                    
                    // Pricing
                    VStack(spacing: 16) {
                        Text("Choose Your Plan")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(AppColors.text)
                        
                        VStack(spacing: 12) {
                            SubscriptionOptionView(
                                title: "Monthly",
                                price: "$4.99",
                                period: "per month",
                                isPopular: false
                            )
                            
                            SubscriptionOptionView(
                                title: "Yearly",
                                price: "$29.99",
                                period: "per year",
                                originalPrice: "$59.88",
                                isPopular: true
                            )
                        }
                    }
                    .padding(.horizontal)
                    
                    // Purchase Button
                    Button(action: {
                        purchaseSubscription()
                    }) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "crown.fill")
                            }
                            Text(isLoading ? "Processing..." : "Start Premium Trial")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [AppColors.primary, AppColors.accent],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .shadow(color: AppColors.primary.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .disabled(isLoading)
                    .accessibilityLabel("Start Premium Trial")
                    .accessibilityHint("Tap to begin your premium subscription trial")
                    .padding(.horizontal)
                    
                    // Restore Purchases
                    Button("Restore Purchases") {
                        restorePurchases()
                    }
                    .foregroundColor(AppColors.primary)
                    .accessibilityLabel("Restore Purchases")
                    .accessibilityHint("Tap to restore any previous premium purchases")
                    .padding(.bottom)
                    
                    // Terms and Privacy
                    VStack(spacing: 8) {
                        Text("By subscribing, you agree to our Terms of Service and Privacy Policy")
                            .font(.caption)
                            .foregroundColor(AppColors.secondaryText)
                            .multilineTextAlignment(.center)
                        
                        HStack(spacing: 20) {
                            Button("Terms of Service") {
                                // Open terms
                            }
                            .font(.caption)
                            .foregroundColor(AppColors.primary)
                            
                            Button("Privacy Policy") {
                                // Open privacy policy
                            }
                            .font(.caption)
                            .foregroundColor(AppColors.primary)
                        }
                    }
                    .padding(.horizontal)
                    
                        Spacer(minLength: 32)
                    }
                    .padding(.horizontal, geometry.size.width > 768 ? 32 : 16)
                    .padding(.top, 20)
                }
                .background(AppColors.background)
            }
            .navigationTitle("Premium")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func purchaseSubscription() {
        isLoading = true
        
        // Simulate purchase process
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            isLoading = false
            // In a real app, this would handle StoreKit purchases
            dismiss()
        }
    }
    
    private func restorePurchases() {
        isLoading = true
        
        // Simulate restore process
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isLoading = false
            // In a real app, this would restore StoreKit purchases
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(AppColors.primary)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(AppColors.text)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(AppColors.secondaryText)
            }
            
            Spacer()
        }
        .padding(.horizontal)
    }
}

struct SubscriptionOptionView: View {
    let title: String
    let price: String
    let period: String
    let originalPrice: String?
    let isPopular: Bool
    
    init(title: String, price: String, period: String, originalPrice: String? = nil, isPopular: Bool = false) {
        self.title = title
        self.price = price
        self.period = period
        self.originalPrice = originalPrice
        self.isPopular = isPopular
    }
    
    var body: some View {
        VStack(spacing: 8) {
            if isPopular {
                Text("MOST POPULAR")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(AppColors.primary)
                    .cornerRadius(8)
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(AppColors.text)
                    
                    HStack(alignment: .bottom, spacing: 4) {
                        Text(price)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(AppColors.text)
                        
                        Text(period)
                            .font(.caption)
                            .foregroundColor(AppColors.secondaryText)
                    }
                    
                    if let originalPrice = originalPrice {
                        Text(originalPrice)
                            .font(.caption)
                            .strikethrough()
                            .foregroundColor(AppColors.secondaryText)
                    }
                }
                
                Spacer()
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(isPopular ? AppColors.primary : AppColors.secondaryText)
            }
        }
        .padding()
        .background(AppColors.secondaryBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isPopular ? AppColors.primary : Color.clear, lineWidth: 2)
        )
    }
}

#Preview {
    SubscriptionView()
}
