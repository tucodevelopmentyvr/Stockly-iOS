import UIKit

extension UIDevice {
    // Helper property to determine if the view is likely being shown in a tab view
    static var isRunningInTabView: Bool {
        // Check if we have any tab bar controller in the view hierarchy
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            
            // Check if rootViewController is a tab controller
            if rootViewController is UITabBarController {
                return true
            }
            
            // Check in the hierarchy
            return findTabBarController(in: rootViewController) != nil
        }
        
        return false
    }
    
    // Helper function to find a tab bar controller in the view hierarchy
    private static func findTabBarController(in viewController: UIViewController?) -> UITabBarController? {
        guard let viewController = viewController else { return nil }
        
        // Check if this controller is a tab controller
        if let tabController = viewController as? UITabBarController {
            return tabController
        }
        
        // Check presented controller
        if let presented = viewController.presentedViewController {
            if let found = findTabBarController(in: presented) {
                return found
            }
        }
        
        // Check children
        for child in viewController.children {
            if let found = findTabBarController(in: child) {
                return found
            }
        }
        
        // Check if parent is a tab controller
        if let parent = viewController.parent as? UITabBarController {
            return parent
        }
        
        return nil
    }
}