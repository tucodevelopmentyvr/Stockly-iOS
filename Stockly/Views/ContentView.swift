import SwiftUI
import SwiftData

struct ContentView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var navigationRouter: NavigationRouter
    
    var body: some View {
        Group {
            if authViewModel.isAuthenticated {
                // Use MainTabView as the primary authenticated view
                MainTabView()
            } else {
                LoginView()
            }
        }
        .onAppear {
            // Check if user has a valid cached authentication token
            if let token = UserDefaults.standard.string(forKey: "authToken"), !token.isEmpty {
                // In a real app, validate token with backend
                authViewModel.isAuthenticated = true
            }
        }
    }
}