import SwiftUI

struct PaywallView: View {
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @Environment(\.dismiss) private var dismiss
    @State private var showingSubscription = false
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                VStack(spacing: 0) {
                    // Scrollable content
                    ScrollView {
                        VStack(spacing: 32) {
                            // Header
                            VStack(spacing: 20) {
                                Image(systemName: "crown.fill")
                                    .font(.system(size: 80))
                                    .foregroundColor(AppColors.accent)
                                
                                VStack(spacing: 12) {
                                    Text("Unlock Premium Features")
                                        .font(AppTypography.title)
                                        .fontWeight(.bold)
                                        .multilineTextAlignment(.center)
                                    
                                    Text("Take your keto journey to the next level with advanced tracking and insights")
                                        .font(AppTypography.body)
                                        .foregroundColor(AppColors.secondaryText)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal)
                                }
                            }
                            .padding(.top, 40)
                            .padding(.bottom, 20)
                            
                            // Features List
                            VStack(spacing: 16) {
                                FeatureRowView(
                                    icon: "infinity",
                                    title: "Unlimited Food Logging",
                                    description: "Log unlimited foods without daily restrictions"
                                )
                                
                                FeatureRowView(
                                    icon: "chart.line.uptrend.xyaxis",
                                    title: "Advanced Analytics",
                                    description: "Detailed insights, trends, and progress tracking"
                                )
                                
                                FeatureRowView(
                                    icon: "square.and.arrow.down",
                                    title: "Export & Backup",
                                    description: "Export your data and create secure backups"
                                )
                                
                                FeatureRowView(
                                    icon: "barcode.viewfinder",
                                    title: "Barcode Scanning",
                                    description: "Quickly scan products to find nutrition info"
                                )
                                
                                FeatureRowView(
                                    icon: "heart.fill",
                                    title: "HealthKit Integration",
                                    description: "Sync your nutrition data with Apple Health"
                                )
                                
                                FeatureRowView(
                                    icon: "square.grid.2x2",
                                    title: "Home Screen Widgets",
                                    description: "Track your macros at a glance"
                                )
                                
                                FeatureRowView(
                                    icon: "calendar.badge.clock",
                                    title: "Extended History",
                                    description: "View historical data beyond 30 days"
                                )
                                
                                FeatureRowView(
                                    icon: "book.fill",
                                    title: "Unlimited Custom Meals",
                                    description: "Create and save unlimited meal templates"
                                )
                            }
                            .padding(.horizontal, max(20, geometry.size.width * 0.1))
                        }
                    }
                    
                    // Fixed bottom section with pricing and CTA
                    VStack(spacing: 16) {
                        Divider()
                        
                        VStack(spacing: 16) {
                            VStack(spacing: 8) {
                                if let monthlyProduct = subscriptionManager.monthlyProduct {
                                    Text("Starting at \(monthlyProduct.displayPrice)/month")
                                        .font(AppTypography.title2)
                                        .fontWeight(.bold)
                                } else {
                                    Text("Try Premium Free")
                                        .font(AppTypography.title2)
                                        .fontWeight(.bold)
                                }
                                
                                Text("Cancel anytime. No commitment.")
                                    .font(AppTypography.caption)
                                    .foregroundColor(AppColors.secondaryText)
                            }
                            
                            Button(action: {
                                showingSubscription = true
                            }) {
                                Text("Continue with Premium")
                                    .font(AppTypography.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(
                                        LinearGradient(
                                            colors: [AppColors.primary, AppColors.accent],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .cornerRadius(AppCornerRadius.medium)
                            }
                            .padding(.horizontal, max(20, geometry.size.width * 0.1))
                            
                            // Restore Purchases
                            Button("Restore Purchases") {
                                Task {
                                    await subscriptionManager.restorePurchases()
                                }
                            }
                            .font(AppTypography.subheadline)
                            .foregroundColor(AppColors.primary)
                            
                            // Terms and Privacy Policy Links
                            VStack(spacing: 8) {
                                Text("Cancel anytime. Subscription automatically renews unless auto-renew is turned off at least 24 hours before the end of the current period.")
                                    .font(AppTypography.caption)
                                    .foregroundColor(AppColors.secondaryText)
                                    .multilineTextAlignment(.center)
                                
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
                            }
                            .padding(.horizontal, max(20, geometry.size.width * 0.1))
                        }
                        .padding(.vertical, 20)
                        .background(AppColors.background)
                    }
                }
            }
            .navigationTitle("Premium")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        print("🔄 PaywallView: Close button tapped")
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(AppColors.secondaryText)
                    }
                }
            }
        }
        .background(AppColors.background)
        .onAppear {
            print("🔄 PaywallView: View appeared")
            print("  - Subscription status: \(subscriptionManager.subscriptionStatus)")
            print("  - Is premium active: \(subscriptionManager.isPremiumActive)")
            print("  - Products loaded: \(subscriptionManager.products.count)")
        }
        .fullScreenCover(isPresented: $showingSubscription) {
            NavigationStack {
                SubscriptionView()
                    .environmentObject(subscriptionManager)
                    .navigationTitle("Premium")
                    .navigationBarTitleDisplayMode(.inline)
                    .navigationBarBackButtonHidden(true)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("Cancel") {
                                showingSubscription = false
                            }
                        }
                    }
            }
        }
        .onChange(of: subscriptionManager.isPremiumActive) { _, isActive in
            if isActive {
                dismiss()
            }
        }
    }
}

struct FeatureRowView: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(AppColors.primary)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(AppTypography.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(AppColors.text)
                
                Text(description)
                    .font(AppTypography.subheadline)
                    .foregroundColor(AppColors.secondaryText)
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(AppColors.secondaryBackground)
        .cornerRadius(AppCornerRadius.medium)
    }
}

#Preview {
    PaywallView()
        .environmentObject(SubscriptionManager.shared)
}


