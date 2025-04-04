import SwiftUI
import UniformTypeIdentifiers
import SwiftData

struct CSVImportView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = CSVImportViewModel()
    
    var body: some View {
        NavigationStack {
            VStack {
                // Import status area
                Group {
                    if viewModel.isImporting {
                        ProgressView("Processing your CSV file...")
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else if !viewModel.importSummary.isEmpty {
                        importSummaryView
                    } else {
                        instructionsView
                    }
                }
                .frame(maxHeight: .infinity)
                
                // File picker button
                if !viewModel.isImporting {
                    Button(action: {
                        viewModel.showFilePicker = true
                    }) {
                        HStack {
                            Image(systemName: "doc.badge.plus")
                            Text("Select CSV File")
                        }
                        .frame(minWidth: 200)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .padding(.bottom)
                    
                    // Sample file button
                    Button(action: {
                        viewModel.generateSampleCSV(modelContext: modelContext)
                    }) {
                        HStack {
                            Image(systemName: "doc.text")
                            Text("Get Sample CSV")
                        }
                        .frame(minWidth: 200)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .padding(.bottom, 24)
                }
            }
            .padding()
            .navigationTitle("Import Inventory from CSV")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .fileImporter(
                isPresented: $viewModel.showFilePicker,
                allowedContentTypes: [UTType.commaSeparatedText],
                allowsMultipleSelection: false
            ) { result in
                viewModel.handleSelectedFile(result, modelContext: modelContext)
            }
            .alert("Import Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage)
            }
        }
    }
    
    private var instructionsView: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("CSV Import Instructions")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 12) {
                Text("1. Prepare your CSV file with these columns:")
                    .fontWeight(.medium)
                
                Text("Required: Name, Description, Category, SKU, Price, Buy_Price, Stock_Quantity, Min_Stock_Level, Measurement_Unit")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("Optional: Tax_Rate, Barcode")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("2. Click 'Select CSV File' to upload your file")
                    .fontWeight(.medium)
                
                Text("3. Need a template? Click 'Get Sample CSV'")
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
        }
        .padding()
    }
    
    private var importSummaryView: some View {
        VStack(spacing: 16) {
            if viewModel.importSuccess {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.green)
                
                Text("Import Completed")
                    .font(.headline)
            } else {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.orange)
                
                Text("Import Completed with Issues")
                    .font(.headline)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Items successfully imported: \(viewModel.importedCount)")
                    .fontWeight(.medium)
                
                if !viewModel.errors.isEmpty {
                    Text("Errors (\(viewModel.errors.count)):")
                        .fontWeight(.medium)
                    
                    ScrollView {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(viewModel.errors, id: \.self) { error in
                                Text("• \(error)")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    .frame(maxHeight: 200)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
            
            Button("Done") {
                dismiss()
            }
            .padding(.horizontal, 40)
            .padding(.vertical, 12)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
        .padding()
    }
}

class CSVImportViewModel: ObservableObject {
    @Published var showFilePicker = false
    @Published var isImporting = false
    @Published var importSummary = ""
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var importedCount = 0
    @Published var errors: [String] = []
    @Published var importSuccess = false
    
    func handleSelectedFile(_ result: Result<[URL], Error>, modelContext: ModelContext) {
        // Reset state
        isImporting = true
        importSummary = ""
        errors = []
        
        // Process selected file
        switch result {
        case .success(let urls):
            guard let selectedFile = urls.first else {
                showError(message: "No file was selected.")
                return
            }
            
            // Import CSV file
            Task {
                do {
                    let inventoryService = InventoryService(modelContext: modelContext)
                    let result = try await inventoryService.importItemsFromCSV(fileURL: selectedFile)
                    
                    await MainActor.run {
                        self.importedCount = result.imported
                        self.errors = result.errors
                        self.importSuccess = result.errors.isEmpty
                        self.isImporting = false
                        
                        if result.imported > 0 {
                            self.importSummary = "Import completed: \(result.imported) items imported"
                            if !result.errors.isEmpty {
                                self.importSummary += " with \(result.errors.count) errors"
                            }
                        } else {
                            self.importSummary = "No items were imported. Please check your CSV file."
                        }
                    }
                } catch let error as CSVImportError {
                    await MainActor.run {
                        switch error {
                        case .invalidFile:
                            showError(message: "The selected file is not a valid CSV file.")
                        case .missingRequiredColumns:
                            showError(message: "The CSV file is missing required columns. Please check the format.")
                        case .invalidData(let row, let details):
                            showError(message: "Error in row \(row): \(details)")
                        case .fileReadError:
                            showError(message: "Failed to read the CSV file. Please check the file permissions.")
                        }
                    }
                } catch {
                    await MainActor.run {
                        showError(message: "An unexpected error occurred: \(error.localizedDescription)")
                    }
                }
            }
            
        case .failure(let error):
            showError(message: "Failed to access the file: \(error.localizedDescription)")
        }
    }
    
    func generateSampleCSV(modelContext: ModelContext) {
        let inventoryService = InventoryService(modelContext: modelContext)
        
        if let sampleURL = inventoryService.generateSampleCSV() {
            // Share the sample file
            let activityVC = UIActivityViewController(activityItems: [sampleURL], applicationActivities: nil)
            
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootViewController = windowScene.windows.first?.rootViewController {
                rootViewController.present(activityVC, animated: true, completion: nil)
            }
        } else {
            showError(message: "Failed to generate sample CSV file.")
        }
    }
    
    private func showError(message: String) {
        isImporting = false
        errorMessage = message
        showError = true
    }
}

#Preview {
    CSVImportView()
}