import SwiftUI
import SwiftData

struct EstimateGeneratorView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel: EstimateViewModel
    @State private var showingItemPicker = false
    @State private var showingPreview = false
    @State private var isGenerating = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    init(modelContext: ModelContext) {
        let inventoryService = InventoryService(modelContext: modelContext)
        _viewModel = StateObject(wrappedValue: EstimateViewModel(inventoryService: inventoryService))
    }
    
    // Breaking the view into smaller components to help the compiler
    var body: some View {
        EstimateFormContent(
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
struct EstimateFormContent: View {
    @ObservedObject var viewModel: EstimateViewModel
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
                // Note: Theme selection removed - now using default theme from Settings
                
                // Document Information
                Section(header: Text("Estimate Information")) {
                    HStack {
                        Text("Number")
                        Spacer()
                        TextField("", text: $viewModel.documentNumber)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    DatePicker("Date", selection: $viewModel.documentDate, displayedComponents: [.date])
                    DatePicker("Expiry Date", selection: $viewModel.expiryDate, displayedComponents: [.date])
                }
                
                // Recipient Information
                Section(header: Text("Client Information")) {
                    HStack {
                        TextField("Client Name", text: $viewModel.recipientName)
                        
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
                            Text("Client Address")
                                .foregroundColor(.secondary)
                                .padding(.top, 8)
                        }
                        
                        TextEditor(text: $viewModel.recipientAddress)
                            .frame(minHeight: 60)
                    }
                    
                    TextField("City", text: $viewModel.clientCity)
                    TextField("Country", text: $viewModel.clientCountry)
                    TextField("Postal Code", text: $viewModel.clientPostalCode)
                }
                
                // Items
                Section(header: Text("Items")) {
                    EstimateItemsView(viewModel: viewModel, showItemPicker: $showingItemPicker)
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
                            alertMessage = "Estimate has been saved"
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
                                alertMessage = "Sharing functionality would be implemented here"
                                showingAlert = true
                            } else {
                                generateDocument()
                                alertMessage = "Generate PDF first before sharing"
                                showingAlert = true
                            }
                        }) {
                            Label("Share Estimate", systemImage: "square.and.arrow.up")
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                        .disabled(isGenerating)
                        .buttonStyle(.bordered)
                    }
                }
            }
            .navigationTitle("Create Estimate")
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

// MARK: - Estimate Items View
struct EstimateItemsView: View {
    @ObservedObject var viewModel: EstimateViewModel
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

// View model for Estimates
class EstimateViewModel: ObservableObject {
    // Now using default theme from settings
    @Published var theme: DocumentTheme = DocumentTheme(rawValue: UserDefaults.standard.string(forKey: "defaultDocumentTheme") ?? DocumentTheme.classic.rawValue) ?? .classic
    @Published var documentNumber = ""
    @Published var documentDate = Date()
    @Published var expiryDate = Date().addingTimeInterval(60*60*24*30) // 30 days from now
    @Published var recipientName = ""
    @Published var recipientAddress = ""
    @Published var clientPhone = ""
    @Published var clientEmail = ""
    @Published var clientCity = ""
    @Published var selectedClient: Client?
    @Published var clientCountry = "United States"
    @Published var clientPostalCode = ""
    @Published var notes = ""
    @Published var headerNote = ""
    @Published var footerNote = ""
    @Published var selectedItems: [PDFItem] = []
    @Published var generatedPDFURL: URL?
    @Published var discountType: String
    @Published var discountValue: String
    @Published var taxRate: String
    
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
        documentNumber = "EST-\(dateString)-\(Int.random(in: 1000...9999))"
    }
    
    func finalizeAndSave() {
        // First generate the PDF if needed
        if generatedPDFURL == nil {
            generateDocument { _ in
                self.saveEstimateToDatabase()
            }
        } else {
            saveEstimateToDatabase()
        }
    }
    
    private func saveEstimateToDatabase() {
        // Convert PDFItems to EstimateItems
        let estimateItems = selectedItems.map { pdfItem -> EstimateItem in
            return EstimateItem(
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
        
        // Calculate subtotal, discount and tax
        let subtotal = selectedItems.reduce(0.0) { $0 + $1.unitPrice * Double($1.quantity) }
        let discountAmount = discountType == "percentage" ? 
            subtotal * (Double(discountValue) ?? 0) / 100 : 
            Double(discountValue) ?? 0
        let afterDiscount = subtotal - discountAmount
        let taxAmount = afterDiscount * (Double(taxRate) ?? 0) / 100
        _ = afterDiscount + taxAmount // Total amount calculated but used in Estimate init
        
        // Create new Estimate object
        let estimate = Estimate(
            number: documentNumber,
            clientName: recipientName,
            clientAddress: recipientAddress,
            clientEmail: clientEmail.isEmpty ? nil : clientEmail,
            clientPhone: clientPhone.isEmpty ? nil : clientPhone,
            status: .draft,
            dateCreated: documentDate,
            expiryDate: expiryDate,
            items: estimateItems,
            discount: Double(discountValue) ?? 0.0,
            discountType: discountType,
            taxRate: Double(taxRate) ?? 0.0,
            notes: notes,
            headerNote: headerNote.isEmpty ? nil : headerNote,
            footerNote: footerNote.isEmpty ? nil : footerNote,
            templateType: theme.rawValue,
            pdfURL: generatedPDFURL
        )
        
        // Save to database
        modelContext.insert(estimate)
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
    
    // Generate PDF document
    func generateDocument(completion: @escaping (Result<URL, Error>) -> Void) {
        // Prepare settings
        let settings = PDFSettings(
            documentTitle: "Estimate",
            companyLogo: companyLogo,
            companyName: companyName.isEmpty ? "Your Company" : companyName,
            companyAddress: companyAddress.isEmpty ? "Your Address" : companyAddress,
            companyEmail: companyEmail.isEmpty ? "your@email.com" : companyEmail,
            companyPhone: companyPhone.isEmpty ? "Your Phone" : companyPhone,
            recipientName: recipientName,
            recipientAddress: recipientAddress,
            documentNumber: documentNumber,
            documentDate: documentDate,
            dueDate: expiryDate,
            currency: "$",
            items: selectedItems,
            notes: notes.isEmpty ? nil : notes,
            disclaimer: footerNote.isEmpty ? nil : footerNote,
            theme: theme,
            includeSignature: false,
            signatureImage: nil
        )
        
        // Generate PDF
        if let pdfURL = pdfService.generatePDF(for: .estimate, settings: settings) {
            let url = pdfURL
            generatedPDFURL = url
            completion(.success(url))
        } else {
            completion(.failure(NSError(domain: "PDFGenerationError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to generate PDF"])))
        }
    }
}