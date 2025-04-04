import SwiftUI
import SwiftData

struct InventoryView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var navigationRouter: NavigationRouter
    @StateObject private var viewModel: InventoryViewModel
    @State private var showingAddItemSheet = false
    @State private var showingScanner = false
    @State private var showingSortOptions = false
    @State private var showingFilterOptions = false
    @State private var isRefreshing = false
    @State private var showingItemDetail = false
    @State private var selectedItem: Item?
    @State private var showingCSVImport = false
    
    init(modelContext: ModelContext) {
        let inventoryService = InventoryService(modelContext: modelContext)
        _viewModel = StateObject(wrappedValue: InventoryViewModel(inventoryService: inventoryService))
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Hidden back gesture area for swipe navigation 
                // (transparent area that responds to swipe gestures)
                Rectangle()
                    .frame(width: 20, height: UIScreen.main.bounds.height)
                    .position(x: 0, y: UIScreen.main.bounds.height/2)
                    .opacity(0.001) // Invisible but still captures gestures
                
                if viewModel.items.isEmpty && !viewModel.isLoading {
                    emptyStateView
                } else {
                    mainListView
                }
                
                // Floating Add Button
                floatingAddButton
            }
            .navigationTitle("Inventory")
            .toolbar {
                ToolbarItem(placement: .principal) {
                    // Only show home button if not shown from tab view
                    if !UIDevice.isRunningInTabView {
                        HomeButtonLink()
                    } else {
                        // Empty view when in tab view to avoid duplicate home button
                        EmptyView()
                    }
                }
                
                ToolbarItem(placement: .topBarLeading) {
                    HStack {
                        Button(action: {
                            showingFilterOptions = true
                        }) {
                            Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
                        }
                        
                        Button(action: {
                            showingSortOptions = true
                        }) {
                            Label("Sort", systemImage: "arrow.up.arrow.down")
                        }
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    HStack {
                        Button(action: {
                            showingCSVImport = true
                        }) {
                            Label("Import", systemImage: "square.and.arrow.down")
                        }
                        
                        // Temporarily disabled to prevent crashes
                        Button(action: {
                            // showingScanner = true
                            viewModel.alertMessage = "Barcode scanning is temporarily disabled"
                            viewModel.showingAlert = true
                        }) {
                            Label("Scan", systemImage: "barcode.viewfinder")
                                .foregroundColor(.gray)
                        }
                        
                        Button(action: {
                            Task {
                                await viewModel.syncFromCloud()
                            }
                        }) {
                            if viewModel.isSyncing {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                            } else {
                                Label("Sync", systemImage: "arrow.clockwise")
                            }
                        }
                        .disabled(viewModel.isSyncing)
                    }
                }
            }
            .refreshable {
                isRefreshing = true
                viewModel.loadItems()
                try? await Task.sleep(for: .seconds(0.5))
                isRefreshing = false
            }
            .safeAreaInset(edge: .top) {
                // Static search bar that's always visible
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search items...", text: $viewModel.searchText)
                        .disableAutocorrection(true)
                        .textInputAutocapitalization(.never)
                        .submitLabel(.search)
                    
                    if !viewModel.searchText.isEmpty {
                        Button(action: {
                            viewModel.searchText = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.vertical, 10)
                .padding(.horizontal)
                .background(Color(UIColor.secondarySystemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
            }
            .overlay {
                if viewModel.isLoading && !isRefreshing {
                    ProgressView("Loading...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.1))
                }
            }
            .sheet(isPresented: $showingAddItemSheet) {
                ItemFormView(viewModel: viewModel, onDismiss: {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        viewModel.loadItems()
                    }
                })
            }
            .sheet(isPresented: $showingScanner) {
                BarcodeScannerView { result in
                    viewModel.scanBarcode(result: result)
                    showingScanner = false
                    showingAddItemSheet = true
                }
            }
            .actionSheet(isPresented: $showingSortOptions) {
                ActionSheet(
                    title: Text("Sort Items"),
                    buttons: [
                        .default(Text("Name (A-Z)")) { viewModel.sortOption = .nameAsc },
                        .default(Text("Name (Z-A)")) { viewModel.sortOption = .nameDesc },
                        .default(Text("Category (A-Z)")) { viewModel.sortOption = .categoryAsc },
                        .default(Text("Category (Z-A)")) { viewModel.sortOption = .categoryDesc },
                        .default(Text("Stock (Low to High)")) { viewModel.sortOption = .stockLevelAsc },
                        .default(Text("Stock (High to Low)")) { viewModel.sortOption = .stockLevelDesc },
                        .default(Text("Price (Low to High)")) { viewModel.sortOption = .priceAsc },
                        .default(Text("Price (High to Low)")) { viewModel.sortOption = .priceDesc },
                        .default(Text("Date Added (Oldest)")) { viewModel.sortOption = .dateAddedAsc },
                        .default(Text("Date Added (Newest)")) { viewModel.sortOption = .dateAddedDesc },
                        .cancel()
                    ]
                )
            }
            .sheet(isPresented: $showingFilterOptions) {
                FilterOptionsView(viewModel: viewModel)
            }
            .alert(isPresented: $viewModel.showingAlert) {
                Alert(
                    title: Text("Notification"),
                    message: Text(viewModel.alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
            .sheet(isPresented: $showingCSVImport) {
                CSVImportView()
            }
        }
    }
    
    // MARK: - Subviews
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "cube.box")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundColor(.secondary)
            
            Text("No Items Found")
                .font(.title2)
                .fontWeight(.medium)
            
            if viewModel.searchText.isEmpty && viewModel.selectedCategory == nil && !viewModel.showLowStockOnly {
                Text("Add your first item to get started")
                    .foregroundColor(.secondary)
                
                Button(action: {
                    viewModel.clearSelection()
                    showingAddItemSheet = true
                }) {
                    Label("Add Item", systemImage: "plus")
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.top)
            } else {
                Text("Try changing your search or filters")
                    .foregroundColor(.secondary)
                
                Button(action: {
                    viewModel.resetFilters()
                }) {
                    Label("Reset Filters", systemImage: "xmark.circle")
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.top)
            }
        }
        .padding()
    }
    
    private var mainListView: some View {
        List {
            ForEach(viewModel.items) { item in
                InventoryItemRow(item: item)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedItem = item
                        viewModel.selectItem(item)
                        showingAddItemSheet = true
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            withAnimation {
                                viewModel.deleteItem(item: item)
                            }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        
                        Button {
                            viewModel.selectItem(item)
                            showingAddItemSheet = true
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        .tint(.blue)
                    }
            }
        }
        .listStyle(InsetGroupedListStyle())
    }
    
    private var floatingAddButton: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button(action: {
                    viewModel.clearSelection()
                    showingAddItemSheet = true
                }) {
                    Image(systemName: "plus")
                        .font(.title)
                        .frame(width: 60, height: 60)
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .clipShape(Circle())
                        .shadow(radius: 4)
                }
                .padding(20)
            }
        }
    }
}

struct InventoryItemRow: View {
    let item: Item
    
    var body: some View {
        HStack(spacing: 15) {
            // Item image or placeholder
            ZStack {
                Rectangle()
                    .fill(Color.secondary.opacity(0.2))
                    .frame(width: 60, height: 60)
                    .cornerRadius(8)
                
                if let imageData = item.imageData, let uiImage = UIImage(data: imageData) {
                    // Display image directly from stored image data
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 60, height: 60)
                        .cornerRadius(8)
                } else if item.imageURL != nil {
                    // Fallback to URL-based image loading
                    AsyncImageView(urlString: item.imageURL!, item: item)
                        .frame(width: 60, height: 60)
                        .cornerRadius(8)
                } else {
                    Image(systemName: "cube.box.fill")
                        .font(.title)
                        .foregroundColor(.secondary)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.headline)
                
                HStack {
                    Text(item.category)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.secondary.opacity(0.2))
                        .cornerRadius(4)
                    
                    Spacer()
                    
                    Text(String(format: "$%.2f", item.price))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                
                HStack {
                    Text("Stock: \(item.stockQuantity)")
                        .font(.subheadline)
                    
                    if item.isLowStock {
                        Text("Low Stock")
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.red)
                            .cornerRadius(4)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct AsyncImageView: View {
    let urlString: String
    let item: Item // Pass the item so we can update its imageData
    @State private var image: UIImage?
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                ProgressView()
            }
        }
        .onAppear {
            loadImage()
        }
    }
    
    private func loadImage() {
        Task {
            do {
                let imageData = try await FirebaseService.shared.downloadImage(from: urlString)
                if let uiImage = UIImage(data: imageData) {
                    DispatchQueue.main.async {
                        self.image = uiImage
                        
                        // Also update the item's imageData so it's cached for next time
                        item.imageData = imageData
                        try? modelContext.save()
                    }
                }
            } catch {
                print("Failed to load image: \(error)")
                
                // Try to load from a local cache using the URL as a key
                if let filename = urlString.components(separatedBy: "/").last {
                    loadFromLocalCache(filename: filename)
                }
            }
        }
    }
    
    private func loadFromLocalCache(filename: String) {
        let fileManager = FileManager.default
        if let documentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
            let fileURL = documentDirectory.appendingPathComponent("itemImages/\(filename)")
            
            if fileManager.fileExists(atPath: fileURL.path),
               let data = try? Data(contentsOf: fileURL),
               let cachedImage = UIImage(data: data) {
                
                DispatchQueue.main.async {
                    self.image = cachedImage
                    
                    // Also update the item's imageData
                    item.imageData = data
                    try? modelContext.save()
                }
            }
        }
    }
}

struct FilterOptionsView: View {
    @ObservedObject var viewModel: InventoryViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Category")) {
                    Picker("Select Category", selection: $viewModel.selectedCategory) {
                        Text("All Categories").tag(String?.none)
                        ForEach(viewModel.getCategories(), id: \.self) { category in
                            Text(category).tag(String?.some(category))
                        }
                    }
                }
                
                Section {
                    Toggle("Show Low Stock Items Only", isOn: $viewModel.showLowStockOnly)
                }
                
                Section {
                    Button("Reset Filters") {
                        viewModel.resetFilters()
                        dismiss()
                    }
                }
            }
            .navigationTitle("Filter Options")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}