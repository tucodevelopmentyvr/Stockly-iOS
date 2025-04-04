import SwiftUI
import SwiftData
import PhotosUI
// import FirebaseCore - Comment out for now until Firebase is properly set up

// Helper function to enable edge swipe gestures for all navigation controllers
func enableEdgeGesturesForAllNavigationControllers(in window: UIWindow) {
    // Declare the function before using it
    func findAndConfigureNavControllers(_ viewController: UIViewController) {
        if let navController = viewController as? UINavigationController {
            // Enable interactive pop gesture even when custom back button is used
            navController.interactivePopGestureRecognizer?.isEnabled = true
            navController.interactivePopGestureRecognizer?.delegate = nil
        }

        // Check presented view controller
        if let presented = viewController.presentedViewController {
            findAndConfigureNavControllers(presented)
        }

        // Check child view controllers
        for child in viewController.children {
            findAndConfigureNavControllers(child)
        }
    }

    // Start from the root view controller
    if let rootViewController = window.rootViewController {
        findAndConfigureNavControllers(rootViewController)
    }
}

@main
struct StocklyApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var subscriptionService = SubscriptionService.shared
    @StateObject private var navigationRouter = NavigationRouter()
    @StateObject private var setupManager = AppSetupManager.shared

    init() {
        // FirebaseApp.configure() - Comment out for now until Firebase is properly set up
        print("Stockly starting in development mode - all features enabled")

        // Enable swipe navigation globally by setting up UIKit preferences
        let appearance = UINavigationBar.appearance()
        appearance.tintColor = UIColor(Color.accentColor)
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()
                    .environmentObject(authViewModel)
                    .environmentObject(navigationRouter)
                    .environmentObject(setupManager)
                    .environmentObject(subscriptionService)
                    .onAppear {
                        // Enable edge swipe gestures for navigation at the UIKit level
                        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                           let window = windowScene.windows.first {
                            enableEdgeGesturesForAllNavigationControllers(in: window)
                        }
                    }

                // Show setup view if setup is not completed
                if setupManager.isSetupRequired() {
                    InitialSetupView()
                        .environmentObject(setupManager)
                        .environmentObject(subscriptionService)
                }
            }
        }
        .modelContainer(for: [Item.self, User.self, Category.self, CustomField.self, Client.self, Supplier.self, Invoice.self, InvoiceItem.self, CustomInvoiceField.self, Estimate.self, EstimateItem.self, CustomEstimateField.self, Bill.self])
    }
}

