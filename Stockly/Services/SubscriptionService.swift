import Foundation
import Combine
import StoreKit
import SwiftData

enum SubscriptionTier: String, CaseIterable, Codable {
    case free = "com.stockly.free"
    case monthly = "com.stockly.monthly"
    case annual = "com.stockly.annual"
}

// Usage limits for the free tier
struct UsageLimits {
    static let maxFreeInvoices = 80
    static let maxFreeProducts = 80
}

class SubscriptionService: ObservableObject {
    static let shared = SubscriptionService()

    // Subscription state
    @Published var currentSubscription: SubscriptionTier = .free
    @Published var isTrialActive = false
    @Published var trialEndDate: Date?

    // Usage tracking
    @Published var invoiceCount: Int = 0
    @Published var productCount: Int = 0

    // Product identifiers
    let monthlySubscriptionID = "com.stockly.monthly"
    let annualSubscriptionID = "com.stockly.annual"

    // Prices (for display when StoreKit products aren't loaded)
    let monthlyPrice = "$1.99"
    let annualPrice = "$23.00"

    // StoreKit products
    @Published var products: [Product] = []
    @Published var purchasedProductIDs = Set<String>()

    // Transaction listener
    var updateListenerTask: Task<Void, Error>?

    private init() {
        // Start listening for transactions
        updateListenerTask = listenForTransactions()

        // Load subscription status from UserDefaults
        if let savedTier = UserDefaults.standard.string(forKey: "subscriptionTier"),
           let tier = SubscriptionTier(rawValue: savedTier) {
            currentSubscription = tier
        }

        // Load usage counts from UserDefaults
        invoiceCount = UserDefaults.standard.integer(forKey: "invoiceCount")
        productCount = UserDefaults.standard.integer(forKey: "productCount")

        // Request products from the App Store
        Task {
            await requestProducts()
        }
    }

    deinit {
        updateListenerTask?.cancel()
    }

    // MARK: - Usage Tracking

    func incrementInvoiceCount() {
        invoiceCount += 1
        UserDefaults.standard.set(invoiceCount, forKey: "invoiceCount")
    }

    func incrementProductCount() {
        productCount += 1
        UserDefaults.standard.set(productCount, forKey: "productCount")
    }

    func resetUsageCounts() {
        invoiceCount = 0
        productCount = 0
        UserDefaults.standard.set(0, forKey: "invoiceCount")
        UserDefaults.standard.set(0, forKey: "productCount")
    }

    // MARK: - Access Control

    func canCreateInvoice() -> Bool {
        return currentSubscription != .free || invoiceCount < UsageLimits.maxFreeInvoices
    }

    func canCreateProduct() -> Bool {
        return currentSubscription != .free || productCount < UsageLimits.maxFreeProducts
    }

    func isApproachingInvoiceLimit() -> Bool {
        return currentSubscription == .free && invoiceCount >= (UsageLimits.maxFreeInvoices - 10) && invoiceCount < UsageLimits.maxFreeInvoices
    }

    func isApproachingProductLimit() -> Bool {
        return currentSubscription == .free && productCount >= (UsageLimits.maxFreeProducts - 10) && productCount < UsageLimits.maxFreeProducts
    }

    func hasReachedInvoiceLimit() -> Bool {
        return currentSubscription == .free && invoiceCount >= UsageLimits.maxFreeInvoices
    }

    func hasReachedProductLimit() -> Bool {
        return currentSubscription == .free && productCount >= UsageLimits.maxFreeProducts
    }

    // MARK: - StoreKit Integration

    @MainActor
    func requestProducts() async {
        do {
            // Request products from the App Store
            let storeProducts = try await Product.products(for: [monthlySubscriptionID, annualSubscriptionID])
            products = storeProducts

            // Check for purchased products
            await checkPurchasedProducts()
        } catch {
            print("Failed to load products: \(error)")
        }
    }

    @MainActor
    func purchase(_ product: Product) async throws -> Bool {
        // Start a purchase
        let result = try await product.purchase()

        switch result {
        case .success(let verificationResult):
            // Check if the transaction is verified
            switch verificationResult {
            case .verified(let transaction):
                // Update the user's subscription
                await updateSubscriptionStatus(transaction: transaction)
                await transaction.finish()
                return true
            case .unverified:
                // Transaction failed verification
                return false
            }
        case .userCancelled:
            return false
        case .pending:
            return false
        @unknown default:
            return false
        }
    }

    @MainActor
    func updateSubscriptionStatus(transaction: Transaction) async {
        // Update the subscription tier based on the product ID
        if transaction.productID == monthlySubscriptionID {
            currentSubscription = .monthly
            UserDefaults.standard.set(SubscriptionTier.monthly.rawValue, forKey: "subscriptionTier")
        } else if transaction.productID == annualSubscriptionID {
            currentSubscription = .annual
            UserDefaults.standard.set(SubscriptionTier.annual.rawValue, forKey: "subscriptionTier")
        }

        // Add the product ID to the set of purchased products
        purchasedProductIDs.insert(transaction.productID)
    }

    @MainActor
    func checkPurchasedProducts() async {
        // Get the current app store transactions
        for await result in Transaction.currentEntitlements {
            // Check if the transaction is verified
            if case .verified(let transaction) = result {
                // Check if the transaction is still valid
                if transaction.revocationDate == nil && !transaction.isUpgraded {
                    // Update the subscription status
                    await updateSubscriptionStatus(transaction: transaction)
                }
            }
        }
    }

    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            // Listen for transactions from the App Store
            for await result in Transaction.updates {
                // Check if the transaction is verified
                if case .verified(let transaction) = result {
                    // Update the subscription status on the main thread
                    await self.updateSubscriptionStatus(transaction: transaction)
                    await transaction.finish()
                }
            }
        }
    }

    // MARK: - Helper Methods

    func getFormattedPrice(for tier: SubscriptionTier) -> String {
        switch tier {
        case .free:
            return "Free"
        case .monthly:
            if let product = products.first(where: { $0.id == monthlySubscriptionID }) {
                return product.displayPrice
            }
            return monthlyPrice + "/month"
        case .annual:
            if let product = products.first(where: { $0.id == annualSubscriptionID }) {
                return product.displayPrice
            }
            return annualPrice + "/year"
        }
    }

    func getSubscriptionDescription(for tier: SubscriptionTier) -> String {
        switch tier {
        case .free:
            return "Up to \(UsageLimits.maxFreeInvoices) invoices and \(UsageLimits.maxFreeProducts) products"
        case .monthly:
            return "Unlimited invoices and products, billed monthly"
        case .annual:
            return "Unlimited invoices and products, billed annually (save 4%)"
        }
    }

    func restorePurchases() async {
        // Request to restore purchases from the App Store
        do {
            try await AppStore.sync()
            await checkPurchasedProducts()
        } catch {
            print("Failed to restore purchases: \(error)")
        }
    }
}