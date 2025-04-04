import SwiftUI
import SwiftData

struct CreateInvoiceView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var subscriptionService: SubscriptionService
    
    @State private var showingSubscriptionAlert = false
    
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
    @State private var dueDate = Date() // Default to current date, user can change
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
    
    // States for showing various sheets and alerts
    @State private var showingItemPicker = false
    @State private var showingAddItemForm = false
    @State private var showingAddCustomFieldForm = false
    @State private var showingDatePicker = false
    @State private var datePickerType: DatePickerType = .issueDate
    @State private var showingDiscountTypePicker = false
    @State private var showingPaymentMethodPicker = false
    @State private var showingTemplateTypePicker = false
    @State private var showingPreview = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var showingDeleteConfirmation = false
    @State private var itemToDelete: InvoiceItemViewModel?
    @State private var customFieldToDelete: CustomFieldViewModel?
    @State private var showingDeleteCustomFieldConfirmation = false
    @State private var showingTaxRateInfo = false
    @State private var showingDiscountInfo = false
    @State private var showingDueDateInfo = false
    @State private var showingInvoiceNumberInfo = false
    @State private var showingPaymentMethodInfo = false
    @State private var showingTemplateInfo = false
    @State private var showingCustomFieldInfo = false
    @State private var showingBankingInfo = false
    @State private var showingNotesInfo = false
    @State private var showingHeaderFooterInfo = false
    
    // App storage for default values
    @AppStorage("defaultTaxRate") private var defaultTaxRate = "0.0"
    @AppStorage("defaultDiscountValue") private var defaultDiscountValue = "0.0"
    @AppStorage("defaultDiscountType") private var defaultDiscountType = "percentage"
    @AppStorage("nextInvoiceNumber") private var nextInvoiceNumber = 1001
    @AppStorage("companyName") private var companyName = ""
    @AppStorage("companyAddress") private var companyAddress = ""
    @AppStorage("companyEmail") private var companyEmail = ""
    @AppStorage("companyPhone") private var companyPhone = ""
    @AppStorage("bankName") private var bankName = ""
    @AppStorage("accountNumber") private var accountNumber = ""
    @AppStorage("routingNumber") private var routingNumber = ""
    @AppStorage("swiftCode") private var swiftCode = ""
    @AppStorage("invoiceDisclaimer") private var invoiceDisclaimer = "Thank you for your business."
    @AppStorage("defaultDocumentTheme") private var defaultDocumentTheme = DocumentTheme.classic.rawValue
    
    // Computed properties for validation and calculations
    private var isFormValid: Bool {
        !clientName.isEmpty && selectedItems.count > 0
    }
    
    private var subtotal: Double {
        selectedItems.reduce(0) { $0 + $1.total }
    }
    
    private var discountAmount: Double {
        let discountValue = Double(discount) ?? 0
        if discountType == "percentage" {
            return subtotal * (discountValue / 100)
        } else {
            return discountValue
        }
    }
    
    private var taxAmount: Double {
        let taxRateValue = Double(taxRate) ?? 0
        return (subtotal - discountAmount) * (taxRateValue / 100)
    }
    
    private var total: Double {
        subtotal - discountAmount + taxAmount
    }
    
    enum DatePickerType {
        case issueDate
        case dueDate
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Client Information Section
                Section(header: Text("Client Information")) {
                    if let client = selectedClient {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(client.name)
                                    .font(.headline)
                                
                                if !client.email.isEmpty {
                                    Text(client.email)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                if !client.phone.isEmpty {
                                    Text(client.phone)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                selectedClient = nil
                                clientName = ""
                                clientAddress = ""
                                clientEmail = ""
                                clientPhone = ""
                                clientCity = ""
                                clientCountry = "United States"
                                clientPostalCode = ""
                            }) {
                                Text("Change")
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.secondary.opacity(0.2))
                                    .cornerRadius(4)
                            }
                        }
                    } else {
                        Button(action: {
                            showingClientPicker = true
                        }) {
                            HStack {
                                Image(systemName: "person.crop.circle.badge.plus")
                                Text("Select Client")
                            }
                        }
                        
                        TextField("Client Name", text: $clientName)
                        TextField("Email", text: $clientEmail)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                        TextField("Phone", text: $clientPhone)
                            .keyboardType(.phonePad)
                        
                        TextField("Address", text: $clientAddress)
                        TextField("City", text: $clientCity)
                        TextField("Postal Code", text: $clientPostalCode)
                        TextField("Country", text: $clientCountry)
                    }
                }
                
                // Invoice Details Section
                Section(header: Text("Invoice Details")) {
                    HStack {
                        Text("Invoice #")
                        Spacer()
                        TextField("Invoice Number", text: $invoiceNumber)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.numberPad)
                        
                        Button(action: {
                            showingInvoiceNumberInfo = true
                        }) {
                            Image(systemName: "info.circle")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    HStack {
                        Text("Issue Date")
                        Spacer()
                        Text(formattedDate(issueDate))
                            .foregroundColor(.secondary)
                        
                        Button(action: {
                            datePickerType = .issueDate
                            showingDatePicker = true
                        }) {
                            Image(systemName: "calendar")
                                .foregroundColor(.blue)
                        }
                    }
                    
                    HStack {
                        Text("Due Date")
                        Spacer()
                        Text(formattedDate(dueDate))
                            .foregroundColor(.secondary)
                        
                        Button(action: {
                            datePickerType = .dueDate
                            showingDatePicker = true
                        }) {
                            Image(systemName: "calendar")
                                .foregroundColor(.blue)
                        }
                        
                        Button(action: {
                            showingDueDateInfo = true
                        }) {
                            Image(systemName: "info.circle")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Items Section
                Section(header: Text("Items")) {
                    ForEach(selectedItems.indices, id: \.self) { index in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(selectedItems[index].name)
                                    .font(.headline)
                                
                                Spacer()
                                
                                Button(action: {
                                    itemToDelete = selectedItems[index]
                                    showingDeleteConfirmation = true
                                }) {
                                    Image(systemName: "trash")
                                        .foregroundColor(.red)
                                }
                            }
                            
                            HStack {
                                Text("\(selectedItems[index].quantity, specifier: "%.2f") × \(formatCurrency(selectedItems[index].price))")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                Text(formatCurrency(selectedItems[index].total))
                                    .font(.subheadline)
                            }
                            
                            if !selectedItems[index].description.isEmpty {
                                Text(selectedItems[index].description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.top, 2)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    
                    Button(action: {
                        showingItemPicker = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.green)
                            Text("Add Item")
                        }
                    }
                    
                    Button(action: {
                        showingAddItemForm = true
                    }) {
                        HStack {
                            Image(systemName: "square.and.pencil")
                                .foregroundColor(.blue)
                            Text("Create New Item")
                        }
                    }
                }
                
                // Totals Section
                Section(header: Text("Totals")) {
                    HStack {
                        Text("Subtotal")
                        Spacer()
                        Text(formatCurrency(subtotal))
                    }
                    
                    HStack {
                        Text("Discount")
                        
                        Button(action: {
                            showingDiscountInfo = true
                        }) {
                            Image(systemName: "info.circle")
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        TextField("0.0", text: $discount)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
                        
                        Button(action: {
                            showingDiscountTypePicker = true
                        }) {
                            Text(discountType == "percentage" ? "%" : "$")
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.secondary.opacity(0.2))
                                .cornerRadius(4)
                        }
                    }
                    
                    if discountAmount > 0 {
                        HStack {
                            Text("Discount Amount")
                            Spacer()
                            Text(formatCurrency(discountAmount))
                                .foregroundColor(.red)
                        }
                    }
                    
                    HStack {
                        Text("Tax Rate")
                        
                        Button(action: {
                            showingTaxRateInfo = true
                        }) {
                            Image(systemName: "info.circle")
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        TextField("0.0", text: $taxRate)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
                        
                        Text("%")
                            .foregroundColor(.secondary)
                    }
                    
                    if taxAmount > 0 {
                        HStack {
                            Text("Tax Amount")
                            Spacer()
                            Text(formatCurrency(taxAmount))
                        }
                    }
                    
                    HStack {
                        Text("Total")
                            .font(.headline)
                        Spacer()
                        Text(formatCurrency(total))
                            .font(.headline)
                    }
                }
                
                // Additional Details Section
                Section(header: Text("Additional Details")) {
                    HStack {
                        Text("Payment Method")
                        Spacer()
                        Text(paymentMethod)
                            .foregroundColor(.secondary)
                        
                        Button(action: {
                            showingPaymentMethodPicker = true
                        }) {
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Button(action: {
                            showingPaymentMethodInfo = true
                        }) {
                            Image(systemName: "info.circle")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    HStack {
                        Text("Template")
                        Spacer()
                        Text(templateType.capitalized)
                            .foregroundColor(.secondary)
                        
                        Button(action: {
                            showingTemplateTypePicker = true
                        }) {
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Button(action: {
                            showingTemplateInfo = true
                        }) {
                            Image(systemName: "info.circle")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    NavigationLink(destination: Text("Banking Details").padding()) {
                        HStack {
                            Text("Banking Details")
                            Spacer()
                            if !bankName.isEmpty || !accountNumber.isEmpty {
                                Text("Added")
                                    .foregroundColor(.green)
                            } else {
                                Text("Not Added")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    NavigationLink(destination: Text("Notes").padding()) {
                        HStack {
                            Text("Notes")
                            Spacer()
                            if !notes.isEmpty {
                                Text("Added")
                                    .foregroundColor(.green)
                            } else {
                                Text("Not Added")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                // Custom Fields Section
                Section(header: HStack {
                    Text("Custom Fields")
                    Spacer()
                    Button(action: {
                        showingCustomFieldInfo = true
                    }) {
                        Image(systemName: "info.circle")
                            .foregroundColor(.secondary)
                    }
                }) {
                    ForEach(customFields.indices, id: \.self) { index in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(customFields[index].name)
                                    .font(.headline)
                                Text(customFields[index].value)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                customFieldToDelete = customFields[index]
                                showingDeleteCustomFieldConfirmation = true
                            }) {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    
                    Button(action: {
                        showingAddCustomFieldForm = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.green)
                            Text("Add Custom Field")
                        }
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
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Preview") {
                        if !subscriptionService.canCreateInvoice() {
                            showingSubscriptionAlert = true
                        } else {
                            showingPreview = true
                        }
                    }
                    .disabled(!isFormValid)
                }
            }
            .onAppear {
                // Check subscription limits when view appears
                if !subscriptionService.canCreateInvoice() {
                    showingSubscriptionAlert = true
                }
                
                // Set default values
                invoiceNumber = String(nextInvoiceNumber)
                taxRate = defaultTaxRate
                discount = defaultDiscountValue
                discountType = defaultDiscountType
                templateType = DocumentTheme(rawValue: defaultDocumentTheme)?.rawValue ?? "classic"
                
                // Set due date to 30 days from now by default
                if let thirtyDaysLater = Calendar.current.date(byAdding: .day, value: 30, to: Date()) {
                    dueDate = thirtyDaysLater
                }
                
                // Set footer note to default disclaimer
                footerNote = invoiceDisclaimer
                
                // Set banking info
                if !bankName.isEmpty || !accountNumber.isEmpty {
                    var info = ""
                    if !bankName.isEmpty {
                        info += "Bank: \(bankName)\n"
                    }
                    if !accountNumber.isEmpty {
                        info += "Account: \(accountNumber)\n"
                    }
                    if !routingNumber.isEmpty {
                        info += "Routing: \(routingNumber)\n"
                    }
                    if !swiftCode.isEmpty {
                        info += "SWIFT: \(swiftCode)"
                    }
                    bankingInfo = info
                }
            }
            .sheet(isPresented: $showingClientPicker) {
                // Client picker sheet
                Text("Client Picker")
            }
            .sheet(isPresented: $showingItemPicker) {
                // Item picker sheet
                Text("Item Picker")
            }
            .sheet(isPresented: $showingAddItemForm) {
                // Add item form
                Text("Add Item Form")
            }
            .sheet(isPresented: $showingAddCustomFieldForm) {
                // Add custom field form
                Text("Add Custom Field Form")
            }
            .sheet(isPresented: $showingDatePicker) {
                // Date picker
                Text("Date Picker")
            }
            .sheet(isPresented: $showingDiscountTypePicker) {
                // Discount type picker
                Text("Discount Type Picker")
            }
            .sheet(isPresented: $showingPaymentMethodPicker) {
                // Payment method picker
                Text("Payment Method Picker")
            }
            .sheet(isPresented: $showingTemplateTypePicker) {
                // Template type picker
                Text("Template Type Picker")
            }
            .sheet(isPresented: $showingPreview) {
                // Invoice preview
                Text("Invoice Preview")
            }
            .sheet(isPresented: $showingSubscriptionAlert) {
                // Subscription limit alert
                SubscriptionLimitView(limitType: .invoice) {
                    // Show subscription view when user taps upgrade
                    dismiss()
                    // This would typically navigate to the subscription view
                }
            }
            .alert(isPresented: $showingAlert) {
                Alert(
                    title: Text("Error"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
            .confirmationDialog(
                "Are you sure you want to delete this item?",
                isPresented: $showingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    if let item = itemToDelete, let index = selectedItems.firstIndex(where: { $0.id == item.id }) {
                        selectedItems.remove(at: index)
                    }
                }
                Button("Cancel", role: .cancel) { }
            }
            .confirmationDialog(
                "Are you sure you want to delete this custom field?",
                isPresented: $showingDeleteCustomFieldConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    if let field = customFieldToDelete, let index = customFields.firstIndex(where: { $0.id == field.id }) {
                        customFields.remove(at: index)
                    }
                }
                Button("Cancel", role: .cancel) { }
            }
            .alert(isPresented: $showingTaxRateInfo) {
                Alert(
                    title: Text("Tax Rate"),
                    message: Text("Enter the tax rate as a percentage (e.g., 7.5 for 7.5%)."),
                    dismissButton: .default(Text("OK"))
                )
            }
            .alert(isPresented: $showingDiscountInfo) {
                Alert(
                    title: Text("Discount"),
                    message: Text("Enter a discount as either a percentage or a fixed amount."),
                    dismissButton: .default(Text("OK"))
                )
            }
            .alert(isPresented: $showingDueDateInfo) {
                Alert(
                    title: Text("Due Date"),
                    message: Text("The date by which payment is expected. Typically 30 days after the issue date."),
                    dismissButton: .default(Text("OK"))
                )
            }
            .alert(isPresented: $showingInvoiceNumberInfo) {
                Alert(
                    title: Text("Invoice Number"),
                    message: Text("A unique identifier for this invoice. The next available number is suggested automatically."),
                    dismissButton: .default(Text("OK"))
                )
            }
            .alert(isPresented: $showingPaymentMethodInfo) {
                Alert(
                    title: Text("Payment Method"),
                    message: Text("The method by which you expect to receive payment for this invoice."),
                    dismissButton: .default(Text("OK"))
                )
            }
            .alert(isPresented: $showingTemplateInfo) {
                Alert(
                    title: Text("Template"),
                    message: Text("Choose a visual style for your invoice. This affects the layout and design of the PDF."),
                    dismissButton: .default(Text("OK"))
                )
            }
            .alert(isPresented: $showingCustomFieldInfo) {
                Alert(
                    title: Text("Custom Fields"),
                    message: Text("Add any additional information that doesn't fit in the standard fields."),
                    dismissButton: .default(Text("OK"))
                )
            }
            .alert(isPresented: $showingBankingInfo) {
                Alert(
                    title: Text("Banking Details"),
                    message: Text("Add your banking information to make it easier for clients to pay you."),
                    dismissButton: .default(Text("OK"))
                )
            }
            .alert(isPresented: $showingNotesInfo) {
                Alert(
                    title: Text("Notes"),
                    message: Text("Add any additional notes or instructions for the client."),
                    dismissButton: .default(Text("OK"))
                )
            }
            .alert(isPresented: $showingHeaderFooterInfo) {
                Alert(
                    title: Text("Header & Footer"),
                    message: Text("Add text to appear at the top and bottom of your invoice."),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
    
    // Helper function to format dates
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    // Helper function to format currency
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$" // Use the user's preferred currency symbol
        return formatter.string(from: NSNumber(value: amount)) ?? "$\(amount)"
    }
    
    // Helper function to create invoice data for preview
    private func createInvoiceData() -> [String: Any] {
        // Create a dictionary with all the invoice data
        var invoiceData: [String: Any] = [
            "invoiceNumber": invoiceNumber,
            "clientName": clientName,
            "clientAddress": clientAddress,
            "clientEmail": clientEmail,
            "clientPhone": clientPhone,
            "clientCity": clientCity,
            "clientCountry": clientCountry,
            "clientPostalCode": clientPostalCode,
            "issueDate": issueDate,
            "dueDate": dueDate,
            "subtotal": subtotal,
            "discount": Double(discount) ?? 0,
            "discountType": discountType,
            "taxRate": Double(taxRate) ?? 0,
            "taxAmount": taxAmount,
            "total": total,
            "paymentMethod": paymentMethod,
            "notes": notes,
            "headerNote": headerNote,
            "footerNote": footerNote,
            "bankingInfo": bankingInfo,
            "templateType": templateType,
            "items": selectedItems.map { item in
                [
                    "name": item.name,
                    "description": item.description,
                    "quantity": item.quantity,
                    "price": item.price,
                    "total": item.total
                ]
            },
            "customFields": customFields.map { field in
                [
                    "name": field.name,
                    "value": field.value
                ]
            }
        ]
        
        return invoiceData
    }
    
    // Helper function to save the invoice
    private func saveInvoice() {
        guard isFormValid else {
            alertMessage = "Please fill in all required fields."
            showingAlert = true
            return
        }
        
        // Create a new invoice
        let invoice = Invoice(
            invoiceNumber: invoiceNumber,
            clientName: clientName,
            clientAddress: clientAddress,
            clientEmail: clientEmail,
            clientPhone: clientPhone,
            clientCity: clientCity,
            clientCountry: clientCountry,
            clientPostalCode: clientPostalCode,
            issueDate: issueDate,
            dueDate: dueDate,
            subtotal: subtotal,
            discount: Double(discount) ?? 0,
            discountType: discountType,
            taxRate: Double(taxRate) ?? 0,
            taxAmount: taxAmount,
            total: total,
            paymentMethod: paymentMethod,
            notes: notes,
            headerNote: headerNote,
            footerNote: footerNote,
            bankingInfo: bankingInfo,
            templateType: templateType,
            status: "draft"
        )
        
        // Add the invoice to the model context
        modelContext.insert(invoice)
        
        // Create invoice items
        for itemVM in selectedItems {
            let invoiceItem = InvoiceItem(
                name: itemVM.name,
                description: itemVM.description,
                quantity: itemVM.quantity,
                price: itemVM.price,
                total: itemVM.total,
                invoice: invoice
            )
            modelContext.insert(invoiceItem)
        }
        
        // Create custom fields
        for fieldVM in customFields {
            let customField = CustomInvoiceField(
                name: fieldVM.name,
                value: fieldVM.value,
                invoice: invoice
            )
            modelContext.insert(customField)
        }
        
        // Update the next invoice number
        nextInvoiceNumber += 1
        
        // Increment the invoice count in the subscription service
        subscriptionService.incrementInvoiceCount()
        
        // Dismiss the view
        dismiss()
    }
}

// View models for invoice items and custom fields
struct InvoiceItemViewModel: Identifiable {
    let id = UUID()
    var name: String
    var description: String
    var quantity: Double
    var price: Double
    
    var total: Double {
        quantity * price
    }
}

struct CustomFieldViewModel: Identifiable {
    let id = UUID()
    var name: String
    var value: String
}

#Preview {
    CreateInvoiceView()
        .environmentObject(SubscriptionService.shared)
}
