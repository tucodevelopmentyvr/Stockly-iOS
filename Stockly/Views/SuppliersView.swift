import SwiftUI
import SwiftData
import Combine

// Import the phone formatter service
import Foundation

struct SuppliersView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.isPresented) private var isPresented
    
    // Use a fully explicit fetch descriptor for better stability
    @Query(FetchDescriptor<Supplier>(sortBy: [SortDescriptor<Supplier>(\.name)]))
    private var suppliers: [Supplier]
    @State private var searchText = ""
    @State private var showingAddSupplier = false
    @State private var selectedSupplier: Supplier?
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
    @State private var filteredSuppliers: [Supplier] = []
    
    private func updateFilteredSuppliers() {
        // If search text is empty or only whitespace, show all suppliers
        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            filteredSuppliers = suppliers.sorted(by: sortOrderComparator)
        } else {
            // Normalize search text by trimming and lowercasing
            let normalizedSearchText = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            
            // Split search into words for more comprehensive matching
            let searchWords = normalizedSearchText.split(separator: " ").map(String.init)
            
            filteredSuppliers = suppliers.filter { supplier in
                // Check if any word in the search matches any field
                searchWords.contains { word in
                    supplier.name.lowercased().contains(word) ||
                    supplier.email?.lowercased().contains(word) ?? false ||
                    supplier.phone?.lowercased().contains(word) ?? false ||
                    supplier.address.lowercased().contains(word) ||
                    supplier.city.lowercased().contains(word) ||
                    supplier.postalCode.lowercased().contains(word) ||
                    supplier.country.lowercased().contains(word) ||
                    supplier.contactPerson?.lowercased().contains(word) ?? false ||
                    supplier.notes?.lowercased().contains(word) ?? false
                }
            }.sorted(by: sortOrderComparator)
        }
    }
    
    // Helper function to determine sort order
    private func sortOrderComparator(_ a: Supplier, _ b: Supplier) -> Bool {
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
                if suppliers.isEmpty {
                    ContentUnavailableView {
                        Label("No Suppliers", systemImage: "box.truck.badge.xmark")
                    } description: {
                        Text("Add your first supplier to get started.")
                    } actions: {
                        Button(action: { showingAddSupplier = true }) {
                            Text("Add Supplier")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else {
                    VStack(spacing: 0) {
                        // Fixed search bar at the top
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.secondary)
                            TextField("Search suppliers...", text: $searchText)
                                .disableAutocorrection(true)
                                .textInputAutocapitalization(.never)
                                .submitLabel(.search)
                            
                            if !searchText.isEmpty {
                                Button(action: {
                                    searchText = ""
                                    updateFilteredSuppliers()
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
                            ForEach(filteredSuppliers) { supplier in
                                // Use NavigationLink instead of tap gesture for reliable navigation
                                NavigationLink(destination: 
                                    SupplierDetailView(supplier: supplier)
                                ) {
                                    SupplierRow(supplier: supplier)
                                        .contentShape(Rectangle())
                                }
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        selectedSupplier = supplier
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
                            // Update filtered suppliers with the new search text
                            updateFilteredSuppliers()
                            
                            // Save the search if there's meaningful content
                            if !newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                saveSearch(newValue)
                            }
                            searchDebounceTimer = nil
                        }
                    }
                    .onAppear {
                        // Initialize filtered suppliers when view appears
                        updateFilteredSuppliers()
                    }
                }
            }
            .navigationTitle("Suppliers")
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
                        
                        Button(action: { showingAddSupplier = true }) {
                            Label("Add Supplier", systemImage: "plus")
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAddSupplier) {
                SupplierFormView(mode: .add) { newSupplier in
                    addSupplier(newSupplier)
                }
            }
            .sheet(isPresented: $showingEditSheet) {
                if let supplier = selectedSupplier {
                    SupplierFormView(mode: .edit, supplier: supplier) { updatedSupplier in
                        updateSupplier(supplier: supplier, with: updatedSupplier)
                    }
                } else {
                    // Handle the case where no supplier is selected
                    Text("No supplier selected")
                        .font(.headline)
                        .padding()
                        .onAppear {
                            // Dismiss the sheet after a short delay
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                showingEditSheet = false
                            }
                        }
                }
            }
            // Use a stable identifier instead of forcing redraw with UUID
            .id("suppliers-view")
            .alert("Delete Supplier", isPresented: $showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    if let supplier = selectedSupplier {
                        deleteSupplier(supplier)
                    }
                }
            } message: {
                Text("Are you sure you want to delete this supplier? This action cannot be undone.")
            }
        }
    }
    
    private func addSupplier(_ supplier: Supplier) {
        modelContext.insert(supplier)
        try? modelContext.save()
    }
    
    private func updateSupplier(supplier: Supplier, with updatedData: Supplier) {
        supplier.name = updatedData.name
        supplier.email = updatedData.email
        supplier.phone = updatedData.phone
        supplier.address = updatedData.address
        supplier.city = updatedData.city
        supplier.country = updatedData.country
        supplier.postalCode = updatedData.postalCode
        supplier.contactPerson = updatedData.contactPerson
        supplier.notes = updatedData.notes
        supplier.updatedAt = Date()
        
        try? modelContext.save()
    }
    
    private func deleteSupplier(_ supplier: Supplier) {
        modelContext.delete(supplier)
        try? modelContext.save()
    }
}

// New view dedicated to viewing supplier details with NavigationLink
struct SupplierDetailView: View {
    let supplier: Supplier
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var showingEditSheet = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header with supplier name
                Text(supplier.name)
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.horizontal)
                
                // Contact person information
                if let contactPerson = supplier.contactPerson, !contactPerson.isEmpty {
                    GroupBox(label: Label("Contact Person", systemImage: "person.fill")) {
                        Text(contactPerson)
                            .padding(.vertical, 8)
                    }
                    .padding(.horizontal)
                }
                
                // Contact information section
                GroupBox(label: Label("Contact Information", systemImage: "building.2.fill")) {
                    VStack(alignment: .leading, spacing: 12) {
                        if let email = supplier.email, !email.isEmpty {
                            HStack {
                                Image(systemName: "envelope")
                                    .frame(width: 24)
                                Text(email)
                                Spacer()
                            }
                        }
                        
                        if let phone = supplier.phone, !phone.isEmpty {
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
                        Text(supplier.address)
                        
                        HStack {
                            if !supplier.city.isEmpty {
                                Text(supplier.city)
                            }
                            if !supplier.postalCode.isEmpty {
                                Text(supplier.postalCode)
                            }
                        }
                        
                        Text(supplier.country)
                    }
                    .padding(.vertical, 8)
                }
                .padding(.horizontal)
                
                // Notes section (if available)
                if let notes = supplier.notes, !notes.isEmpty {
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
                            Text(formattedDate(supplier.createdAt))
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("Last Updated:")
                                .fontWeight(.medium)
                            Spacer()
                            Text(formattedDate(supplier.updatedAt))
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
            SupplierFormView(mode: .edit, supplier: supplier) { updatedSupplier in
                updateSupplier(supplier: supplier, with: updatedSupplier)
            }
        }
    }
    
    private func updateSupplier(supplier: Supplier, with updatedData: Supplier) {
        supplier.name = updatedData.name
        supplier.email = updatedData.email
        supplier.phone = updatedData.phone
        supplier.address = updatedData.address
        supplier.city = updatedData.city
        supplier.country = updatedData.country
        supplier.postalCode = updatedData.postalCode
        supplier.contactPerson = updatedData.contactPerson
        supplier.notes = updatedData.notes
        supplier.updatedAt = Date()
        
        try? modelContext.save()
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

struct SupplierRow: View {
    let supplier: Supplier
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(supplier.name)
                .font(.headline)
            
            if let contactPerson = supplier.contactPerson, !contactPerson.isEmpty {
                Label(contactPerson, systemImage: "person")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if let email = supplier.email, !email.isEmpty {
                Label(email, systemImage: "envelope")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if let phone = supplier.phone, !phone.isEmpty {
                // Use phone formatter service
                let formattedPhone = PhoneFormatterService.format(phone) ?? phone
                Label(formattedPhone, systemImage: "phone")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(supplier.address)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                HStack {
                    if !supplier.city.isEmpty {
                        Text(supplier.city)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("•")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Text(supplier.country)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct SupplierFormView: View {
    enum FormMode {
        case add
        case edit
    }
    
    let mode: FormMode
    var supplier: Supplier?
    var onSave: (Supplier) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var address = ""
    @State private var city = ""
    @State private var country = "United States"
    @State private var postalCode = ""
    @State private var contactPerson = ""
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
                Section(header: Text("Supplier Information")) {
                    TextField("Company Name *", text: $name)
                    TextField("Contact Person", text: $contactPerson)
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
            .navigationTitle(mode == .add ? "Add Supplier" : "Edit Supplier")
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
                            
                            let newSupplier = Supplier(
                                name: name,
                                email: email.isEmpty ? nil : email,
                                phone: formattedPhone,
                                address: address,
                                city: city,
                                country: country,
                                postalCode: postalCode,
                                contactPerson: contactPerson.isEmpty ? nil : contactPerson,
                                notes: notes.isEmpty ? nil : notes
                            )
                            onSave(newSupplier)
                            dismiss()
                        } else {
                            showingErrors = true
                        }
                    }
                }
            }
            .onAppear {
                if let supplier = supplier, mode == .edit {
                    name = supplier.name
                    email = supplier.email ?? ""
                    phone = supplier.phone ?? ""
                    address = supplier.address
                    city = supplier.city
                    country = supplier.country
                    postalCode = supplier.postalCode
                    contactPerson = supplier.contactPerson ?? ""
                    notes = supplier.notes ?? ""
                }
            }
        }
    }
}