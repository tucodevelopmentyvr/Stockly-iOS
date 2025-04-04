import Foundation
import SwiftData

enum MeasurementUnitType: String, Codable, CaseIterable {
    case piece = "PCS"
    case kilogram = "KG"
    case liter = "LTR"
    case carat = "CT"
    case meter = "M"
    case gram = "G"
    case unit = "UNIT"
    case box = "BOX"
    case pair = "PAIR"
}

@Model
final class Item {
    var id: UUID
    var name: String
    var itemDescription: String // Changed from 'description' to avoid conflicts
    var category: String
    var sku: String // Product code/SKU
    var price: Double // Sales unit price
    var buyPrice: Double // Buy unit price
    var stockQuantity: Int
    var minStockLevel: Int
    var measurementUnit: String // KG, LTR, PCS, etc.
    var taxRate: Double // Tax percentage
    var barcode: String?
    var imageURL: String?
    var imageData: Data? // Store image data directly in the database
    var createdAt: Date
    var updatedAt: Date
    var inventoryAddedAt: Date // Time inventory was added
    
    init(
        name: String,
        description: String,
        category: String,
        sku: String,
        price: Double,
        buyPrice: Double,
        stockQuantity: Int,
        minStockLevel: Int,
        measurementUnit: MeasurementUnitType = .piece,
        taxRate: Double = 0.0,
        barcode: String? = nil,
        imageURL: String? = nil,
        imageData: Data? = nil
    ) {
        self.id = UUID()
        self.name = name
        self.itemDescription = description
        self.category = category
        self.sku = sku
        self.price = price
        self.buyPrice = buyPrice
        self.stockQuantity = stockQuantity
        self.minStockLevel = minStockLevel
        self.measurementUnit = measurementUnit.rawValue
        self.taxRate = taxRate
        self.barcode = barcode
        self.imageURL = imageURL
        self.imageData = imageData
        self.createdAt = Date()
        self.updatedAt = Date()
        self.inventoryAddedAt = Date()
    }
    
    var isLowStock: Bool {
        return stockQuantity <= minStockLevel
    }
    
    var stockValue: Double {
        return Double(stockQuantity) * price
    }
    
    var profit: Double {
        return price - buyPrice
    }
    
    var profitPercentage: Double {
        guard buyPrice > 0 else { return 0 }
        return (profit / buyPrice) * 100
    }
}