import SwiftUI
import SwiftData

// Custom field for document generation
struct DocumentCustomField: Identifiable {
    var id: UUID
    var name: String
    var value: String
}

// MARK: - Main Document Generator View
struct DocumentGeneratorView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel: DocumentViewModel
    @State private var showingItemPicker = false
    @State private var showingPreview = false
    @State private var isGenerating = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    init(modelContext: ModelContext) {
        let inventoryService = InventoryService(modelContext: modelContext)
        _viewModel = StateObject(wrappedValue: DocumentViewModel(inventoryService: inventoryService))
    }
    
    // Breaking the view into smaller components to help the compiler
    var body: some View {
        DocumentFormContent(
            viewModel: viewModel,
            showingItemPicker: $showingItemPicker,
            showingPreview: $showingPreview,
            isGenerating: $isGenerating,
            showingAlert: $showingAlert,
            alertMessage: $alertMessage,
            generateDocument: generateDocument
        )
    }
    
    private func generateDocument() {
        isGenerating = true
        
        viewModel.generateDocument { result in
            isGenerating = false
            
            switch result {
            case .success:
                showingPreview = true
            case .failure(let error):
                alertMessage = "Failed to generate document: \(error.localizedDescription)"
                showingAlert = true
            }
        }
    }
}

// MARK: - Form Content View
struct DocumentFormContent: View {
    @ObservedObject var viewModel: DocumentViewModel
    @Binding var showingItemPicker: Bool
    @Binding var showingPreview: Bool
    @Binding var isGenerating: Bool
    @Binding var showingAlert: Bool
    @Binding var alertMessage: String
    @State private var showClientPicker = false
    var generateDocument: () -> Void
    
    var body: some View {
        NavigationStack {
            Form {
                // Document Type
                Section(header: Text("Document Type")) {
                    Picker("Type", selection: $viewModel.documentType) {
                        Text("Invoice").tag(DocumentType.invoice)
                        Text("Consignment").tag(DocumentType.consignment)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                // Note: Theme selection removed - now using default theme from Settings
                
                // Document Information
                Section(header: Text("Document Information")) {
                    HStack {
                        Text("Number")
                        Spacer()
                        TextField("", text: $viewModel.documentNumber)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    DatePicker("Date", selection: $viewModel.documentDate, displayedComponents: [.date])
                    
                    if viewModel.documentType == .invoice {
                        DatePicker("Due Date", selection: $viewModel.dueDate, displayedComponents: [.date])
                    }
                }
                
                // Recipient Information
                Section(header: Text("Recipient Information")) {
                    HStack {
                        TextField("Recipient Name", text: $viewModel.recipientName)
                        
                        // Client selection button
                        Button(action: {
                            showClientPicker = true
                        }) {
                            Image(systemName: "person.fill.badge.plus")
                                .foregroundColor(.accentColor)
                        }
                        .buttonStyle(.borderless)
                    }
                    
                    TextField("Phone Number", text: $viewModel.clientPhone)
                        .keyboardType(.phonePad)
                    
                    TextField("Email Address", text: $viewModel.clientEmail)
                        .keyboardType(.emailAddress)
                    
                    ZStack(alignment: .topLeading) {
                        if viewModel.recipientAddress.isEmpty {
                            Text("Recipient Address")
                                .foregroundColor(.secondary)
                                .padding(.top, 8)
                        }
                        
                        TextEditor(text: $viewModel.recipientAddress)
                            .frame(minHeight: 60)
                    }
                    
                    TextField("City", text: $viewModel.clientCity)
                    
                    TextField("Country", text: $viewModel.clientCountry)
                    
                    TextField("Postal Code", text: $viewModel.clientPostalCode)
                    
                    Picker("Payment Method", selection: $viewModel.paymentMethod) {
                        Text("Cash").tag("Cash")
                        Text("Credit Card").tag("Credit Card")
                        Text("Debit Card").tag("Debit Card")
                        Text("Bank Transfer").tag("Bank Transfer")
                        Text("Check").tag("Check")
                        Text("Payment App").tag("Payment App")
                        Text("Other").tag("Other")
                    }
                }
                
                // Items
                Section(header: Text("Items")) {
                    DocumentItemsView(viewModel: viewModel, showItemPicker: $showingItemPicker)
                }
                
                // Discounts & Taxes
                Section(header: Text("Discounts & Taxes")) {
                    Picker("Discount Type", selection: $viewModel.discountType) {
                        Text("Percentage (%)").tag("percentage")
                        Text("Fixed Amount ($)").tag("fixed")
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    HStack {
                        Text(viewModel.discountType == "percentage" ? "Discount (%)" : "Discount ($)")
                        Spacer()
                        TextField("0.0", text: $viewModel.discountValue)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }
                    
                    HStack {
                        Text("Tax Rate (%)")
                        Spacer()
                        TextField("0.0", text: $viewModel.taxRate)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }
                    
                    HStack {
                        Text("Rounding Adjustment")
                        Spacer()
                        Stepper(String(format: "$%.2f", viewModel.roundingAdjustment), 
                                value: $viewModel.roundingAdjustment, 
                                in: -1.0...1.0,
                                step: 0.01)
                    }
                }
                
                // Additional Information
                Section(header: Text("Additional Information")) {
                    ZStack(alignment: .topLeading) {
                        if viewModel.notes.isEmpty {
                            Text("Notes")
                                .foregroundColor(.secondary)
                                .padding(.top, 8)
                        }
                        
                        TextEditor(text: $viewModel.notes)
                            .frame(minHeight: 60)
                    }
                    
                    ZStack(alignment: .topLeading) {
                        if viewModel.headerNote.isEmpty {
                            Text("Header Note")
                                .foregroundColor(.secondary)
                                .padding(.top, 8)
                        }
                        
                        TextEditor(text: $viewModel.headerNote)
                            .frame(minHeight: 60)
                    }
                    
                    ZStack(alignment: .topLeading) {
                        if viewModel.footerNote.isEmpty {
                            Text("Footer Note")
                                .foregroundColor(.secondary)
                                .padding(.top, 8)
                        }
                        
                        TextEditor(text: $viewModel.footerNote)
                            .frame(minHeight: 60)
                    }
                    
                    ZStack(alignment: .topLeading) {
                        if viewModel.disclaimer.isEmpty {
                            Text("Disclaimer")
                                .foregroundColor(.secondary)
                                .padding(.top, 8)
                        }
                        
                        TextEditor(text: $viewModel.disclaimer)
                            .frame(minHeight: 60)
                    }
                    
                    Button(action: {
                        // Show signature pad
                    }) {
                        HStack {
                            Text("Signature")
                            Spacer()
                            Text(viewModel.signature != nil ? "Signed" : "Not Signed")
                                .foregroundColor(viewModel.signature != nil ? .green : .gray)
                        }
                    }
                    
                    Toggle("Include Signature", isOn: $viewModel.includeSignature)
                    
                    Button(action: {
                        // Add custom field type definition outside
                        let newField = DocumentCustomField(id: UUID(), name: "Custom Field", value: "")
                        viewModel.customFields.append(newField)
                    }) {
                        Label("Add Custom Field", systemImage: "plus.circle")
                    }
                    
                    ForEach(viewModel.customFields, id: \.id) { field in
                        HStack {
                            TextField("Field Name", text: Binding(
                                get: { field.name },
                                set: { newValue in
                                    if let index = viewModel.customFields.firstIndex(where: { $0.id == field.id }) {
                                        viewModel.customFields[index].name = newValue
                                    }
                                }
                            ))
                            
                            TextField("Value", text: Binding(
                                get: { field.value },
                                set: { newValue in
                                    if let index = viewModel.customFields.firstIndex(where: { $0.id == field.id }) {
                                        viewModel.customFields[index].value = newValue
                                    }
                                }
                            ))
                        }
                    }
                }
                
                // Buttons Section
                Section {
                    VStack(spacing: 15) {
                        Button(action: generateDocument) {
                            if isGenerating {
                                HStack {
                                    Spacer()
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle())
                                    Spacer()
                                }
                            } else {
                                Text("Generate PDF")
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .fontWeight(.semibold)
                            }
                        }
                        .disabled(isGenerating || viewModel.selectedItems.isEmpty || viewModel.recipientName.isEmpty)
                        .listRowBackground(Color.accentColor)
                        .foregroundColor(.white)
                        
                        Button(action: {
                            viewModel.finalizeAndSave()
                            alertMessage = "Invoice has been saved"
                            showingAlert = true
                        }) {
                            Text("Finalize & Save")
                                .frame(maxWidth: .infinity, alignment: .center)
                                .fontWeight(.semibold)
                        }
                        .disabled(isGenerating || viewModel.selectedItems.isEmpty || viewModel.recipientName.isEmpty)
                        .buttonStyle(.borderedProminent)
                        .tint(.green)
                        
                        Button(action: {
                            // Share functionality
                            if viewModel.generatedPDFURL != nil {
                                // We have a PDF to share - would implement sharing here
                                alertMessage = "Sharing functionality would be implemented here"
                                showingAlert = true
                            } else {
                                generateDocument()
                                alertMessage = "Generate PDF first before sharing"
                                showingAlert = true
                            }
                        }) {
                            Label("Share Invoice", systemImage: "square.and.arrow.up")
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                        .disabled(isGenerating)
                        .buttonStyle(.bordered)
                    }
                }
            }
            .navigationTitle(viewModel.documentType == .invoice ? "Create Invoice" : "Create Consignment")
            .sheet(isPresented: $showingItemPicker) {
                ItemPickerView(
                    inventoryItems: viewModel.availableItems,
                    selectedItems: $viewModel.selectedItems
                )
            }
            .sheet(isPresented: $showingPreview) {
                if let pdfURL = viewModel.generatedPDFURL {
                    EnhancedPDFPreviewView(url: pdfURL)
                }
            }
            .sheet(isPresented: $showClientPicker) {
                ClientPickerView(selectedClient: Binding(
                    get: { viewModel.selectedClient },
                    set: { client in
                        viewModel.selectedClient = client
                        if let client = client {
                            viewModel.recipientName = client.name
                            viewModel.recipientAddress = client.address
                            viewModel.clientCity = client.city
                            viewModel.clientCountry = client.country
                            viewModel.clientPostalCode = client.postalCode
                            viewModel.clientEmail = client.email ?? ""
                            viewModel.clientPhone = client.phone ?? ""
                        }
                    }
                ))
            }
            .alert(isPresented: $showingAlert) {
                Alert(
                    title: Text("Notification"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
        .onAppear {
            viewModel.loadItems()
            viewModel.loadCompanyInfo()
        }
    }
}

// MARK: - Document Items View
struct DocumentItemsView: View {
    @ObservedObject var viewModel: DocumentViewModel
    @Binding var showItemPicker: Bool
    
    var body: some View {
        VStack {
            if viewModel.selectedItems.isEmpty {
                Text("No items added")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 10)
            } else {
                ForEach(Array(zip(viewModel.selectedItems.indices, viewModel.selectedItems)), id: \.0) { index, item in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.name)
                                .font(.headline)
                            
                            Text("Qty: \(item.quantity)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Text(String(format: "$%.2f", item.unitPrice * Double(item.quantity)))
                            .fontWeight(.semibold)
                    }
                }
                .onDelete { indexSet in
                    viewModel.selectedItems.remove(atOffsets: indexSet)
                }
            }
            
            Button(action: {
                showItemPicker = true
            }) {
                Label("Add Items", systemImage: "plus")
            }
        }
    }
}

class DocumentViewModel: ObservableObject {
    @Published var documentType: DocumentType = .invoice
    // Now using default theme from settings
    @Published var theme: DocumentTheme = DocumentTheme(rawValue: UserDefaults.standard.string(forKey: "defaultDocumentTheme") ?? DocumentTheme.classic.rawValue) ?? .classic
    @Published var documentNumber = ""
    @Published var documentDate = Date()
    @Published var dueDate = Date().addingTimeInterval(60*60*24*30) // 30 days from now
    @Published var recipientName = ""
    @Published var recipientAddress = ""
    @Published var clientPhone = ""
    @Published var clientEmail = ""
    @Published var clientCity = ""
    @Published var selectedClient: Client?
    @Published var clientCountry = "United States"
    @Published var clientPostalCode = ""
    @Published var notes = ""
    @Published var disclaimer = ""
    @Published var includeSignature = false
    @Published var selectedItems: [PDFItem] = []
    @Published var generatedPDFURL: URL?
    @Published var discountType: String
    @Published var discountValue: String
    @Published var taxRate: String
    @Published var paymentMethod = "Bank Transfer"
    @Published var roundingAdjustment: Double = 0.0
    @Published var signature: Data? = nil
    @Published var headerNote = ""
    @Published var footerNote = ""
    @Published var customFields: [DocumentCustomField] = []
    
    private let inventoryService: InventoryService
    let modelContext: ModelContext
    private let pdfService = PDFService()
    
    @Published var availableItems: [Item] = []
    
    // Company information
    private var companyName = ""
    private var companyAddress = ""
    private var companyEmail = ""
    private var companyPhone = ""
    private var companyLogo: UIImage?
    
    init(inventoryService: InventoryService) {
        self.inventoryService = inventoryService
        self.modelContext = inventoryService.modelContext
        
        // Load default tax and discount values from settings
        self.taxRate = UserDefaults.standard.string(forKey: "defaultTaxRate") ?? "0.0"
        self.discountValue = UserDefaults.standard.string(forKey: "defaultDiscountValue") ?? "0.0"
        self.discountType = UserDefaults.standard.string(forKey: "defaultDiscountType") ?? "percentage"
        
        // Generate a document number
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd"
        let dateString = dateFormatter.string(from: Date())
        documentNumber = "\(documentType == .invoice ? "INV" : "CON")-\(dateString)-\(Int.random(in: 1000...9999))"
        
        // Load saved disclaimer if available
        if let savedDisclaimer = UserDefaults.standard.string(forKey: "invoiceDisclaimer") {
            disclaimer = savedDisclaimer
        } else {
            disclaimer = "Thank you for your business."
        }
    }
    
    func finalizeAndSave() {
        // First generate the PDF
        if generatedPDFURL == nil {
            generateDocument { _ in
                self.saveInvoiceToDatabase()
            }
        } else {
            saveInvoiceToDatabase()
        }
    }
    
    private func saveInvoiceToDatabase() {
        // Convert PDFItems to InvoiceItems and update inventory
        let invoiceItems = selectedItems.map { pdfItem -> InvoiceItem in
            // Decrement inventory quantity for this item
            if let inventoryItem = availableItems.first(where: { $0.name == pdfItem.name }) {
                inventoryItem.stockQuantity -= pdfItem.quantity
                // Ensure we don't go below zero
                if inventoryItem.stockQuantity < 0 {
                    inventoryItem.stockQuantity = 0
                }
                try? modelContext.save()
            }
            
            return InvoiceItem(
                name: pdfItem.name,
                description: pdfItem.description,
                quantity: pdfItem.quantity,
                unitPrice: pdfItem.unitPrice
            )
        }
        
        // If a new client was entered, save them to the database
        if selectedClient == nil && !recipientName.isEmpty {
            let newClient = Client(
                name: recipientName,
                email: clientEmail.isEmpty ? nil : clientEmail,
                phone: clientPhone.isEmpty ? nil : clientPhone,
                address: recipientAddress,
                city: clientCity,
                country: clientCountry,
                postalCode: clientPostalCode
            )
            modelContext.insert(newClient)
            try? modelContext.save()
            selectedClient = newClient
        }
        
        // Create new Invoice object
        let invoice = Invoice(
            number: documentNumber,
            clientName: recipientName,
            clientAddress: recipientAddress,
            clientEmail: clientEmail.isEmpty ? nil : clientEmail,
            clientPhone: clientPhone.isEmpty ? nil : clientPhone,
            status: .pending,
            paymentMethod: "Bank Transfer", // Default payment method
            documentType: documentType == .invoice ? "invoice" : "consignment",
            dateCreated: documentDate,
            dueDate: dueDate,
            items: invoiceItems,
            notes: notes,
            headerNote: "",
            footerNote: disclaimer,
            templateType: theme.rawValue,
            pdfURL: generatedPDFURL
        )
        
        // Save to database
        modelContext.insert(invoice)
        
        try? modelContext.save()
    }
    
    func loadItems() {
        availableItems = inventoryService.getItems(sortBy: .nameAsc)
    }
    
    func loadCompanyInfo() {
        companyName = UserDefaults.standard.string(forKey: "companyName") ?? ""
        companyAddress = UserDefaults.standard.string(forKey: "companyAddress") ?? ""
        companyEmail = UserDefaults.standard.string(forKey: "companyEmail") ?? ""
        companyPhone = UserDefaults.standard.string(forKey: "companyPhone") ?? ""
        
        if let logoData = UserDefaults.standard.data(forKey: "companyLogo"),
           let logo = UIImage(data: logoData) {
            companyLogo = logo
        }
    }
    
    func generateDocument(completion: @escaping (Result<URL, Error>) -> Void) {
        // Prepare settings
        let settings = PDFSettings(
            documentTitle: documentType == .invoice ? "Invoice" : "Consignment",
            companyLogo: companyLogo,
            companyName: companyName.isEmpty ? "Your Company" : companyName,
            companyAddress: companyAddress.isEmpty ? "Your Address" : companyAddress,
            companyEmail: companyEmail.isEmpty ? "your@email.com" : companyEmail,
            companyPhone: companyPhone.isEmpty ? "Your Phone" : companyPhone,
            recipientName: recipientName,
            recipientAddress: recipientAddress,
            documentNumber: documentNumber,
            documentDate: documentDate,
            dueDate: documentType == .invoice ? dueDate : nil,
            currency: "$",
            items: selectedItems,
            notes: notes.isEmpty ? nil : notes,
            disclaimer: disclaimer.isEmpty ? nil : disclaimer,
            theme: theme,
            includeSignature: includeSignature,
            signatureImage: nil
        )
        
        // Generate PDF
        if let url = pdfService.generatePDF(for: documentType, settings: settings) {
            generatedPDFURL = url
            completion(.success(url))
        } else {
            completion(.failure(NSError(domain: "PDFGenerationError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to generate PDF"])))
        }
    }
}

struct ThemePreviewCard: View {
    let theme: DocumentTheme
    @Binding var selectedTheme: DocumentTheme
    
    var body: some View {
        VStack {
            ZStack {
                Rectangle()
                    .fill(colorForTheme(theme))
                    .frame(width: 80, height: 100)
                    .cornerRadius(8)
                
                VStack(spacing: 4) {
                    Rectangle()
                        .fill(Color.white.opacity(0.7))
                        .frame(width: 60, height: 10)
                    
                    Rectangle()
                        .fill(Color.white.opacity(0.5))
                        .frame(width: 60, height: 60)
                    
                    Rectangle()
                        .fill(Color.white.opacity(0.7))
                        .frame(width: 60, height: 10)
                }
            }
            
            Text(theme.rawValue.capitalized)
                .font(.caption)
                .padding(.top, 4)
        }
        .padding(5)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .stroke(selectedTheme == theme ? Color.accentColor : Color.clear, lineWidth: 2)
        )
        .onTapGesture {
            selectedTheme = theme
        }
    }
    
    private func colorForTheme(_ theme: DocumentTheme) -> Color {
        switch theme {
        case .classic:
            return Color.blue
        case .modern:
            return Color.indigo
        case .minimalist:
            return Color.gray
        case .professional:
            return Color.teal
        case .custom:
            return Color.purple
        }
    }
}

// MARK: - Item Picker View
struct ItemPickerView: View {
    let inventoryItems: [Item]
    @Binding var selectedItems: [PDFItem]
    @State private var quantities: [UUID: Int] = [:]
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    
    var filteredItems: [Item] {
        if searchText.isEmpty {
            return inventoryItems
        } else {
            return inventoryItems.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredItems, id: \.id) { item in
                    ItemPickerRow(
                        item: item,
                        quantity: Binding(
                            get: { quantities[item.id, default: 0] },
                            set: { quantities[item.id] = $0 }
                        ),
                        maxQuantity: item.stockQuantity
                    )
                }
            }
            .searchable(text: $searchText, prompt: "Search items...")
            .navigationTitle("Select Items")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        // Add items with quantity > 0 to selectedItems
                        for (itemId, quantity) in quantities where quantity > 0 {
                            if let item = inventoryItems.first(where: { $0.id == itemId }) {
                                let pdfItem = PDFItem(
                                    name: item.name,
                                    description: item.itemDescription,
                                    quantity: quantity,
                                    unitPrice: item.price
                                )
                                
                                // Check if item already exists in selectedItems
                                if let index = selectedItems.firstIndex(where: { $0.name == item.name }) {
                                    selectedItems[index] = pdfItem
                                } else {
                                    selectedItems.append(pdfItem)
                                }
                            }
                        }
                        dismiss()
                    }
                }
            }
            .onAppear {
                // Initialize quantities with existing selected items
                for selectedItem in selectedItems {
                    if let item = inventoryItems.first(where: { $0.name == selectedItem.name }) {
                        quantities[item.id] = selectedItem.quantity
                    }
                }
            }
        }
    }
}

// MARK: - Item Picker Row
struct ItemPickerRow: View {
    let item: Item
    @Binding var quantity: Int
    let maxQuantity: Int
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.headline)
                
                Text(String(format: "$%.2f", item.price))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Stepper("Qty: \(quantity)", 
                   value: $quantity,
                   in: 0...maxQuantity)
                .fixedSize()
        }
    }
}

// PDF Viewer now uses EnhancedPDFPreviewView from PDFPreviewView.swift

struct ActivityViewController: UIViewControllerRepresentable {
    var activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: applicationActivities
        )
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // Update if needed
    }
}