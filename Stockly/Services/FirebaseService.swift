import Foundation
import Combine
import UIKit

// Note: In a real app, you would import Firebase
// The Firebase imports are commented out for now while we resolve the package issues
// import FirebaseCore
// import FirebaseFirestore
// import FirebaseAuth
// import FirebaseStorage

enum FirebaseError: Error {
    case notConfigured
    case authError
    case databaseError
    case storageError
    case networkError
    case unknown
}

class FirebaseService: ObservableObject {
    static let shared = FirebaseService()
    
    @Published var isConfigured = false
    @Published var isSyncing = false
    @Published var lastSyncTime: Date?
    @Published var syncError: FirebaseError?
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        // For testing without Firebase
        isConfigured = true
        print("Mock Firebase service initialized")
    }
    
    // MARK: - Database Operations
    
    func fetchItems() async throws -> [Item] {
        // Return mock data for testing
        try await Task.sleep(for: .seconds(0.5))
        
        return [
            Item(name: "MacBook Pro", description: "16-inch Laptop", category: "Electronics", sku: "MB-PRO-16", price: 2499.99, buyPrice: 2100.00, stockQuantity: 10, minStockLevel: 3, taxRate: 8.0),
            Item(name: "iPhone 15", description: "Smartphone", category: "Electronics", sku: "IP-15-256", price: 999.99, buyPrice: 850.00, stockQuantity: 20, minStockLevel: 5, taxRate: 8.0),
            Item(name: "AirPods Pro", description: "Wireless Earbuds", category: "Accessories", sku: "APP-2-WH", price: 249.99, buyPrice: 200.00, stockQuantity: 15, minStockLevel: 5, taxRate: 8.0),
            Item(name: "iPad Pro", description: "11-inch Tablet", category: "Electronics", sku: "IPAD-P-11", price: 799.99, buyPrice: 650.00, stockQuantity: 8, minStockLevel: 3, taxRate: 8.0),
            Item(name: "Magic Mouse", description: "Wireless Mouse", category: "Accessories", sku: "MM-WL-3", price: 79.99, buyPrice: 60.00, stockQuantity: 12, minStockLevel: 5, taxRate: 8.0),
            Item(name: "HDMI Cable", description: "2m Cable", category: "Accessories", sku: "HDMI-2M", price: 19.99, buyPrice: 8.50, stockQuantity: 30, minStockLevel: 10, taxRate: 8.0),
            Item(name: "USB-C Hub", description: "Multi-port Adapter", category: "Accessories", sku: "USB-HUB-7", price: 59.99, buyPrice: 35.00, stockQuantity: 0, minStockLevel: 5, taxRate: 8.0)
        ]
    }
    
    func saveItem(_ item: Item) async throws {
        // Simulate saving to database
        try await Task.sleep(for: .seconds(0.3))
    }
    
    func deleteItem(id: UUID) async throws {
        // Simulate deleting from database
        try await Task.sleep(for: .seconds(0.3))
    }
    
    // MARK: - Storage Operations
    
    func uploadImage(_ imageData: Data, itemId: UUID) async throws -> String {
        // Simulate image upload
        try await Task.sleep(for: .seconds(0.5))
        return "https://example.com/images/\(itemId.uuidString).jpg"
    }
    
    func downloadImage(from urlString: String) async throws -> Data {
        // Simulate image download with a delay
        try await Task.sleep(for: .seconds(0.3))
        
        // Create a placeholder colored image
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 100, height: 100))
        let placeholderImage = renderer.image { ctx in
            UIColor.systemBlue.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: 100, height: 100))
            
            // Add a label with the item name (first letters)
            let text = String(urlString.split(separator: "/").last?.prefix(2) ?? "IT")
            let attributes: [NSAttributedString.Key: Any] = [
                .foregroundColor: UIColor.white,
                .font: UIFont.boldSystemFont(ofSize: 40)
            ]
            
            let textSize = text.size(withAttributes: attributes)
            let textRect = CGRect(
                x: (100 - textSize.width) / 2,
                y: (100 - textSize.height) / 2,
                width: textSize.width,
                height: textSize.height
            )
            
            text.draw(in: textRect, withAttributes: attributes)
        }
        
        return placeholderImage.jpegData(compressionQuality: 0.8) ?? Data()
    }
    
    // MARK: - Sync Operations
    
    @MainActor
    func syncLocalToCloud(items: [Item]) async throws {
        isSyncing = true
        
        defer {
            isSyncing = false
            lastSyncTime = Date()
        }
        
        // Simulate sync delay
        try await Task.sleep(for: .seconds(1))
    }
    
    @MainActor
    func syncCloudToLocal() async throws -> [Item] {
        isSyncing = true
        
        defer {
            isSyncing = false
            lastSyncTime = Date()
        }
        
        return try await fetchItems()
    }
}