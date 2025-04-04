import Foundation
import UIKit
import PDFKit
import SwiftUI

enum DocumentType {
    case invoice
    case consignment
    case estimate
}

enum DocumentTheme: String, CaseIterable {
    case classic
    case modern
    case minimalist
    case professional
    case custom
}

struct PDFSettings {
    var documentTitle: String
    var companyLogo: UIImage?
    var companyName: String
    var companyAddress: String
    var companyEmail: String
    var companyPhone: String
    var recipientName: String
    var recipientAddress: String
    var documentNumber: String
    var documentDate: Date
    var dueDate: Date?
    var currency: String
    var items: [PDFItem]
    var subtotal: Double?
    var discount: Double?
    var discountType: String?
    var tax: Double?
    var taxRate: Double?
    var totalAmount: Double?
    var notes: String?
    var disclaimer: String?
    var theme: DocumentTheme
    var includeSignature: Bool
    var signatureImage: UIImage?
}

struct PDFItem {
    var name: String
    var description: String
    var quantity: Int
    var unitPrice: Double
    
    var total: Double {
        return Double(quantity) * unitPrice
    }
}

// Main PDF Service class
class PDFService {
    // MARK: - Public Methods
    
    /// Primary method to generate a PDF document and save it to a specified location
    /// - Returns: URL to the saved PDF file (nil if generation failed)
    func generatePDF(for type: DocumentType, settings: PDFSettings) -> URL? {
        // Create PDF data
        guard let pdfData = createPDFData(for: type, settings: settings) else {
            print("Failed to generate PDF data")
            return nil
        }
        
        // Generate file name
        let fileName = generateFileName(for: type, number: settings.documentNumber)
        
        // Save PDF to documents directory
        return savePDFToDocuments(data: pdfData, fileName: fileName)
    }
    
    /// Share generated PDF with the system share sheet
    func sharePDF(from viewController: UIViewController, fileURL: URL) {
        let activityViewController = UIActivityViewController(
            activityItems: [fileURL], 
            applicationActivities: nil
        )
        
        // On iPad, present from a popover
        if let popover = activityViewController.popoverPresentationController {
            popover.sourceView = viewController.view
            popover.sourceRect = CGRect(x: viewController.view.bounds.midX, 
                                       y: viewController.view.bounds.midY, 
                                       width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        viewController.present(activityViewController, animated: true)
    }
    
    // MARK: - Private Methods
    
    /// Create the actual PDF data
    private func createPDFData(for type: DocumentType, settings: PDFSettings) -> Data? {
        // Create a PDF document format (A4 size)
        let pageRect = CGRect(x: 0, y: 0, width: 595.2, height: 841.8)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        
        // Load custom layout if available
        let layout = PDFLayoutService.loadLayout(for: type)
        
        // Generate PDF data
        let data = renderer.pdfData { (context) in
            context.beginPage()
            
            if settings.theme == .custom && !layout.isEmpty {
                // Render using custom layout
                renderWithCustomLayout(context: context.cgContext, in: pageRect, settings: settings, layout: layout, type: type)
            } else {
                // Add content to the PDF based on document type and theme
                switch type {
                case .invoice:
                    renderInvoice(context: context.cgContext, in: pageRect, settings: settings)
                case .consignment:
                    renderConsignment(context: context.cgContext, in: pageRect, settings: settings)
                case .estimate:
                    renderEstimate(context: context.cgContext, in: pageRect, settings: settings)
                }
            }
        }
        
        return data
    }
    
    /// Generate a meaningful file name for the PDF
    private func generateFileName(for type: DocumentType, number: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd"
        let dateString = dateFormatter.string(from: Date())
        
        let documentName: String
        switch type {
        case .invoice:
            documentName = "Invoice"
        case .consignment:
            documentName = "Consignment"
        case .estimate:
            documentName = "Estimate"
        }
        
        return "\(documentName)_\(number)_\(dateString)"
    }
    
    /// Save PDF data to the documents directory
    func savePDFToDocuments(data: Data, fileName: String) -> URL? {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("Could not access documents directory")
            return nil
        }
        
        let fileURL = documentsDirectory.appendingPathComponent("\(fileName).pdf")
        
        do {
            try data.write(to: fileURL)
            return fileURL
        } catch {
            print("Error saving PDF: \(error)")
            return nil
        }
    }
    
    // MARK: - PDF Rendering Methods
    
    /// Render a PDF using custom layout
    private func renderWithCustomLayout(context: CGContext, in rect: CGRect, settings: PDFSettings, layout: [ComponentLayout], type: DocumentType) {
        // Sort components by z-index to determine rendering order
        let sortedComponents = layout.sorted { $0.zIndex < $1.zIndex }
        
        // Dictionary of rendering functions for each component type
        let componentRenderers: [PDFComponentType: (CGContext, CGRect, PDFSettings) -> Void] = [
            .companyLogo: { [self] ctx, r, s in self.renderCompanyLogo(context: ctx, in: r, settings: s) },
            .companyInfo: { [self] ctx, r, s in self.renderCompanyInfo(context: ctx, in: r, settings: s) },
            .clientInfo: { [self] ctx, r, s in self.renderClientInfo(context: ctx, in: r, settings: s) },
            .documentTitle: { [self] ctx, r, s in self.renderDocumentTitle(ctx, r, s, type: type) },
            .documentDate: { [self] ctx, r, s in self.renderDocumentDate(ctx, r, s, type: type) },
            .itemsTable: { [self] ctx, r, s in self.renderItemsTable(context: ctx, in: r, settings: s) },
            .summary: { [self] ctx, r, s in self.renderSummary(context: ctx, in: r, settings: s) },
            .notes: { [self] ctx, r, s in self.renderNotes(context: ctx, in: r, settings: s) },
            .signature: { [self] ctx, r, s in self.renderSignature(context: ctx, in: r, settings: s) },
            .disclaimer: { [self] ctx, r, s in self.renderDisclaimer(context: ctx, in: r, settings: s) }
        ]
        
        // Render each component based on its custom position and size
        for component in sortedComponents where component.isVisible {
            guard let componentType = PDFComponentType(rawValue: component.componentType),
                  let renderer = componentRenderers[componentType] else {
                continue
            }
            
            // Create a graphics context state to isolate each component's rendering
            context.saveGState()
            
            // Call the specific rendering function for this component
            renderer(context, component.rect, settings)
            
            context.restoreGState()
        }
    }
    
    /// Render company logo component
    private func renderCompanyLogo(context: CGContext, in rect: CGRect, settings: PDFSettings) {
        if let logo = settings.companyLogo {
            logo.draw(in: rect)
        }
    }
    
    /// Render company info component
    private func renderCompanyInfo(context: CGContext, in rect: CGRect, settings: PDFSettings) {
        let companyAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12),
            .foregroundColor: UIColor.darkGray
        ]
        
        let companyNameAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 16),
            .foregroundColor: UIColor.black
        ]
        
        let nameString = NSAttributedString(string: settings.companyName, attributes: companyNameAttributes)
        nameString.draw(at: CGPoint(x: rect.maxX - nameString.size().width, y: rect.minY))
        
        let addressString = NSAttributedString(string: settings.companyAddress, attributes: companyAttributes)
        addressString.draw(at: CGPoint(x: rect.maxX - addressString.size().width, y: rect.minY + 20))
        
        let emailString = NSAttributedString(string: settings.companyEmail, attributes: companyAttributes)
        emailString.draw(at: CGPoint(x: rect.maxX - emailString.size().width, y: rect.minY + 40))
        
        let phoneString = NSAttributedString(string: settings.companyPhone, attributes: companyAttributes)
        phoneString.draw(at: CGPoint(x: rect.maxX - phoneString.size().width, y: rect.minY + 60))
    }
    
    /// Render client info component
    private func renderClientInfo(context: CGContext, in rect: CGRect, settings: PDFSettings) {
        let recipientAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12),
            .foregroundColor: UIColor.black
        ]
        
        let recipientTitleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 14),
            .foregroundColor: UIColor.black
        ]
        
        let billToString = NSAttributedString(string: "Bill To:", attributes: recipientTitleAttributes)
        billToString.draw(at: CGPoint(x: rect.minX, y: rect.minY))
        
        let recipientNameString = NSAttributedString(string: settings.recipientName, attributes: recipientAttributes)
        recipientNameString.draw(at: CGPoint(x: rect.minX, y: rect.minY + 20))
        
        let recipientAddressString = NSAttributedString(string: settings.recipientAddress, attributes: recipientAttributes)
        recipientAddressString.draw(at: CGPoint(x: rect.minX, y: rect.minY + 40))
    }
    
    /// Render document title based on type
    private func renderDocumentTitle(_ context: CGContext, _ rect: CGRect, _ settings: PDFSettings, type: DocumentType) {
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 24),
            .foregroundColor: UIColor.black
        ]
        
        let title: String
        switch type {
        case .invoice:
            title = "INVOICE"
        case .estimate:
            title = "ESTIMATE"
        case .consignment:
            title = "CONSIGNMENT NOTE"
        }
        
        let titleString = NSAttributedString(string: title, attributes: titleAttributes)
        titleString.draw(at: CGPoint(x: rect.midX - titleString.size().width / 2, y: rect.minY))
        
        let numberAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14),
            .foregroundColor: UIColor.darkGray
        ]
        
        let prefix: String
        switch type {
        case .invoice:
            prefix = "Invoice #:"
        case .estimate:
            prefix = "Estimate #:"
        case .consignment:
            prefix = "Consignment #:"
        }
        
        let numberString = NSAttributedString(string: "\(prefix) \(settings.documentNumber)", attributes: numberAttributes)
        numberString.draw(at: CGPoint(x: rect.midX - numberString.size().width / 2, y: rect.minY + 30))
    }
    
    /// Render document date information based on document type
    private func renderDocumentDate(_ context: CGContext, _ rect: CGRect, _ settings: PDFSettings, type: DocumentType) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        
        let dateAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12),
            .foregroundColor: UIColor.darkGray
        ]
        
        let dateString = NSAttributedString(string: "Date: \(dateFormatter.string(from: settings.documentDate))", attributes: dateAttributes)
        dateString.draw(at: CGPoint(x: rect.maxX - dateString.size().width, y: rect.minY))
        
        if let dueDate = settings.dueDate {
            let dueDateLabel: String
            switch type {
            case .invoice:
                dueDateLabel = "Due Date:"
            case .estimate:
                dueDateLabel = "Valid Until:"
            case .consignment:
                dueDateLabel = "Delivery Date:"
            }
            
            let dueDateString = NSAttributedString(string: "\(dueDateLabel) \(dateFormatter.string(from: dueDate))", attributes: dateAttributes)
            dueDateString.draw(at: CGPoint(x: rect.maxX - dueDateString.size().width, y: rect.minY + 20))
        }
    }
    
    /// Render the items table
    private func renderItemsTable(context: CGContext, in rect: CGRect, settings: PDFSettings) {
        // Header row
        let headerAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 12),
            .foregroundColor: UIColor.white
        ]
        
        // Draw header background
        context.setFillColor(UIColor.darkGray.cgColor)
        context.fill(CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: 25))
        
        // Calculate column widths based on total width
        let itemWidth = rect.width * 0.3
        let descWidth = rect.width * 0.3
        let qtyWidth = rect.width * 0.1
        let priceWidth = rect.width * 0.15
        let totalWidth = rect.width * 0.15
        
        // Column positions
        let itemX = rect.minX + 10
        let descX = itemX + itemWidth
        let qtyX = descX + descWidth
        let priceX = qtyX + qtyWidth
        let totalX = priceX + priceWidth
        
        // Draw header text
        let nameHeaderString = NSAttributedString(string: "Item", attributes: headerAttributes)
        nameHeaderString.draw(at: CGPoint(x: itemX, y: rect.minY + 5))
        
        let descHeaderString = NSAttributedString(string: "Description", attributes: headerAttributes)
        descHeaderString.draw(at: CGPoint(x: descX, y: rect.minY + 5))
        
        let qtyHeaderString = NSAttributedString(string: "Qty", attributes: headerAttributes)
        qtyHeaderString.draw(at: CGPoint(x: qtyX, y: rect.minY + 5))
        
        let priceHeaderString = NSAttributedString(string: "Price", attributes: headerAttributes)
        priceHeaderString.draw(at: CGPoint(x: priceX, y: rect.minY + 5))
        
        let totalHeaderString = NSAttributedString(string: "Total", attributes: headerAttributes)
        totalHeaderString.draw(at: CGPoint(x: totalX, y: rect.minY + 5))
        
        // Draw items
        let rowAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12),
            .foregroundColor: UIColor.black
        ]
        
        let rowHeight: CGFloat = 30
        let visibleRows = min(Int((rect.height - 30) / rowHeight), settings.items.count)
        
        for index in 0..<visibleRows {
            let item = settings.items[index]
            let yPos = rect.minY + 30 + CGFloat(index) * rowHeight
            
            // Alternating row background
            if index % 2 == 1 {
                context.setFillColor(UIColor(white: 0.95, alpha: 1.0).cgColor)
                context.fill(CGRect(x: rect.minX, y: yPos, width: rect.width, height: rowHeight))
            }
            
            let nameString = NSAttributedString(string: item.name, attributes: rowAttributes)
            nameString.draw(at: CGPoint(x: itemX, y: yPos + 5))
            
            let descString = NSAttributedString(string: item.description, attributes: rowAttributes)
            descString.draw(at: CGPoint(x: descX, y: yPos + 5))
            
            let qtyString = NSAttributedString(string: "\(item.quantity)", attributes: rowAttributes)
            qtyString.draw(at: CGPoint(x: qtyX, y: yPos + 5))
            
            let priceString = NSAttributedString(string: "\(settings.currency) \(String(format: "%.2f", item.unitPrice))", attributes: rowAttributes)
            priceString.draw(at: CGPoint(x: priceX, y: yPos + 5))
            
            let totalString = NSAttributedString(string: "\(settings.currency) \(String(format: "%.2f", item.total))", attributes: rowAttributes)
            totalString.draw(at: CGPoint(x: totalX, y: yPos + 5))
            
            // Draw divider line
            context.setStrokeColor(UIColor.lightGray.cgColor)
            context.setLineWidth(0.5)
            context.move(to: CGPoint(x: rect.minX, y: yPos + rowHeight))
            context.addLine(to: CGPoint(x: rect.maxX, y: yPos + rowHeight))
            context.strokePath()
        }
        
        // If we have more items than can fit, show an indicator
        if settings.items.count > visibleRows {
            let moreItemsAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.italicSystemFont(ofSize: 10),
                .foregroundColor: UIColor.darkGray
            ]
            
            let moreItemsString = NSAttributedString(
                string: "... and \(settings.items.count - visibleRows) more items",
                attributes: moreItemsAttributes
            )
            
            let yPos = rect.minY + 30 + CGFloat(visibleRows) * rowHeight + 5
            moreItemsString.draw(at: CGPoint(x: rect.midX - moreItemsString.size().width / 2, y: yPos))
        }
    }
    
    /// Render financial summary component
    private func renderSummary(context: CGContext, in rect: CGRect, settings: PDFSettings) {
        let regularAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14),
            .foregroundColor: UIColor.black
        ]
        
        let totalAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 16),
            .foregroundColor: UIColor.black
        ]
        
        var yPosition: CGFloat = rect.minY
        
        // Calculate or use provided subtotal
        let subtotal = settings.subtotal ?? settings.items.reduce(0) { $0 + $1.total }
        
        // Subtotal
        let subtotalString = NSAttributedString(
            string: "Subtotal: \(settings.currency) \(String(format: "%.2f", subtotal))",
            attributes: regularAttributes
        )
        subtotalString.draw(at: CGPoint(x: rect.maxX - subtotalString.size().width, y: yPosition))
        yPosition += 25
        
        // Discount (if available and not zero)
        if let discount = settings.discount, discount > 0 {
            let discountLabel: String
            if let discountType = settings.discountType, discountType == "percentage" {
                discountLabel = "Discount (\(String(format: "%.1f", discount))%): -\(settings.currency) "
                // Calculate discount amount based on percentage
                let discountAmount = subtotal * (discount / 100)
                let discountString = NSAttributedString(
                    string: discountLabel + String(format: "%.2f", discountAmount),
                    attributes: regularAttributes
                )
                discountString.draw(at: CGPoint(x: rect.maxX - discountString.size().width, y: yPosition))
            } else {
                let discountString = NSAttributedString(
                    string: "Discount: -\(settings.currency) \(String(format: "%.2f", discount))",
                    attributes: regularAttributes
                )
                discountString.draw(at: CGPoint(x: rect.maxX - discountString.size().width, y: yPosition))
            }
            yPosition += 25
        }
        
        // Tax
        if let tax = settings.tax, tax > 0 {
            let taxLabel: String
            if let taxRate = settings.taxRate {
                taxLabel = "Tax (\(String(format: "%.1f", taxRate))%): \(settings.currency) "
            } else {
                taxLabel = "Tax: \(settings.currency) "
            }
            
            let taxString = NSAttributedString(
                string: taxLabel + String(format: "%.2f", tax),
                attributes: regularAttributes
            )
            taxString.draw(at: CGPoint(x: rect.maxX - taxString.size().width, y: yPosition))
            yPosition += 25
        }
        
        // Divider line before total
        context.setStrokeColor(UIColor.lightGray.cgColor)
        context.setLineWidth(0.5)
        context.move(to: CGPoint(x: rect.maxX - 200, y: yPosition - 5))
        context.addLine(to: CGPoint(x: rect.maxX, y: yPosition - 5))
        context.strokePath()
        
        // Total
        let finalTotal = settings.totalAmount ?? subtotal - (settings.discount ?? 0) + (settings.tax ?? 0)
        let totalString = NSAttributedString(
            string: "Total: \(settings.currency) \(String(format: "%.2f", finalTotal))",
            attributes: totalAttributes
        )
        totalString.draw(at: CGPoint(x: rect.maxX - totalString.size().width, y: yPosition))
    }
    
    /// Render notes component
    private func renderNotes(context: CGContext, in rect: CGRect, settings: PDFSettings) {
        if let notes = settings.notes, !notes.isEmpty {
            let notesAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12),
                .foregroundColor: UIColor.darkGray
            ]
            
            let notesTitleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 14),
                .foregroundColor: UIColor.black
            ]
            
            let notesTitleString = NSAttributedString(string: "Notes:", attributes: notesTitleAttributes)
            notesTitleString.draw(at: CGPoint(x: rect.minX, y: rect.minY))
            
            let notesString = NSAttributedString(string: notes, attributes: notesAttributes)
            notesString.draw(at: CGPoint(x: rect.minX, y: rect.minY + 20))
        }
    }
    
    /// Render signature component
    private func renderSignature(context: CGContext, in rect: CGRect, settings: PDFSettings) {
        if settings.includeSignature {
            let signatureAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12),
                .foregroundColor: UIColor.black
            ]
            
            let signatureLineAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 10),
                .foregroundColor: UIColor.darkGray
            ]
            
            let signatureString = NSAttributedString(string: "Signature:", attributes: signatureAttributes)
            signatureString.draw(at: CGPoint(x: rect.minX, y: rect.minY))
            
            // Draw signature line
            context.setStrokeColor(UIColor.black.cgColor)
            context.setLineWidth(0.5)
            context.move(to: CGPoint(x: rect.minX, y: rect.minY + 30))
            context.addLine(to: CGPoint(x: rect.minX + 160, y: rect.minY + 30))
            context.strokePath()
            
            let signatureLineString = NSAttributedString(string: "Authorized Signature", attributes: signatureLineAttributes)
            signatureLineString.draw(at: CGPoint(x: rect.minX, y: rect.minY + 35))
            
            // Draw signature image if available
            if let signatureImage = settings.signatureImage {
                let signatureRect = CGRect(x: rect.minX, y: rect.minY, width: 160, height: 30)
                signatureImage.draw(in: signatureRect)
            }
        }
    }
    
    /// Render disclaimer component
    private func renderDisclaimer(context: CGContext, in rect: CGRect, settings: PDFSettings) {
        if let disclaimer = settings.disclaimer, !disclaimer.isEmpty {
            let disclaimerAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 10),
                .foregroundColor: UIColor.darkGray
            ]
            
            let disclaimerString = NSAttributedString(string: disclaimer, attributes: disclaimerAttributes)
            disclaimerString.draw(at: CGPoint(x: rect.minX, y: rect.minY))
        }
    }
    
    /// Render an invoice PDF
    private func renderInvoice(context: CGContext, in rect: CGRect, settings: PDFSettings) {
        let drawingRect = CGRect(x: 40, y: 40, width: rect.width - 80, height: rect.height - 80)
        
        // Header
        renderHeader(context: context, rect: drawingRect, settings: settings)
        
        // Document type and number
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 24),
            .foregroundColor: UIColor.black
        ]
        
        let titleString = NSAttributedString(string: "INVOICE", attributes: titleAttributes)
        titleString.draw(at: CGPoint(x: drawingRect.midX - titleString.size().width / 2, y: 120))
        
        let numberAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14),
            .foregroundColor: UIColor.darkGray
        ]
        
        let numberString = NSAttributedString(string: "Invoice #: \(settings.documentNumber)", attributes: numberAttributes)
        numberString.draw(at: CGPoint(x: drawingRect.midX - numberString.size().width / 2, y: 150))
        
        // Date and Due Date
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        
        let dateAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12),
            .foregroundColor: UIColor.darkGray
        ]
        
        let dateString = NSAttributedString(string: "Date: \(dateFormatter.string(from: settings.documentDate))", attributes: dateAttributes)
        dateString.draw(at: CGPoint(x: drawingRect.maxX - dateString.size().width, y: 170))
        
        if let dueDate = settings.dueDate {
            let dueDateString = NSAttributedString(string: "Due Date: \(dateFormatter.string(from: dueDate))", attributes: dateAttributes)
            dueDateString.draw(at: CGPoint(x: drawingRect.maxX - dueDateString.size().width, y: 190))
        }
        
        // Recipient info
        let recipientAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12),
            .foregroundColor: UIColor.black
        ]
        
        let recipientTitleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 14),
            .foregroundColor: UIColor.black
        ]
        
        let billToString = NSAttributedString(string: "Bill To:", attributes: recipientTitleAttributes)
        billToString.draw(at: CGPoint(x: 40, y: 220))
        
        let recipientNameString = NSAttributedString(string: settings.recipientName, attributes: recipientAttributes)
        recipientNameString.draw(at: CGPoint(x: 40, y: 240))
        
        let recipientAddressString = NSAttributedString(string: settings.recipientAddress, attributes: recipientAttributes)
        recipientAddressString.draw(at: CGPoint(x: 40, y: 260))
        
        // Items table
        renderItemsTable(context: context, rect: CGRect(x: 40, y: 320, width: rect.width - 80, height: 300), settings: settings)
        
        // Summary section (Subtotal, Discount, Tax, Total)
        let regularAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14),
            .foregroundColor: UIColor.black
        ]
        
        let totalAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 16),
            .foregroundColor: UIColor.black
        ]
        
        var yPosition: CGFloat = 630
        
        // Calculate or use provided subtotal
        let subtotal = settings.subtotal ?? settings.items.reduce(0) { $0 + $1.total }
        
        // Subtotal
        let subtotalString = NSAttributedString(
            string: "Subtotal: \(settings.currency) \(String(format: "%.2f", subtotal))",
            attributes: regularAttributes
        )
        subtotalString.draw(at: CGPoint(x: rect.width - 80 - subtotalString.size().width, y: yPosition))
        yPosition += 25
        
        // Discount (if available and not zero)
        if let discount = settings.discount, discount > 0 {
            let discountLabel: String
            if let discountType = settings.discountType, discountType == "percentage" {
                discountLabel = "Discount (\(String(format: "%.1f", discount))%): -\(settings.currency) "
                // Calculate discount amount based on percentage
                let discountAmount = subtotal * (discount / 100)
                let discountString = NSAttributedString(
                    string: discountLabel + String(format: "%.2f", discountAmount),
                    attributes: regularAttributes
                )
                discountString.draw(at: CGPoint(x: rect.width - 80 - discountString.size().width, y: yPosition))
            } else {
                let discountString = NSAttributedString(
                    string: "Discount: -\(settings.currency) \(String(format: "%.2f", discount))",
                    attributes: regularAttributes
                )
                discountString.draw(at: CGPoint(x: rect.width - 80 - discountString.size().width, y: yPosition))
            }
            yPosition += 25
        }
        
        // Tax
        if let tax = settings.tax, tax > 0 {
            let taxLabel: String
            if let taxRate = settings.taxRate {
                taxLabel = "Tax (\(String(format: "%.1f", taxRate))%): \(settings.currency) "
            } else {
                taxLabel = "Tax: \(settings.currency) "
            }
            
            let taxString = NSAttributedString(
                string: taxLabel + String(format: "%.2f", tax),
                attributes: regularAttributes
            )
            taxString.draw(at: CGPoint(x: rect.width - 80 - taxString.size().width, y: yPosition))
            yPosition += 25
        }
        
        // Divider line before total
        context.setStrokeColor(UIColor.lightGray.cgColor)
        context.setLineWidth(0.5)
        context.move(to: CGPoint(x: rect.width - 250, y: yPosition - 5))
        context.addLine(to: CGPoint(x: rect.width - 40, y: yPosition - 5))
        context.strokePath()
        
        // Total
        let finalTotal = settings.totalAmount ?? subtotal - (settings.discount ?? 0) + (settings.tax ?? 0)
        let totalString = NSAttributedString(
            string: "Total: \(settings.currency) \(String(format: "%.2f", finalTotal))",
            attributes: totalAttributes
        )
        totalString.draw(at: CGPoint(x: rect.width - 80 - totalString.size().width, y: yPosition))
        
        // Notes
        if let notes = settings.notes, !notes.isEmpty {
            let notesAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12),
                .foregroundColor: UIColor.darkGray
            ]
            
            let notesTitleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 14),
                .foregroundColor: UIColor.black
            ]
            
            let notesTitleString = NSAttributedString(string: "Notes:", attributes: notesTitleAttributes)
            notesTitleString.draw(at: CGPoint(x: 40, y: 670))
            
            let notesString = NSAttributedString(string: notes, attributes: notesAttributes)
            notesString.draw(at: CGPoint(x: 40, y: 690))
        }
        
        // Disclaimer
        if let disclaimer = settings.disclaimer, !disclaimer.isEmpty {
            let disclaimerAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 10),
                .foregroundColor: UIColor.darkGray
            ]
            
            let disclaimerString = NSAttributedString(string: disclaimer, attributes: disclaimerAttributes)
            disclaimerString.draw(at: CGPoint(x: 40, y: rect.height - 60))
        }
        
        // Signature
        if settings.includeSignature {
            let signatureAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12),
                .foregroundColor: UIColor.black
            ]
            
            let signatureLineAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 10),
                .foregroundColor: UIColor.darkGray
            ]
            
            let signatureString = NSAttributedString(string: "Signature:", attributes: signatureAttributes)
            signatureString.draw(at: CGPoint(x: 40, y: rect.height - 120))
            
            // Draw signature line
            context.setStrokeColor(UIColor.black.cgColor)
            context.setLineWidth(0.5)
            context.move(to: CGPoint(x: 40, y: rect.height - 90))
            context.addLine(to: CGPoint(x: 200, y: rect.height - 90))
            context.strokePath()
            
            let signatureLineString = NSAttributedString(string: "Authorized Signature", attributes: signatureLineAttributes)
            signatureLineString.draw(at: CGPoint(x: 40, y: rect.height - 85))
            
            // Draw signature image if available
            if let signatureImage = settings.signatureImage {
                let signatureRect = CGRect(x: 40, y: rect.height - 120, width: 160, height: 50)
                signatureImage.draw(in: signatureRect)
            }
        }
    }
    
    /// Render an estimate PDF
    private func renderEstimate(context: CGContext, in rect: CGRect, settings: PDFSettings) {
        let drawingRect = CGRect(x: 40, y: 40, width: rect.width - 80, height: rect.height - 80)
        
        // Header
        renderHeader(context: context, rect: drawingRect, settings: settings)
        
        // Document type and number
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 24),
            .foregroundColor: UIColor.black
        ]
        
        let titleString = NSAttributedString(string: "ESTIMATE", attributes: titleAttributes)
        titleString.draw(at: CGPoint(x: drawingRect.midX - titleString.size().width / 2, y: 120))
        
        let numberAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14),
            .foregroundColor: UIColor.darkGray
        ]
        
        let numberString = NSAttributedString(string: "Estimate #: \(settings.documentNumber)", attributes: numberAttributes)
        numberString.draw(at: CGPoint(x: drawingRect.midX - numberString.size().width / 2, y: 150))
        
        // Date and Expiry Date
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        
        let dateAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12),
            .foregroundColor: UIColor.darkGray
        ]
        
        let dateString = NSAttributedString(string: "Date: \(dateFormatter.string(from: settings.documentDate))", attributes: dateAttributes)
        dateString.draw(at: CGPoint(x: drawingRect.maxX - dateString.size().width, y: 170))
        
        if let expiryDate = settings.dueDate {
            let expiryDateString = NSAttributedString(string: "Valid Until: \(dateFormatter.string(from: expiryDate))", attributes: dateAttributes)
            expiryDateString.draw(at: CGPoint(x: drawingRect.maxX - expiryDateString.size().width, y: 190))
        }
        
        // Recipient info
        let recipientAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12),
            .foregroundColor: UIColor.black
        ]
        
        let recipientTitleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 14),
            .foregroundColor: UIColor.black
        ]
        
        let clientString = NSAttributedString(string: "Client:", attributes: recipientTitleAttributes)
        clientString.draw(at: CGPoint(x: 40, y: 220))
        
        let recipientNameString = NSAttributedString(string: settings.recipientName, attributes: recipientAttributes)
        recipientNameString.draw(at: CGPoint(x: 40, y: 240))
        
        let recipientAddressString = NSAttributedString(string: settings.recipientAddress, attributes: recipientAttributes)
        recipientAddressString.draw(at: CGPoint(x: 40, y: 260))
        
        // Items table
        renderItemsTable(context: context, rect: CGRect(x: 40, y: 320, width: rect.width - 80, height: 300), settings: settings)
        
        // Notes, disclaimer, etc.
        if let notes = settings.notes, !notes.isEmpty {
            let notesAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12),
                .foregroundColor: UIColor.darkGray
            ]
            
            let notesTitleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 14),
                .foregroundColor: UIColor.black
            ]
            
            let notesTitleString = NSAttributedString(string: "Notes:", attributes: notesTitleAttributes)
            notesTitleString.draw(at: CGPoint(x: 40, y: 670))
            
            let notesString = NSAttributedString(string: notes, attributes: notesAttributes)
            notesString.draw(at: CGPoint(x: 40, y: 690))
        }
        
        // Disclaimer
        if let disclaimer = settings.disclaimer, !disclaimer.isEmpty {
            let disclaimerAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 10),
                .foregroundColor: UIColor.darkGray
            ]
            
            let disclaimerString = NSAttributedString(string: disclaimer, attributes: disclaimerAttributes)
            disclaimerString.draw(at: CGPoint(x: 40, y: drawingRect.height - 60))
        }
    }
    
    /// Render a consignment PDF
    private func renderConsignment(context: CGContext, in rect: CGRect, settings: PDFSettings) {
        let drawingRect = CGRect(x: 40, y: 40, width: rect.width - 80, height: rect.height - 80)
        
        // Header
        renderHeader(context: context, rect: drawingRect, settings: settings)
        
        // Document type and number
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 24),
            .foregroundColor: UIColor.black
        ]
        
        let titleString = NSAttributedString(string: "CONSIGNMENT NOTE", attributes: titleAttributes)
        titleString.draw(at: CGPoint(x: drawingRect.midX - titleString.size().width / 2, y: 120))
        
        let numberAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14),
            .foregroundColor: UIColor.darkGray
        ]
        
        let numberString = NSAttributedString(string: "Consignment #: \(settings.documentNumber)", attributes: numberAttributes)
        numberString.draw(at: CGPoint(x: drawingRect.midX - numberString.size().width / 2, y: 150))
        
        // Date
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        
        let dateAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12),
            .foregroundColor: UIColor.darkGray
        ]
        
        let dateString = NSAttributedString(string: "Date: \(dateFormatter.string(from: settings.documentDate))", attributes: dateAttributes)
        dateString.draw(at: CGPoint(x: drawingRect.maxX - dateString.size().width, y: 170))
        
        // Recipient info
        let recipientAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12),
            .foregroundColor: UIColor.black
        ]
        
        let recipientTitleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 14),
            .foregroundColor: UIColor.black
        ]
        
        let deliverToString = NSAttributedString(string: "Deliver To:", attributes: recipientTitleAttributes)
        deliverToString.draw(at: CGPoint(x: 40, y: 220))
        
        let recipientNameString = NSAttributedString(string: settings.recipientName, attributes: recipientAttributes)
        recipientNameString.draw(at: CGPoint(x: 40, y: 240))
        
        let recipientAddressString = NSAttributedString(string: settings.recipientAddress, attributes: recipientAttributes)
        recipientAddressString.draw(at: CGPoint(x: 40, y: 260))
        
        // Items table
        renderItemsTable(context: context, rect: CGRect(x: 40, y: 320, width: rect.width - 80, height: 300), settings: settings)
        
        // Total items
        let totalItems = settings.items.reduce(0) { $0 + $1.quantity }
        
        let totalAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 16),
            .foregroundColor: UIColor.black
        ]
        
        let totalString = NSAttributedString(string: "Total Items: \(totalItems)", attributes: totalAttributes)
        totalString.draw(at: CGPoint(x: rect.width - 80 - totalString.size().width, y: 630))
        
        // Notes
        if let notes = settings.notes, !notes.isEmpty {
            let notesAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12),
                .foregroundColor: UIColor.darkGray
            ]
            
            let notesTitleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 14),
                .foregroundColor: UIColor.black
            ]
            
            let notesTitleString = NSAttributedString(string: "Notes:", attributes: notesTitleAttributes)
            notesTitleString.draw(at: CGPoint(x: 40, y: 670))
            
            let notesString = NSAttributedString(string: notes, attributes: notesAttributes)
            notesString.draw(at: CGPoint(x: 40, y: 690))
        }
        
        // Disclaimer
        if let disclaimer = settings.disclaimer, !disclaimer.isEmpty {
            let disclaimerAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 10),
                .foregroundColor: UIColor.darkGray
            ]
            
            let disclaimerString = NSAttributedString(string: disclaimer, attributes: disclaimerAttributes)
            disclaimerString.draw(at: CGPoint(x: 40, y: rect.height - 60))
        }
        
        // Signature
        if settings.includeSignature {
            let signatureAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12),
                .foregroundColor: UIColor.black
            ]
            
            let signatureLineAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 10),
                .foregroundColor: UIColor.darkGray
            ]
            
            // Sender signature
            let senderSignatureString = NSAttributedString(string: "Sender Signature:", attributes: signatureAttributes)
            senderSignatureString.draw(at: CGPoint(x: 40, y: rect.height - 120))
            
            context.setStrokeColor(UIColor.black.cgColor)
            context.setLineWidth(0.5)
            context.move(to: CGPoint(x: 40, y: rect.height - 90))
            context.addLine(to: CGPoint(x: 200, y: rect.height - 90))
            context.strokePath()
            
            let senderLineString = NSAttributedString(string: "Sender", attributes: signatureLineAttributes)
            senderLineString.draw(at: CGPoint(x: 40, y: rect.height - 85))
            
            // Recipient signature
            let recipientSignatureString = NSAttributedString(string: "Recipient Signature:", attributes: signatureAttributes)
            recipientSignatureString.draw(at: CGPoint(x: 300, y: rect.height - 120))
            
            context.setStrokeColor(UIColor.black.cgColor)
            context.setLineWidth(0.5)
            context.move(to: CGPoint(x: 300, y: rect.height - 90))
            context.addLine(to: CGPoint(x: 460, y: rect.height - 90))
            context.strokePath()
            
            let recipientLineString = NSAttributedString(string: "Recipient", attributes: signatureLineAttributes)
            recipientLineString.draw(at: CGPoint(x: 300, y: rect.height - 85))
            
            // Draw signature image if available
            if let signatureImage = settings.signatureImage {
                let signatureRect = CGRect(x: 40, y: rect.height - 120, width: 160, height: 50)
                signatureImage.draw(in: signatureRect)
            }
        }
    }
    
    /// Common method to render the header section
    private func renderHeader(context: CGContext, rect: CGRect, settings: PDFSettings) {
        // Company logo
        if let logo = settings.companyLogo {
            let logoRect = CGRect(x: rect.minX, y: rect.minY, width: 100, height: 50)
            logo.draw(in: logoRect)
        }
        
        // Company info
        let companyAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12),
            .foregroundColor: UIColor.darkGray
        ]
        
        let companyNameAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 16),
            .foregroundColor: UIColor.black
        ]
        
        let nameString = NSAttributedString(string: settings.companyName, attributes: companyNameAttributes)
        nameString.draw(at: CGPoint(x: rect.maxX - nameString.size().width, y: rect.minY))
        
        let addressString = NSAttributedString(string: settings.companyAddress, attributes: companyAttributes)
        addressString.draw(at: CGPoint(x: rect.maxX - addressString.size().width, y: rect.minY + 20))
        
        let emailString = NSAttributedString(string: settings.companyEmail, attributes: companyAttributes)
        emailString.draw(at: CGPoint(x: rect.maxX - emailString.size().width, y: rect.minY + 40))
        
        let phoneString = NSAttributedString(string: settings.companyPhone, attributes: companyAttributes)
        phoneString.draw(at: CGPoint(x: rect.maxX - phoneString.size().width, y: rect.minY + 60))
    }
    
    /// Common method to render the items table
    private func renderItemsTable(context: CGContext, rect: CGRect, settings: PDFSettings) {
        // Header row
        let headerAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 12),
            .foregroundColor: UIColor.white
        ]
        
        // Draw header background
        context.setFillColor(UIColor.darkGray.cgColor)
        context.fill(CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: 25))
        
        // Draw header text
        let nameHeaderString = NSAttributedString(string: "Item", attributes: headerAttributes)
        nameHeaderString.draw(at: CGPoint(x: rect.minX + 10, y: rect.minY + 5))
        
        let descHeaderString = NSAttributedString(string: "Description", attributes: headerAttributes)
        descHeaderString.draw(at: CGPoint(x: rect.minX + 150, y: rect.minY + 5))
        
        let qtyHeaderString = NSAttributedString(string: "Qty", attributes: headerAttributes)
        qtyHeaderString.draw(at: CGPoint(x: rect.minX + 350, y: rect.minY + 5))
        
        let priceHeaderString = NSAttributedString(string: "Price", attributes: headerAttributes)
        priceHeaderString.draw(at: CGPoint(x: rect.minX + 400, y: rect.minY + 5))
        
        let totalHeaderString = NSAttributedString(string: "Total", attributes: headerAttributes)
        totalHeaderString.draw(at: CGPoint(x: rect.minX + 470, y: rect.minY + 5))
        
        // Draw items
        let rowAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12),
            .foregroundColor: UIColor.black
        ]
        
        for (index, item) in settings.items.enumerated() {
            let yPos = rect.minY + 30 + CGFloat(index * 30)
            
            // Alternating row background
            if index % 2 == 1 {
                context.setFillColor(UIColor(white: 0.95, alpha: 1.0).cgColor)
                context.fill(CGRect(x: rect.minX, y: yPos, width: rect.width, height: 25))
            }
            
            let nameString = NSAttributedString(string: item.name, attributes: rowAttributes)
            nameString.draw(at: CGPoint(x: rect.minX + 10, y: yPos + 5))
            
            let descString = NSAttributedString(string: item.description, attributes: rowAttributes)
            descString.draw(at: CGPoint(x: rect.minX + 150, y: yPos + 5))
            
            let qtyString = NSAttributedString(string: "\(item.quantity)", attributes: rowAttributes)
            qtyString.draw(at: CGPoint(x: rect.minX + 350, y: yPos + 5))
            
            let priceString = NSAttributedString(string: "\(settings.currency) \(String(format: "%.2f", item.unitPrice))", attributes: rowAttributes)
            priceString.draw(at: CGPoint(x: rect.minX + 400, y: yPos + 5))
            
            let totalString = NSAttributedString(string: "\(settings.currency) \(String(format: "%.2f", item.total))", attributes: rowAttributes)
            totalString.draw(at: CGPoint(x: rect.minX + 470, y: yPos + 5))
            
            // Draw divider line
            context.setStrokeColor(UIColor.lightGray.cgColor)
            context.setLineWidth(0.5)
            context.move(to: CGPoint(x: rect.minX, y: yPos + 25))
            context.addLine(to: CGPoint(x: rect.maxX, y: yPos + 25))
            context.strokePath()
        }
    }
}

// MARK: - PDF Preview View
class PDFPreviewController: UIViewController {
    private var pdfView = PDFView()
    private let fileURL: URL
    private var document: PDFDocument?
    
    init(fileURL: URL) {
        self.fileURL = fileURL
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // Add share button
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .action,
            target: self,
            action: #selector(sharePDF)
        )
        
        // Add open button
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "Open",
            style: .plain,
            target: self,
            action: #selector(openPDF)
        )
        
        // Setup view with placeholder (don't load PDF yet)
        pdfView.translatesAutoresizingMaskIntoConstraints = false
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        pdfView.backgroundColor = .systemGray6
        
        view.addSubview(pdfView)
        
        NSLayoutConstraint.activate([
            pdfView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            pdfView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            pdfView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            pdfView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor)
        ])
        
        // Add label to indicate PDF is ready
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "PDF Generated Successfully\nTap 'Open' to view or 'Share' to export"
        label.textAlignment = .center
        label.numberOfLines = 0
        label.textColor = .label
        
        view.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    @objc private func openPDF() {
        // Only load the PDF when the user requests it
        if document == nil {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                guard let self = self else { return }
                
                if let document = PDFDocument(url: self.fileURL) {
                    DispatchQueue.main.async {
                        self.document = document
                        self.pdfView.document = document
                        
                        // Reset view to show first page
                        if let firstPage = document.page(at: 0) {
                            self.pdfView.go(to: PDFDestination(page: firstPage, at: .zero))
                        }
                    }
                }
            }
        }
    }
    
    @objc private func sharePDF() {
        let activityViewController = UIActivityViewController(
            activityItems: [fileURL],
            applicationActivities: nil
        )
        
        if let popover = activityViewController.popoverPresentationController {
            popover.barButtonItem = navigationItem.rightBarButtonItem
        }
        
        present(activityViewController, animated: true)
    }
}

// Completely redesigned SwiftUI wrapper for PDFKit that reliably displays PDFs
struct PDFPreviewView: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> UIViewController {
        // Create a container view controller to manage the PDF view
        let container = StablePDFViewController()
        container.pdfURL = url
        return container
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // Cast to our custom controller and update the URL if needed
        if let pdfVC = uiViewController as? StablePDFViewController {
            if pdfVC.pdfURL != url {
                pdfVC.pdfURL = url
                pdfVC.loadPDFIfNeeded()
            }
        }
    }
    
    // Custom UIViewController subclass to ensure stability
    class StablePDFViewController: UIViewController {
        var pdfURL: URL?
        private var pdfView: PDFView?
        private var loadingLabel: UILabel?
        private var loadingIndicator: UIActivityIndicatorView?
        private var loadingAttempts = 0
        private var isLoading = false
        
        override func viewDidLoad() {
            super.viewDidLoad()
            view.backgroundColor = .systemBackground
            setupUI()
        }
        
        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            // Attempt to load PDF after view has fully appeared to prevent dismissal issues
            loadPDFIfNeeded()
        }
        
        private func setupUI() {
            // Create PDF view but don't load document yet
            let pdfView = PDFView(frame: view.bounds)
            pdfView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            pdfView.displayMode = .singlePageContinuous
            pdfView.displayDirection = .vertical
            pdfView.autoScales = true
            pdfView.backgroundColor = .systemBackground
            pdfView.usePageViewController(true)
            pdfView.alpha = 0 // Start hidden until loaded
            view.addSubview(pdfView)
            self.pdfView = pdfView
            
            // Add loading indicator
            let indicator = UIActivityIndicatorView(style: .large)
            indicator.center = CGPoint(x: view.bounds.midX, y: view.bounds.midY - 20)
            indicator.autoresizingMask = [.flexibleLeftMargin, .flexibleRightMargin, .flexibleTopMargin, .flexibleBottomMargin]
            indicator.startAnimating()
            view.addSubview(indicator)
            self.loadingIndicator = indicator
            
            // Add loading label
            let label = UILabel(frame: CGRect(x: 0, y: indicator.frame.maxY + 10, width: view.bounds.width, height: 30))
            label.text = "Loading PDF..."
            label.textAlignment = .center
            label.textColor = .secondaryLabel
            label.autoresizingMask = [.flexibleWidth, .flexibleTopMargin, .flexibleBottomMargin]
            view.addSubview(label)
            self.loadingLabel = label
        }
        
        func loadPDFIfNeeded() {
            guard !isLoading, let url = pdfURL, FileManager.default.fileExists(atPath: url.path) else { return }
            
            isLoading = true
            loadingAttempts += 1
            
            // Try to load the PDF with increasing delays if needed
            let delay = loadingAttempts == 1 ? 0.3 : (loadingAttempts == 2 ? 0.5 : 1.0)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                guard let self = self, let pdfView = self.pdfView else { return }
                
                if let document = PDFDocument(url: url) {
                    // Set document
                    pdfView.document = document
                    
                    // Go to first page
                    if let firstPage = document.page(at: 0) {
                        pdfView.go(to: PDFDestination(page: firstPage, at: .zero))
                    }
                    
                    // Show the PDF view with animation
                    UIView.animate(withDuration: 0.3) {
                        pdfView.alpha = 1.0
                        self.loadingIndicator?.alpha = 0.0
                        self.loadingLabel?.alpha = 0.0
                    } completion: { _ in
                        self.loadingIndicator?.removeFromSuperview()
                        self.loadingLabel?.removeFromSuperview()
                    }
                    
                    self.isLoading = false
                } else if self.loadingAttempts < 3 {
                    // Retry up to 3 times
                    self.isLoading = false
                    self.loadPDFIfNeeded()
                } else {
                    // Show error after multiple failed attempts
                    self.loadingLabel?.text = "Could not load PDF"
                    self.loadingIndicator?.stopAnimating()
                    self.isLoading = false
                }
            }
        }
    }
}