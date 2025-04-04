import SwiftUI
import SwiftData

struct MainMenuView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.modelContext) private var modelContext
    @AppStorage("darkModeEnabled") private var darkModeEnabled = false
    @State private var selection: String? = nil
    @EnvironmentObject private var navigationRouter: NavigationRouter
    
    var body: some View {
        // Use NavigationView with stack style to ensure proper animation
        NavigationView {
            // This is a workaround to ensure the back button never appears in the main menu
            ZStack {
            VStack {
                // Main content
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 15) {
                    Image(systemName: "cube.box.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 60, height: 60)
                        .foregroundColor(.accentColor)
                    
                    Text("Stockly")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Inventory Management System")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 30)
                .padding(.bottom, 40)
                
                // Main Menu with fully clickable buttons
                VStack(spacing: 20) {
                    Button(action: {
                        selection = "clients"
                    }) {
                        MenuButtonWithoutAction(title: "Clients", icon: "person.2.fill", color: .blue)
                    }
                    .background(
                        NavigationLink("", destination: ClientsView()
                            .customNavigation(previousPageTitle: "Main Menu"), 
                            tag: "clients", selection: $selection)
                            .opacity(0)
                    )
                    
                    Button(action: {
                        selection = "suppliers"
                    }) {
                        MenuButtonWithoutAction(title: "Suppliers", icon: "shippingbox.fill", color: .orange)
                    }
                    .background(
                        NavigationLink("", destination: SuppliersView()
                            .customNavigation(previousPageTitle: "Main Menu"),
                            tag: "suppliers", selection: $selection)
                            .opacity(0)
                    )
                    
                    Button(action: {
                        selection = "products"
                    }) {
                        MenuButtonWithoutAction(title: "Inventory", icon: "cube.box.fill", color: .green)
                    }
                    .background(
                        NavigationLink("", destination: InventoryView(modelContext: modelContext)
                            .customNavigation(previousPageTitle: "Main Menu"), tag: "products", selection: $selection)
                            .opacity(0)
                    )
                    
                    Button(action: {
                        selection = "invoices"
                    }) {
                        MenuButtonWithoutAction(title: "Invoices", icon: "doc.text.fill", color: .purple)
                    }
                    .background(
                        NavigationLink("", destination: InvoiceManagementView()
                            .customNavigation(previousPageTitle: "Main Menu"), tag: "invoices", selection: $selection)
                            .opacity(0)
                    )
                    
                    Button(action: {
                        selection = "estimates"
                    }) {
                        MenuButtonWithoutAction(title: "Estimates", icon: "doc.plaintext.fill", color: .indigo)
                    }
                    .background(
                        NavigationLink("", destination: EstimateManagementView()
                            .customNavigation(previousPageTitle: "Main Menu"), tag: "estimates", selection: $selection)
                            .opacity(0)
                    )
                    
                    // Dashboard button
                    Button(action: {
                        selection = "dashboard"
                    }) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(Color(UIColor.secondarySystemBackground))
                                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 3)
                                
                                HStack {
                                    Image(systemName: "chart.pie.fill")
                                        .font(.title2)
                                        .foregroundColor(.accentColor)
                                    
                                    Text("Go to Dashboard")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.secondary)
                                }
                                .padding()
                            }
                        }
                        .frame(height: 60)
                    }
                    .background(
                        NavigationLink("", destination: DashboardTabView()
                            .customNavigation(previousPageTitle: "Main Menu"), tag: "dashboard", selection: $selection)
                            .opacity(0)
                    )
                    .padding(.top, 20)
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Bottom Info
                VStack(spacing: 8) {
                    HStack {
                        Text("Version 1.0.0")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Toggle("", isOn: $darkModeEnabled)
                            .labelsHidden()
                        
                        Image(systemName: darkModeEnabled ? "moon.fill" : "sun.max.fill")
                            .foregroundColor(darkModeEnabled ? .yellow : .orange)
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 20)
            }
            .padding()
            .background(
                Color(UIColor.systemBackground)
                    .edgesIgnoringSafeArea(.all)
            )
            .preferredColorScheme(darkModeEnabled ? .dark : .light)
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: SettingsView()
                        .customNavigation(previousPageTitle: "Main Menu")) {
                        Image(systemName: "gear")
                    }
                }
                // Remove any back button display
                ToolbarItem(placement: .navigationBarLeading) {
                    EmptyView()
                }
            }
            // Ensure the back button is hidden when appearing
            .onAppear {
                // This completely removes the back button at the UIKit level
                DispatchQueue.main.async {
                    // Clear navigation history when returning to main menu
                    navigationRouter.path = NavigationPath()
                    
                    // Additional trick to force UI update
                    selection = nil
                    
                    // Force remove the back button completely at UIKit level
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                        if let window = windowScene.windows.first {
                            // Find all navigation controllers in the view hierarchy and manipulate them
                            findAndClearNavigationControllers(window.rootViewController)
                        }
                    }
                }
            }
            
            // A task specifically for updating navigation state
            .task {
                // Reset the navigation path
                navigationRouter.path = NavigationPath()
            }
            
            // Add navigationDestination inside the NavigationView
            .navigationDestination(for: String.self) { destination in
                switch destination {
                case "clients":
                    ClientsView()
                        .customNavigation(previousPageTitle: "Main Menu")
                case "suppliers":
                    SuppliersView()
                        .customNavigation(previousPageTitle: "Main Menu")
                case "products":
                    InventoryView(modelContext: modelContext)
                        .customNavigation(previousPageTitle: "Main Menu")
                case "invoices":
                    InvoiceManagementView()
                        .customNavigation(previousPageTitle: "Main Menu")
                case "estimates":
                    EstimateManagementView()
                        .customNavigation(previousPageTitle: "Main Menu")
                case "dashboard":
                    DashboardTabView()
                        .customNavigation(previousPageTitle: "Main Menu")
                case "settings":
                    SettingsView()
                        .customNavigation(previousPageTitle: "Main Menu")
                default:
                    Text("Page not found")
                }
            }
        }
    }
}

// Extension to properly hide back button
extension View {
    func hideBackButton() -> some View {
        self.navigationBarBackButtonHidden(true)
            .onAppear {
                // This removes the back button at the UIKit level
                let appearance = UINavigationBarAppearance()
                appearance.configureWithTransparentBackground()
                UINavigationBar.appearance().standardAppearance = appearance
                UINavigationBar.appearance().scrollEdgeAppearance = appearance
            }
    }
}

struct MenuButton: View {
    var title: String
    var icon: String
    var color: Color
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 15)
                    .fill(color.opacity(0.15))
                    .shadow(color: color.opacity(0.1), radius: 5, x: 0, y: 3)
                
                HStack {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(color)
                    
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
                .padding()
            }
            .frame(height: 70)
        }
    }
}

struct MenuButtonWithoutAction: View {
    var title: String
    var icon: String
    var color: Color
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 15)
                .fill(color.opacity(0.15))
                .shadow(color: color.opacity(0.1), radius: 5, x: 0, y: 3)
            
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding()
        }
        .frame(height: 70)
    }
}

// Helper method to find and clear all navigation controllers in the view hierarchy
private func findAndClearNavigationControllers(_ viewController: UIViewController?) {
    guard let viewController = viewController else { return }
    
    // If this is a navigation controller, clear its stack
    if let navController = viewController as? UINavigationController {
        // Hide back button
        navController.navigationBar.topItem?.hidesBackButton = true
        
        // Remove all except the first view controller
        if navController.viewControllers.count > 1 {
            navController.viewControllers = [navController.viewControllers.first!]
        }
        
        // Set a left bar button item to null to ensure no back button
        navController.topViewController?.navigationItem.leftBarButtonItem = nil
        navController.topViewController?.navigationItem.hidesBackButton = true
    }
    
    // Check presented view controller
    if let presented = viewController.presentedViewController {
        findAndClearNavigationControllers(presented)
    }
    
    // Check child view controllers
    for child in viewController.children {
        findAndClearNavigationControllers(child)
    }
}

struct DashboardTabView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTab = 0
    @Environment(\.presentationMode) private var presentationMode
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Dashboard Tab
            DashboardView(modelContext: modelContext)
                .tabItem {
                    Label("Dashboard", systemImage: "chart.pie.fill")
                }
                .tag(0)
            
            // Inventory Tab
            InventoryView(modelContext: modelContext)
                .tabItem {
                    Label("Inventory", systemImage: "cube.box.fill")
                }
                .tag(1)
            
            // Categories Tab
            CategoriesView()
                .tabItem {
                    Label("Categories", systemImage: "folder.fill")
                }
                .tag(2)
            
            // Invoice Tab
            InvoiceManagementView()
                .tabItem {
                    Label("Invoices", systemImage: "doc.text.fill")
                }
                .tag(3)
                
            // Settings Tab
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(4)
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                HomeButtonLink()
            }
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Back")
                }
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}