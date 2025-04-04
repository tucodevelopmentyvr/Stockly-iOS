import Foundation
import SwiftData
import Combine
import UniformTypeIdentifiers

enum SortOption {
    case nameAsc
    case nameDesc
    case stockLevelAsc
    case stockLevelDesc
    case priceAsc
    case priceDesc
    case dateAddedAsc
    case dateAddedDesc
    case categoryAsc
    case categoryDesc
}

// CSV Import Error types
enum CSVImportError: Error {
    case invalidFile
    case missingRequiredColumns
    case invalidData(row: Int, details: String)
    case fileReadError
}

class InventoryService {
    private let _modelContext: ModelContext
    
    var modelContext: ModelContext {
        return _modelContext
    }
    
    init(modelContext: ModelContext) {
        self._modelContext = modelContext
    }
    
    // CRUD operations
    func addItem(_ item: Item) {
        _modelContext.insert(item)
        do {
            try _modelContext.save()
        } catch {
            print("Failed to save item: \(error)")
        }
    }
    
    func updateItem(_ item: Item) {
        item.updatedAt = Date()
        do {
            try _modelContext.save()
        } catch {
            print("Failed to update item: \(error)")
        }
    }
    
    func deleteItem(_ item: Item) {
        _modelContext.delete(item)
        do {
            try _modelContext.save()
        } catch {
            print("Failed to delete item: \(error)")
        }
    }
    
    func getItems(sortBy: SortOption = .nameAsc, searchText: String = "", category: String? = nil, lowStockOnly: Bool = false) -> [Item] {
        var predicates: [Predicate<Item>] = []
        
        // Store search criteria for post-fetch filtering
        let trimmedSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let hasSearchText = !trimmedSearch.isEmpty
        
        // Apply category filter if provided
        if let category = category, !category.isEmpty {
            predicates.append(#Predicate<Item> { item in
                item.category == category
            })
        }
        
        // Apply low stock filter if enabled
        if lowStockOnly {
            predicates.append(#Predicate<Item> { item in
                item.stockQuantity <= item.minStockLevel
            })
        }
        
        // Combine all predicates
        var finalPredicate: Predicate<Item>? = nil
        
        if !predicates.isEmpty {
            if predicates.count == 1 {
                // If there's only one predicate, just use it
                finalPredicate = predicates[0]
            } else {
                // Combine predicates manually
                finalPredicate = #Predicate<Item> { item in
                    // Item must match all predicates (AND logic)
                    predicates.allSatisfy { predicate in
                        predicate.evaluate(item)
                    }
                }
            }
        }
        
        // Apply sorting
        let sortDescriptor: SortDescriptor<Item>
        switch sortBy {
        case .nameAsc:
            sortDescriptor = SortDescriptor(\Item.name, order: .forward)
        case .nameDesc:
            sortDescriptor = SortDescriptor(\Item.name, order: .reverse)
        case .stockLevelAsc:
            sortDescriptor = SortDescriptor(\Item.stockQuantity, order: .forward)
        case .stockLevelDesc:
            sortDescriptor = SortDescriptor(\Item.stockQuantity, order: .reverse)
        case .priceAsc:
            sortDescriptor = SortDescriptor(\Item.price, order: .forward)
        case .priceDesc:
            sortDescriptor = SortDescriptor(\Item.price, order: .reverse)
        case .dateAddedAsc:
            sortDescriptor = SortDescriptor(\Item.createdAt, order: .forward)
        case .dateAddedDesc:
            sortDescriptor = SortDescriptor(\Item.createdAt, order: .reverse)
        case .categoryAsc:
            sortDescriptor = SortDescriptor(\Item.category, order: .forward)
        case .categoryDesc:
            sortDescriptor = SortDescriptor(\Item.category, order: .reverse)
        }
        
        do {
            let descriptor = FetchDescriptor<Item>(predicate: finalPredicate, sortBy: [sortDescriptor])
            var items = try _modelContext.fetch(descriptor)
            
            // Apply search filter after fetch if needed
            if hasSearchText {
                let lowercasedSearch = trimmedSearch.lowercased()
                // Split search into words for better matching
                let searchWords = lowercasedSearch.split(separator: " ").map(String.init)
                
                if searchWords.count > 1 {
                    // Multi-word search - any word can match any field
                    items = items.filter { item in
                        searchWords.contains { word in
                            item.name.lowercased().contains(word) ||
                            item.itemDescription.lowercased().contains(word) ||
                            item.category.lowercased().contains(word) ||
                            item.sku.lowercased().contains(word) ||
                            (item.barcode != nil && item.barcode!.lowercased().contains(word))
                        }
                    }
                } else {
                    // Single word search
                    items = items.filter { item in
                        item.name.lowercased().contains(lowercasedSearch) ||
                        item.itemDescription.lowercased().contains(lowercasedSearch) ||
                        item.category.lowercased().contains(lowercasedSearch) ||
                        item.sku.lowercased().contains(lowercasedSearch) ||
                        (item.barcode != nil && item.barcode!.lowercased().contains(lowercasedSearch))
                    }
                }
            }
            
            return items
        } catch {
            print("Failed to fetch items: \(error)")
            return []
        }
    }
    
    func getItem(by id: UUID) -> Item? {
        let predicate = #Predicate<Item> { item in
            item.id == id
        }
        
        let descriptor = FetchDescriptor<Item>(predicate: predicate)
        
        do {
            let items = try _modelContext.fetch(descriptor)
            return items.first
        } catch {
            print("Failed to fetch item: \(error)")
            return nil
        }
    }
    
    func getItemByBarcode(_ barcode: String) -> Item? {
        let predicate = #Predicate<Item> { item in
            item.barcode == barcode
        }
        
        let descriptor = FetchDescriptor<Item>(predicate: predicate)
        
        do {
            let items = try _modelContext.fetch(descriptor)
            return items.first
        } catch {
            print("Failed to fetch item by barcode: \(error)")
            return nil
        }
    }
    
    func getTotalStockValue() -> Double {
        do {
            let items = try _modelContext.fetch(FetchDescriptor<Item>())
            return items.reduce(0) { $0 + $1.stockValue }
        } catch {
            print("Failed to calculate total stock value: \(error)")
            return 0
        }
    }
    
    func getLowStockItems() -> [Item] {
        let predicate = #Predicate<Item> { item in
            item.stockQuantity <= item.minStockLevel
        }
        
        let descriptor = FetchDescriptor<Item>(predicate: predicate)
        
        do {
            return try _modelContext.fetch(descriptor)
        } catch {
            print("Failed to fetch low stock items: \(error)")
            return []
        }
    }
    
    func getOutOfStockItems() -> [Item] {
        let predicate = #Predicate<Item> { item in
            item.stockQuantity == 0
        }
        
        let descriptor = FetchDescriptor<Item>(predicate: predicate)
        
        do {
            return try _modelContext.fetch(descriptor)
        } catch {
            print("Failed to fetch out of stock items: \(error)")
            return []
        }
    }
    
    func getAllCategories() -> [String] {
        do {
            // First get categories from the Category model
            let categoryDescriptor = FetchDescriptor<Category>()
            let categories = try _modelContext.fetch(categoryDescriptor)
            let categoryNames = categories.map { $0.name }
            
            // Then get any additional categories from items that might not be in the Category model
            let itemDescriptor = FetchDescriptor<Item>()
            let items = try _modelContext.fetch(itemDescriptor)
            let itemCategories = Set(items.map { $0.category })
            
            // Combine both sets and sort
            let allCategories = Set(categoryNames).union(itemCategories)
            return Array(allCategories).sorted()
        } catch {
            print("Failed to fetch categories: \(error)")
            return []
        }
    }
    
    func addCategory(_ category: Category) throws {
        // Check if category already exists first
        let existingCategories = getAllCategories()
        if existingCategories.contains(category.name) {
            // Category already exists, no need to add it
            return
        }
        
        _modelContext.insert(category)
        try _modelContext.save()
    }
    
    // MARK: - CSV Import/Export
    
    func importItemsFromCSV(fileURL: URL) async throws -> (imported: Int, errors: [String]) {
        guard fileURL.startAccessingSecurityScopedResource() else {
            throw CSVImportError.invalidFile
        }
        
        defer {
            fileURL.stopAccessingSecurityScopedResource()
        }
        
        // Read CSV content
        let csvContent: String
        do {
            csvContent = try String(contentsOf: fileURL, encoding: .utf8)
        } catch {
            throw CSVImportError.fileReadError
        }
        
        // Parse CSV
        var rows = csvContent.components(separatedBy: .newlines)
        guard !rows.isEmpty else { throw CSVImportError.invalidFile }
        
        // Extract headers
        let headers = rows.removeFirst().components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        
        // Verify required columns exist
        let requiredColumns = ["name", "description", "category", "sku", "price", "buy_price", "stock_quantity", "min_stock_level", "measurement_unit"]
        for column in requiredColumns {
            if !headers.contains(where: { $0.lowercased() == column }) {
                throw CSVImportError.missingRequiredColumns
            }
        }
        
        // Extract indices for each column
        let nameIndex = headers.firstIndex(where: { $0.lowercased() == "name" })!
        let descriptionIndex = headers.firstIndex(where: { $0.lowercased() == "description" })!
        let categoryIndex = headers.firstIndex(where: { $0.lowercased() == "category" })!
        let skuIndex = headers.firstIndex(where: { $0.lowercased() == "sku" })!
        let priceIndex = headers.firstIndex(where: { $0.lowercased() == "price" })!
        let buyPriceIndex = headers.firstIndex(where: { $0.lowercased() == "buy_price" })!
        let stockQuantityIndex = headers.firstIndex(where: { $0.lowercased() == "stock_quantity" })!
        let minStockLevelIndex = headers.firstIndex(where: { $0.lowercased() == "min_stock_level" })!
        let measurementUnitIndex = headers.firstIndex(where: { $0.lowercased() == "measurement_unit" })!
        
        // Optional column indices
        let taxRateIndex = headers.firstIndex(where: { $0.lowercased() == "tax_rate" })
        let barcodeIndex = headers.firstIndex(where: { $0.lowercased() == "barcode" })
        
        var importedCount = 0
        var errors: [String] = []
        
        // Process each row
        for (rowIndex, row) in rows.enumerated() {
            let rowNumber = rowIndex + 2 // +2 because headers are row 1 and rowIndex is 0-based
            
            // Skip empty rows
            if row.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                continue
            }
            
            let columns = row.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            
            // Ensure row has correct number of columns
            guard columns.count >= headers.count else {
                errors.append("Row \(rowNumber): Insufficient columns")
                continue
            }
            
            // Extract required values
            guard let price = Double(columns[priceIndex]),
                  let buyPrice = Double(columns[buyPriceIndex]),
                  let stockQuantity = Int(columns[stockQuantityIndex]),
                  let minStockLevel = Int(columns[minStockLevelIndex]) else {
                errors.append("Row \(rowNumber): Invalid numeric data")
                continue
            }
            
            // Get optional values
            let taxRate = taxRateIndex.flatMap { Double(columns[$0]) } ?? 0.0
            let barcode = barcodeIndex.flatMap { columns[$0] }
            
            // Get measurement unit
            let unitStr = columns[measurementUnitIndex].uppercased()
            let measurementUnit = MeasurementUnitType.allCases.first { $0.rawValue == unitStr } ?? .piece
            
            // Create and add item
            let name = columns[nameIndex]
            let description = columns[descriptionIndex]
            let category = columns[categoryIndex]
            let sku = columns[skuIndex]
            
            // Check for duplicate SKU
            let existingItem = getItemBySKU(sku)
            if existingItem != nil {
                errors.append("Row \(rowNumber): Duplicate SKU '\(sku)'")
                continue
            }
            
            // Create category if it doesn't exist
            if !getAllCategories().contains(category) {
                try? addCategory(Category(name: category))
            }
            
            let item = Item(
                name: name,
                description: description,
                category: category,
                sku: sku,
                price: price,
                buyPrice: buyPrice,
                stockQuantity: stockQuantity,
                minStockLevel: minStockLevel,
                measurementUnit: measurementUnit,
                taxRate: taxRate,
                barcode: barcode
            )
            
            addItem(item)
            importedCount += 1
        }
        
        return (importedCount, errors)
    }
    
    // Helper function to get item by SKU (to check for duplicates)
    func getItemBySKU(_ sku: String) -> Item? {
        let predicate = #Predicate<Item> { item in
            item.sku == sku
        }
        
        let descriptor = FetchDescriptor<Item>(predicate: predicate)
        
        do {
            let items = try _modelContext.fetch(descriptor)
            return items.first
        } catch {
            print("Failed to fetch item by SKU: \(error)")
            return nil
        }
    }
    
    // Export items to CSV
    func exportItemsToCSV() -> URL? {
        let items = getItems()
        
        // Create CSV header
        let header = "Name,Description,Category,SKU,Price,Buy Price,Stock Quantity,Min Stock Level,Measurement Unit,Tax Rate,Barcode\n"
        
        // Create CSV rows
        var csvContent = header
        for item in items {
            let row = "\"\(item.name)\",\"\(item.itemDescription)\",\"\(item.category)\",\"\(item.sku)\",\(item.price),\(item.buyPrice),\(item.stockQuantity),\(item.minStockLevel),\(item.measurementUnit),\(item.taxRate),\"\(item.barcode ?? "")\"\n"
            csvContent.append(row)
        }
        
        // Create temporary file
        let temporaryDirectory = FileManager.default.temporaryDirectory
        let fileName = "inventory_export_\(Date().timeIntervalSince1970).csv"
        let fileURL = temporaryDirectory.appendingPathComponent(fileName)
        
        do {
            try csvContent.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            print("Failed to export CSV: \(error)")
            return nil
        }
    }
    
    // Generate sample CSV data for demo/testing
    func generateSampleCSV() -> URL? {
        let csvContent = """
        Name,Description,Category,SKU,Price,Buy Price,Stock Quantity,Min Stock Level,Measurement Unit,Tax Rate,Barcode
        "Diamond Solitaire Ring","14K Gold Diamond Solitaire Ring","Rings","BJ-R001",1299.99,750.00,5,2,PCS,7.5,"4901234567890"
        "Sapphire Pendant","18K White Gold Sapphire Pendant","Pendants","BJ-P001",899.99,450.00,8,3,PCS,7.5,"4901234567891"
        "Pearl Stud Earrings","Freshwater Pearl Stud Earrings","Earrings","BJ-E001",199.99,80.00,15,5,PAIR,7.5,"4901234567892"
        "Gold Chain Necklace","18K Gold Chain Necklace, 18 inch","Necklaces","BJ-N001",599.99,300.00,10,4,PCS,7.5,"4901234567893"
        "Silver Bangle","Sterling Silver Bangle with Diamonds","Bracelets","BJ-B001",249.99,120.00,12,4,PCS,7.5,"4901234567894"
        "Emerald Drop Earrings","Emerald and Diamond Drop Earrings","Earrings","BJ-E002",1499.99,800.00,3,1,PAIR,7.5,"4901234567895"
        "Rose Gold Wedding Band","14K Rose Gold Wedding Band","Rings","BJ-R002",799.99,400.00,7,3,PCS,7.5,"4901234567896"
        "Diamond Tennis Bracelet","18K White Gold Diamond Tennis Bracelet","Bracelets","BJ-B002",2499.99,1200.00,2,1,PCS,7.5,"4901234567897"
        "Ruby Pendant","Ruby and Diamond Pendant in 14K Gold","Pendants","BJ-P002",1099.99,550.00,4,2,PCS,7.5,"4901234567898"
        "Pearl Necklace","Freshwater Pearl Necklace, 16 inch","Necklaces","BJ-N002",349.99,170.00,6,2,PCS,7.5,"4901234567899"
        """
        
        let temporaryDirectory = FileManager.default.temporaryDirectory
        let fileName = "brunelo_jewellers_sample.csv"
        let fileURL = temporaryDirectory.appendingPathComponent(fileName)
        
        do {
            try csvContent.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            print("Failed to generate sample CSV: \(error)")
            return nil
        }
    }
}