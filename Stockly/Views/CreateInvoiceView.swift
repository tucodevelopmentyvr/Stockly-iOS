import SwiftUI
import SwiftData

struct CreateInvoiceView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var invoiceNumber = ""
    @State private var clientName = ""
    @State private var clientAddress = ""
    @State private var clientEmail = ""
    @State private var clientPhone = ""
    @State private var clientCity = ""
    @State private var clientCountry = "United States"
    @State private var clientPostalCode = ""
    @State private var selectedClient: Client?
    @State private var showingClientPicker = false
    @State private var issueDate = Date()
    @State private var dueDate = Date().addingTimeInterval(60*60*24*30) // 30 days
    @State private var selectedItems: [InvoiceItemViewModel] = []
    @State private var discount = ""
    @State private var discountType = "percentage" // or "fixed"
    @State private var paymentMethod = "Cash"
    @State private var taxRate = ""
    @State private var notes = ""
    @State private var headerNote = ""
    @State private var footerNote = ""
    @State private var bankingInfo = ""
    @State private var customFields: [CustomFieldViewModel] = []
    @State private var templateType = "standard"
    
    @State private var signature: Data?
    @State private var showingItemSelector = false
    @State private var showingSignatureCapture = false
    @State private var showingAddCustomField = false
    @State private var showingPreview = false
    @State private var isGenerating = false
    @State private var generatedInvoice: Invoice?
    
    // Tax and rounding
    @State private var roundingAdjustment: Double = 0.0
    @AppStorage("defaultTaxRate") private var defaultTaxRate = "0.0"
    
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    @StateObject private var inventoryViewModel: InventoryViewModel
    
    init(modelContext: ModelContext) {
        let inventoryService = InventoryService(modelContext: modelContext)
        _inventoryViewModel = StateObject(wrappedValue: InventoryViewModel(inventoryService: inventoryService))
        
        // Generate invoice number
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd"
        let dateString = dateFormatter.string(from: Date())
        _invoiceNumber = State(initialValue: "INV-\(dateString)-\(Int.random(in: 1000...9999))")
        
        // Load defaults from settings
        _taxRate = State(initialValue: UserDefaults.standard.string(forKey: "defaultTaxRate") ?? "0.0")
        _headerNote = State(initialValue: UserDefaults.standard.string(forKey: "invoiceHeaderNote") ?? "")
        _footerNote = State(initialValue: UserDefaults.standard.string(forKey: "invoiceFooterNote") ?? "")
        _bankingInfo = State(initialValue: UserDefaults.standard.string(forKey: "bankingInfo") ?? "")
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Client Information
                Section(header: Text("Client Information")) {
                    HStack {
                        TextField("Client Name", text: $clientName)
                        
                        // Client selection button
                        Button(action: {
                            showingClientPicker = true
                        }) {
                            Image(systemName: "person.fill.badge.plus")
                                .foregroundColor(.accentColor)
                        }
                        .buttonStyle(.borderless)
                    }
                    
                    ZStack(alignment: .topLeading) {
                        if clientAddress.isEmpty {
                            Text("Client Address")
                                .foregroundColor(.secondary)
                                .padding(.top, 8)
                        }
                        TextEditor(text: $clientAddress)
                            .frame(minHeight: 60)
                    }
                    
                    TextField("City", text: $clientCity)
                    
                    HStack {
                        Text("Country")
                        Spacer()
                        Text(clientCountry)
                            .foregroundColor(.secondary)
                    }
                    
                    TextField("Postal Code", text: $clientPostalCode)
                    
                    TextField("Client Email", text: $clientEmail)
                        .keyboardType(.emailAddress)
                    
                    TextField("Client Phone", text: $clientPhone)
                        .keyboardType(.phonePad)
                }
                
                // Invoice Information
                Section(header: Text("Invoice Details")) {
                    HStack {
                        Text("Invoice #")
                        Spacer()
                        TextField("", text: $invoiceNumber)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    DatePicker("Issue Date", selection: $issueDate, displayedComponents: [.date])
                    DatePicker("Due Date", selection: $dueDate, displayedComponents: [.date])
                    
                    Picker("Payment Method", selection: $paymentMethod) {
                        Text("Cash").tag("Cash")
                        Text("Credit Card").tag("Credit Card")
                        Text("Debit Card").tag("Debit Card")
                        Text("Bank Transfer").tag("Bank Transfer")
                        Text("Check").tag("Check")
                        Text("Payment App").tag("Payment App")
                        Text("Other").tag("Other")
                    }
                }
                
                // Items Section
                Section(header: Text("Items")) {
                    if selectedItems.isEmpty {
                        Text("No items added")
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 10)
                    } else {
                        ForEach(Array(zip(selectedItems.indices, selectedItems)), id: \.0) { index, item in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(item.name)
                                        .font(.headline)
                                    
                                    Spacer()
                                    
                                    Button(action: {
                                        selectedItems[index].isExpanded.toggle()
                                    }) {
                                        Image(systemName: selectedItems[index].isExpanded ? "chevron.up" : "chevron.down")
                                            .foregroundColor(.gray)
                                    }
                                }
                                
                                if selectedItems[index].isExpanded {
                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack {
                                            Text("Quantity:")
                                            TextField("0", text: $selectedItems[index].quantity)
                                                .keyboardType(.numberPad)
                                                .multilineTextAlignment(.trailing)
                                                .onChange(of: selectedItems[index].quantity) { _, _ in
                                                    updateItemTotal(at: index)
                                                }
                                        }
                                        
                                        HStack {
                                            Text("Unit Price: $")
                                            TextField("0.00", text: $selectedItems[index].unitPrice)
                                                .keyboardType(.decimalPad)
                                                .multilineTextAlignment(.trailing)
                                                .onChange(of: selectedItems[index].unitPrice) { _, _ in
                                                    updateItemTotal(at: index)
                                                }
                                        }
                                        
                                        HStack {
                                            Text("Tax: %")
                                            TextField("0.0", text: $selectedItems[index].tax)
                                                .keyboardType(.decimalPad)
                                                .multilineTextAlignment(.trailing)
                                                .onChange(of: selectedItems[index].tax) { _, _ in
                                                    updateItemTotal(at: index)
                                                }
                                        }
                                        
                                        HStack {
                                            Text("Discount: %")
                                            TextField("0.0", text: $selectedItems[index].discount)
                                                .keyboardType(.decimalPad)
                                                .multilineTextAlignment(.trailing)
                                                .onChange(of: selectedItems[index].discount) { _, _ in
                                                    updateItemTotal(at: index)
                                                }
                                        }
                                    }
                                    .padding(.vertical, 8)
                                }
                                
                                HStack {
                                    Text("Total: ")
                                        .foregroundColor(.secondary)
                                    
                                    Spacer()
                                    
                                    Text("$\(calculateItemTotal(item), specifier: "%.2f")")
                                        .fontWeight(.medium)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .onDelete { indices in
                            selectedItems.remove(atOffsets: indices)
                        }
                    }
                    
                    Button(action: {
                        showingItemSelector = true
                    }) {
                        Label("Add Item", systemImage: "plus")
                    }
                }
                
                // Discounts & Taxes
                Section(header: Text("Amounts")) {
                    Picker("Discount Type", selection: $discountType) {
                        Text("Percentage (%)").tag("percentage")
                        Text("Fixed Amount ($)").tag("fixed")
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    HStack {
                        Text(discountType == "percentage" ? "Discount (%)" : "Discount ($)")
                        Spacer()
                        TextField("0.0", text: $discount)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }
                    
                    HStack {
                        Text("Tax Rate (%)")
                        Spacer()
                        TextField("0.0", text: $taxRate)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }
                    
                    HStack {
                        Text("Rounding Adjustment")
                        Spacer()
                        Stepper(String(format: "$%.2f", roundingAdjustment), 
                                value: $roundingAdjustment, 
                                in: -1.0...1.0,
                                step: 0.01)
                    }
                }
                
                // Summary
                Section(header: Text("Summary")) {
                    HStack {
                        Text("Subtotal")
                        Spacer()
                        Text("$\(calculateSubtotal(), specifier: "%.2f")")
                    }
                    
                    HStack {
                        Text(discountType == "percentage" ? 
                             "Discount (\(discount)%)" : 
                             "Discount")
                        Spacer()
                        Text("$\(calculateDiscountAmount(), specifier: "%.2f")")
                            .foregroundColor(.red)
                    }
                    
                    HStack {
                        Text("Tax (\(taxRate)%)")
                        Spacer()
                        Text("$\(calculateTaxAmount(), specifier: "%.2f")")
                    }
                    
                    if roundingAdjustment != 0 {
                        HStack {
                            Text("Rounding")
                            Spacer()
                            Text("$\(roundingAdjustment, specifier: "%.2f")")
                                .foregroundColor(roundingAdjustment > 0 ? .primary : .red)
                        }
                    }
                    
                    Divider()
                    
                    HStack {
                        Text("Total")
                            .fontWeight(.bold)
                        Spacer()
                        Text("$\(calculateTotal(), specifier: "%.2f")")
                            .fontWeight(.bold)
                    }
                }
                
                // Notes
                Section(header: Text("Notes")) {
                    ZStack(alignment: .topLeading) {
                        if notes.isEmpty {
                            Text("Notes for this invoice")
                                .foregroundColor(.secondary)
                                .padding(.top, 8)
                        }
                        TextEditor(text: $notes)
                            .frame(minHeight: 60)
                    }
                }
                
                // Custom Fields
                Section(header: HStack {
                    Text("Custom Fields")
                    Spacer()
                    Button(action: {
                        showingAddCustomField = true
                    }) {
                        Image(systemName: "plus.circle")
                            .foregroundColor(.accentColor)
                    }
                }) {
                    if customFields.isEmpty {
                        Text("No custom fields")
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 10)
                    } else {
                        ForEach(Array(zip(customFields.indices, customFields)), id: \.0) { index, field in
                            HStack {
                                Text(field.name)
                                Spacer()
                                TextField("Value", text: $customFields[index].value)
                                    .multilineTextAlignment(.trailing)
                            }
                        }
                        .onDelete { indices in
                            customFields.remove(atOffsets: indices)
                        }
                    }
                }
                
                // Additional Settings
                Section(header: Text("Additional Settings")) {
                    NavigationLink(destination: InvoiceHeaderFooterView(
                        headerNote: $headerNote,
                        footerNote: $footerNote,
                        bankingInfo: $bankingInfo
                    )) {
                        Text("Header/Footer & Banking Info")
                    }
                    
                    NavigationLink(destination: InvoiceTemplateSelectionView(
                        templateType: $templateType
                    )) {
                        Text("Template Selection")
                    }
                    
                    Button(action: {
                        showingSignatureCapture = true
                    }) {
                        HStack {
                            Text("Add Signature")
                            Spacer()
                            if signature != nil {
                                Text("Signature Added")
                                    .foregroundColor(.green)
                            } else {
                                Text("No Signature")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                // Action Buttons
                Section {
                    VStack(spacing: 12) {
                        Button(action: generateInvoice) {
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
                        .disabled(isGenerating || clientName.isEmpty || selectedItems.isEmpty)
                        .listRowBackground(Color.accentColor)
                        .foregroundColor(.white)
                        
                        Button(action: {
                            finalizeInvoice()
                        }) {
                            Text("Finalize & Save Invoice")
                                .frame(maxWidth: .infinity, alignment: .center)
                                .fontWeight(.semibold)
                        }
                        .disabled(isGenerating || clientName.isEmpty || selectedItems.isEmpty)
                        .listRowBackground(Color.green)
                        .foregroundColor(.white)
                    }
                }
            }
            .navigationTitle("Create Invoice")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingItemSelector) {
                InvoiceItemSelectorView(
                    inventory: inventoryViewModel,
                    selectedItems: $selectedItems
                )
            }
            .sheet(isPresented: $showingSignatureCapture) {
                SignatureCaptureView(signature: $signature)
            }
            .sheet(isPresented: $showingAddCustomField) {
                AddCustomFieldView(customFields: $customFields)
            }
            .sheet(isPresented: $showingPreview) {
                if let invoice = generatedInvoice {
                    InvoicePreviewView(invoice: invoice)
                }
            }
            .sheet(isPresented: $showingClientPicker) {
                ClientPickerView(selectedClient: Binding(
                    get: { selectedClient },
                    set: { client in
                        selectedClient = client
                        if let client = client {
                            clientName = client.name
                            clientAddress = client.address
                            clientCity = client.city
                            clientCountry = client.country
                            clientPostalCode = client.postalCode
                            clientEmail = client.email ?? ""
                            clientPhone = client.phone ?? ""
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
            .onAppear {
                inventoryViewModel.loadItems()
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func updateItemTotal(at index: Int) {
        // Update calculations when values change
        // No implementation needed as we calculate on-the-fly
    }
    
    private func calculateItemTotal(_ item: InvoiceItemViewModel) -> Double {
        guard let quantity = Int(item.quantity), 
              let unitPrice = Double(item.unitPrice),
              let tax = Double(item.tax),
              let discount = Double(item.discount) else {
            return 0.0
        }
        
        let subtotal = Double(quantity) * unitPrice
        let discountAmount = subtotal * (discount / 100)
        let afterDiscount = subtotal - discountAmount
        let taxAmount = afterDiscount * (tax / 100)
        
        return afterDiscount + taxAmount
    }
    
    private func calculateSubtotal() -> Double {
        selectedItems.reduce(0) { $0 + calculateItemTotal($1) }
    }
    
    private func calculateDiscountAmount() -> Double {
        let subtotal = calculateSubtotal()
        if discountType == "percentage" {
            if let discountPercentage = Double(discount) {
                return subtotal * (discountPercentage / 100)
            }
        } else {
            if let fixedDiscount = Double(discount) {
                return fixedDiscount
            }
        }
        return 0.0
    }
    
    private func calculateTaxAmount() -> Double {
        let subtotal = calculateSubtotal()
        let discountAmount = calculateDiscountAmount()
        let afterDiscount = subtotal - discountAmount
        
        if let taxPercentage = Double(taxRate) {
            return afterDiscount * (taxPercentage / 100)
        }
        return 0.0
    }
    
    private func calculateTotal() -> Double {
        let subtotal = calculateSubtotal()
        let discountAmount = calculateDiscountAmount()
        let taxAmount = calculateTaxAmount()
        
        return subtotal - discountAmount + taxAmount + roundingAdjustment
    }
    
    private func finalizeInvoice() {
        isGenerating = true
        
        // Convert view models to model objects and update inventory quantities
        let invoiceItems = selectedItems.compactMap { item -> InvoiceItem? in
            guard let quantity = Int(item.quantity),
                  let unitPrice = Double(item.unitPrice),
                  let tax = Double(item.tax),
                  let discount = Double(item.discount) else {
                return nil
            }
            
            // Decrement inventory quantity for this item
            if let inventoryItem = inventoryViewModel.findItemByName(item.name) {
                inventoryItem.stockQuantity -= quantity
                // Ensure we don't go below zero
                if inventoryItem.stockQuantity < 0 {
                    inventoryItem.stockQuantity = 0
                }
                try? modelContext.save()
            }
            
            return InvoiceItem(
                name: item.name,
                description: item.description,
                quantity: quantity,
                unitPrice: unitPrice,
                tax: tax,
                discount: discount
            )
        }
        
        // If a new client was entered, save them to the database
        if selectedClient == nil && !clientName.isEmpty {
            let newClient = Client(
                name: clientName,
                email: clientEmail.isEmpty ? nil : clientEmail,
                phone: clientPhone.isEmpty ? nil : clientPhone,
                address: clientAddress,
                city: clientCity,
                country: clientCountry,
                postalCode: clientPostalCode
            )
            modelContext.insert(newClient)
            try? modelContext.save()
            selectedClient = newClient
        }
        
        let customFieldModels = customFields.map { field in
            CustomInvoiceField(name: field.name, value: field.value)
        }
        
        let discountValue = Double(discount) ?? 0.0
        let taxRateValue = Double(taxRate) ?? 0.0
        
        // Create finalized invoice
        let invoice = Invoice(
            number: invoiceNumber,
            clientName: clientName,
            clientAddress: clientAddress,
            clientEmail: clientEmail.isEmpty ? nil : clientEmail,
            clientPhone: clientPhone.isEmpty ? nil : clientPhone,
            status: .pending, // Marked as pending instead of draft
            paymentMethod: paymentMethod,
            documentType: "invoice",
            dateCreated: issueDate,
            dueDate: dueDate,
            items: invoiceItems,
            discount: discountValue,
            discountType: discountType,
            taxRate: taxRateValue,
            notes: notes,
            headerNote: headerNote.isEmpty ? nil : headerNote,
            footerNote: footerNote.isEmpty ? nil : footerNote,
            bankingInfo: bankingInfo.isEmpty ? nil : bankingInfo,
            signature: signature,
            templateType: templateType,
            customFields: customFieldModels
        )
        
        // Save to database
        modelContext.insert(invoice)
        
        do {
            try modelContext.save()
            isGenerating = false
            alertMessage = "Invoice finalized and saved successfully"
            showingAlert = true
            
            // Increment the next invoice number
            UserDefaults.standard.set(
                (UserDefaults.standard.integer(forKey: "nextInvoiceNumber") + 1),
                forKey: "nextInvoiceNumber"
            )
            
            // Close the form after a brief delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                dismiss()
            }
        } catch {
            isGenerating = false
            alertMessage = "Failed to finalize invoice: \(error.localizedDescription)"
            showingAlert = true
        }
    }
    
    private func generateInvoice() {
        isGenerating = true
        
        // Convert view models to model objects
        let invoiceItems = selectedItems.compactMap { item -> InvoiceItem? in
            guard let quantity = Int(item.quantity),
                  let unitPrice = Double(item.unitPrice),
                  let tax = Double(item.tax),
                  let discount = Double(item.discount) else {
                return nil
            }
            
            return InvoiceItem(
                name: item.name,
                description: item.description,
                quantity: quantity,
                unitPrice: unitPrice,
                tax: tax,
                discount: discount
            )
        }
        
        let customFieldModels = customFields.map { field in
            CustomInvoiceField(name: field.name, value: field.value)
        }
        
        let discountValue = Double(discount) ?? 0.0
        let taxRateValue = Double(taxRate) ?? 0.0
        
        // Create invoice
        let invoice = Invoice(
            number: invoiceNumber,
            clientName: clientName,
            clientAddress: clientAddress,
            clientEmail: clientEmail.isEmpty ? nil : clientEmail,
            clientPhone: clientPhone.isEmpty ? nil : clientPhone,
            status: .draft,
            documentType: "invoice",
            dateCreated: issueDate,
            dueDate: dueDate,
            items: invoiceItems,
            discount: discountValue,
            discountType: discountType,
            taxRate: taxRateValue,
            notes: notes,
            headerNote: headerNote.isEmpty ? nil : headerNote,
            footerNote: footerNote.isEmpty ? nil : footerNote,
            bankingInfo: bankingInfo.isEmpty ? nil : bankingInfo,
            signature: signature,
            templateType: templateType,
            customFields: customFieldModels
        )
        
        // Save to database
        modelContext.insert(invoice)
        
        do {
            try modelContext.save()
            generatedInvoice = invoice
            isGenerating = false
            showingPreview = true
        } catch {
            isGenerating = false
            alertMessage = "Failed to save invoice: \(error.localizedDescription)"
            showingAlert = true
        }
    }
}

// MARK: - Supporting Views

struct InvoiceItemSelectorView: View {
    @ObservedObject var inventory: InventoryViewModel
    @Binding var selectedItems: [InvoiceItemViewModel]
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var selectedItemsForInvoice: [Item: Int] = [:]
    
    var filteredItems: [Item] {
        if searchText.isEmpty {
            return inventory.items
        } else {
            return inventory.items.filter { 
                $0.name.localizedCaseInsensitiveContains(searchText) || 
                $0.sku.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredItems, id: \.id) { item in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.name)
                                .font(.headline)
                            
                            Text("SKU: \(item.sku)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text(String(format: "$%.2f", item.price))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Stepper(
                            "\(selectedItemsForInvoice[item, default: 0])",
                            value: Binding(
                                get: { selectedItemsForInvoice[item, default: 0] },
                                set: { selectedItemsForInvoice[item] = $0 }
                            ),
                            in: 0...(item.stockQuantity)
                        )
                        .fixedSize()
                    }
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
                        for (item, quantity) in selectedItemsForInvoice where quantity > 0 {
                            let newItem = InvoiceItemViewModel(
                                name: item.name,
                                description: item.itemDescription,
                                quantity: String(quantity),
                                unitPrice: String(format: "%.2f", item.price),
                                tax: String(format: "%.1f", item.taxRate),
                                discount: "0.0"
                            )
                            
                            if let existingIndex = selectedItems.firstIndex(where: { $0.name == item.name }) {
                                // Update existing item if it already exists
                                if let existingQty = Int(selectedItems[existingIndex].quantity),
                                   let newQty = Int(newItem.quantity) {
                                    selectedItems[existingIndex].quantity = String(existingQty + newQty)
                                } else {
                                    selectedItems[existingIndex] = newItem
                                }
                            } else {
                                // Add new item
                                selectedItems.append(newItem)
                            }
                        }
                        dismiss()
                    }
                }
            }
        }
    }
}

struct SignatureCaptureView: View {
    @Binding var signature: Data?
    @Environment(\.dismiss) private var dismiss
    @State private var currentDrawing = Drawing()
    @State private var drawings: [Drawing] = []
    @State private var color: Color = .black
    @State private var lineWidth: CGFloat = 3
    
    var body: some View {
        NavigationStack {
            VStack {
                // Signature area
                ZStack {
                    Rectangle()
                        .fill(Color.white)
                        .border(Color.gray, width: 1)
                        .shadow(radius: 3)
                    
                    if drawings.isEmpty && currentDrawing.points.isEmpty {
                        Text("Sign Here")
                            .foregroundColor(.gray)
                    }
                    
                    // Draw existing lines
                    ForEach(drawings) { drawing in
                        Path { path in
                            if let firstPoint = drawing.points.first {
                                path.move(to: firstPoint)
                                for point in drawing.points.dropFirst() {
                                    path.addLine(to: point)
                                }
                            }
                        }
                        .stroke(color, lineWidth: lineWidth)
                    }
                    
                    // Draw current line
                    Path { path in
                        if let firstPoint = currentDrawing.points.first {
                            path.move(to: firstPoint)
                            for point in currentDrawing.points.dropFirst() {
                                path.addLine(to: point)
                            }
                        }
                    }
                    .stroke(color, lineWidth: lineWidth)
                    
                    // Gesture for drawing
                    Canvas { context, size in
                        // Draw signature on canvas
                    }
                    .gesture(
                        DragGesture(minimumDistance: 0, coordinateSpace: .local)
                            .onChanged { value in
                                let newPoint = value.location
                                if currentDrawing.points.isEmpty || currentDrawing.points.last != newPoint {
                                    currentDrawing.points.append(newPoint)
                                }
                            }
                            .onEnded { _ in
                                if !currentDrawing.points.isEmpty {
                                    drawings.append(currentDrawing)
                                    currentDrawing = Drawing()
                                }
                            }
                    )
                }
                .padding()
                
                // Controls
                HStack {
                    Button("Clear") {
                        drawings = []
                        currentDrawing = Drawing()
                    }
                    .buttonStyle(.bordered)
                    
                    Spacer()
                    
                    Button("Save") {
                        // Render signature to image and convert to data
                        let renderer = ImageRenderer(content: signatureView)
                        if let uiImage = renderer.uiImage {
                            signature = uiImage.pngData()
                            dismiss()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            }
            .navigationTitle("Signature")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var signatureView: some View {
        ZStack {
            Rectangle()
                .fill(Color.white)
            
            ForEach(drawings) { drawing in
                Path { path in
                    if let firstPoint = drawing.points.first {
                        path.move(to: firstPoint)
                        for point in drawing.points.dropFirst() {
                            path.addLine(to: point)
                        }
                    }
                }
                .stroke(color, lineWidth: lineWidth)
            }
        }
        .frame(width: 500, height: 200)
    }
    
    struct Drawing: Identifiable {
        let id = UUID()
        var points: [CGPoint] = []
    }
}

struct AddCustomFieldView: View {
    @Binding var customFields: [CustomFieldViewModel]
    @Environment(\.dismiss) private var dismiss
    @State private var fieldName = ""
    @State private var fieldValue = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Custom Field")) {
                    TextField("Field Name", text: $fieldName)
                    TextField("Field Value", text: $fieldValue)
                }
                
                Section {
                    Button("Add Field") {
                        if !fieldName.isEmpty {
                            let newField = CustomFieldViewModel(name: fieldName, value: fieldValue)
                            customFields.append(newField)
                            dismiss()
                        }
                    }
                    .disabled(fieldName.isEmpty)
                }
            }
            .navigationTitle("Add Custom Field")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct InvoiceHeaderFooterView: View {
    @Binding var headerNote: String
    @Binding var footerNote: String
    @Binding var bankingInfo: String
    
    var body: some View {
        Form {
            Section(header: Text("Header Note")) {
                ZStack(alignment: .topLeading) {
                    if headerNote.isEmpty {
                        Text("Header note (appears at top of invoice)")
                            .foregroundColor(.secondary)
                            .padding(.top, 8)
                    }
                    TextEditor(text: $headerNote)
                        .frame(minHeight: 100)
                }
            }
            
            Section(header: Text("Footer Note")) {
                ZStack(alignment: .topLeading) {
                    if footerNote.isEmpty {
                        Text("Footer note (appears at bottom of invoice)")
                            .foregroundColor(.secondary)
                            .padding(.top, 8)
                    }
                    TextEditor(text: $footerNote)
                        .frame(minHeight: 100)
                }
            }
            
            Section(header: Text("Banking Information")) {
                ZStack(alignment: .topLeading) {
                    if bankingInfo.isEmpty {
                        Text("Bank details for payment")
                            .foregroundColor(.secondary)
                            .padding(.top, 8)
                    }
                    TextEditor(text: $bankingInfo)
                        .frame(minHeight: 100)
                }
            }
        }
        .navigationTitle("Header & Footer")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct InvoiceTemplateSelectionView: View {
    @Binding var templateType: String
    
    private let templates = [
        "standard", "modern", "minimal", "professional", "elegant"
    ]
    
    var body: some View {
        VStack {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    ForEach(templates, id: \.self) { template in
                        VStack {
                            // Template preview
                            ZStack {
                                Rectangle()
                                    .fill(colorForTemplate(template))
                                    .frame(width: 200, height: 250)
                                    .cornerRadius(10)
                                
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(templateType == template ? Color.accentColor : Color.clear, lineWidth: 3)
                                    .frame(width: 200, height: 250)
                                
                                VStack(spacing: 10) {
                                    Rectangle()
                                        .fill(Color.white.opacity(0.7))
                                        .frame(height: 30)
                                    
                                    Rectangle()
                                        .fill(Color.white.opacity(0.5))
                                        .frame(height: 100)
                                    
                                    Rectangle()
                                        .fill(Color.white.opacity(0.7))
                                        .frame(height: 30)
                                }
                                .frame(width: 160)
                                .padding()
                            }
                            
                            Text(template.capitalized)
                                .font(.headline)
                        }
                        .onTapGesture {
                            templateType = template
                        }
                    }
                }
                .padding()
            }
            
            // Template details
            VStack(alignment: .leading, spacing: 10) {
                Text("Template: \(templateType.capitalized)")
                    .font(.headline)
                
                Text("This template features a clean layout with a professional design, perfect for business invoices.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .padding(.bottom)
                
                Text("Features:")
                    .font(.subheadline)
                
                VStack(alignment: .leading, spacing: 5) {
                    HStack(alignment: .top, spacing: 5) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Professional header and footer layout")
                    }
                    
                    HStack(alignment: .top, spacing: 5) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Clear itemization and totals section")
                    }
                    
                    HStack(alignment: .top, spacing: 5) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Space for company logo and branding")
                    }
                }
            }
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(10)
            .padding()
            
            Spacer()
        }
        .navigationTitle("Select Template")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func colorForTemplate(_ template: String) -> Color {
        switch template {
        case "standard":
            return .blue
        case "modern":
            return .indigo
        case "minimal":
            return .gray
        case "professional":
            return .teal
        case "elegant":
            return .purple
        default:
            return .blue
        }
    }
}

struct InvoicePreviewView: View {
    let invoice: Invoice
    @Environment(\.dismiss) private var dismiss
    @State private var showingShareSheet = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 5) {
                        Text("INVOICE")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("#\(invoice.number)")
                            .font(.title3)
                        
                        if let headerNote = invoice.headerNote {
                            Text(headerNote)
                                .font(.callout)
                                .foregroundColor(.secondary)
                                .padding(.top, 2)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(10)
                    
                    // Date and Client Info
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Date Issued:")
                                .font(.headline)
                            Text(invoice.dateCreated, style: .date)
                            
                            Text("Due Date:")
                                .font(.headline)
                                .padding(.top, 4)
                            Text(invoice.dueDate, style: .date)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Bill To:")
                                .font(.headline)
                            Text(invoice.clientName)
                                .fontWeight(.semibold)
                            Text(invoice.clientAddress)
                                .fixedSize(horizontal: false, vertical: true)
                            
                            if let email = invoice.clientEmail {
                                Text(email)
                            }
                            if let phone = invoice.clientPhone {
                                Text(phone)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(10)
                    
                    // Items
                    VStack(spacing: 0) {
                        // Header
                        HStack {
                            Text("Item")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Text("Qty")
                                .fontWeight(.semibold)
                                .frame(width: 50)
                            
                            Text("Price")
                                .fontWeight(.semibold)
                                .frame(width: 80)
                            
                            Text("Total")
                                .fontWeight(.semibold)
                                .frame(width: 80)
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal)
                        .background(Color.accentColor.opacity(0.1))
                        
                        // Item rows
                        ForEach(invoice.items, id: \.id) { item in
                            VStack {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(item.name)
                                            .fontWeight(.medium)
                                        if let description = item.itemDescription {
                                            Text(description)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    
                                    Text("\(item.quantity)")
                                        .frame(width: 50)
                                    
                                    Text("$\(item.unitPrice, specifier: "%.2f")")
                                        .frame(width: 80)
                                    
                                    Text("$\(item.totalAmount, specifier: "%.2f")")
                                        .frame(width: 80)
                                }
                                
                                Divider()
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                        }
                        
                        // Totals
                        VStack(spacing: 8) {
                            HStack {
                                Spacer()
                                Text("Subtotal:")
                                Text("$\(invoice.subtotal, specifier: "%.2f")")
                                    .frame(width: 80)
                            }
                            
                            if invoice.discount > 0 {
                                HStack {
                                    Spacer()
                                    Text("Discount:")
                                    Text("-$\(invoice.discount, specifier: "%.2f")")
                                        .frame(width: 80)
                                        .foregroundColor(.red)
                                }
                            }
                            
                            if invoice.tax > 0 {
                                HStack {
                                    Spacer()
                                    Text("Tax (\(invoice.taxRate, specifier: "%.1f")%):")
                                    Text("$\(invoice.tax, specifier: "%.2f")")
                                        .frame(width: 80)
                                }
                            }
                            
                            HStack {
                                Spacer()
                                Text("Total:")
                                    .font(.headline)
                                Text("$\(invoice.totalAmount, specifier: "%.2f")")
                                    .font(.headline)
                                    .frame(width: 80)
                            }
                        }
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground))
                    }
                    .background(Color(UIColor.tertiarySystemBackground))
                    .cornerRadius(10)
                    .shadow(radius: 1)
                    
                    // Notes
                    if !invoice.notes.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Notes:")
                                .font(.headline)
                            
                            Text(invoice.notes)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(10)
                    }
                    
                    // Banking Info
                    if let bankingInfo = invoice.bankingInfo {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Payment Information:")
                                .font(.headline)
                            
                            Text(bankingInfo)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(10)
                    }
                    
                    // Custom Fields
                    if let customFields = invoice.customFields, !customFields.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Additional Information:")
                                .font(.headline)
                            
                            ForEach(customFields, id: \.id) { field in
                                HStack {
                                    Text("\(field.name):")
                                        .fontWeight(.medium)
                                    Spacer()
                                    Text(field.value)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(10)
                    }
                    
                    // Signature
                    if let signatureData = invoice.signature, let uiImage = UIImage(data: signatureData) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Signature:")
                                .font(.headline)
                            
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 100)
                                .background(Color.white)
                                .cornerRadius(8)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(10)
                    }
                    
                    // Footer
                    if let footerNote = invoice.footerNote {
                        Text(footerNote)
                            .font(.footnote)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding()
                    }
                }
                .padding()
            }
            .navigationTitle("Invoice Preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingShareSheet = true
                    }) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            // In a full implementation, you would render the invoice to PDF and share it
            .sheet(isPresented: $showingShareSheet) {
                Text("PDF Sharing functionality would be implemented here")
                    .padding()
            }
        }
    }
}

// MARK: - View Models

struct InvoiceItemViewModel: Identifiable {
    let id = UUID()
    var name: String
    var description: String
    var quantity: String
    var unitPrice: String
    var tax: String
    var discount: String
    var isExpanded: Bool = false
}

struct CustomFieldViewModel: Identifiable {
    let id = UUID()
    var name: String
    var value: String
}