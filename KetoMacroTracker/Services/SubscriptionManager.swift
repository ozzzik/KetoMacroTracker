//
//  SubscriptionManager.swift
//  KetoMacroTracker
//
//  Ads-only build: no subscriptions. All features unlocked; ads shown via AdManager.
//

import Foundation
import SwiftUI

/// Stub for ads-only build. Always reports premium; no StoreKit.
@MainActor
class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()

    @Published var products: [SubscriptionProductStub] = []
    @Published var subscriptionStatus: SubscriptionStatus = .subscribed
    @Published var currentSubscription: SubscriptionProductStub?
    @Published var expirationDate: Date? = Date.distantFuture
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var receiptData: ReceiptData?
    @Published var hasCheckedSubscriptionStatus = true
    @Published var hasUsedFreeTrial = true

    var isPremiumActive: Bool { true }

    init() {}

    func loadProducts() async {}
    func updateSubscriptionStatus() async {}
    func restorePurchases() async {}
    func purchase(_ product: SubscriptionProductStub) async throws {}
    func isFreeTrialAvailable(for product: SubscriptionProductStub) -> Bool { false }
    func checkIfUserHasUsedTrial() async {}

    var monthlyProduct: SubscriptionProductStub? { nil }
    var yearlyProduct: SubscriptionProductStub? { nil }
    var yearlySavings: String { "" }
}

/// Stub type so views that expect a "product" still compile. Not used when subscriptions are removed.
struct SubscriptionProductStub: Identifiable {
    let id: String
    let displayName: String
    let displayPrice: String
}

struct ReceiptData {
    let isInBillingRetryPeriod: Bool
    let isTrialPeriod: Bool
    let expiresDate: Date?
    let productId: String?
    let originalTransactionId: String?
    let rawReceipt: String
}

enum SubscriptionStatus {
    case notSubscribed
    case subscribed
    case expired
    case inGracePeriod

    var displayText: String {
        switch self {
        case .notSubscribed: return "Not Subscribed"
        case .subscribed: return "Premium Active"
        case .expired: return "Subscription Expired"
        case .inGracePeriod: return "Grace Period"
        }
    }
}
