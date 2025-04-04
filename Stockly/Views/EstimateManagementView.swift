import SwiftUI
import SwiftData
import Foundation

// MARK: - Estimate Edit Data Model
struct EstimateEditData {
    var clientName: String
    var clientAddress: String
    var clientEmail: String?
    var clientPhone: String?
    var status: Estimate.Status
    var expiryDate: Date
    var notes: String
    var shouldRegeneratePDF: Bool = false
    
    init(from estimate: Estimate) {
        self.clientName = estimate.clientName
        self.clientAddress = estimate.clientAddress
        self.clientEmail = estimate.clientEmail
        self.clientPhone = estimate.clientPhone
        self.status = estimate.status
        self.expiryDate = estimate.expiryDate
        self.notes = estimate.notes
    }
}

// MARK: - Estimate Edit View
struct EstimateEditView: View {
    let estimate: Estimate
    let onSave: (EstimateEditData) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var editData: EstimateEditData
    @State private var showRegeneratePDFAlert = false
    
    init(estimate: Estimate, onSave: @escaping (EstimateEditData) -> Void) {
        self.estimate = estimate
        self.onSave = onSave
        _editData = State(initialValue: EstimateEditData(from: estimate))
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
                
                // Estimate Details Section
                Section(header: Text("Estimate Details")) {
                    Picker("Status", selection: $editData.status) {
                        Text("Draft").tag(Estimate.Status.draft)
                        Text("Sent").tag(Estimate.Status.sent)
                        Text("Accepted").tag(Estimate.Status.accepted)
                        Text("Rejected").tag(Estimate.Status.rejected)
                        Text("Expired").tag(Estimate.Status.expired)
                        Text("Converted").tag(Estimate.Status.converted)
                    }
                    
                    DatePicker("Expiry Date", selection: $editData.expiryDate, displayedComponents: [.date])
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
            .navigationTitle("Edit Estimate")
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
                Text("You've made significant changes to this estimate. Would you like to update the PDF?")
            }
        }
    }
    
    // Determine if important fields have changed
    private func hasSignificantChanges() -> Bool {
        return editData.clientName != estimate.clientName ||
               editData.clientAddress != estimate.clientAddress ||
               editData.status != estimate.status
    }
    
    // Save changes and dismiss
    private func saveAndDismiss() {
        onSave(editData)
        dismiss()
    }
}

struct EstimateManagementView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewMode: ViewMode = .issued
    @Environment(\.presentationMode) private var presentationMode
    
    enum ViewMode {
        case issued
        case create
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Tab Selection
            Picker("View", selection: $viewMode) {
                Text("Issued Estimates").tag(ViewMode.issued)
                Text("Create New").tag(ViewMode.create)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            
            // Content based on selected tab
            if viewMode == .issued {
                IssuedEstimatesView()
            } else {
                EstimateGeneratorView(modelContext: modelContext)
            }
        }
        .navigationTitle("Estimates")
        .toolbar {
            ToolbarItem(placement: .principal) {
                HomeButtonLink()
            }
            // No additional back button needed - just use the home button in the center
        }
    }
}

struct IssuedEstimatesView: View {
    @Environment(\.modelContext) private var modelContext
    
    // Make the query more explicit with a full descriptor
    @Query(FetchDescriptor<Estimate>(sortBy: [SortDescriptor<Estimate>(\.dateCreated, order: .reverse)]))
    private var estimates: [Estimate]
    @State private var searchText = ""
    @State private var sortOrder: SortOrder = .dateDesc
    @State private var showingEstimateDetail = false
    @State private var selectedEstimate: Estimate?
    @State private var showingDeleteConfirmation = false
    
    enum SortOrder {
        case dateDesc
        case dateAsc
        case numberAsc
        case numberDesc
        case amountDesc
        case amountAsc
    }
    
    var filteredEstimates: [Estimate] {
        let filtered = searchText.isEmpty 
            ? estimates 
            : estimates.filter { 
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
    
    var body: some View {
        VStack {
            if estimates.isEmpty {
                ContentUnavailableView(
                    "No Estimates Yet",
                    systemImage: "doc.text",
                    description: Text("Create your first estimate to get started.")
                )
            } else {
                List {
                    ForEach(filteredEstimates) { estimate in
                        // Use NavigationLink instead of tap gesture for reliable navigation
                        NavigationLink(destination: 
                            EstimateDetailView(estimate: estimate)
                        ) {
                            EstimateListItem(estimate: estimate)
                                .contentShape(Rectangle())
                        }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    selectedEstimate = estimate
                                    showingDeleteConfirmation = true
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                }
                .searchable(text: $searchText, prompt: "Search estimates...")
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
        .alert("Delete Estimate", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let estimate = selectedEstimate {
                    deleteEstimate(estimate)
                }
            }
        } message: {
            Text("Are you sure you want to delete this estimate? This action cannot be undone.")
        }
        // Don't use UUID() for ID as it causes view recreation issues
    }
    
    private func deleteEstimate(_ estimate: Estimate) {
        // Before deleting estimate, first detach any EstimateItems
        for item in estimate.items {
            item.estimate = nil
        }
        modelContext.delete(estimate)
        try? modelContext.save()
    }
}

struct EstimateListItem: View {
    let estimate: Estimate
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(estimate.number)
                    .font(.headline)
                
                Text(estimate.clientName)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(formattedDate(estimate.dateCreated))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(formattedAmount(estimate.totalAmount))
                    .font(.headline)
                
                Text(estimate.status.rawValue)
                    .font(.caption)
                    .padding(4)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(statusColor(estimate.status).opacity(0.2))
                    )
                    .foregroundColor(statusColor(estimate.status))
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
    
    private func statusColor(_ status: Estimate.Status) -> Color {
        switch status {
        case .draft:
            return .orange
        case .sent:
            return .blue
        case .accepted:
            return .green
        case .rejected:
            return .red
        case .expired:
            return .gray
        case .converted:
            return .purple
        }
    }
}

struct EstimateDetailView: View {
    let estimate: Estimate
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var showingPDFPreview = false
    @State private var isGeneratingPDF = false
    @State private var showingEditEstimate = false
    @State private var showingStatusUpdateAlert = false
    
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
    
    private func statusColor(_ status: Estimate.Status) -> Color {
        switch status {
        case .draft:
            return .orange
        case .sent:
            return .blue
        case .accepted:
            return .green
        case .rejected:
            return .red
        case .expired:
            return .gray
        case .converted:
            return .purple
        }
    }
    
    var body: some View {
        // Using NavigationView instead of NavigationStack for better stability
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Estimate #\(estimate.number)")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("Created on \(formattedDate(estimate.dateCreated))")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(12)
                    
                    // Status
                    VStack(spacing: 10) {
                        HStack {
                            Text("Status:")
                                .fontWeight(.medium)
                            
                            Text(estimate.status.rawValue)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(statusColor(estimate.status).opacity(0.2))
                                )
                                .foregroundColor(statusColor(estimate.status))
                        }
                        
                        HStack {
                            Text("Valid Until:")
                                .fontWeight(.medium)
                            
                            Text(formattedDate(estimate.expiryDate))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.blue.opacity(0.1))
                                )
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Client Information
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Client Information")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text(estimate.clientName)
                            .font(.body)
                        
                        Text(estimate.clientAddress)
                            .font(.body)
                            .foregroundColor(.secondary)
                            
                        // Format and display phone if available
                        if let phone = estimate.clientPhone, !phone.isEmpty {
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
                    
                    // Items
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Items")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        ForEach(estimate.items) { item in
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
                                
                                if item.id != estimate.items.last?.id {
                                    Divider()
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(12)
                    
                    // Summary
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Summary")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        let subtotalString = String(format: "%.2f", estimate.subtotal)
                        HStack {
                            Text("Subtotal")
                            Spacer()
                            Text("$" + subtotalString)
                        }
                        
                        let taxString = String(format: "%.2f", estimate.tax)
                        HStack {
                            Text("Tax")
                            Spacer()
                            Text("$" + taxString)
                        }
                        
                        Divider()
                        
                        let totalString = String(format: "%.2f", estimate.totalAmount)
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
                    
                    // Notes
                    if !estimate.notes.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Notes")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Text(estimate.notes)
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(12)
                    }
                }
                .padding()
            }
            .navigationTitle("Estimate Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") {
                        dismiss()
                    }
                }
                
                // Home button removed as requested
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            // Check if PDF exists first, regenerate if needed
                            if estimate.pdfURL == nil || !FileManager.default.fileExists(atPath: estimate.pdfURL!.path) {
                                regeneratePDF()
                            } else {
                                // Make sure we're not in generating state
                                isGeneratingPDF = false
                                // Show PDF viewer without closing/reopening - directly
                                showingPDFPreview = true
                            }
                        } label: {
                            Label("View PDF", systemImage: "doc.text.fill")
                        }
                        
                        Button {
                            // Show edit functionality
                            showingEditEstimate = true
                        } label: {
                            Label("Edit Estimate", systemImage: "pencil")
                        }
                        
                        Button {
                            // Mark as accepted functionality
                            markAsAccepted()
                        } label: {
                            Label("Mark as Accepted", systemImage: "checkmark.circle")
                        }
                        
                        Button(role: .destructive) {
                            dismiss()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                let modelContext = estimate.modelContext
                                // Before deleting estimate, first detach any EstimateItems
                                for item in estimate.items {
                                    item.estimate = nil
                                }
                                modelContext?.delete(estimate)
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
            // Force view to refresh when shown
            .id(UUID())
            .sheet(isPresented: $showingEditEstimate) {
                EstimateEditView(estimate: estimate, onSave: { updatedEstimate in
                    updateEstimate(with: updatedEstimate)
                })
            }
            .alert("Status Updated", isPresented: $showingStatusUpdateAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Estimate has been marked as accepted.")
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
                } else if let pdfURL = estimate.pdfURL, FileManager.default.fileExists(atPath: pdfURL.path) {
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

                            Text("This estimate doesn't have an associated PDF file yet.")
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
    
    // Mark estimate as accepted
    func markAsAccepted() {
        // Update estimate status to accepted
        estimate.status = .accepted
        estimate.updatedAt = Date()
        try? modelContext.save()
        
        // Show success alert
        showingStatusUpdateAlert = true
    }
    
    // Update estimate with edited data
    private func updateEstimate(with updatedEstimate: EstimateEditData) {
        // Update basic estimate information
        estimate.clientName = updatedEstimate.clientName
        estimate.clientAddress = updatedEstimate.clientAddress
        estimate.clientEmail = updatedEstimate.clientEmail
        estimate.clientPhone = updatedEstimate.clientPhone
        estimate.status = updatedEstimate.status
        estimate.expiryDate = updatedEstimate.expiryDate
        estimate.notes = updatedEstimate.notes
        estimate.updatedAt = Date()
        
        // Save changes
        try? modelContext.save()
        
        // Regenerate PDF if needed
        if updatedEstimate.shouldRegeneratePDF {
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
            
            // Convert EstimateItems to PDFItems
            let pdfItems = estimate.items.map { item -> PDFItem in
                return PDFItem(
                    name: item.name,
                    description: item.itemDescription ?? "",
                    quantity: item.quantity,
                    unitPrice: item.unitPrice
                )
            }
            
            let settings = PDFSettings(
                documentTitle: "Estimate",
                companyLogo: companyLogo,
                companyName: companyName,
                companyAddress: companyAddress,
                companyEmail: companyEmail,
                companyPhone: companyPhone,
                recipientName: estimate.clientName,
                recipientAddress: estimate.clientAddress,
                documentNumber: estimate.number,
                documentDate: estimate.dateCreated,
                dueDate: estimate.expiryDate,
                currency: "$",
                items: pdfItems,
                notes: estimate.notes.isEmpty ? nil : estimate.notes,
                disclaimer: estimate.footerNote,
                theme: DocumentTheme(rawValue: estimate.templateType) ?? .classic,
                includeSignature: false,
                signatureImage: nil
            )
            
            // Generate PDF
            if let pdfURL = pdfService.generatePDF(for: .estimate, settings: settings) {
                // Add a small pause for better UX if PDF generation is very fast
                Thread.sleep(forTimeInterval: 0.5)
                
                // Update estimate with new PDF URL
                DispatchQueue.main.async {
                    estimate.pdfURL = pdfURL
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

// Wrapper for PDF Preview
struct EstimatePDFPreviewWrapper: View {
    let url: URL
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var navigationRouter: NavigationRouter
    
    var body: some View {
        NavigationView {
            PDFPreviewView(url: url)
                .navigationTitle("PDF Preview")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Close") {
                            dismiss()
                        }
                    }
                    
                    ToolbarItem(placement: .principal) {
                        Button(action: {
                            dismiss()
                            // Use a slight delay before posting the notification
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                NotificationCenter.default.post(name: NSNotification.Name("ReturnToMainMenu"), object: nil)
                                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                                   let rootVC = windowScene.windows.first?.rootViewController {
                                    rootVC.dismiss(animated: true)
                                }
                            }
                        }) {
                            Image(systemName: "house.fill")
                                .imageScale(.large)
                                .foregroundColor(.accentColor)
                        }
                    }
                    
                    ToolbarItem(placement: .navigationBarTrailing) {
                        ShareLink(item: url)
                    }
                }
        }
    }
}