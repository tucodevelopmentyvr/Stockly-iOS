import SwiftUI
import SwiftData

struct MoreMenuView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selection: String? = nil
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink(destination: BillsView(modelContext: modelContext)) {
                        Label("Bills & Expenses", systemImage: "creditcard.fill")
                    }
                    
                    NavigationLink(destination: Text("Reports").padding()) {
                        Label("Reports", systemImage: "chart.bar.fill")
                    }
                    
                    NavigationLink(destination: Text("Backup & Restore").padding()) {
                        Label("Backup & Restore", systemImage: "arrow.triangle.2.circlepath")
                    }
                } header: {
                    Text("Additional Features")
                }
                
                Section {
                    NavigationLink(destination: SettingsView()) {
                        Label("Settings", systemImage: "gear")
                    }
                    
                    NavigationLink(destination: HelpView()) {
                        Label("Help & Support", systemImage: "questionmark.circle")
                    }
                } header: {
                    Text("App Settings")
                }
            }
            .navigationTitle("More")
        }
    }
}

#Preview {
    MoreMenuView()
        .modelContainer(for: [Item.self])
}
