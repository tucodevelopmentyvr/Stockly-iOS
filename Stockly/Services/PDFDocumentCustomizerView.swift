import SwiftUI

struct PDFDocumentCustomizerView: View {
    @State private var documentType: DocumentType
    @State private var showPreview = false
    @State private var previewURL: URL?
    @Environment(\.presentationMode) var presentationMode
    
    // Sample data for preview
    private let sampleSettings: PDFSettings = {
        return PDFSettings(
            documentTitle: "Sample Document",
            companyLogo: UIImage(systemName: "building.2")?.withTintColor(.blue, renderingMode: .alwaysOriginal),
            companyName: "Acme Corporation",
            companyAddress: "123 Business Street, City, Country",
            companyEmail: "info@acmecorp.example",
            companyPhone: "+1 (555) 123-4567",
            recipientName: "John Smith",
            recipientAddress: "456 Client Road, Town, Country",
            documentNumber: "INV-2025-001",
            documentDate: Date(),
            dueDate: Calendar.current.date(byAdding: .day, value: 30, to: Date()),
            currency: "$",
            items: [
                PDFItem(name: "Product A", description: "High-quality item", quantity: 2, unitPrice: 49.99),
                PDFItem(name: "Service B", description: "Professional service", quantity: 1, unitPrice: 199.99),
                PDFItem(name: "Product C", description: "Essential component", quantity: 5, unitPrice: 29.99)
            ],
            subtotal: nil,
            discount: 10,
            discountType: "percentage",
            tax: nil,
            taxRate: 8.5,
            totalAmount: nil,
            notes: "Thank you for your business!",
            disclaimer: "This document is valid for 30 days from the issue date.",
            theme: .custom,
            includeSignature: true,
            signatureImage: nil
        )
    }()
    
    init(for documentType: DocumentType) {
        _documentType = State(initialValue: documentType)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Document Layout Customizer")
                    .font(.headline)
                Spacer()
                Button("Close") {
                    presentationMode.wrappedValue.dismiss()
                }
                .padding(.horizontal)
            }
            .padding()
            .background(Color(.systemGray6))
            
            // Main content with editor and preview buttons
            ZStack {
                // Layout editor view
                PDFLayoutEditorView(for: documentType)
                
                // Preview button overlay at bottom
                VStack {
                    Spacer()
                    
                    Button(action: {
                        generatePreview()
                    }) {
                        HStack {
                            Image(systemName: "eye")
                            Text("Preview Document")
                        }
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .padding(.bottom, 20)
                }
            }
        }
        .sheet(isPresented: $showPreview) {
            if let url = previewURL {
                PDFPreviewView(url: url)
                    .ignoresSafeArea()
            } else {
                Text("Error generating preview")
                    .padding()
            }
        }
    }
    
    private func generatePreview() {
        // Create a temporary settings object with the sample data
        var previewSettings = sampleSettings
        
        // Set the appropriate title based on document type
        switch documentType {
        case .invoice:
            previewSettings.documentTitle = "Invoice"
        case .estimate:
            previewSettings.documentTitle = "Estimate"
        case .consignment:
            previewSettings.documentTitle = "Consignment"
        }
        
        // Generate PDF with the customized layout
        let pdfService = PDFService()
        if let url = pdfService.generatePDF(for: documentType, settings: previewSettings) {
            previewURL = url
            showPreview = true
        }
    }
}

// MARK: - Theme Selection View
struct DocumentThemeSelector: View {
    @Binding var selectedTheme: DocumentTheme
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Document Theme")
                .font(.headline)
                .padding(.bottom, 5)
            
            ForEach(DocumentTheme.allCases, id: \.self) { theme in
                Button(action: {
                    selectedTheme = theme
                }) {
                    HStack {
                        Image(systemName: selectedTheme == theme ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(selectedTheme == theme ? .blue : .gray)
                        
                        Text(theme.rawValue.capitalized)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        if theme == .custom {
                            Image(systemName: "pencil")
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding(.horizontal)
    }
}

// Integration point for showing the customizer from document creation screens
extension View {
    func documentCustomizer(for documentType: DocumentType, isPresented: Binding<Bool>) -> some View {
        self.sheet(isPresented: isPresented) {
            PDFDocumentCustomizerView(for: documentType)
        }
    }
}