import SwiftUI
import SwiftData

struct MainTabView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var navigationRouter: NavigationRouter
    @AppStorage("selectedTab") private var selectedTab = 0
    
    var body: some View {
        // Enable swipe-to-navigate for the entire app by default
        MainMenuView()
            .gesture(
                DragGesture(minimumDistance: 50, coordinateSpace: .local)
                    .onEnded { value in
                        // This is just a catch-all gesture for the root view
                        // The actual navigation gestures are handled by SwipeNavigationGestureModifier
                    }
            )
    }
}

// This is kept for backwards compatibility, now DashboardTabView in MainMenuView handles this
struct LegacyTabView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("selectedTab") private var selectedTab = 0
    
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
            
            // Invoices Tab (renamed from Documents)
            DocumentGeneratorView(modelContext: modelContext)
                .tabItem {
                    Label("Invoices", systemImage: "doc.text.fill")
                }
                .tag(2)
            
            // Settings Tab
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(3)
        }
        .onAppear {
            // Set a default appearance for all instances of UITabBar
            let appearance = UITabBarAppearance()
            appearance.configureWithDefaultBackground()
            UITabBar.appearance().standardAppearance = appearance
            
            if #available(iOS 15.0, *) {
                UITabBar.appearance().scrollEdgeAppearance = appearance
            }
        }
    }
}