import SwiftUI
import SwiftData

struct CategoriesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var categories: [Category]
    @State private var showingAddCategory = false
    @State private var selectedCategory: Category?
    @State private var showingEditSheet = false
    @State private var showingDeleteConfirmation = false
    @State private var searchText = ""
    
    var filteredCategories: [Category] {
        if searchText.isEmpty {
            return categories
        } else {
            return categories.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if categories.isEmpty {
                    ContentUnavailableView {
                        Label("No Categories", systemImage: "folder.badge.questionmark")
                    } description: {
                        Text("Add your first category to organize your inventory.")
                    } actions: {
                        Button(action: { showingAddCategory = true }) {
                            Text("Add Category")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else {
                    List {
                        ForEach(filteredCategories) { category in
                            CategoryRow(category: category)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedCategory = category
                                    showingEditSheet = true
                                }
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        selectedCategory = category
                                        showingDeleteConfirmation = true
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    }
                    .searchable(text: $searchText, prompt: "Search categories...")
                }
            }
            .navigationTitle("Categories")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddCategory = true }) {
                        Label("Add Category", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddCategory) {
                CategoryFormView(mode: .add) { newCategory in
                    addCategory(newCategory)
                }
            }
            .sheet(isPresented: $showingEditSheet) {
                if let category = selectedCategory {
                    CategoryFormView(mode: .edit, category: category) { updatedCategory in
                        updateCategory(category: category, with: updatedCategory)
                    }
                }
            }
            .alert("Delete Category", isPresented: $showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    if let category = selectedCategory {
                        deleteCategory(category)
                    }
                }
            } message: {
                Text("Are you sure you want to delete this category? All custom fields associated with this category will also be deleted.")
            }
        }
    }
    
    private func addCategory(_ category: Category) {
        modelContext.insert(category)
        try? modelContext.save()
    }
    
    private func updateCategory(category: Category, with updatedData: Category) {
        category.name = updatedData.name
        category.categoryDescription = updatedData.categoryDescription
        category.updatedAt = Date()
        
        try? modelContext.save()
    }
    
    private func deleteCategory(_ category: Category) {
        modelContext.delete(category)
        try? modelContext.save()
    }
}

struct CategoryRow: View {
    let category: Category
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(category.name)
                .font(.headline)
            
            if let description = category.categoryDescription, !description.isEmpty {
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text("Custom Fields: \(category.customFields?.count ?? 0)")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 2)
    }
}

struct CategoryFormView: View {
    enum FormMode {
        case add
        case edit
    }
    
    let mode: FormMode
    var category: Category?
    var onSave: (Category) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var description = ""
    @State private var showingErrors = false
    @State private var customFields: [CustomFieldEntry] = []
    @State private var showingAddField = false
    
    struct CustomFieldEntry: Identifiable {
        let id = UUID()
        var name: String
        var type: FieldType
        var required: Bool
        var options: [String]?
    }
    
    private var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Category Information")) {
                    TextField("Name *", text: $name)
                    
                    ZStack(alignment: .topLeading) {
                        if description.isEmpty {
                            Text("Description")
                                .foregroundColor(.secondary)
                                .padding(.top, 8)
                        }
                        
                        TextEditor(text: $description)
                            .frame(minHeight: 60)
                    }
                }
                
                Section(header: Text("Custom Fields")) {
                    if customFields.isEmpty {
                        Text("No custom fields")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(customFields) { field in
                            VStack(alignment: .leading) {
                                Text(field.name)
                                    .font(.headline)
                                
                                HStack {
                                    Text(field.type.rawValue.capitalized)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    if field.required {
                                        Text("• Required")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                if field.type == .dropdown, let options = field.options, !options.isEmpty {
                                    Text("Options: \(options.joined(separator: ", "))")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .onDelete(perform: deleteField)
                    }
                    
                    Button(action: { showingAddField = true }) {
                        Label("Add Custom Field", systemImage: "plus")
                    }
                }
                
                if showingErrors && !isFormValid {
                    Section {
                        Text("Please fill in all required fields")
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle(mode == .add ? "Add Category" : "Edit Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if isFormValid {
                            let newCategory = Category(
                                name: name,
                                description: description.isEmpty ? nil : description
                            )
                            
                            // Add custom fields if any
                            if !customFields.isEmpty {
                                var fields: [CustomField] = []
                                for field in customFields {
                                    let customField = CustomField(
                                        name: field.name,
                                        fieldType: field.type,
                                        required: field.required,
                                        options: field.options
                                    )
                                    fields.append(customField)
                                }
                                newCategory.customFields = fields
                            }
                            
                            onSave(newCategory)
                            dismiss()
                        } else {
                            showingErrors = true
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAddField) {
                CustomFieldFormView { field in
                    customFields.append(field)
                }
            }
            .onAppear {
                if let category = category, mode == .edit {
                    name = category.name
                    description = category.categoryDescription ?? ""
                    
                    // Load custom fields if any
                    if let fields = category.customFields {
                        customFields = fields.map { field in
                            CustomFieldEntry(
                                name: field.name,
                                type: field.type,
                                required: field.required,
                                options: field.options
                            )
                        }
                    }
                }
            }
        }
    }
    
    private func deleteField(at offsets: IndexSet) {
        customFields.remove(atOffsets: offsets)
    }
}

struct CustomFieldFormView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var fieldType: FieldType = .text
    @State private var required = false
    @State private var options = ""
    @State private var showingErrors = false
    
    var onSave: (CategoryFormView.CustomFieldEntry) -> Void
    
    private var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        (fieldType != .dropdown || !options.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Field Information")) {
                    TextField("Name *", text: $name)
                    
                    Picker("Type", selection: $fieldType) {
                        Text("Text").tag(FieldType.text)
                        Text("Number").tag(FieldType.number)
                        Text("Date").tag(FieldType.date)
                        Text("Yes/No").tag(FieldType.boolean)
                        Text("Dropdown").tag(FieldType.dropdown)
                    }
                    
                    Toggle("Required", isOn: $required)
                }
                
                if fieldType == .dropdown {
                    Section(header: Text("Dropdown Options *"), footer: Text("Enter options separated by commas")) {
                        TextEditor(text: $options)
                            .frame(minHeight: 60)
                    }
                }
                
                if showingErrors && !isFormValid {
                    Section {
                        Text("Please fill in all required fields")
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Add Custom Field")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        if isFormValid {
                            let optionsArray: [String]? = fieldType == .dropdown ? 
                                options.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) } : 
                                nil
                            
                            let field = CategoryFormView.CustomFieldEntry(
                                name: name,
                                type: fieldType,
                                required: required,
                                options: optionsArray
                            )
                            
                            onSave(field)
                            dismiss()
                        } else {
                            showingErrors = true
                        }
                    }
                }
            }
        }
    }
}