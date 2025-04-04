import Foundation
import SwiftData

// Use existing DocumentType from PDFService.swift

@Model
final class Invoice {
    enum Status: String, Codable {
        case draft
        case pending
        case paid
        case overdue
        case cancelled
    }
    
    enum PaymentMethod: String, Codable {
        case creditCard = "Credit Card"
        case debitCard = "Debit Card"
        case cash = "Cash"
        case bankTransfer = "Bank Transfer"
        case check = "Check"
        case paymentApp = "Payment App"
        case other = "Other"
    }
    
    var id: UUID
    var number: String
    var clientName: String
    var clientAddress: String
    var clientEmail: String?
    var clientPhone: String?
    var status: Status
    var paymentMethod: String? // Store as string to support custom methods
    var documentType: String // "invoice" or "consignment"
    var dateCreated: Date
    var dueDate: Date
    var items: [InvoiceItem]
    var subtotal: Double
    var discount: Double
    var discountType: String // percentage or fixed
    var tax: Double
    var taxRate: Double
    var totalAmount: Double
    var notes: String
    var headerNote: String?
    var footerNote: String?
    var bankingInfo: String?
    var signature: Data?
    var barcodeData: String?
    var qrCodeData: String?
    var templateType: String
    var customFields: [CustomInvoiceField]?
    var createdAt: Date
    var updatedAt: Date
    var pdfURL: URL?
    
    init(
        number: String,
        clientName: String,
        clientAddress: String,
        clientEmail: String? = nil,
        clientPhone: String? = nil,
        status: Status = .draft,
        paymentMethod: String? = nil,
        documentType: String = "invoice",
        dateCreated: Date = Date(),
        dueDate: Date,
        items: [InvoiceItem],
        discount: Double = 0.0,
        discountType: String = "percentage",
        taxRate: Double = 0.0,
        notes: String = "",
        headerNote: String? = nil,
        footerNote: String? = nil,
        bankingInfo: String? = nil,
        signature: Data? = nil,
        templateType: String = "standard",
        customFields: [CustomInvoiceField]? = nil,
        pdfURL: URL? = nil
    ) {
        // First initialize all stored properties before calculations
        self.id = UUID()
        self.number = number
        self.clientName = clientName
        self.clientAddress = clientAddress
        self.clientEmail = clientEmail
        self.clientPhone = clientPhone
        self.status = status
        self.paymentMethod = paymentMethod
        self.documentType = documentType
        self.dateCreated = dateCreated
        self.dueDate = dueDate
        self.items = items
        self.notes = notes
        self.headerNote = headerNote
        self.footerNote = footerNote
        self.bankingInfo = bankingInfo
        self.signature = signature
        self.templateType = templateType
        self.customFields = customFields
        self.createdAt = Date()
        self.updatedAt = Date()
        self.pdfURL = pdfURL
        
        // Calculate totals after all properties are initialized
        let calculatedSubtotal = items.reduce(0) { $0 + $1.totalAmount }
        self.subtotal = calculatedSubtotal
        self.discount = discount
        self.discountType = discountType
        self.taxRate = taxRate
        
        // Apply discount
        let discountAmount = discountType == "percentage" ? 
            calculatedSubtotal * (discount / 100) : 
            discount
        
        let afterDiscount = calculatedSubtotal - discountAmount
        
        // Apply tax
        let calculatedTax = afterDiscount * (taxRate / 100)
        self.tax = calculatedTax
        
        // Calculate total amount
        let calculatedTotal = afterDiscount + calculatedTax
        // Round to nearest value if needed
        self.totalAmount = (calculatedTotal * 100).rounded() / 100
        
        // Generate QR code data
        self.qrCodeData = generateQRCodeData()
        self.barcodeData = number
    }
    
    private func generateQRCodeData() -> String {
        return """
        INVOICE:\(number)
        CLIENT:\(clientName)
        DATE:\(dateCreated.formatted(date: .numeric, time: .omitted))
        AMOUNT:\(String(format: "%.2f", totalAmount))
        STATUS:\(status.rawValue)
        """
    }
}

@Model
final class InvoiceItem {
    var id: UUID
    var name: String
    var itemDescription: String? // Changed from 'description' to avoid conflicts
    var quantity: Int
    var unitPrice: Double
    var tax: Double
    var discount: Double
    var totalAmount: Double
    
    @Relationship(deleteRule: .nullify) var invoice: Invoice?
    
    init(name: String, description: String? = nil, quantity: Int, unitPrice: Double, tax: Double = 0.0, discount: Double = 0.0) {
        self.id = UUID()
        self.name = name
        self.itemDescription = description
        self.quantity = quantity
        self.unitPrice = unitPrice
        self.tax = tax
        self.discount = discount
        
        // Calculate total amount with tax and discount
        let itemTotal = Double(quantity) * unitPrice
        let discountAmount = itemTotal * (discount / 100)
        let afterDiscount = itemTotal - discountAmount
        let taxAmount = afterDiscount * (tax / 100)
        self.totalAmount = afterDiscount + taxAmount
    }
}

@Model
final class CustomInvoiceField {
    var id: UUID
    var name: String
    var value: String
    
    @Relationship(deleteRule: .nullify) var invoice: Invoice?
    
    init(name: String, value: String) {
        self.id = UUID()
        self.name = name
        self.value = value
    }
}