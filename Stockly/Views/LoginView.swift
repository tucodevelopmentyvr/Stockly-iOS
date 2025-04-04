import SwiftUI

struct LoginView: View {
    @StateObject private var viewModel = AuthViewModel()
    @State private var isRegistering = false
    @State private var isLoading = false
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ZStack {
            // Background
            (colorScheme == .dark ? Color(UIColor.systemBackground) : Color(UIColor.secondarySystemBackground))
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Logo and App Name
                VStack(spacing: 15) {
                    Image(systemName: "cube.box.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .foregroundColor(.accentColor)
                    
                    Text("Stockly")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Inventory Management System")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 40)
                
                // Login Form
                VStack(spacing: 20) {
                    if isRegistering {
                        // Name field (registration only)
                        TextField("Full Name", text: $viewModel.name)
                            .textContentType(.name)
                            .autocapitalization(.words)
                            .padding()
                            .background(Color(UIColor.secondarySystemBackground).opacity(colorScheme == .dark ? 0.5 : 1))
                            .cornerRadius(10)
                    }
                    
                    // Email field
                    TextField("Email", text: $viewModel.email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground).opacity(colorScheme == .dark ? 0.5 : 1))
                        .cornerRadius(10)
                    
                    // Password field
                    SecureField("Password", text: $viewModel.password)
                        .textContentType(isRegistering ? .newPassword : .password)
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground).opacity(colorScheme == .dark ? 0.5 : 1))
                        .cornerRadius(10)
                    
                    if isRegistering {
                        // Confirm Password field (registration only)
                        SecureField("Confirm Password", text: $viewModel.confirmPassword)
                            .textContentType(.newPassword)
                            .padding()
                            .background(Color(UIColor.secondarySystemBackground).opacity(colorScheme == .dark ? 0.5 : 1))
                            .cornerRadius(10)
                    }
                    
                    // Login/Register Button
                    Button(action: {
                        isLoading = true
                        Task {
                            if isRegistering {
                                await viewModel.register()
                            } else {
                                await viewModel.login()
                            }
                            isLoading = false
                        }
                    }) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .padding(.trailing, 10)
                            }
                            
                            Text(isRegistering ? "Create Account" : "Sign In")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(isLoading)
                    
                    // Switch between Login and Register
                    Button(action: {
                        withAnimation {
                            isRegistering.toggle()
                            // Clear fields when switching
                            viewModel.email = ""
                            viewModel.password = ""
                            viewModel.confirmPassword = ""
                            viewModel.name = ""
                        }
                    }) {
                        Text(isRegistering ? "Already have an account? Sign In" : "Don't have an account? Create one")
                            .foregroundColor(.accentColor)
                    }
                }
                .padding(.horizontal, 30)
                
                Spacer()
                
                // Trial Info
                VStack(spacing: 8) {
                    Text("3-Day Free Trial Available")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                    
                    Text("Then $1.99/month")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.bottom)
            }
            .padding()
        }
        .alert(isPresented: $viewModel.showingError) {
            Alert(
                title: Text("Error"),
                message: Text(viewModel.errorMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }
}