import SwiftUI
import StoreKit

struct SubscriptionView: View {
    @EnvironmentObject private var subscriptionService: SubscriptionService
    @Environment(\.dismiss) private var dismiss
    
    @State private var isLoading = false
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Stockly Subscription")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("Choose the plan that works for you")
                            .foregroundColor(.secondary)
                    }
                    .padding(.top)
                    
                    // Current plan
                    currentPlanSection
                    
                    // Usage stats
                    usageStatsSection
                    
                    // Subscription options
                    subscriptionOptionsSection
                    
                    // Restore purchases button
                    Button(action: {
                        Task {
                            isLoading = true
                            await subscriptionService.restorePurchases()
                            isLoading = false
                            
                            // Show success message
                            alertTitle = "Purchases Restored"
                            alertMessage = "Your purchases have been restored."
                            showingAlert = true
                        }
                    }) {
                        Text("Restore Purchases")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .padding(.horizontal)
                    .padding(.top)
                    
                    // Terms and privacy
                    VStack(spacing: 8) {
                        Text("By subscribing, you agree to our Terms of Service and Privacy Policy.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Text("Subscriptions will automatically renew unless canceled at least 24 hours before the end of the current period. You can manage your subscriptions in your App Store account settings.")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
                .padding(.bottom)
            }
            .navigationTitle("Subscription")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .overlay {
                if isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.2))
                }
            }
            .alert(alertTitle, isPresented: $showingAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    // MARK: - View Components
    
    private var currentPlanSection: some View {
        VStack(spacing: 16) {
            Text("Current Plan")
                .font(.headline)
            
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.accentColor.opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: subscriptionService.currentSubscription == .free ? "star" : "crown.fill")
                        .font(.title2)
                        .foregroundColor(.accentColor)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(subscriptionService.currentSubscription == .free ? "Free Plan" : "Premium Plan")
                        .font(.headline)
                    
                    Text(subscriptionService.getSubscriptionDescription(for: subscriptionService.currentSubscription))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding()
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(12)
            .padding(.horizontal)
        }
    }
    
    private var usageStatsSection: some View {
        VStack(spacing: 16) {
            if subscriptionService.currentSubscription == .free {
                Text("Your Usage")
                    .font(.headline)
                
                HStack(spacing: 20) {
                    // Invoices usage
                    VStack {
                        ZStack {
                            Circle()
                                .stroke(Color.secondary.opacity(0.2), lineWidth: 8)
                                .frame(width: 80, height: 80)
                            
                            Circle()
                                .trim(from: 0, to: min(CGFloat(subscriptionService.invoiceCount) / CGFloat(UsageLimits.maxFreeInvoices), 1.0))
                                .stroke(
                                    subscriptionService.hasReachedInvoiceLimit() ? Color.red : 
                                    subscriptionService.isApproachingInvoiceLimit() ? Color.orange : Color.green,
                                    lineWidth: 8
                                )
                                .frame(width: 80, height: 80)
                                .rotationEffect(.degrees(-90))
                            
                            VStack(spacing: 0) {
                                Text("\(subscriptionService.invoiceCount)")
                                    .font(.headline)
                                Text("/\(UsageLimits.maxFreeInvoices)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Text("Invoices")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    // Products usage
                    VStack {
                        ZStack {
                            Circle()
                                .stroke(Color.secondary.opacity(0.2), lineWidth: 8)
                                .frame(width: 80, height: 80)
                            
                            Circle()
                                .trim(from: 0, to: min(CGFloat(subscriptionService.productCount) / CGFloat(UsageLimits.maxFreeProducts), 1.0))
                                .stroke(
                                    subscriptionService.hasReachedProductLimit() ? Color.red : 
                                    subscriptionService.isApproachingProductLimit() ? Color.orange : Color.green,
                                    lineWidth: 8
                                )
                                .frame(width: 80, height: 80)
                                .rotationEffect(.degrees(-90))
                            
                            VStack(spacing: 0) {
                                Text("\(subscriptionService.productCount)")
                                    .font(.headline)
                                Text("/\(UsageLimits.maxFreeProducts)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Text("Products")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(12)
                .padding(.horizontal)
            }
        }
    }
    
    private var subscriptionOptionsSection: some View {
        VStack(spacing: 16) {
            Text("Subscription Options")
                .font(.headline)
            
            // Monthly subscription option
            subscriptionOptionCard(
                title: "Monthly Premium",
                price: subscriptionService.getFormattedPrice(for: .monthly),
                description: subscriptionService.getSubscriptionDescription(for: .monthly),
                isCurrentPlan: subscriptionService.currentSubscription == .monthly,
                action: {
                    purchaseSubscription(tier: .monthly)
                }
            )
            
            // Annual subscription option
            subscriptionOptionCard(
                title: "Annual Premium",
                price: subscriptionService.getFormattedPrice(for: .annual),
                description: subscriptionService.getSubscriptionDescription(for: .annual),
                isCurrentPlan: subscriptionService.currentSubscription == .annual,
                isBestValue: true,
                action: {
                    purchaseSubscription(tier: .annual)
                }
            )
        }
    }
    
    private func subscriptionOptionCard(
        title: String,
        price: String,
        description: String,
        isCurrentPlan: Bool,
        isBestValue: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        VStack(spacing: 12) {
            if isBestValue {
                Text("BEST VALUE")
                    .font(.caption)
                    .fontWeight(.bold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(4)
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                    
                    Text(price)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Spacer()
                
                if isCurrentPlan {
                    Text("Current")
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.secondary.opacity(0.2))
                        .cornerRadius(4)
                } else {
                    Button(action: action) {
                        Text("Subscribe")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .disabled(isLoading)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isBestValue ? Color.green : Color.secondary.opacity(0.3), lineWidth: isBestValue ? 2 : 1)
        )
        .padding(.horizontal)
    }
    
    // MARK: - Helper Methods
    
    private func purchaseSubscription(tier: SubscriptionTier) {
        let productID = tier == .monthly ? subscriptionService.monthlySubscriptionID : subscriptionService.annualSubscriptionID
        
        guard let product = subscriptionService.products.first(where: { $0.id == productID }) else {
            // Product not found
            alertTitle = "Product Unavailable"
            alertMessage = "This subscription product is currently unavailable. Please try again later."
            showingAlert = true
            return
        }
        
        // Start the purchase process
        isLoading = true
        
        Task {
            do {
                let success = try await subscriptionService.purchase(product)
                
                await MainActor.run {
                    isLoading = false
                    
                    if success {
                        // Purchase successful
                        alertTitle = "Purchase Successful"
                        alertMessage = "Thank you for subscribing to Stockly Premium!"
                        showingAlert = true
                    } else {
                        // Purchase failed
                        alertTitle = "Purchase Failed"
                        alertMessage = "There was an error processing your purchase. Please try again later."
                        showingAlert = true
                    }
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    
                    // Purchase error
                    alertTitle = "Purchase Error"
                    alertMessage = error.localizedDescription
                    showingAlert = true
                }
            }
        }
    }
}

#Preview {
    SubscriptionView()
        .environmentObject(SubscriptionService.shared)
}
