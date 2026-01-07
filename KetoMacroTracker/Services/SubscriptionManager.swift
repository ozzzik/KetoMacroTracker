import Foundation
import StoreKit
import SwiftUI
import UIKit

/// Receipt data structure for debugging subscription issues
struct ReceiptData {
    let isInBillingRetryPeriod: Bool
    let isTrialPeriod: Bool
    let expiresDate: Date?
    let productId: String?
    let originalTransactionId: String?
    let rawReceipt: String
}

/// Clean SubscriptionManager built on StoreKit2 best practices
/// Based on: StoreHelper (Russell Archer) & StoreKit2 Demo (Aisultan)
@MainActor
class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()
    
    // MARK: - Product Configuration
    
    /// Product IDs for subscriptions
    private let productIds: Set<String> = [
        "com.ketomacrotracker.monthly",
        "com.ketomacrotracker.yearly"
    ]
    
    // MARK: - Published State
    
    /// Available subscription products from App Store
    @Published var products: [Product] = []
    
    /// Current subscription status
    @Published var subscriptionStatus: SubscriptionStatus = .notSubscribed
    
    /// Currently active subscription product
    @Published var currentSubscription: Product?
    
    /// Subscription expiration date (if active)
    @Published var expirationDate: Date?
    
    /// Loading state for purchases and restores
    @Published var isLoading = false
    
    /// Error message for user display
    @Published var errorMessage: String?
    
    /// Receipt verification data for debugging
    @Published var receiptData: ReceiptData?
    
    /// Whether subscription status has been checked at least once
    @Published var hasCheckedSubscriptionStatus = false
    
    // MARK: - Private State
    
    /// Task for listening to transaction updates
    private var updateListenerTask: Task<Void, Never>?
    
    // MARK: - Initialization
    
    init() {
        print("🔧 SubscriptionManager initialized")
        // Start listening for transaction updates immediately
        updateListenerTask = listenForTransactions()
        
        // Load products and check subscription status
        Task { @MainActor in
            print("🔧 Starting product load in init...")
            await loadProducts()
            await updateSubscriptionStatus()
        }
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    // MARK: - Product Loading
    
    /// Load products from App Store
    func loadProducts() async {
        print("📦 Loading products...")
        print("📦 Product IDs to load: \(Array(productIds))")
        print("📦 Current thread: \(Thread.isMainThread ? "Main" : "Background")")
        
        // Diagnostic: Check if running on simulator
        #if targetEnvironment(simulator)
        print("📱 Running on Simulator - StoreKit config should work")
        #else
        print("📱 Running on Device - StoreKit config may not work, need App Store Connect setup")
        #endif
        
        do {
            // Ensure we're on main actor for StoreKit operations
            let loadedProducts = try await Product.products(for: productIds)
            
            print("📦 Raw products loaded: \(loadedProducts.count)")
            
            // Sort by price (monthly first, then yearly)
            await MainActor.run {
                products = loadedProducts.sorted { $0.price < $1.price }
                
                print("✅ Loaded \(products.count) products")
                if products.isEmpty {
                    print("⚠️ WARNING: No products loaded! This might mean:")
                    print("  1. StoreKit Configuration file is not set up in Xcode scheme")
                    print("  2. Product IDs don't match the StoreKit configuration file")
                    print("  3. Running on physical device (StoreKit config only works on simulator)")
                    print("  4. StoreKit configuration file path is incorrect in scheme")
                    print("  5. Configuration file not added to Xcode project")
                    print("")
                    print("🔍 Troubleshooting steps:")
                    print("  - MUST run on Simulator (not physical device) for StoreKit config to work")
                    print("  - Check Xcode scheme: Product → Scheme → Edit Scheme → Run → Options")
                    print("  - Verify StoreKit Configuration dropdown shows: KetoMacroTracker/Configuration.storekit")
                    print("  - Ensure Configuration.storekit appears in Xcode Project Navigator")
                    print("  - Try: Product → Clean Build Folder, then restart Xcode")
                    print("  - Ensure product IDs match: com.ketomacrotracker.monthly, com.ketomacrotracker.yearly")
                }
                for product in products {
                    print("  - \(product.displayName) (\(product.id)): \(product.displayPrice)")
                }
            }
        } catch {
            print("❌ Failed to load products: \(error)")
            print("❌ Error type: \(type(of: error))")
            print("❌ Error description: \(error.localizedDescription)")
            
            if let storeKitError = error as? StoreKitError {
                print("❌ StoreKit error code: \(storeKitError)")
                print("❌ StoreKit error details: \(String(describing: storeKitError))")
            }
            
            await MainActor.run {
                errorMessage = "Failed to load subscription options. Please check your StoreKit configuration or try again."
            }
        }
    }
    
    // MARK: - Purchase
    
    /// Purchase a subscription product
    func purchase(_ product: Product) async throws {
        print("💳 Starting purchase for: \(product.displayName) (ID: \(product.id))")
        print("💳 Product type: \(product.type)")
        print("💳 Product price: \(product.displayPrice)")
        print("💳 iOS version: \(UIDevice.current.systemVersion)")
        
        // Check if we're in a supported environment
        guard product.type == .autoRenewable else {
            throw StoreError.failedVerification
        }
        
        isLoading = true
        errorMessage = nil
        
        defer { 
            isLoading = false
            print("💳 Purchase process completed")
        }
        
        do {
            print("💳 Calling product.purchase()...")
            let result = try await product.purchase()
            print("💳 Purchase result received: \(result)")
            
            switch result {
            case .success(let verification):
                print("✅ Purchase successful, verifying...")
                let transaction = try checkVerified(verification)
                print("✅ Transaction verified: \(transaction.id)")
                
                // Update subscription status
                await updateSubscriptionStatus()
                
                // Finish the transaction
                await transaction.finish()
                print("✅ Transaction finished: \(transaction.id)")
                
            case .userCancelled:
                print("⚠️ User cancelled purchase")
                // Don't update subscription status when user cancels
                return
                
            case .pending:
                print("⏳ Purchase pending approval")
                errorMessage = "Purchase is pending approval"
                
            @unknown default:
                print("⚠️ Unknown purchase result")
                errorMessage = "Unknown purchase result"
            }
        } catch {
            print("❌ Purchase failed with error: \(error)")
            print("❌ Error type: \(type(of: error))")
            print("❌ Error description: \(error.localizedDescription)")
            
            // Handle specific error types
            let userFriendlyMessage: String
            if let storeKitError = error as? StoreKitError {
                switch storeKitError {
                case .networkError:
                    userFriendlyMessage = "Network connection failed. Please check your internet connection and try again."
                case .userCancelled:
                    userFriendlyMessage = "Purchase was cancelled."
                    return // Don't show error for user cancellation
                case .systemError:
                    userFriendlyMessage = "System error occurred. Please try again."
                default:
                    userFriendlyMessage = "Purchase failed: \(error.localizedDescription)"
                }
            } else {
                userFriendlyMessage = "Purchase failed: \(error.localizedDescription)"
            }
            
            errorMessage = userFriendlyMessage
            throw error
        }
    }
    
    // MARK: - Transaction Listener
    
    /// Listen for transaction updates from the App Store
    private func listenForTransactions() -> Task<Void, Never> {
        return Task.detached { [weak self] in
            print("👂 Starting transaction listener...")
            
            for await result in Transaction.updates {
                do {
                    let transaction = try await self?.checkVerified(result)
                    
                    if let transaction = transaction {
                        print("🔔 Transaction update: \(transaction.id)")
                        
                        // Update subscription status on main actor
                        await self?.updateSubscriptionStatus()
                        
                        // Finish the transaction
                        await transaction.finish()
                    }
                } catch {
                    print("❌ Transaction verification failed: \(error)")
                }
            }
        }
    }
    
    // MARK: - Subscription Status
    
    /// Check and update current subscription status
    func updateSubscriptionStatus() async {
        print("🔄 Updating subscription status...")
        
        var activeSubscription: Product?
        var latestExpiration: Date?
        var status: SubscriptionStatus = .notSubscribed
        
        // Check current entitlements
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                
                print("🔍 Checking transaction: \(transaction.productID)")
                
                // Check if this is one of our subscription products
                if productIds.contains(transaction.productID) {
                    print("✅ Found active entitlement: \(transaction.productID)")
                    
                    // Find the matching product (or load it if not in products array)
                    var product: Product?
                    if let existingProduct = products.first(where: { $0.id == transaction.productID }) {
                        product = existingProduct
                    } else {
                        // Product not loaded yet, try to load it
                        print("⚠️ Product \(transaction.productID) not in products array, loading...")
                        do {
                            let loadedProducts = try await Product.products(for: [transaction.productID])
                            if let loadedProduct = loadedProducts.first {
                                product = loadedProduct
                                await MainActor.run {
                                    if !products.contains(where: { $0.id == loadedProduct.id }) {
                                        products.append(loadedProduct)
                                        products.sort { $0.price < $1.price }
                                    }
                                }
                            }
                        } catch {
                            print("❌ Failed to load product \(transaction.productID): \(error)")
                        }
                    }
                    
                    if let product = product {
                        activeSubscription = product
                        latestExpiration = transaction.expirationDate
                        
                        // Determine status based on transaction state
                        if let expiration = transaction.expirationDate {
                            if expiration > Date() {
                                status = .subscribed
                                print("✅ Subscription active until: \(expiration)")
                            } else {
                                status = .expired
                                print("⚠️ Subscription expired: \(expiration)")
                            }
                        } else {
                            // No expiration date means it's a lifetime or non-expiring subscription
                            status = .subscribed
                            print("✅ Subscription active (no expiration)")
                        }
                        
                        // Check for cancellation (will expire but still active)
                        if transaction.revocationDate != nil {
                            status = .expired
                            print("⚠️ Subscription revoked")
                        }
                    }
                }
            } catch {
                print("❌ Failed to verify entitlement: \(error)")
            }
        }
        
        // Update published properties on main actor
        await MainActor.run {
            currentSubscription = activeSubscription
            expirationDate = latestExpiration
            subscriptionStatus = status
            hasCheckedSubscriptionStatus = true
            
            print("📊 Subscription status updated: \(status)")
            if let expiration = latestExpiration {
                print("📅 Expiration date: \(expiration)")
            }
        }
    }
    
    // MARK: - Restore Purchases
    
    /// Restore previous purchases
    func restorePurchases() async {
        print("🔄 Restoring purchases...")
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        defer {
            Task { @MainActor in
                isLoading = false
            }
        }
        
        do {
            // Sync with App Store
            print("🔄 Syncing with App Store...")
            try await AppStore.sync()
            print("✅ App Store sync completed")
            
            // Reload products in case they weren't loaded
            if products.isEmpty {
                print("⚠️ No products loaded, loading products first...")
                await loadProducts()
            }
            
            // Update subscription status
            await updateSubscriptionStatus()
            
            await MainActor.run {
                if subscriptionStatus == .subscribed {
                    print("✅ Purchases restored successfully")
                    errorMessage = nil
                } else {
                    print("ℹ️ No active subscriptions found")
                    errorMessage = "No active subscriptions found. If you have an active subscription, please try again or contact support."
                }
            }
        } catch {
            print("❌ Failed to restore purchases: \(error)")
            await MainActor.run {
                errorMessage = "Failed to restore purchases: \(error.localizedDescription)"
            }
        }
    }
    
    // MARK: - Verification
    
    /// Verify a transaction using StoreKit2 verification
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(let item, let error):
            print("❌ Transaction verification failed for \(item): \(error)")
            print("❌ Verification error details: \(error.localizedDescription)")
            throw StoreError.failedVerification
        case .verified(let safe):
            print("✅ Transaction verified successfully: \(safe)")
            return safe
        }
    }
    
    // MARK: - Helper Properties
    
    /// Check if user has premium access
    var isPremiumActive: Bool {
        // Only return true if we have a valid subscription with future expiration
        if let expiration = expirationDate, expiration > Date() {
            switch subscriptionStatus {
            case .subscribed:
                return true
            case .inGracePeriod:
                return true
            case .notSubscribed, .expired:
                return false
            }
        }
        
        return false
    }
    
    /// Get monthly product
    var monthlyProduct: Product? {
        products.first { $0.id.contains("monthly") }
    }
    
    /// Get yearly product
    var yearlyProduct: Product? {
        products.first { $0.id.contains("yearly") }
    }
    
    /// Calculate yearly savings
    var yearlySavings: String {
        guard let monthly = monthlyProduct,
              let yearly = yearlyProduct else {
            return "Save 17%"
        }
        
        let monthlyCost = monthly.price * 12
        let yearlyCost = yearly.price
        let savings = monthlyCost - yearlyCost
        let savingsPercent = (savings / monthlyCost) * 100
        
        // Convert Decimal to Double for String formatting
        let percentValue = (savingsPercent as NSDecimalNumber).doubleValue
        return String(format: "%.0f%%", percentValue)
    }
    
    // MARK: - Debug Methods (Basic - For Testing Only)
    
    #if DEBUG
    /// Simulate premium activation (debug only)
    func activateSubscription() {
        subscriptionStatus = .subscribed
        expirationDate = Calendar.current.date(byAdding: .year, value: 1, to: Date())
        print("🔄 Premium activated (simulation)")
    }
    
    /// Cancel subscription (debug only - simulates cancellation)
    func cancelSubscription() {
        subscriptionStatus = .notSubscribed
        currentSubscription = nil
        expirationDate = nil
        print("🔄 Subscription cancelled (simulation)")
    }
    #endif
}

// MARK: - Subscription Status

enum SubscriptionStatus {
    case notSubscribed
    case subscribed
    case expired
    case inGracePeriod
    
    var displayText: String {
        switch self {
        case .notSubscribed:
            return "Not Subscribed"
        case .subscribed:
            return "Premium Active"
        case .expired:
            return "Subscription Expired"
        case .inGracePeriod:
            return "Grace Period"
        }
    }
}

// MARK: - Store Error

enum StoreError: Error, LocalizedError {
    case failedVerification
    
    var errorDescription: String? {
        switch self {
        case .failedVerification:
            return "Transaction verification failed"
        }
    }
}


