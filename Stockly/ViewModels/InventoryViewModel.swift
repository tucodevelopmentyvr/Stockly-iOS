import Foundation
import SwiftData
import Combine
import SwiftUI

class InventoryViewModel: ObservableObject {
    @Published var items: [Item] = []
    @Published var selectedItem: Item?
    @Published var searchText = ""
    @Published var isLoading = false
    @Published var selectedCategory: String?
    @Published var sortOption: SortOption = .nameAsc
    @Published var showLowStockOnly = false
    @Published var isEditing = false
    @Published var showingAlert = false
    @Published var alertMessage = ""
    @Published var isSyncing = false
    
    // Disabled recent searches storage
    private var recentSearchesData: Data = Data()
    @Published var recentSearches: [String] = []
    
    // Method to find an item by name
    func findItemByName(_ name: String) -> Item? {
        return items.first { $0.name == name }
    }
    
    // Disabled - do nothing
    func saveSearch(_ query: String) {
        // Search history disabled
    }
    
    // Disabled - do nothing
    func loadRecentSearches() {
        // Search history disabled - keep empty list
        recentSearches = []
    }
    
    // New item form properties
    @Published var newItemName = ""
    @Published var newItemDescription = ""
    @Published var newItemCategory = ""
    @Published var newItemSKU = ""
    @Published var newItemPrice = ""
    @Published var newItemBuyPrice = ""
    @Published var newItemQuantity = ""
    @Published var newItemMinStock = ""
    @Published var newItemMeasurementUnit = MeasurementUnitType.piece
    @Published var newItemTaxRate = ""
    @Published var newItemBarcode = ""
    @Published var newItemImage: UIImage?
    
    private let inventoryService: InventoryService
    private let firebaseService: FirebaseService
    private var cancellables = Set<AnyCancellable>()
    
    init(inventoryService: InventoryService, firebaseService: FirebaseService = FirebaseService.shared) {
        self.inventoryService = inventoryService
        self.firebaseService = firebaseService
        
        // Simplify search handling to avoid potential conflicts
        $searchText
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] text in
                // Need to use Task to ensure we're on the main actor for UI updates
                Task { @MainActor in
                    // Add a slight delay to prevent UI update conflicts
                    try? await Task.sleep(for: .nanoseconds(50_000_000)) // 0.05 seconds
                    
                    // Search history disabled - no need to save searches
                    
                    // Load items with the latest search text
                    self?.loadItems()
                }
            }
            .store(in: &cancellables)
        
        // Set up category filtering
        $selectedCategory
            .sink { [weak self] _ in
                self?.loadItems()
            }
            .store(in: &cancellables)
        
        // Set up sort option
        $sortOption
            .sink { [weak self] _ in
                self?.loadItems()
            }
            .store(in: &cancellables)
        
        // Set up low stock filtering
        $showLowStockOnly
            .sink { [weak self] _ in
                self?.loadItems()
            }
            .store(in: &cancellables)
        
        // Load recent searches
        loadRecentSearches()
        
        // Initial load
        loadItems()
    }
    
    func loadItems() {
        isLoading = true
        // Use Task instead of DispatchQueue to avoid UI update issues
        Task { @MainActor in
            // Introduce a very small delay to prevent UI rendering conflicts
            try? await Task.sleep(for: .nanoseconds(100_000_000)) // 0.1 seconds
            
            self.items = self.inventoryService.getItems(
                sortBy: self.sortOption,
                searchText: self.searchText,
                category: self.selectedCategory,
                lowStockOnly: self.showLowStockOnly
            )
            self.isLoading = false
        }
    }
    
    func addItem() {
        guard validateItemInputs() else { return }
        
        guard let price = Double(newItemPrice),
              let buyPrice = Double(newItemBuyPrice),
              let quantity = Int(newItemQuantity),
              let minStock = Int(newItemMinStock) else {
            showAlert("Please enter valid numbers for prices, quantity, and minimum stock level")
            return
        }
        
        // Default tax rate to 0% as this has been removed from the form
        let taxRate = 0.0
        
        let newItem = Item(
            name: newItemName,
            description: newItemDescription,
            category: newItemCategory,
            sku: newItemSKU,
            price: price,
            buyPrice: buyPrice,
            stockQuantity: quantity,
            minStockLevel: minStock,
            measurementUnit: newItemMeasurementUnit,
            taxRate: taxRate,
            barcode: newItemBarcode.isEmpty ? nil : newItemBarcode
        )
        
        inventoryService.addItem(newItem)
        
        // If we have an image, upload it
        if let image = newItemImage, let imageData = image.jpegData(compressionQuality: 0.8) {
            uploadImageForItem(imageData: imageData, item: newItem)
        }
        
        clearNewItemForm()
        loadItems()
        showAlert("Item added successfully")
    }
    
    func updateItem() {
        guard let item = selectedItem else { return }
        
        guard validateItemInputs() else { return }
        
        guard let price = Double(newItemPrice),
              let buyPrice = Double(newItemBuyPrice),
              let quantity = Int(newItemQuantity),
              let minStock = Int(newItemMinStock) else {
            showAlert("Please enter valid numbers for prices, quantity, and minimum stock level")
            return
        }
        
        // Keep the existing tax rate when updating
        let taxRate = item.taxRate
        
        item.name = newItemName
        item.itemDescription = newItemDescription
        item.category = newItemCategory
        item.sku = newItemSKU
        item.price = price
        item.buyPrice = buyPrice
        item.stockQuantity = quantity
        item.minStockLevel = minStock
        item.measurementUnit = newItemMeasurementUnit.rawValue
        item.taxRate = taxRate
        item.barcode = newItemBarcode.isEmpty ? nil : newItemBarcode
        item.updatedAt = Date()
        
        inventoryService.updateItem(item)
        
        // If we have a new image, upload it
        if let image = newItemImage, let imageData = image.jpegData(compressionQuality: 0.8) {
            uploadImageForItem(imageData: imageData, item: item)
        }
        
        clearNewItemForm()
        loadItems()
        showAlert("Item updated successfully")
    }
    
    func deleteItem(item: Item) {
        inventoryService.deleteItem(item)
        loadItems()
    }
    
    func selectItem(_ item: Item) {
        selectedItem = item
        populateEditForm(with: item)
        isEditing = true
    }
    
    func clearSelection() {
        selectedItem = nil
        clearNewItemForm()
        isEditing = false
    }
    
    func resetFilters() {
        searchText = ""
        selectedCategory = nil
        sortOption = .nameAsc
        showLowStockOnly = false
    }
    
    func getCategories() -> [String] {
        return inventoryService.getAllCategories()
    }
    
    func addCategory(name: String) -> Bool {
        // Check if category already exists
        let existingCategories = inventoryService.getAllCategories()
        if existingCategories.contains(name) {
            // Category already exists, just select it
            newItemCategory = name
            return true
        }
        
        // Add the new category through the inventory service
        let newCategory = Category(name: name)
        do {
            try inventoryService.addCategory(newCategory)
            return true
        } catch {
            showAlert("Failed to create category: \(error.localizedDescription)")
            return false
        }
    }
    
    func scanBarcode(result: String) {
        if let existingItem = inventoryService.getItemByBarcode(result) {
            selectItem(existingItem)
        } else {
            clearNewItemForm()
            newItemBarcode = result
        }
    }
    
    func getTotalStockValue() -> Double {
        return inventoryService.getTotalStockValue()
    }
    
    func getLowStockItems() -> [Item] {
        return inventoryService.getLowStockItems()
    }
    
    func getOutOfStockItems() -> [Item] {
        return inventoryService.getOutOfStockItems()
    }
    
    // MARK: - Cloud Sync
    
    @MainActor
    func syncToCloud() async {
        isSyncing = true
        
        do {
            try await firebaseService.syncLocalToCloud(items: items)
            isSyncing = false
            showAlert("Data synced to cloud successfully")
        } catch {
            isSyncing = false
            showAlert("Failed to sync data: \(error.localizedDescription)")
        }
    }
    
    @MainActor
    func syncFromCloud() async {
        isSyncing = true
        
        do {
            let cloudItems = try await firebaseService.syncCloudToLocal()
            
            // Merge cloud items with local items
            for cloudItem in cloudItems {
                if let existingItem = inventoryService.getItem(by: cloudItem.id) {
                    // Update existing item if cloud version is newer
                    if cloudItem.updatedAt > existingItem.updatedAt {
                        existingItem.name = cloudItem.name
                        existingItem.itemDescription = cloudItem.itemDescription
                        existingItem.category = cloudItem.category
                        existingItem.price = cloudItem.price
                        existingItem.stockQuantity = cloudItem.stockQuantity
                        existingItem.minStockLevel = cloudItem.minStockLevel
                        existingItem.barcode = cloudItem.barcode
                        existingItem.imageURL = cloudItem.imageURL
                        existingItem.updatedAt = cloudItem.updatedAt
                        
                        inventoryService.updateItem(existingItem)
                    }
                } else {
                    // Add new item from cloud
                    inventoryService.addItem(cloudItem)
                }
            }
            
            loadItems()
            isSyncing = false
            showAlert("Data synced from cloud successfully")
        } catch {
            isSyncing = false
            showAlert("Failed to sync data: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Private Helpers
    
    private func uploadImageForItem(imageData: Data, item: Item) {
        // Set image data directly on the item model
        item.imageData = imageData
        
        // Also try to upload to Firebase, but the core image data is already saved
        Task { @MainActor in
            do {
                let imageURL = try await firebaseService.uploadImage(imageData, itemId: item.id)
                
                // Update item with image URL
                item.imageURL = imageURL
                inventoryService.updateItem(item)
                
                // Save image locally using the URL as filename
                if let image = UIImage(data: imageData),
                   let filename = imageURL.components(separatedBy: "/").last {
                    saveImageLocally(image: image, filename: filename)
                }
                
                // Refresh items list
                loadItems()
            } catch {
                print("Failed to upload image: \(error)")
                
                // Even if upload fails, the image data is already saved in the item.imageData property
                
                // Save locally with item ID as filename for backup
                if let image = UIImage(data: imageData) {
                    saveImageLocally(image: image, filename: "\(item.id.uuidString).jpg")
                    
                    // Still set a local URL to retrieve it later
                    let localURL = "local://images/\(item.id.uuidString).jpg"
                    item.imageURL = localURL
                    inventoryService.updateItem(item)
                }
            }
        }
    }
    
    private func populateEditForm(with item: Item) {
        newItemName = item.name
        newItemDescription = item.itemDescription
        newItemCategory = item.category
        newItemSKU = item.sku
        newItemPrice = String(format: "%.2f", item.price)
        newItemBuyPrice = String(format: "%.2f", item.buyPrice)
        newItemQuantity = "\(item.stockQuantity)"
        newItemMinStock = "\(item.minStockLevel)"
        newItemTaxRate = String(format: "%.2f", item.taxRate)
        
        // Set measurement unit
        if let unitType = MeasurementUnitType.allCases.first(where: { $0.rawValue == item.measurementUnit }) {
            newItemMeasurementUnit = unitType
        } else {
            newItemMeasurementUnit = .piece // Default
        }
        
        newItemBarcode = item.barcode ?? ""
        newItemImage = nil // Load image if needed
        
        if let imageURL = item.imageURL {
            loadItemImage(from: imageURL)
        }
    }
    
    private func loadItemImage(from urlString: String) {
        // Mark as loading to prevent premature form submission
        isSyncing = true
        
        // If the selected item has image data, use it directly - this is the most reliable source
        if let selectedItem = selectedItem, let imageData = selectedItem.imageData, let image = UIImage(data: imageData) {
            newItemImage = image
            isSyncing = false
            return
        }
        
        // If no direct image data, try the local cache
        if let filename = urlString.components(separatedBy: "/").last, 
           let cachedImage = loadImageFromCache(filename: filename) {
            newItemImage = cachedImage
            isSyncing = false
            return
        }
        
        // As a last resort, try downloading from Firebase
        Task { @MainActor in
            do {
                // Add a small delay to ensure the form is displayed before loading starts
                try await Task.sleep(for: .seconds(0.2))
                
                let imageData = try await firebaseService.downloadImage(from: urlString)
                if let image = UIImage(data: imageData) {
                    // Store the loaded image
                    newItemImage = image
                    
                    // Also save a local copy using the URL as filename
                    if let filename = urlString.components(separatedBy: "/").last {
                        saveImageLocally(image: image, filename: filename)
                    }
                    
                    // Also update the selected item's imageData for future use
                    if let selectedItem = selectedItem {
                        selectedItem.imageData = imageData
                        inventoryService.updateItem(selectedItem)
                    }
                }
            } catch {
                print("Failed to load image from URL: \(error)")
                
                // Try once more with a different approach - load by item ID
                if let selectedItem = selectedItem {
                    let localFilename = "\(selectedItem.id.uuidString).jpg"
                    if let cachedImage = loadImageFromCache(filename: localFilename) {
                        newItemImage = cachedImage
                    }
                }
            }
            
            // End loading state
            isSyncing = false
        }
    }
    
    // Helper method to save images locally
    private func saveImageLocally(image: UIImage, filename: String) {
        if let data = image.jpegData(compressionQuality: 0.8) {
            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let fileURL = documentsDirectory.appendingPathComponent("itemImages/\(filename)")
            
            // Create directory if it doesn't exist
            let directoryURL = fileURL.deletingLastPathComponent()
            if !FileManager.default.fileExists(atPath: directoryURL.path) {
                try? FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
            }
            
            try? data.write(to: fileURL)
        }
    }
    
    // Helper method to load images from cache
    private func loadImageFromCache(filename: String) -> UIImage? {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = documentsDirectory.appendingPathComponent("itemImages/\(filename)")
        
        if FileManager.default.fileExists(atPath: fileURL.path),
           let data = try? Data(contentsOf: fileURL),
           let image = UIImage(data: data) {
            return image
        }
        return nil
    }
    
    private func clearNewItemForm() {
        newItemName = ""
        newItemDescription = ""
        newItemCategory = ""
        newItemSKU = ""
        newItemPrice = ""
        newItemBuyPrice = ""
        newItemQuantity = ""
        newItemMinStock = ""
        newItemMeasurementUnit = .piece
        newItemTaxRate = "0" // Default to 0 but not shown in UI
        newItemBarcode = ""
        newItemImage = nil
    }
    
    private func validateItemInputs() -> Bool {
        guard !newItemName.isEmpty else {
            showAlert("Please enter a name for the item")
            return false
        }
        
        guard !newItemSKU.isEmpty else {
            showAlert("Please enter a SKU/product code")
            return false
        }
        
        guard !newItemCategory.isEmpty else {
            showAlert("Please select a category for the item")
            return false
        }
        
        guard !newItemPrice.isEmpty, let price = Double(newItemPrice), price >= 0 else {
            showAlert("Please enter a valid sales price")
            return false
        }
        
        guard !newItemBuyPrice.isEmpty, let buyPrice = Double(newItemBuyPrice), buyPrice >= 0 else {
            showAlert("Please enter a valid purchase price")
            return false
        }
        
        // Tax rate validation removed - tax rate is no longer on the form
        
        guard !newItemQuantity.isEmpty, let quantity = Int(newItemQuantity), quantity >= 0 else {
            showAlert("Please enter a valid quantity")
            return false
        }
        
        guard !newItemMinStock.isEmpty, let minStock = Int(newItemMinStock), minStock >= 0 else {
            showAlert("Please enter a valid minimum stock level")
            return false
        }
        
        return true
    }
    
    private func showAlert(_ message: String) {
        DispatchQueue.main.async {
            self.alertMessage = message
            self.showingAlert = true
        }
    }
}