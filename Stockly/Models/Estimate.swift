import Foundation
import SwiftData

@Model
final class Estimate {
    enum Status: String, Codable {
        case draft
        case sent
        case accepted
        case rejected
        case expired
        case converted
    }
    
    var id: UUID
    var number: String
    var clientName: String
    var clientAddress: String
    var clientEmail: String?
    var clientPhone: String?
    var status: Status
    var dateCreated: Date
    var expiryDate: Date
    var items: [EstimateItem]
    var subtotal: Double
    var discount: Double
    var discountType: String // percentage or fixed
    var tax: Double
    var taxRate: Double
    var totalAmount: Double
    var notes: String
    var headerNote: String?
    var footerNote: String?
    var templateType: String
    var customFields: [CustomEstimateField]?
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
        dateCreated: Date = Date(),
        expiryDate: Date,
        items: [EstimateItem],
        discount: Double = 0.0,
        discountType: String = "percentage",
        taxRate: Double = 0.0,
        notes: String = "",
        headerNote: String? = nil,
        footerNote: String? = nil,
        templateType: String = "standard",
        customFields: [CustomEstimateField]? = nil,
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
        self.dateCreated = dateCreated
        self.expiryDate = expiryDate
        self.items = items
        self.notes = notes
        self.headerNote = headerNote
        self.footerNote = footerNote
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
    }
}

@Model
final class EstimateItem {
    var id: UUID
    var name: String
    var itemDescription: String?
    var quantity: Int
    var unitPrice: Double
    var tax: Double
    var discount: Double
    var totalAmount: Double
    
    @Relationship(deleteRule: .nullify) var estimate: Estimate?
    
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
final class CustomEstimateField {
    var id: UUID
    var name: String
    var value: String
    
    @Relationship(deleteRule: .nullify) var estimate: Estimate?
    
    init(name: String, value: String) {
        self.id = UUID()
        self.name = name
        self.value = value
    }
}