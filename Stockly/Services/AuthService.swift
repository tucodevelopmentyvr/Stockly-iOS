import Foundation
import Combine
import SwiftData

enum AuthError: Error {
    case invalidCredentials
    case networkError
    case tokenExpired
    case unknown
}

class AuthService: ObservableObject {
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var authToken: String?
    @Published var authError: AuthError?
    
    private var cancellables = Set<AnyCancellable>()
    
    // For development: automatically authenticate
    init() {
        #if DEBUG
        // Skip authentication during development (for testing only)
        // Comment or remove this when you want to test the login flow
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let mockUser = User(email: "test@example.com", name: "Test User", role: .manager)
            self.currentUser = mockUser
            self.isAuthenticated = true
            self.authToken = "mock-jwt-token"
            UserDefaults.standard.set("mock-jwt-token", forKey: "authToken")
        }
        #endif
    }
    
    // Firebase or custom JWT implementation would go here
    func login(email: String, password: String) async throws -> User {
        // Simple validation for demonstration
        if email.isEmpty || password.isEmpty {
            throw AuthError.invalidCredentials
        }
        
        // Simulate network delay
        try await Task.sleep(for: .seconds(1))
        
        // In a real app, we would validate credentials and get a JWT token
        let mockUser = User(email: email, name: "Test User", role: .manager)
        self.currentUser = mockUser
        self.isAuthenticated = true
        self.authToken = "mock-jwt-token"
        
        // Save token for persistence
        UserDefaults.standard.set("mock-jwt-token", forKey: "authToken")
        
        // Update last login time
        mockUser.lastLoginAt = Date()
        
        return mockUser
    }
    
    func logout() {
        self.currentUser = nil
        self.isAuthenticated = false
        self.authToken = nil
        
        // Clear token
        UserDefaults.standard.removeObject(forKey: "authToken")
    }
    
    func register(email: String, password: String, name: String) async throws -> User {
        // Simple validation for demonstration
        if email.isEmpty || password.isEmpty || name.isEmpty {
            throw AuthError.invalidCredentials
        }
        
        // Simulate network delay
        try await Task.sleep(for: .seconds(1))
        
        // In a real app, we would create a new user in the backend
        let newUser = User(email: email, name: name, role: .employee)
        return newUser
    }
    
    // RBAC - Role Based Access Control
    func canPerformAction(_ action: String) -> Bool {
        guard let user = currentUser else { return false }
        
        // Implement role-based permissions
        switch action {
        case "manage_users":
            return user.isAdmin
        case "edit_inventory":
            return user.isManager
        case "view_inventory":
            return true // All authenticated users can view inventory
        default:
            return false
        }
    }
}