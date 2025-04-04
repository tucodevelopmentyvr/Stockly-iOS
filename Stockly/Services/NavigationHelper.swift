//  NavigationHelper.swift
//  Stockly

import SwiftUI

// Navigation router to handle navigation across the app
class NavigationRouter: ObservableObject {
    @Published var path = NavigationPath()
    
    init() {
        // Listen for "ReturnToMainMenu" notifications
        NotificationCenter.default.addObserver(self, 
            selector: #selector(handleReturnToMainMenu), 
            name: NSNotification.Name("ReturnToMainMenu"), 
            object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func handleReturnToMainMenu() {
        // Clear the navigation stack to return to main menu
        DispatchQueue.main.async {
            self.path = NavigationPath()
            
            // Also try using UIKit to ensure we go back to main menu
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootViewController = windowScene.windows.first?.rootViewController {
                
                // Try to dismiss any presented controllers
                rootViewController.dismiss(animated: false)
                
                // Try to pop to root view in navigation controller
                if let navController = rootViewController as? UINavigationController {
                    navController.popToRootViewController(animated: true)
                }
                
                // Also try to dismiss all modal controllers in the hierarchy
                self.dismissAllPresentedControllers(rootViewController)
            }
        }
    }
    
    // Helper method to recursively dismiss all presented controllers
    private func dismissAllPresentedControllers(_ viewController: UIViewController) {
        if let presentedViewController = viewController.presentedViewController {
            // Recursively dismiss deeper controllers first
            dismissAllPresentedControllers(presentedViewController)
            
            // Then dismiss this controller
            viewController.dismiss(animated: false, completion: nil)
        }
        
        // Also check for tab bar controller tabs
        if let tabBarController = viewController as? UITabBarController {
            for childVC in tabBarController.viewControllers ?? [] {
                dismissAllPresentedControllers(childVC)
            }
        }
        
        // Check for navigation controller stack
        if let navigationController = viewController as? UINavigationController {
            navigationController.popToRootViewController(animated: false)
            for childVC in navigationController.viewControllers {
                dismissAllPresentedControllers(childVC)
            }
        }
    }
    
    func navigateToHome() {
        // Call the common handler
        handleReturnToMainMenu()
        
        // Additional fallback navigation methods to ensure we return home
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            // Try using UIKit methods to dismiss any presented views
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootViewController = windowScene.windows.first?.rootViewController {
                
                // Dismiss all presented modals
                var currentVC = rootViewController
                while let presentedVC = currentVC.presentedViewController {
                    presentedVC.dismiss(animated: false, completion: nil)
                    currentVC = presentedVC
                }
                
                // Find the main navigation controller and pop to root
                self.findAndPopToRootNavigationController(rootViewController)
                
                // Post a notification that can be observed in SwiftUI views
                NotificationCenter.default.post(name: NSNotification.Name("ForceNavigateToMainMenu"), object: nil)
            }
        }
    }
    
    private func findAndPopToRootNavigationController(_ viewController: UIViewController) {
        // Check if this is a navigation controller
        if let navController = viewController as? UINavigationController {
            navController.popToRootViewController(animated: true)
        }
        
        // Check child view controllers
        for childVC in viewController.children {
            findAndPopToRootNavigationController(childVC)
        }
        
        // Check if this is a tab bar controller
        if let tabController = viewController as? UITabBarController {
            tabController.selectedIndex = 0  // Select the first tab
            if let navVC = tabController.selectedViewController as? UINavigationController {
                navVC.popToRootViewController(animated: true)
            }
        }
    }
    
    func navigateBack() {
        if !path.isEmpty {
            path.removeLast()
        }
    }
    
    func navigate(to destination: String) {
        path.append(destination)
    }
}

struct CustomNavigationModifier: ViewModifier {
    let previousPageTitle: String
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var navigationRouter: NavigationRouter
    
    func body(content: Content) -> some View {
        content
            // Don't add any navigation buttons
            .navigationBarBackButtonHidden(true)
            // Add custom transition for consistent animation direction
            .transition(.asymmetric(
                insertion: .move(edge: .trailing),
                removal: .move(edge: .leading)
            ))
    }
}

// Environment key to control navigation stack presentation direction
private struct IsNavigationStackPresentedKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

extension EnvironmentValues {
    var isPresented: Bool {
        get { self[IsNavigationStackPresentedKey.self] }
        set { self[IsNavigationStackPresentedKey.self] = newValue }
    }
}

// View extension for easier usage
extension View {
    func customNavigation(previousPageTitle: String) -> some View {
        // Use a transaction for controlling animation
        return self
            .modifier(CustomNavigationModifier(previousPageTitle: previousPageTitle))
            .environment(\.isPresented, true)
            // Force the correct animation direction
            .transition(.asymmetric(
                insertion: .move(edge: .trailing),
                removal: .move(edge: .leading)
            ))
            // Add animation transaction to control timing
            .transaction { transaction in
                transaction.animation = .easeInOut(duration: 0.3)
            }
            // Add swipe gestures for navigation
            .modifier(SwipeNavigationGestureModifier())
    }
}

// Swipe gesture modifier for back/forward navigation
struct SwipeNavigationGestureModifier: ViewModifier {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var navigationRouter: NavigationRouter
    
    func body(content: Content) -> some View {
        content
            .gesture(
                DragGesture(minimumDistance: 50, coordinateSpace: .local)
                    .onEnded { value in
                        // Swipe from left edge to right (to go back)
                        if value.startLocation.x < 50 && value.translation.width > 100 {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                presentationMode.wrappedValue.dismiss()
                            }
                        }
                        // Swipe from right edge to left (to go forward to next in stack if possible)
                        else if value.startLocation.x > UIScreen.main.bounds.width - 50 && value.translation.width < -100 {
                            // This would be used if we have a forward navigation action
                            // Currently there's no standard way to go "forward" in the stack
                            // but this gesture is included for potential future use
                        }
                    }
            )
    }
}

// Home button that consistently navigates to main menu
struct HomeButtonLink: View {
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject private var navigationRouter: NavigationRouter
    @State private var navigateToRoot = false
    
    var body: some View {
        Button(action: {
            // Use multiple approaches to reliably return to main menu
            DispatchQueue.main.async {
                // First approach: Dismiss current view
                presentationMode.wrappedValue.dismiss()
                
                // Second approach: Post notification for any listeners
                NotificationCenter.default.post(name: NSNotification.Name("ReturnToMainMenu"), object: nil)
                
                // Third approach: Reset navigation router
                navigationRouter.path = NavigationPath()
                
                // Fourth approach: Direct UIKit intervention
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let rootViewController = windowScene.windows.first?.rootViewController {
                    
                    // Dismiss any presented modals
                    var currentVC = rootViewController
                    while let presentedVC = currentVC.presentedViewController {
                        presentedVC.dismiss(animated: false, completion: nil)
                        currentVC = presentedVC
                    }
                    
                    // Find and pop navigation controllers
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        forceNavigateToRoot(rootViewController)
                    }
                }
                
                // Set state to trigger navigation link if other methods fail
                navigateToRoot = true
            }
        }) {
            Image(systemName: "house.fill")
                .imageScale(.large)
                .foregroundColor(.accentColor)
        }
        // Last resort approach: Use NavigationLink as fallback
        .background(
            NavigationLink(destination: ContentView(), isActive: $navigateToRoot) {
                EmptyView()
            }
        )
    }
    
    // Helper function to force navigation to root using UIKit
    private func forceNavigateToRoot(_ viewController: UIViewController) {
        // First dismiss any presented controllers
        if let presented = viewController.presentedViewController {
            viewController.dismiss(animated: false) {
                self.forceNavigateToRoot(viewController)
            }
            return
        }
        
        // Check if we're in a navigation controller
        if let navController = viewController as? UINavigationController {
            // Pop to root
            navController.popToRootViewController(animated: true)
        } else if let tabController = viewController as? UITabBarController {
            // If in a tab controller, check each tab
            for (index, controller) in (tabController.viewControllers ?? []).enumerated() {
                if let nav = controller as? UINavigationController {
                    nav.popToRootViewController(animated: false)
                }
                // Select the first tab
                if index == 0 {
                    tabController.selectedIndex = 0
                }
            }
        }
        
        // Find the top-level navigation controller
        var current: UIViewController? = viewController
        while current != nil {
            if let navController = current as? UINavigationController {
                navController.popToRootViewController(animated: true)
                break
            }
            current = current?.parent
        }
    }
}