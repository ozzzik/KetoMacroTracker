import SwiftUI
import StoreKit

struct SubscriptionView: View {
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedProduct: Product?
    @State private var showingPurchaseAlert = false
    @State private var purchaseMessage = ""
    
    /// Dynamic message based on subscription status
    private var subscriptionMessage: String {
        switch subscriptionManager.subscriptionStatus {
        case .notSubscribed:
            if subscriptionManager.hasUsedFreeTrial {
                return "Subscribe to unlock all premium features for tracking your keto macros."
            } else {
                return "Start your free trial and unlock all premium features for tracking your keto macros."
            }
        case .expired:
            return "Your subscription has ended. Subscribe to continue enjoying premium features."
        case .inGracePeriod:
            return "Your subscription is in grace period. Subscribe to continue enjoying premium features."
        case .subscribed:
            return "You're already subscribed! Thank you for supporting the app."
        }
    }
    
    /// Dynamic button text based on subscription status
    private var buttonText: String {
        switch subscriptionManager.subscriptionStatus {
        case .notSubscribed:
            // If they've used a trial, show "Subscribe" instead of "Start Free Trial"
            return subscriptionManager.hasUsedFreeTrial ? "Subscribe Now" : "Start Free Trial"
        case .expired:
            return "Renew Subscription"
        case .inGracePeriod:
            return "Renew Subscription"
        case .subscribed:
            return "Manage Subscription"
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Scrollable content
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 16) {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 60))
                                .foregroundColor(AppColors.accent)
                            
                            Text("Unlock Premium Features")
                                .font(AppTypography.title)
                                .fontWeight(.bold)
                                .multilineTextAlignment(.center)
                            
                            Text(subscriptionMessage)
                                .font(AppTypography.body)
                                .foregroundColor(AppColors.secondaryText)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .padding(.top, 20)
                        .padding(.bottom, 20)
                        
                        // Subscription Options
                        VStack(spacing: 16) {
                            // Yearly Option (Recommended)
                            if let yearlyProduct = subscriptionManager.yearlyProduct {
                                SubscriptionOptionView(
                                    product: yearlyProduct,
                                    isRecommended: true,
                                    isSelected: selectedProduct?.id == yearlyProduct.id,
                                    savingsText: subscriptionManager.yearlySavings
                                ) {
                                    selectedProduct = yearlyProduct
                                }
                            }
                            
                            // Monthly Option
                            if let monthlyProduct = subscriptionManager.monthlyProduct {
                                SubscriptionOptionView(
                                    product: monthlyProduct,
                                    isRecommended: false,
                                    isSelected: selectedProduct?.id == monthlyProduct.id,
                                    savingsText: nil
                                ) {
                                    selectedProduct = monthlyProduct
                                }
                            }
                        }
                        .padding(.horizontal, max(20, geometry.size.width * 0.1))
                    }
                }
                
                // Fixed bottom section for pricing and CTA
                VStack(spacing: 16) {
                    Divider()
                    
                    Button(action: purchaseSubscription) {
                        HStack {
                            if subscriptionManager.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Text(buttonText)
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            LinearGradient(
                                colors: [AppColors.primary, AppColors.accent],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(.white)
                        .cornerRadius(AppCornerRadius.medium)
                    }
                    .disabled(subscriptionManager.isLoading || (selectedProduct == nil && subscriptionManager.products.isEmpty))
                    .padding(.horizontal, max(20, geometry.size.width * 0.1))
                    
                    // Restore Purchases
                    Button("Restore Purchases") {
                        Task {
                            await subscriptionManager.restorePurchases()
                        }
                    }
                    .font(AppTypography.subheadline)
                    .foregroundColor(AppColors.primary)
                    .disabled(subscriptionManager.isLoading)
                    
                    // Terms and Privacy Policy Links
                    VStack(spacing: 8) {
                        HStack(spacing: 16) {
                            Link("Privacy Policy", destination: URL(string: "https://www.apple.com/legal/privacy/")!)
                                .font(AppTypography.caption)
                                .foregroundColor(AppColors.primary)
                            
                            Text("•")
                                .font(AppTypography.caption)
                                .foregroundColor(AppColors.secondaryText)
                            
                            Link("Terms of Use", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                                .font(AppTypography.caption)
                                .foregroundColor(AppColors.primary)
                        }
                        
                        if !subscriptionManager.hasUsedFreeTrial {
                            Text("Start your free trial. Cancel anytime during the trial and you'll keep access until the trial ends. No charge will occur.")
                                .font(AppTypography.caption)
                                .foregroundColor(AppColors.secondaryText)
                                .multilineTextAlignment(.center)
                        } else if subscriptionManager.subscriptionStatus == .expired {
                            Text("Your subscription has ended. Subscribe to continue enjoying premium features.")
                                .font(AppTypography.caption)
                                .foregroundColor(AppColors.secondaryText)
                                .multilineTextAlignment(.center)
                        }
                        
                        Text("Subscription automatically renews unless auto-renew is turned off at least 24 hours before the end of the current period.")
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.secondaryText)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, max(20, geometry.size.width * 0.1))
                    .padding(.bottom, 20)
                }
                .background(AppColors.background)
            }
            .background(AppColors.background)
            .task {
                print("🔄 Loading subscription products...")
                await subscriptionManager.loadProducts()
                
                // Auto-select yearly product if available
                if let yearlyProduct = subscriptionManager.yearlyProduct {
                    print("✅ Auto-selected yearly product: \(yearlyProduct.id)")
                    selectedProduct = yearlyProduct
                } else if let monthlyProduct = subscriptionManager.monthlyProduct {
                    print("✅ Auto-selected monthly product: \(monthlyProduct.id)")
                    selectedProduct = monthlyProduct
                } else {
                    print("⚠️ No products available for selection")
                }
            }
            .alert("Purchase Result", isPresented: $showingPurchaseAlert) {
                Button("OK") { }
            } message: {
                Text(purchaseMessage)
            }
        }
    }
    
    private func purchaseSubscription() {
        print("🛒 purchaseSubscription() called")
        print("  - selectedProduct: \(selectedProduct?.id ?? "nil")")
        print("  - isLoading: \(subscriptionManager.isLoading)")
        print("  - Available products: \(subscriptionManager.products.count)")
        
        // Check if products are loaded
        if subscriptionManager.products.isEmpty {
            print("⚠️ No products available, loading...")
            purchaseMessage = "Loading subscription options... Please try again in a moment."
            showingPurchaseAlert = true
            
            // Try to load products
            Task {
                await subscriptionManager.loadProducts()
                if let yearlyProduct = subscriptionManager.yearlyProduct {
                    selectedProduct = yearlyProduct
                } else if let monthlyProduct = subscriptionManager.monthlyProduct {
                    selectedProduct = monthlyProduct
                }
            }
            return
        }
        
        guard let product = selectedProduct else { 
            print("⚠️ No product selected")
            purchaseMessage = "Please select a subscription option"
            showingPurchaseAlert = true
            return 
        }
        
        // Check if already loading
        guard !subscriptionManager.isLoading else {
            print("⚠️ Purchase already in progress")
            purchaseMessage = "Purchase already in progress. Please wait..."
            showingPurchaseAlert = true
            return
        }
        
        print("🛒 Starting purchase for product: \(product.id)")
        Task {
            do {
                try await subscriptionManager.purchase(product)
                
                // Wait a moment for subscription status to update
                try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                
                // Only show success if subscription is actually active
                if subscriptionManager.isPremiumActive {
                    print("✅ Purchase completed successfully")
                    purchaseMessage = "Subscription activated successfully!"
                    showingPurchaseAlert = true
                    
                    // Wait a bit more then dismiss
                    try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 more second
                    dismiss()
                } else {
                    // Purchase completed but subscription not active (likely cancelled)
                    print("⚠️ Purchase completed but subscription not active (user may have cancelled)")
                    // Don't show any message for cancellation
                }
            } catch {
                // Check if it's a StoreKit user cancellation error
                if let storeKitError = error as? StoreKitError {
                    if case .userCancelled = storeKitError {
                        print("⚠️ User cancelled purchase - no message shown")
                        return // Silently handle cancellation
                    }
                }
                
                let errorMessage = error.localizedDescription
                print("❌ Purchase error: \(errorMessage)")
                
                // Don't show error for user cancellation
                if !errorMessage.lowercased().contains("cancelled") {
                    purchaseMessage = "Purchase failed: \(errorMessage)"
                    showingPurchaseAlert = true
                }
            }
        }
    }
}

struct SubscriptionOptionView: View {
    let product: Product
    let isRecommended: Bool
    let isSelected: Bool
    let savingsText: String?
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(product.displayName)
                                .font(AppTypography.headline)
                                .fontWeight(.semibold)
                            
                            if isRecommended {
                                Text("BEST VALUE")
                                    .font(AppTypography.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(AppColors.accent)
                                    .cornerRadius(4)
                            }
                        }
                        
                        Text(formatPrice(product.price))
                            .font(AppTypography.title2)
                            .fontWeight(.bold)
                            .foregroundColor(AppColors.text)
                        
                        if let savingsText = savingsText {
                            Text("Save \(savingsText)")
                                .font(AppTypography.caption)
                                .foregroundColor(AppColors.success)
                                .fontWeight(.medium)
                        }
                    }
                    
                    Spacer()
                    
                    // Selection indicator
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundColor(isSelected ? AppColors.primary : AppColors.secondaryText)
                }
                .padding(16)
            }
            .background(
                RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                    .fill(AppColors.secondaryBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                            .stroke(isSelected ? AppColors.primary : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func formatPrice(_ price: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        
        if product.id.contains("yearly") {
            return "\(formatter.string(from: price as NSDecimalNumber) ?? "")/year"
        } else {
            return "\(formatter.string(from: price as NSDecimalNumber) ?? "")/month"
        }
    }
}

#Preview {
    SubscriptionView()
        .environmentObject(SubscriptionManager.shared)
}
