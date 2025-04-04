import Foundation
import Combine

enum SubscriptionTier: String, CaseIterable {
    case free = "com.stockly.free"
    case premium = "com.stockly.premium"
}

class SubscriptionService: ObservableObject {
    static let shared = SubscriptionService()
    
    @Published var currentSubscription: SubscriptionTier = .premium  // Always premium for testing
    @Published var isTrialActive = false
    @Published var trialEndDate: Date?
    
    private init() {
        print("Subscription service initialized - Premium access enabled for testing")
    }
    
    func hasAccess() -> Bool {
        return true  // Always return true for testing
    }
    
    @MainActor
    func checkSubscriptionStatus() async {
        // For testing, always set subscription to premium
        currentSubscription = .premium
    }
}