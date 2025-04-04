import SwiftUI
import PhotosUI

struct ItemFormView: View {
    @ObservedObject var viewModel: InventoryViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingImagePicker = false
    @State private var showingCategorySheet = false
    @State private var newCategory = ""
    @FocusState private var focusedField: FormField?
    @State private var itemImage: UIImage? // Local state for the image
    var onDismiss: (() -> Void)? = nil
    
    enum FormField {
        case name, description, category, sku, price, buyPrice, quantity, 
             minStock, measurementUnit, barcode
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Image Section
                Section {
                    HStack {
                        Spacer()
                        ZStack {
                            if let image = itemImage ?? viewModel.newItemImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 150, height: 150)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.secondary, lineWidth: 1)
                                    )
                            } else {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.secondary.opacity(0.2))
                                    .frame(width: 150, height: 150)
                                    .overlay(
                                        Image(systemName: "photo")
                                            .font(.largeTitle)
                                            .foregroundColor(.secondary)
                                    )
                            }
                            
                            VStack {
                                Spacer()
                                HStack {
                                    Spacer()
                                    Button(action: {
                                        showingImagePicker = true
                                    }) {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.title)
                                            .foregroundColor(.accentColor)
                                            .background(Circle().fill(Color.white))
                                    }
                                    .offset(x: 5, y: 5)
                                }
                            }
                            .frame(width: 150, height: 150)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 10)
                    .listRowInsets(EdgeInsets())
                }
                
                // Basic Info Section
                Section(header: Text("Basic Information")) {
                    TextField("Item Name", text: $viewModel.newItemName)
                        .focused($focusedField, equals: .name)
                        .submitLabel(.next)
                        .onSubmit { focusedField = .sku }
                    
                    TextField("Product Code (SKU)", text: $viewModel.newItemSKU)
                        .focused($focusedField, equals: .sku)
                        .submitLabel(.next)
                        .onSubmit { focusedField = .description }
                    
                    ZStack(alignment: .topLeading) {
                        if viewModel.newItemDescription.isEmpty {
                            Text("Description")
                                .foregroundColor(.secondary)
                                .padding(.top, 8)
                        }
                        
                        TextEditor(text: $viewModel.newItemDescription)
                            .focused($focusedField, equals: .description)
                            .frame(minHeight: 100)
                    }
                    .onTapGesture {
                        if focusedField != .description {
                            focusedField = .description
                        }
                    }
                    
                    HStack {
                        Text("Category")
                        Spacer()
                        
                        Picker("", selection: $viewModel.newItemCategory) {
                            Text("Select a category").tag("")
                            
                            ForEach(viewModel.getCategories(), id: \.self) { category in
                                Text(category).tag(category)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        
                        Button(action: {
                            showingCategorySheet = true
                        }) {
                            Image(systemName: "plus.circle")
                        }
                    }
                }
                
                // Stock & Price Section
                Section(header: Text("Stock & Price")) {
                    HStack {
                        Text("Measurement Unit")
                        Spacer()
                        Picker("", selection: $viewModel.newItemMeasurementUnit) {
                            ForEach(MeasurementUnitType.allCases, id: \.self) { unit in
                                Text(unit.rawValue).tag(unit)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                    
                    HStack {
                        Text("$")
                        TextField("Sales Price", text: $viewModel.newItemPrice)
                            .keyboardType(.decimalPad)
                            .focused($focusedField, equals: .price)
                            .submitLabel(.next)
                            .onSubmit { focusedField = .buyPrice }
                    }
                    
                    HStack {
                        Text("$")
                        TextField("Purchase Price", text: $viewModel.newItemBuyPrice)
                            .keyboardType(.decimalPad)
                            .focused($focusedField, equals: .buyPrice)
                            .submitLabel(.next)
                            .onSubmit { focusedField = .quantity }
                    }
                    
                    // Tax Rate removed - it should only be on invoices and estimates
                    
                    HStack {
                        Text("Quantity")
                        Spacer()
                        TextField("", text: $viewModel.newItemQuantity)
                            .keyboardType(.numberPad)
                            .focused($focusedField, equals: .quantity)
                            .submitLabel(.next)
                            .onSubmit { focusedField = .minStock }
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }
                    
                    HStack {
                        Text("Minimum Stock Level")
                        Spacer()
                        TextField("", text: $viewModel.newItemMinStock)
                            .keyboardType(.numberPad)
                            .focused($focusedField, equals: .minStock)
                            .submitLabel(.next)
                            .onSubmit { focusedField = .barcode }
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }
                }
                
                // Additional Info Section
                Section(header: Text("Additional Information")) {
                    HStack {
                        Image(systemName: "barcode")
                            .foregroundColor(.secondary)
                        TextField("Barcode/QR Code", text: $viewModel.newItemBarcode)
                            .focused($focusedField, equals: .barcode)
                            .submitLabel(.done)
                    }
                    
                    Text("Added: \(Date().formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Save Button
                Section {
                    Button(action: saveItem) {
                        Text(viewModel.isEditing ? "Update Item" : "Add Item")
                            .frame(maxWidth: .infinity, alignment: .center)
                            .fontWeight(.semibold)
                    }
                    .listRowBackground(Color.accentColor)
                    .foregroundColor(.white)
                }
            }
            .navigationTitle(viewModel.isEditing ? "Edit Item" : "Add New Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingImagePicker) {
                PHPickerView(image: $itemImage, onPick: { image in
                    // Sync our local image to the view model's image
                    viewModel.newItemImage = image 
                })
            }
            .sheet(isPresented: $showingCategorySheet) {
                addCategoryView
            }
            .onAppear {
                // If editing an item with imageData, load it immediately
                if viewModel.isEditing, let selectedItem = viewModel.selectedItem, let imageData = selectedItem.imageData {
                    self.itemImage = UIImage(data: imageData)
                    // Also set the view model's image
                    viewModel.newItemImage = self.itemImage
                }
            }
        }
    }
    
    private var addCategoryView: some View {
        NavigationStack {
            Form {
                Section(header: Text("Add New Category")) {
                    TextField("Category Name", text: $newCategory)
                        .autocapitalization(.words)
                }
                
                Section {
                    Button("Add Category") {
                        if !newCategory.isEmpty {
                            // Add category to the database
                            if viewModel.addCategory(name: newCategory) {
                                newCategory = ""
                                showingCategorySheet = false
                            }
                        }
                    }
                    .disabled(newCategory.isEmpty)
                }
            }
            .navigationTitle("New Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showingCategorySheet = false
                    }
                }
            }
        }
    }
    
    private func saveItem() {
        // Make sure we update the viewModel's image from our local state if needed
        if let localImage = itemImage, viewModel.newItemImage == nil {
            viewModel.newItemImage = localImage
        }
        
        if viewModel.isEditing {
            viewModel.updateItem()
        } else {
            viewModel.addItem()
        }
        
        // Call the onDismiss closure if it exists
        onDismiss?()
        dismiss()
    }
}

struct PHPickerView: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    var onPick: ((UIImage) -> Void)? = nil
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: PHPickerView
        
        init(_ parent: PHPickerView) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            
            guard let result = results.first else { return }
            
            result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] (object, error) in
                guard let self = self, let image = object as? UIImage else { return }
                
                DispatchQueue.main.async {
                    // Update binding
                    self.parent.image = image
                    
                    // Call the callback
                    self.parent.onPick?(image)
                }
            }
        }
    }
}