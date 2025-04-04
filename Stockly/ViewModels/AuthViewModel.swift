import Foundation
import Combine

class AuthViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var confirmPassword = ""
    @Published var name = ""
    @Published var isAuthenticated = false
    @Published var user: User?
    @Published var showingError = false
    @Published var errorMessage = ""
    @Published var isLoading = false
    
    private let authService: AuthService
    private var cancellables = Set<AnyCancellable>()
    
    init(authService: AuthService = AuthService()) {
        self.authService = authService
        
        // Bind to auth service
        authService.$isAuthenticated
            .assign(to: \.isAuthenticated, on: self)
            .store(in: &cancellables)
        
        authService.$currentUser
            .assign(to: \.user, on: self)
            .store(in: &cancellables)
    }
    
    @MainActor
    func login() async {
        guard !email.isEmpty, !password.isEmpty else {
            showError("Email and password are required")
            return
        }
        
        isLoading = true
        
        do {
            _ = try await authService.login(email: email, password: password)
            isLoading = false
            clearFields()
        } catch let error as AuthError {
            handleAuthError(error)
        } catch {
            showError("An unexpected error occurred")
        }
    }
    
    @MainActor
    func register() async {
        guard !email.isEmpty, !password.isEmpty, !confirmPassword.isEmpty, !name.isEmpty else {
            showError("All fields are required")
            return
        }
        
        guard password == confirmPassword else {
            showError("Passwords do not match")
            return
        }
        
        isLoading = true
        
        do {
            _ = try await authService.register(email: email, password: password, name: name)
            
            // Automatically login after registration
            _ = try await authService.login(email: email, password: password)
            
            isLoading = false
            clearFields()
        } catch let error as AuthError {
            handleAuthError(error)
        } catch {
            showError("An unexpected error occurred")
        }
    }
    
    func logout() {
        authService.logout()
    }
    
    private func handleAuthError(_ error: AuthError) {
        DispatchQueue.main.async {
            self.isLoading = false
            
            switch error {
            case .invalidCredentials:
                self.showError("Invalid email or password")
            case .networkError:
                self.showError("Network error. Please check your connection")
            case .tokenExpired:
                self.showError("Your session has expired. Please log in again")
            case .unknown:
                self.showError("An unexpected error occurred")
            }
        }
    }
    
    private func showError(_ message: String) {
        DispatchQueue.main.async {
            self.errorMessage = message
            self.showingError = true
        }
    }
    
    private func clearFields() {
        email = ""
        password = ""
        confirmPassword = ""
        name = ""
    }
    
    func validateEmail() -> Bool {
        let emailRegex = #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return email.range(of: emailRegex, options: .regularExpression) != nil
    }
}