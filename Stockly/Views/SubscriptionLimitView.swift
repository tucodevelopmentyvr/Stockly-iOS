import SwiftUI

struct SubscriptionLimitView: View {
    @EnvironmentObject private var subscriptionService: SubscriptionService
    @Environment(\.dismiss) private var dismiss
    
    var limitType: LimitType
    var onUpgrade: () -> Void
    
    enum LimitType {
        case invoice
        case product
        
        var title: String {
            switch self {
            case .invoice:
                return "Invoice Limit Reached"
            case .product:
                return "Product Limit Reached"
            }
        }
        
        var message: String {
            switch self {
            case .invoice:
                return "You've reached the limit of \(UsageLimits.maxFreeInvoices) invoices in the free plan."
            case .product:
                return "You've reached the limit of \(UsageLimits.maxFreeProducts) products in the free plan."
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Header
                Image(systemName: "exclamationmark.circle")
                    .font(.system(size: 60))
                    .foregroundColor(.orange)
                    .padding()
                
                Text(limitType.title)
                    .font(.title)
                    .fontWeight(.bold)
                
                Text(limitType.message)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                // Subscription options
                VStack(spacing: 16) {
                    Text("Upgrade to Premium for:")
                        .font(.headline)
                    
                    HStack(spacing: 16) {
                        FeatureItem(icon: "infinity", text: "Unlimited Invoices")
                        FeatureItem(icon: "infinity", text: "Unlimited Products")
                    }
                    
                    HStack(spacing: 16) {
                        FeatureItem(icon: "checkmark.seal.fill", text: "Priority Support")
                        FeatureItem(icon: "arrow.up.forward", text: "Future Features")
                    }
                }
                .padding()
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(12)
                .padding(.horizontal)
                
                // Pricing
                VStack(spacing: 16) {
                    Button(action: {
                        dismiss()
                        onUpgrade()
                    }) {
                        HStack {
                            Text("Upgrade to Premium")
                            Spacer()
                            Text("From \(subscriptionService.monthlyPrice)/month")
                        }
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: {
                        dismiss()
                    }) {
                        Text("Maybe Later")
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .padding(.top)
            .navigationTitle("Subscription Required")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct FeatureItem: View {
    var icon: String
    var text: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.accentColor)
            Text(text)
                .font(.subheadline)
            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color.white)
        .cornerRadius(8)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

#Preview {
    SubscriptionLimitView(limitType: .invoice, onUpgrade: {})
        .environmentObject(SubscriptionService.shared)
}
