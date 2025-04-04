import SwiftUI
import SwiftData
import Combine

// Import the phone formatter service
import Foundation

// Client Picker for use in Invoice and Document Generator
struct ClientPickerView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allClients: [Client]
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedClient: Client?
    @State private var searchText = ""
    @State private var showingAddClient = false
    
    var filteredClients: [Client] {
        if searchText.isEmpty {
            return allClients
        } else {
            return allClients.filter { client in
                client.name.localizedCaseInsensitiveContains(searchText) ||
                client.email?.localizedCaseInsensitiveContains(searchText) ?? false ||
                client.phone?.localizedCaseInsensitiveContains(searchText) ?? false
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredClients) { client in
                    ClientRow(client: client)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedClient = client
                            dismiss()
                        }
                }
            }
            .searchable(text: $searchText, prompt: "Search clients...")
            .navigationTitle("Select Client")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddClient = true }) {
                        Label("Add Client", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddClient) {
                ClientFormView(mode: .add) { newClient in
                    modelContext.insert(newClient)
                    try? modelContext.save()
                    selectedClient = newClient
                    dismiss()
                }
            }
        }
    }
}

struct ClientsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.isPresented) private var isPresented
    
    // Use a fully explicit fetch descriptor for better stability
    @Query(FetchDescriptor<Client>(sortBy: [SortDescriptor<Client>(\.name)])) 
    private var clients: [Client]
    @State private var searchText = ""
    @State private var showingAddClient = false
    @State private var selectedClient: Client?
    @State private var showingEditSheet = false
    @State private var showingDeleteConfirmation = false
    @State private var sortOrder: SortOrder = .nameAsc
    @State private var searchDebounceTimer: Timer?
    
    // Disabled recent searches storage
    private var recentSearchesData: Data = Data()
    
    // Empty recent searches
    private var recentSearches: [String] {
        return []
    }
    
    // Disabled - do nothing
    private func updateRecentSearches(_ searches: [String]) {
        // Search history disabled
    }
    
    enum SortOrder {
        case nameAsc
        case nameDesc
        case dateCreatedDesc
        case dateCreatedAsc
    }
    
    // Changed from computed property to state property with update method
    @State private var filteredClients: [Client] = []
    
    private func updateFilteredClients() {
        // If search text is empty or only whitespace, show all clients
        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            filteredClients = clients.sorted(by: sortOrderComparator)
        } else {
            // Normalize search text by trimming and lowercasing
            let normalizedSearchText = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            
            // Expanded search to include more fields
            filteredClients = clients.filter { client in
                client.name.lowercased().contains(normalizedSearchText) ||
                client.email?.lowercased().contains(normalizedSearchText) ?? false ||
                client.phone?.lowercased().contains(normalizedSearchText) ?? false ||
                client.address.lowercased().contains(normalizedSearchText) ||
                client.city.lowercased().contains(normalizedSearchText) ||
                client.postalCode.lowercased().contains(normalizedSearchText) ||
                client.country.lowercased().contains(normalizedSearchText) ||
                client.notes?.lowercased().contains(normalizedSearchText) ?? false
            }.sorted(by: sortOrderComparator)
        }
    }
    
    // Helper function to determine sort order
    private func sortOrderComparator(_ a: Client, _ b: Client) -> Bool {
        switch sortOrder {
        case .nameAsc:
            return a.name < b.name
        case .nameDesc:
            return a.name > b.name
        case .dateCreatedDesc:
            return a.createdAt > b.createdAt
        case .dateCreatedAsc:
            return a.createdAt < b.createdAt
        }
    }
    
    // Disabled - do nothing
    private func saveSearch(_ query: String) {
        // Search history disabled
    }
    
    var body: some View {
        NavigationStack {
            // Add a hidden back button that can be triggered programmatically
            // This helps with swipe gesture navigation
            Group {
                if clients.isEmpty {
                    ContentUnavailableView {
                        Label("No Clients", systemImage: "person.2.slash")
                    } description: {
                        Text("Add your first client to get started.")
                    } actions: {
                        Button(action: { showingAddClient = true }) {
                            Text("Add Client")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else {
                    VStack(spacing: 0) {
                        // Fixed search bar at the top
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.secondary)
                            TextField("Search clients...", text: $searchText)
                                .disableAutocorrection(true)
                                .textInputAutocapitalization(.never)
                                .submitLabel(.search)
                            
                            if !searchText.isEmpty {
                                Button(action: {
                                    searchText = ""
                                    updateFilteredClients()
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal)
                        .background(Color(UIColor.secondarySystemBackground))
                        
                        // Regular list below the search bar
                        List {
                            ForEach(filteredClients) { client in
                                // Use NavigationLink instead of tap gesture for reliable navigation
                                NavigationLink(destination: 
                                    ClientDetailView(client: client)
                                ) {
                                    ClientRow(client: client)
                                        .contentShape(Rectangle())
                                }
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        selectedClient = client
                                        showingDeleteConfirmation = true
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                        }
                    }
                    
                    // Removed search suggestions overlay
                    
                    .onChange(of: searchText) { oldValue, newValue in
                        // Cancel any existing timer
                        searchDebounceTimer?.invalidate()
                        
                        // Set a new timer to process the search after a short delay
                        searchDebounceTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { _ in
                            // Update filtered clients with the new search text
                            updateFilteredClients()
                            
                            // Save the search if there's meaningful content
                            if !newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                saveSearch(newValue)
                            }
                            searchDebounceTimer = nil
                        }
                    }
                    .onAppear {
                        // Initialize filtered clients when view appears
                        updateFilteredClients()
                    }
                }
            }
            .navigationTitle("Clients")
            .toolbar {
                ToolbarItem(placement: .principal) {
                    NavigationLink(destination: MainMenuView()) {
                        Image(systemName: "house.fill")
                            .imageScale(.large)
                            .foregroundColor(.accentColor)
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        Menu {
                            Button {
                                sortOrder = .nameAsc
                            } label: {
                                Label("Name (A to Z)", systemImage: "arrow.up.doc")
                            }
                            
                            Button {
                                sortOrder = .nameDesc
                            } label: {
                                Label("Name (Z to A)", systemImage: "arrow.down.doc")
                            }
                            
                            Button {
                                sortOrder = .dateCreatedDesc
                            } label: {
                                Label("Newest First", systemImage: "calendar.badge.clock")
                            }
                            
                            Button {
                                sortOrder = .dateCreatedAsc
                            } label: {
                                Label("Oldest First", systemImage: "calendar")
                            }
                        } label: {
                            Label("Sort", systemImage: "arrow.up.arrow.down")
                        }
                        
                        Button(action: { showingAddClient = true }) {
                            Label("Add Client", systemImage: "plus")
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAddClient) {
                ClientFormView(mode: .add) { newClient in
                    addClient(newClient)
                }
            }
            .sheet(isPresented: $showingEditSheet) {
                if let client = selectedClient {
                    ClientFormView(mode: .edit, client: client) { updatedClient in
                        updateClient(client: client, with: updatedClient)
                    }
                } else {
                    Text("No client selected")
                        .font(.headline)
                        .padding()
                        .onAppear {
                            // Automatically dismiss if no client is selected
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                showingEditSheet = false
                            }
                        }
                }
            }
            // Use a stable identifier instead of forcing redraw with UUID
            .id("clients-view")
            .alert("Delete Client", isPresented: $showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    if let client = selectedClient {
                        deleteClient(client)
                    }
                }
            } message: {
                Text("Are you sure you want to delete this client? This action cannot be undone.")
            }
        }
    }
    
    private func addClient(_ client: Client) {
        modelContext.insert(client)
        try? modelContext.save()
    }
    
    private func updateClient(client: Client, with updatedData: Client) {
        client.name = updatedData.name
        client.email = updatedData.email
        client.phone = updatedData.phone
        client.address = updatedData.address
        client.city = updatedData.city
        client.country = updatedData.country
        client.postalCode = updatedData.postalCode
        client.notes = updatedData.notes
        client.updatedAt = Date()
        
        try? modelContext.save()
    }
    
    private func deleteClient(_ client: Client) {
        modelContext.delete(client)
        try? modelContext.save()
    }
}

// New view dedicated to viewing client details with NavigationLink
struct ClientDetailView: View {
    let client: Client
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var showingEditSheet = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header with client name
                Text(client.name)
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.horizontal)
                
                // Contact information section
                GroupBox(label: Label("Contact Information", systemImage: "person.fill")) {
                    VStack(alignment: .leading, spacing: 12) {
                        if let email = client.email, !email.isEmpty {
                            HStack {
                                Image(systemName: "envelope")
                                    .frame(width: 24)
                                Text(email)
                                Spacer()
                            }
                        }
                        
                        if let phone = client.phone, !phone.isEmpty {
                            // Format phone number
                            let formattedPhone = PhoneFormatterService.format(phone) ?? phone
                            HStack {
                                Image(systemName: "phone")
                                    .frame(width: 24)
                                Text(formattedPhone)
                                Spacer()
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                .padding(.horizontal)
                
                // Address information
                GroupBox(label: Label("Address", systemImage: "location.fill")) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(client.address)
                        
                        HStack {
                            if !client.city.isEmpty {
                                Text(client.city)
                            }
                            if !client.postalCode.isEmpty {
                                Text(client.postalCode)
                            }
                        }
                        
                        Text(client.country)
                    }
                    .padding(.vertical, 8)
                }
                .padding(.horizontal)
                
                // Notes section (if available)
                if let notes = client.notes, !notes.isEmpty {
                    GroupBox(label: Label("Notes", systemImage: "note.text")) {
                        Text(notes)
                            .padding(.vertical, 8)
                    }
                    .padding(.horizontal)
                }
                
                // Metadata section
                GroupBox(label: Label("Additional Information", systemImage: "info.circle")) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Created:")
                                .fontWeight(.medium)
                            Spacer()
                            Text(formattedDate(client.createdAt))
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("Last Updated:")
                                .fontWeight(.medium)
                            Spacer()
                            Text(formattedDate(client.updatedAt))
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingEditSheet = true }) {
                    Text("Edit")
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            ClientFormView(mode: .edit, client: client) { updatedClient in
                updateClient(client: client, with: updatedClient)
            }
        }
    }
    
    private func updateClient(client: Client, with updatedData: Client) {
        client.name = updatedData.name
        client.email = updatedData.email
        client.phone = updatedData.phone
        client.address = updatedData.address
        client.city = updatedData.city
        client.country = updatedData.country
        client.postalCode = updatedData.postalCode
        client.notes = updatedData.notes
        client.updatedAt = Date()
        
        try? modelContext.save()
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

struct ClientRow: View {
    let client: Client
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(client.name)
                .font(.headline)
            
            if let email = client.email, !email.isEmpty {
                Label(email, systemImage: "envelope")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if let phone = client.phone, !phone.isEmpty {
                // Use the phone formatter service
                let formattedPhone = PhoneFormatterService.format(phone) ?? phone
                Label(formattedPhone, systemImage: "phone")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(client.address)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                HStack {
                    if !client.city.isEmpty {
                        Text(client.city)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("•")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Text(client.country)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct ClientFormView: View {
    enum FormMode {
        case add
        case edit
    }
    
    let mode: FormMode
    var client: Client?
    var onSave: (Client) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var address = ""
    @State private var city = ""
    @State private var country = "United States"
    @State private var postalCode = ""
    @State private var notes = ""
    @State private var showingCountryPicker = false
    @State private var showingErrors = false
    
    private var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !address.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Client Information")) {
                    TextField("Name *", text: $name)
                    TextField("Email", text: $email)
                    TextField("Phone Number", text: $phone)
                }
                
                Section(header: Text("Address")) {
                    ZStack(alignment: .topLeading) {
                        if address.isEmpty {
                            Text("Street Address *")
                                .foregroundColor(.secondary)
                                .padding(.top, 8)
                        }
                        
                        TextEditor(text: $address)
                            .frame(minHeight: 60)
                    }
                    
                    TextField("City", text: $city)
                    
                    Button(action: {
                        showingCountryPicker = true
                    }) {
                        HStack {
                            Text("Country")
                            Spacer()
                            Text(country)
                                .foregroundColor(.secondary)
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                    .sheet(isPresented: $showingCountryPicker) {
                        CountryPickerView(selectedCountry: $country)
                    }
                    
                    TextField("Postal Code", text: $postalCode)
                }
                
                Section(header: Text("Additional Information")) {
                    ZStack(alignment: .topLeading) {
                        if notes.isEmpty {
                            Text("Notes")
                                .foregroundColor(.secondary)
                                .padding(.top, 8)
                        }
                        
                        TextEditor(text: $notes)
                            .frame(minHeight: 60)
                    }
                }
                
                if showingErrors && !isFormValid {
                    Section {
                        Text("Please fill in all required fields")
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle(mode == .add ? "Add Client" : "Edit Client")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if isFormValid {
                            // Format the phone number before saving
                            let formattedPhone = phone.isEmpty ? nil : PhoneFormatterService.format(phone)
                            
                            let newClient = Client(
                                name: name,
                                email: email.isEmpty ? nil : email,
                                phone: formattedPhone,
                                address: address,
                                city: city,
                                country: country,
                                postalCode: postalCode,
                                notes: notes.isEmpty ? nil : notes
                            )
                            onSave(newClient)
                            dismiss()
                        } else {
                            showingErrors = true
                        }
                    }
                }
            }
            .onAppear {
                if let client = client, mode == .edit {
                    name = client.name
                    email = client.email ?? ""
                    phone = client.phone ?? ""
                    address = client.address
                    city = client.city
                    country = client.country
                    postalCode = client.postalCode
                    notes = client.notes ?? ""
                }
            }
        }
    }
}