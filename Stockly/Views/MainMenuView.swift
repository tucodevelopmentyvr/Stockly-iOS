import SwiftUI
import SwiftData

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

struct MainMenuView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.modelContext) private var modelContext
    @AppStorage("darkModeEnabled") private var darkModeEnabled = false
    @State private var selection: String? = nil
    @EnvironmentObject private var navigationRouter: NavigationRouter
    @EnvironmentObject private var subscriptionService: SubscriptionService

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

    // Menu button content extraction for reuse
    @ViewBuilder
    private var menuButtonsContent: some View {
        // Dashboard button moved to first position
        Button(action: {
            selection = "dashboard"
        }) {
            CompactMenuButton(title: "Dashboard", icon: "chart.pie.fill", color: .gray)
        }
        .background(
            NavigationLink("", destination: DashboardTabView()
                .customNavigation(previousPageTitle: "Main Menu"), tag: "dashboard", selection: $selection)
                .opacity(0)
        )

        Button(action: {
            selection = "clients"
        }) {
            CompactMenuButton(title: "Clients", icon: "person.2.fill", color: .blue)
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
            CompactMenuButton(title: "Suppliers", icon: "shippingbox.fill", color: .orange)
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
            CompactMenuButton(title: "Inventory", icon: "cube.box.fill", color: .green)
        }
        .background(
            NavigationLink("", destination: InventoryView(modelContext: modelContext)
                .customNavigation(previousPageTitle: "Main Menu"), tag: "products", selection: $selection)
                .opacity(0)
        )

        Button(action: {
            selection = "invoices"
        }) {
            CompactMenuButton(title: "Invoices", icon: "doc.text.fill", color: .purple)
        }
        .background(
            NavigationLink("", destination: InvoiceManagementView()
                .customNavigation(previousPageTitle: "Main Menu"), tag: "invoices", selection: $selection)
                .opacity(0)
        )

        Button(action: {
            selection = "estimates"
        }) {
            CompactMenuButton(title: "Estimates", icon: "doc.plaintext.fill", color: .indigo)
        }
        .background(
            NavigationLink("", destination: EstimateManagementView()
                .customNavigation(previousPageTitle: "Main Menu"), tag: "estimates", selection: $selection)
                .opacity(0)
        )

        Button(action: {
            selection = "bills"
        }) {
            CompactMenuButton(title: "Bills & Expenses", icon: "creditcard.fill", color: .red)
        }
        .background(
            NavigationLink("", destination: BillsView(modelContext: modelContext)
                .customNavigation(previousPageTitle: "Main Menu"), tag: "bills", selection: $selection)
                .opacity(0)
        )
    }

    // Grid layout for iPad
    @ViewBuilder
    private var menuButtonsGrid: some View {
        // Dashboard
        Button(action: { selection = "dashboard" }) {
            GridMenuButton(title: "Dashboard", icon: "chart.pie.fill", color: .accentColor)
        }
        .background(
            NavigationLink("", destination: DashboardTabView()
                .customNavigation(previousPageTitle: "Main Menu"), tag: "dashboard", selection: $selection)
                .opacity(0)
        )

        // Clients
        Button(action: { selection = "clients" }) {
            GridMenuButton(title: "Clients", icon: "person.2.fill", color: .blue)
        }
        .background(
            NavigationLink("", destination: ClientsView()
                .customNavigation(previousPageTitle: "Main Menu"), tag: "clients", selection: $selection)
                .opacity(0)
        )

        // Suppliers
        Button(action: { selection = "suppliers" }) {
            GridMenuButton(title: "Suppliers", icon: "shippingbox.fill", color: .orange)
        }
        .background(
            NavigationLink("", destination: SuppliersView()
                .customNavigation(previousPageTitle: "Main Menu"), tag: "suppliers", selection: $selection)
                .opacity(0)
        )

        // Inventory
        Button(action: { selection = "products" }) {
            GridMenuButton(title: "Inventory", icon: "cube.box.fill", color: .green)
        }
        .background(
            NavigationLink("", destination: InventoryView(modelContext: modelContext)
                .customNavigation(previousPageTitle: "Main Menu"), tag: "products", selection: $selection)
                .opacity(0)
        )

        // Invoices
        Button(action: { selection = "invoices" }) {
            GridMenuButton(title: "Invoices", icon: "doc.text.fill", color: .purple)
        }
        .background(
            NavigationLink("", destination: InvoiceManagementView()
                .customNavigation(previousPageTitle: "Main Menu"), tag: "invoices", selection: $selection)
                .opacity(0)
        )

        // Estimates
        Button(action: { selection = "estimates" }) {
            GridMenuButton(title: "Estimates", icon: "doc.plaintext.fill", color: .indigo)
        }
        .background(
            NavigationLink("", destination: EstimateManagementView()
                .customNavigation(previousPageTitle: "Main Menu"), tag: "estimates", selection: $selection)
                .opacity(0)
        )

        // Bills & Expenses
        Button(action: { selection = "bills" }) {
            GridMenuButton(title: "Bills & Expenses", icon: "creditcard.fill", color: .red)
        }
        .background(
            NavigationLink("", destination: BillsView(modelContext: modelContext)
                .customNavigation(previousPageTitle: "Main Menu"), tag: "bills", selection: $selection)
                .opacity(0)
        )
    }

    var body: some View {
        // Use NavigationView with stack style to ensure proper animation
        NavigationView {
            // This is a workaround to ensure the back button never appears in the main menu
            ZStack {
                GeometryReader { geometry in
                    // Adapt UI based on device type and orientation
                    let isIPad = UIDevice.current.userInterfaceIdiom == .pad
                    let isLandscape = geometry.size.width > geometry.size.height

                    if isIPad && isLandscape {
                        // iPad Landscape layout with side-by-side sections
                        HStack(spacing: 0) {
                            // Left Panel - Logo and App Info
                            VStack(spacing: 15) {
                                Spacer()

                                Text("Stockly")
                                    .font(.system(size: 40, weight: .bold))

                                Text("Inventory Management System")
                                    .font(.title3)
                                    .foregroundColor(.secondary)

                                Spacer()

                                // Bottom Info
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
                                .padding(.bottom, 20)
                            }
                            .frame(width: geometry.size.width * 0.4)
                            .padding()
                            .background(
                                Color(UIColor.systemBackground)
                                    .edgesIgnoringSafeArea(.all)
                            )

                            // Right Panel - Menu Buttons
                            ScrollView {
                                VStack(spacing: 20) {
                                    menuButtonsContent
                                }
                                .padding(.vertical, 30)
                                .padding(.horizontal)
                            }
                            .frame(width: geometry.size.width * 0.6)
                            .background(
                                Color(UIColor.secondarySystemBackground)
                                    .edgesIgnoringSafeArea(.all)
                            )
                        }
                    } else {
                        // Portrait layout for iPhone and iPad Portrait
                        VStack {
                            // Main content
                            VStack(spacing: 0) {
                                // Header
                                VStack(spacing: 5) {
                                    Text("Stockly")
                                        .font(isIPad ? .system(size: 36, weight: .bold) : .title)
                                        .fontWeight(.bold)

                                    Text("Inventory Management System")
                                        .font(isIPad ? .callout : .caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.top, isIPad ? 10 : 5)
                                .padding(.bottom, isIPad ? 25 : 20)

                                // Main Menu with Grid layout on iPad
                                if isIPad {
                                    // Grid layout for iPad in portrait
                                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                                        menuButtonsGrid
                                    }
                                    .padding(.horizontal)
                                } else {
                                    // Adaptive grid layout for iPhone
                                    let columns = [
                                        GridItem(.flexible())
                                    ]
                                    ScrollView {
                                        LazyVGrid(columns: columns, spacing: 12) {
                                            menuButtonsContent
                                        }
                                        .padding(.horizontal, 5)
                                    }
                                }

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
                        }
                    }
                }
                .preferredColorScheme(darkModeEnabled ? .dark : .light)
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
                    case "bills":
                        BillsView(modelContext: modelContext)
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

// New more compact menu button for better touch targets
struct CompactMenuButton: View {
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
                    .font(.title3)
                    .foregroundColor(color)
                    .frame(width: 30, alignment: .center)

                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.subheadline)
            }
            .padding(.horizontal, 15)
            .padding(.vertical, 12)
        }
        .frame(minHeight: 56)
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

struct GridMenuButton: View {
    var title: String
    var icon: String
    var color: Color

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 15)
                .fill(color.opacity(0.15))
                .shadow(color: color.opacity(0.1), radius: 5, x: 0, y: 3)

            VStack(spacing: 15) {
                Image(systemName: icon)
                    .font(.system(size: 30))
                    .foregroundColor(color)

                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
            }
            .padding()
        }
        .aspectRatio(1.0, contentMode: .fit)
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

            // More Tab
            MoreMenuView()
                .tabItem {
                    Label("More", systemImage: "ellipsis.circle.fill")
                }
                .tag(4)

            // Settings Tab
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(5)
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                HomeButtonLink()
            }
            // Back button removed as requested
        }
        .navigationBarBackButtonHidden(true)
    }
}