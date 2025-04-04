import SwiftUI
import SwiftData
import Foundation

// MARK: - Invoice Edit Data Model
struct InvoiceEditData {
    var clientName: String
    var clientAddress: String
    var clientEmail: String?
    var clientPhone: String?
    var status: Invoice.Status
    var paymentMethod: String?
    var dueDate: Date
    var notes: String
    var shouldRegeneratePDF: Bool = false
    
    init(from invoice: Invoice) {
        self.clientName = invoice.clientName
        self.clientAddress = invoice.clientAddress
        self.clientEmail = invoice.clientEmail
        self.clientPhone = invoice.clientPhone
        self.status = invoice.status
        self.paymentMethod = invoice.paymentMethod
        self.dueDate = invoice.dueDate
        self.notes = invoice.notes
    }
}

// MARK: - Invoice Edit View
struct InvoiceEditView: View {
    let invoice: Invoice
    let onSave: (InvoiceEditData) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var editData: InvoiceEditData
    @State private var showRegeneratePDFAlert = false
    
    init(invoice: Invoice, onSave: @escaping (InvoiceEditData) -> Void) {
        self.invoice = invoice
        self.onSave = onSave
        _editData = State(initialValue: InvoiceEditData(from: invoice))
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Client Information Section
                Section(header: Text("Client Information")) {
                    TextField("Client Name", text: $editData.clientName)
                    
                    ZStack(alignment: .topLeading) {
                        if editData.clientAddress.isEmpty {
                            Text("Client Address")
                                .foregroundColor(.secondary)
                                .padding(.top, 8)
                        }
                        
                        TextEditor(text: $editData.clientAddress)
                            .frame(minHeight: 60)
                    }
                    
                    TextField("Email", text: Binding(
                        get: { editData.clientEmail ?? "" },
                        set: { editData.clientEmail = $0.isEmpty ? nil : $0 }
                    ))
                    .keyboardType(.emailAddress)
                    
                    TextField("Phone", text: Binding(
                        get: { editData.clientPhone ?? "" },
                        set: { editData.clientPhone = $0.isEmpty ? nil : $0 }
                    ))
                    .keyboardType(.phonePad)
                }
                
                // Invoice Details Section
                Section(header: Text("Invoice Details")) {
                    Picker("Status", selection: $editData.status) {
                        Text("Draft").tag(Invoice.Status.draft)
                        Text("Pending").tag(Invoice.Status.pending)
                        Text("Paid").tag(Invoice.Status.paid)
                        Text("Overdue").tag(Invoice.Status.overdue)
                        Text("Cancelled").tag(Invoice.Status.cancelled)
                    }
                    
                    // Only show payment method if not empty
                    if let paymentMethod = editData.paymentMethod, !paymentMethod.isEmpty {
                        Picker("Payment Method", selection: Binding(
                            get: { paymentMethod },
                            set: { editData.paymentMethod = $0 }
                        )) {
                            Text("Cash").tag("Cash")
                            Text("Credit Card").tag("Credit Card")
                            Text("Debit Card").tag("Debit Card")
                            Text("Bank Transfer").tag("Bank Transfer")
                            Text("Check").tag("Check")
                            Text("Payment App").tag("Payment App")
                            Text("Other").tag("Other")
                        }
                    }
                    
                    DatePicker("Due Date", selection: $editData.dueDate, displayedComponents: [.date])
                }
                
                // Notes Section
                Section(header: Text("Notes")) {
                    ZStack(alignment: .topLeading) {
                        if editData.notes.isEmpty {
                            Text("Notes")
                                .foregroundColor(.secondary)
                                .padding(.top, 8)
                        }
                        
                        TextEditor(text: $editData.notes)
                            .frame(minHeight: 100)
                    }
                }
                
                // PDF Regeneration Section
                Section {
                    Toggle("Regenerate PDF", isOn: $editData.shouldRegeneratePDF)
                    
                    if editData.shouldRegeneratePDF {
                        Text("A new PDF will be generated when you save")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Edit Invoice")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        // Check if we need to regenerate PDF
                        if hasSignificantChanges() && !editData.shouldRegeneratePDF {
                            showRegeneratePDFAlert = true
                        } else {
                            saveAndDismiss()
                        }
                    }
                }
            }
            .alert("Update PDF?", isPresented: $showRegeneratePDFAlert) {
                Button("Save Without Updating PDF") {
                    saveAndDismiss()
                }
                
                Button("Update PDF", role: .destructive) {
                    editData.shouldRegeneratePDF = true
                    saveAndDismiss()
                }
                
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("You've made significant changes to this invoice. Would you like to update the PDF?")
            }
        }
    }
    
    // Determine if important fields have changed
    private func hasSignificantChanges() -> Bool {
        return editData.clientName != invoice.clientName ||
               editData.clientAddress != invoice.clientAddress ||
               editData.status != invoice.status
    }
    
    // Save changes and dismiss
    private func saveAndDismiss() {
        onSave(editData)
        dismiss()
    }
}

struct InvoiceManagementView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewMode: ViewMode = .issued
    
    enum ViewMode {
        case issued
        case create
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Tab Selection
            Picker("View", selection: $viewMode) {
                Text("Issued Invoices").tag(ViewMode.issued)
                Text("Create New").tag(ViewMode.create)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            
            // Content based on selected tab
            if viewMode == .issued {
                IssuedInvoicesView()
            } else {
                DocumentGeneratorView(modelContext: modelContext)
            }
        }
        .navigationTitle("Invoices")
        .toolbar {
            ToolbarItem(placement: .principal) {
                HomeButtonLink()
            }
        }
    }
}

struct IssuedInvoicesView: View {
    @Environment(\.modelContext) private var modelContext
    
    // Make the query more explicit with a full descriptor
    @Query(FetchDescriptor<Invoice>(sortBy: [SortDescriptor<Invoice>(\.dateCreated, order: .reverse)])) 
    private var invoices: [Invoice]
    @State private var searchText = ""
    @State private var sortOrder: SortOrder = .dateDesc
    @State private var showingInvoiceDetail = false
    @State private var selectedInvoice: Invoice?
    @State private var showingDeleteConfirmation = false
    
    enum SortOrder {
        case dateDesc
        case dateAsc
        case numberAsc
        case numberDesc
        case amountDesc
        case amountAsc
    }
    
    var filteredInvoices: [Invoice] {
        let filtered = searchText.isEmpty 
            ? invoices 
            : invoices.filter { 
                $0.number.localizedCaseInsensitiveContains(searchText) ||
                $0.clientName.localizedCaseInsensitiveContains(searchText)
            }
        
        switch sortOrder {
        case .dateDesc:
            return filtered.sorted { $0.dateCreated > $1.dateCreated }
        case .dateAsc:
            return filtered.sorted { $0.dateCreated < $1.dateCreated }
        case .numberAsc:
            return filtered.sorted { $0.number < $1.number }
        case .numberDesc:
            return filtered.sorted { $0.number > $1.number }
        case .amountDesc:
            return filtered.sorted { $0.totalAmount > $1.totalAmount }
        case .amountAsc:
            return filtered.sorted { $0.totalAmount < $1.totalAmount }
        }
    }
    
    // No need for custom init as we're using the @Query property wrapper
    // and environment model context automatically
    
    var body: some View {
        VStack {
            if invoices.isEmpty {
                ContentUnavailableView(
                    "No Invoices Yet",
                    systemImage: "doc.text",
                    description: Text("Create your first invoice to get started.")
                )
            } else {
                List {
                    ForEach(filteredInvoices) { invoice in
                        NavigationLink(destination: 
                            InvoiceDetailView(invoice: invoice)
                        ) {
                            InvoiceListItem(invoice: invoice)
                                .contentShape(Rectangle())
                        }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    selectedInvoice = invoice
                                    showingDeleteConfirmation = true
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                }
                .searchable(text: $searchText, prompt: "Search invoices...")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Menu {
                            Button {
                                sortOrder = .dateDesc
                            } label: {
                                Label("Newest First", systemImage: "calendar.badge.clock")
                            }
                            
                            Button {
                                sortOrder = .dateAsc
                            } label: {
                                Label("Oldest First", systemImage: "calendar")
                            }
                            
                            Button {
                                sortOrder = .numberAsc
                            } label: {
                                Label("Number (A to Z)", systemImage: "arrow.up.doc")
                            }
                            
                            Button {
                                sortOrder = .numberDesc
                            } label: {
                                Label("Number (Z to A)", systemImage: "arrow.down.doc")
                            }
                            
                            Button {
                                sortOrder = .amountDesc
                            } label: {
                                Label("Highest Amount", systemImage: "arrow.down.circle.dotted")
                            }
                            
                            Button {
                                sortOrder = .amountAsc
                            } label: {
                                Label("Lowest Amount", systemImage: "arrow.up.circle.dotted")
                            }
                        } label: {
                            Label("Sort", systemImage: "arrow.up.arrow.down")
                        }
                    }
                }
            }
        }
        .alert("Delete Invoice", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let invoice = selectedInvoice {
                    deleteInvoice(invoice)
                }
            }
        } message: {
            Text("Are you sure you want to delete this invoice? This action cannot be undone.")
        }
        // Don't use UUID() for ID as it causes view recreation issues
    }
    
    private func deleteInvoice(_ invoice: Invoice) {
        // Before deleting invoice, first detach any InvoiceItems
        for item in invoice.items {
            item.invoice = nil
        }
        modelContext.delete(invoice)
        try? modelContext.save()
    }
}

struct InvoiceListItem: View {
    let invoice: Invoice
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(invoice.number)
                    .font(.headline)
                
                Text(invoice.clientName)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(formattedDate(invoice.dateCreated))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(formattedAmount(invoice.totalAmount))
                    .font(.headline)
                
                Text(invoice.status.rawValue)
                    .font(.caption)
                    .padding(4)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(statusColor(invoice.status).opacity(0.2))
                    )
                    .foregroundColor(statusColor(invoice.status))
            }
        }
        .padding(.vertical, 4)
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    private func formattedAmount(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$"
        return formatter.string(from: NSNumber(value: amount)) ?? "$\(amount)"
    }
    
    private func statusColor(_ status: Invoice.Status) -> Color {
        switch status {
        case .draft:
            return .orange
        case .pending:
            return .blue
        case .paid:
            return .green
        case .overdue:
            return .red
        case .cancelled:
            return .gray
        }
    }
}

struct InvoiceDetailView: View {
    let invoice: Invoice
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var showingPDFPreview = false
    @State private var isGeneratingPDF = false
    @State private var showingEditInvoice = false
    @State private var showingStatusUpdateAlert = false
    
    // Computed properties to help avoid type-checking issues
    private var invoiceNumber: String {
        return invoice.number
    }
    
    private var invoiceDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: invoice.dateCreated)
    }
    
    // Separate views to break up the complex expressions
    private var headerView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Invoice " + invoiceNumber)
                .font(.title)
                .fontWeight(.bold)
            
            Text("Created on " + invoiceDate)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private var clientInformationView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Client Information")
                .font(.headline)
                .fontWeight(.semibold)
            
            Text(invoice.clientName)
                .font(.body)
            
            Text(invoice.clientAddress)
                .font(.body)
                .foregroundColor(.secondary)
                
            // Format and display phone if available
            if let phone = invoice.clientPhone, !phone.isEmpty {
                let formattedPhone = PhoneFormatterService.format(phone) ?? phone
                Text("Phone: " + formattedPhone)
                    .font(.body)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private var summaryView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Summary")
                .font(.headline)
                .fontWeight(.semibold)
            
            let subtotalString = String(format: "%.2f", invoice.subtotal)
            HStack {
                Text("Subtotal")
                Spacer()
                Text("$" + subtotalString)
            }
            
            let taxString = String(format: "%.2f", invoice.tax)
            HStack {
                Text("Tax")
                Spacer()
                Text("$" + taxString)
            }
            
            Divider()
            
            let totalString = String(format: "%.2f", invoice.totalAmount)
            HStack {
                Text("Total")
                    .fontWeight(.bold)
                Spacer()
                Text("$" + totalString)
                    .fontWeight(.bold)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    // More subviews to break up the complex UI
    private var statusView: some View {
        VStack(spacing: 10) {
            HStack {
                Text("Status:")
                    .fontWeight(.medium)
                
                Text(invoice.status.rawValue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(getStatusColor(invoice.status).opacity(0.2))
                    )
                    .foregroundColor(getStatusColor(invoice.status))
            }
            
            if let paymentMethod = invoice.paymentMethod {
                HStack {
                    Text("Payment Method:")
                        .fontWeight(.medium)
                    
                    Text(paymentMethod)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.blue.opacity(0.1))
                        )
                        .foregroundColor(.blue)
                }
            }
        }
        .padding(.horizontal)
    }
    
    private var itemsView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Items")
                .font(.headline)
                .fontWeight(.semibold)
            
            ForEach(invoice.items) { item in
                itemRow(item)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private func itemRow(_ item: InvoiceItem) -> some View {
        VStack {
            HStack {
                VStack(alignment: .leading) {
                    Text(item.name)
                        .font(.body)
                    
                    if let desc = item.itemDescription, !desc.isEmpty {
                        Text(desc)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                let formattedPrice = String(format: "%.2f", item.unitPrice)
                Text("\(item.quantity) × $\(formattedPrice)")
                    .font(.body)
            }
            .padding(.vertical, 4)
            
            if item.id != invoice.items.last?.id {
                Divider()
            }
        }
    }
    
    private var notesView: some View {
        Group {
            if !invoice.notes.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Notes")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(invoice.notes)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(12)
            }
        }
    }
    
    var body: some View {
        // Using regular NavigationView to avoid state issues with NavigationStack
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    headerView
                    statusView
                    clientInformationView
                    itemsView
                    summaryView
                    notesView
                }
                .padding()
            }
            .navigationTitle("Invoice Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                // Home button removed as requested
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            // Check if PDF exists first, regenerate if needed
                            if invoice.pdfURL == nil || !FileManager.default.fileExists(atPath: invoice.pdfURL!.path) {
                                regeneratePDF()
                            } else {
                                // Make sure we're not in generating state
                                isGeneratingPDF = false
                                // Show the PDF preview directly without delay
                                showingPDFPreview = true
                            }
                        } label: {
                            Label("View PDF", systemImage: "doc.text.fill")
                        }
                        
                        Button {
                            // Show edit functionality
                            showingEditInvoice = true
                        } label: {
                            Label("Edit Invoice", systemImage: "pencil")
                        }
                        
                        Button {
                            // Mark as paid functionality
                            markAsPaid()
                        } label: {
                            Label("Mark as Paid", systemImage: "checkmark.circle")
                        }
                        
                        Button(role: .destructive) {
                            dismiss()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                let modelContext = invoice.modelContext
                                // Before deleting invoice, first detach any InvoiceItems
                                for item in invoice.items {
                                    item.invoice = nil
                                }
                                modelContext?.delete(invoice)
                                try? modelContext?.save()
                            }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .alert("Status Updated", isPresented: $showingStatusUpdateAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Invoice has been marked as paid.")
            }
            .sheet(isPresented: $showingPDFPreview) {
                if isGeneratingPDF {
                    NavigationStack {
                        VStack(spacing: 20) {
                            ProgressView("Generating PDF...")
                                .progressViewStyle(CircularProgressViewStyle())
                                .padding()

                            Text("Please wait...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .navigationTitle("PDF Preview")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarLeading) {
                                Button("Cancel") {
                                    isGeneratingPDF = false
                                    showingPDFPreview = false
                                }
                            }
                        }
                    }
                } else if let pdfURL = invoice.pdfURL, FileManager.default.fileExists(atPath: pdfURL.path) {
                    // Use our PDF viewer without ID to prevent recreation issues
                    EstimatePDFPreviewWrapper(url: pdfURL)
                } else {
                    NavigationStack {
                        VStack(spacing: 20) {
                            Image(systemName: "doc.text.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 60, height: 60)
                                .foregroundColor(.secondary)

                            Text("PDF not available")
                                .font(.headline)

                            Text("This invoice doesn't have an associated PDF file yet.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)

                            Button(action: {
                                regeneratePDF()
                            }) {
                                Text("Generate PDF Now")
                                    .padding()
                                    .background(Color.accentColor)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                            }
                        }
                        .padding()
                        .navigationTitle("PDF Preview")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarLeading) {
                                Button("Close") {
                                    showingPDFPreview = false
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    func getStatusColor(_ status: Invoice.Status) -> Color {
        switch status {
        case .draft:
            return .orange
        case .pending:
            return .blue
        case .paid:
            return .green
        case .overdue:
            return .red
        case .cancelled:
            return .gray
        }
    }
    
    // Mark invoice as paid
    func markAsPaid() {
        // Update invoice status to paid
        invoice.status = .paid
        invoice.updatedAt = Date()
        try? modelContext.save()
        
        // Show success alert
        showingStatusUpdateAlert = true
    }
    
    // Update invoice with edited data
    private func updateInvoice(with updatedInvoice: InvoiceEditData) {
        // Update basic invoice information
        invoice.clientName = updatedInvoice.clientName
        invoice.clientAddress = updatedInvoice.clientAddress
        invoice.clientEmail = updatedInvoice.clientEmail
        invoice.clientPhone = updatedInvoice.clientPhone
        invoice.status = updatedInvoice.status
        invoice.paymentMethod = updatedInvoice.paymentMethod
        invoice.dueDate = updatedInvoice.dueDate
        invoice.notes = updatedInvoice.notes
        invoice.updatedAt = Date()
        
        // Save changes
        try? modelContext.save()
        
        // Regenerate PDF if needed
        if updatedInvoice.shouldRegeneratePDF {
            regeneratePDF()
        }
    }
    
    // Function to regenerate PDF
    func regeneratePDF() {
        // First show the loading screen
        isGeneratingPDF = true
        
        // Use a slight delay before showing the sheet to ensure proper state
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            showingPDFPreview = true
        }
        
        // Run on background thread
        DispatchQueue.global(qos: .userInitiated).async {
            // Create PDF settings
            let pdfService = PDFService()
            
            // Setup company info
            let companyName = UserDefaults.standard.string(forKey: "companyName") ?? "Your Company"
            let companyAddress = UserDefaults.standard.string(forKey: "companyAddress") ?? "Your Address"
            let companyEmail = UserDefaults.standard.string(forKey: "companyEmail") ?? "your@email.com"
            let companyPhone = UserDefaults.standard.string(forKey: "companyPhone") ?? "Your Phone"
            var companyLogo: UIImage?
            
            if let logoData = UserDefaults.standard.data(forKey: "companyLogo"),
               let logo = UIImage(data: logoData) {
                companyLogo = logo
            }
            
            // Convert InvoiceItems to PDFItems
            let pdfItems = invoice.items.map { item -> PDFItem in
                return PDFItem(
                    name: item.name,
                    description: item.itemDescription ?? "",
                    quantity: item.quantity,
                    unitPrice: item.unitPrice
                )
            }
            
            let settings = PDFSettings(
                documentTitle: "Invoice",
                companyLogo: companyLogo,
                companyName: companyName,
                companyAddress: companyAddress,
                companyEmail: companyEmail,
                companyPhone: companyPhone,
                recipientName: invoice.clientName,
                recipientAddress: invoice.clientAddress,
                documentNumber: invoice.number,
                documentDate: invoice.dateCreated,
                dueDate: invoice.dueDate,
                currency: "$",
                items: pdfItems,
                subtotal: invoice.subtotal,
                discount: invoice.discount,
                discountType: invoice.discountType,
                tax: invoice.tax,
                taxRate: invoice.taxRate,
                totalAmount: invoice.totalAmount,
                notes: invoice.notes.isEmpty ? nil : invoice.notes,
                disclaimer: invoice.footerNote,
                theme: DocumentTheme(rawValue: invoice.templateType) ?? .classic,
                includeSignature: false,
                signatureImage: nil
            )
            
            // Generate PDF
            if let pdfURL = pdfService.generatePDF(for: .invoice, settings: settings) {
                // Add a small pause for better UX if PDF generation is very fast
                Thread.sleep(forTimeInterval: 0.5)
                
                // Update invoice with new PDF URL
                DispatchQueue.main.async {
                    invoice.pdfURL = pdfURL
                    try? modelContext.save()
                    
                    // Stop the loading indicator after a slight delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        isGeneratingPDF = false
                    }
                }
            } else {
                // Failed to generate PDF - dismiss sheet completely after a delay
                Thread.sleep(forTimeInterval: 0.5)
                DispatchQueue.main.async {
                    isGeneratingPDF = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        showingPDFPreview = false
                    }
                }
            }
        }
    }
}
