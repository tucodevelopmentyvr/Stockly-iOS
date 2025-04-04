import SwiftUI
import SwiftData
import PhotosUI
import PDFKit

struct InitialSetupView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var setupManager: AppSetupManager

    @State private var currentStep = 0
    @State private var showingBackupPicker = false
    @State private var showingImagePicker = false
    @State private var selectedImage: PhotosPickerItem?
    @State private var companyLogo: UIImage?
    @State private var isRestoringBackup = false
    @State private var backupPassword = ""
    @State private var showingPasswordPrompt = false
    @State private var selectedBackupURL: URL?
    @State private var alertMessage = ""
    @State private var showingAlert = false

    // Company Information
    @AppStorage("companyName") private var companyName = ""
    @AppStorage("companyAddress") private var companyAddress = ""
    @AppStorage("companyEmail") private var companyEmail = ""
    @AppStorage("companyPhone") private var companyPhone = ""
    @AppStorage("companyWebsite") private var companyWebsite = ""

    // Tax and Invoice Settings
    @AppStorage("currencySymbol") private var currencySymbol = "$"
    @AppStorage("measurementUnit") private var measurementUnit = "pcs"
    @AppStorage("invoiceDisclaimer") private var invoiceDisclaimer = "Thank you for your business."
    @AppStorage("defaultTaxRate") private var defaultTaxRate = "0.0"
    @AppStorage("defaultDiscountValue") private var defaultDiscountValue = "0.0"
    @AppStorage("defaultDiscountType") private var defaultDiscountType = "percentage"
    @AppStorage("defaultDocumentTheme") private var defaultDocumentTheme = DocumentTheme.classic.rawValue
    @AppStorage("nextInvoiceNumber") private var nextInvoiceNumber = 1001
    @AppStorage("nextEstimateNumber") private var nextEstimateNumber = 5001
    @AppStorage("country") private var country = "United States"
    @AppStorage("dateFormat") private var dateFormat = DateFormat.mmddyyyy.rawValue

    // Steps in the setup process
    let steps = ["Welcome", "Company Info", "Logo", "Invoice Settings", "Complete"]

    var body: some View {
        NavigationStack {
            VStack {
                // Progress indicator
                StepProgressView(currentStep: currentStep, steps: steps)
                    .padding(.top)

                // Content for current step
                ScrollView {
                    VStack(spacing: 20) {
                        switch currentStep {
                        case 0:
                            welcomeStep
                        case 1:
                            companyInfoStep
                        case 2:
                            logoStep
                        case 3:
                            invoiceSettingsStep
                        case 4:
                            completeStep
                        default:
                            Text("Unknown step")
                        }
                    }
                    .padding()
                }
                .scrollDismissesKeyboard(.interactively)

                // Navigation buttons
                HStack {
                    if currentStep > 0 {
                        Button("Back") {
                            withAnimation {
                                currentStep -= 1
                            }
                        }
                        .buttonStyle(.bordered)
                    }

                    Spacer()

                    if currentStep < steps.count - 1 {
                        Button(currentStep == 0 ? "Get Started" : "Next") {
                            withAnimation {
                                currentStep += 1
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    } else {
                        Button("Finish Setup") {
                            completeSetup()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                .padding()
            }
            .navigationTitle("Setup Your Business")
            .navigationBarTitleDisplayMode(.inline)
            .interactiveDismissDisabled() // Prevent dismissal during setup
            .fileImporter(
                isPresented: $showingBackupPicker,
                allowedContentTypes: [.data],
                allowsMultipleSelection: false
            ) { result in
                handleBackupSelection(result)
            }
            .photosPicker(
                isPresented: $showingImagePicker,
                selection: $selectedImage,
                matching: .images
            )
            .onChange(of: selectedImage) { oldValue, newValue in
                if let newValue {
                    loadImage(from: newValue)
                }
            }
            .alert(alertMessage, isPresented: $showingAlert) {
                Button("OK", role: .cancel) { }
            }
            .sheet(isPresented: $showingPasswordPrompt) {
                backupPasswordPrompt
            }
        }
    }

    // MARK: - Step Views

    // Step 1: Welcome
    private var welcomeStep: some View {
        VStack(spacing: 20) {
            Image(systemName: "building.2.fill")
                .font(.system(size: 60))
                .foregroundColor(.accentColor)
                .padding()

            Text("Welcome to Stockly")
                .font(.title)
                .fontWeight(.bold)

            Text("Let's set up your business information to get started. This will only take a few minutes.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)

            Divider()
                .padding(.vertical)

            Text("Already have a backup?")
                .font(.headline)

            Button(action: {
                showingBackupPicker = true
            }) {
                HStack {
                    Image(systemName: "arrow.down.doc.fill")
                    Text("Restore from Backup")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accentColor.opacity(0.1))
                .cornerRadius(10)
            }
            .buttonStyle(.plain)
        }
    }

    // Step 2: Company Information
    private var companyInfoStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Business Information")
                .font(.title2)
                .fontWeight(.bold)

            Text("This information will appear on your invoices and estimates.")
                .foregroundColor(.secondary)

            Group {
                TextField("Business Name", text: $companyName)
                    .textFieldStyle(.roundedBorder)

                TextField("Email", text: $companyEmail)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()

                TextField("Phone", text: $companyPhone)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.phonePad)

                TextField("Website (Optional)", text: $companyWebsite)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.URL)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
            }

            Text("Business Address")
                .font(.headline)
                .padding(.top, 5)

            TextEditor(text: $companyAddress)
                .frame(height: 100)
                .padding(4)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                )
        }
    }

    // Step 3: Logo
    private var logoStep: some View {
        VStack(spacing: 20) {
            Text("Business Logo")
                .font(.title2)
                .fontWeight(.bold)

            Text("Add your business logo to appear on invoices and estimates.")
                .foregroundColor(.secondary)

            if let logo = companyLogo {
                Image(uiImage: logo)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 150)
                    .cornerRadius(8)
                    .padding()
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                    )
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.secondary.opacity(0.1))
                        .frame(height: 150)

                    VStack {
                        Image(systemName: "photo")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)

                        Text("No logo selected")
                            .foregroundColor(.secondary)
                            .padding(.top, 8)
                    }
                }
                .padding()
            }

            Text("For best results, use a square image at least 300×300 pixels.")
                .font(.caption)
                .foregroundColor(.secondary)

            HStack(spacing: 20) {
                Button(action: {
                    showingImagePicker = true
                }) {
                    HStack {
                        Image(systemName: "photo.fill")
                        Text(companyLogo == nil ? "Select Logo" : "Change Logo")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .buttonStyle(.plain)

                if companyLogo != nil {
                    Button(action: {
                        companyLogo = nil
                        saveLogoToUserDefaults(nil)
                    }) {
                        HStack {
                            Image(systemName: "trash.fill")
                            Text("Remove")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .buttonStyle(.plain)
                }
            }

            Text("You can skip this step and add a logo later.")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top)
        }
    }

    // Step 4: Invoice Settings
    private var invoiceSettingsStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Invoice & Estimate Settings")
                .font(.title2)
                .fontWeight(.bold)

            Text("Configure default settings for your documents.")
                .foregroundColor(.secondary)

            Group {
                HStack {
                    Text("Currency Symbol:")
                    Spacer()
                    TextField("$", text: $currencySymbol)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 80)
                        .multilineTextAlignment(.trailing)
                }

                HStack {
                    Text("Default Tax Rate (%):")
                    Spacer()
                    TextField("0.0", text: $defaultTaxRate)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 80)
                        .multilineTextAlignment(.trailing)
                        .keyboardType(.decimalPad)
                }

                HStack {
                    Text("Default Measurement Unit:")
                    Spacer()
                    TextField("pcs", text: $measurementUnit)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 80)
                        .multilineTextAlignment(.trailing)
                }

                HStack {
                    Text("Next Invoice #:")
                    Spacer()
                    TextField("1001", value: $nextInvoiceNumber, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 80)
                        .multilineTextAlignment(.trailing)
                        .keyboardType(.numberPad)
                }

                HStack {
                    Text("Next Estimate #:")
                    Spacer()
                    TextField("5001", value: $nextEstimateNumber, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 80)
                        .multilineTextAlignment(.trailing)
                        .keyboardType(.numberPad)
                }
            }

            Text("Invoice/Estimate Disclaimer:")
                .font(.headline)
                .padding(.top, 5)

            TextEditor(text: $invoiceDisclaimer)
                .frame(height: 100)
                .padding(4)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                )

            Text("Document Theme:")
                .font(.headline)
                .padding(.top, 5)

            Picker("Theme", selection: $defaultDocumentTheme) {
                Text("Classic").tag(DocumentTheme.classic.rawValue)
                Text("Modern").tag(DocumentTheme.modern.rawValue)
                Text("Professional").tag(DocumentTheme.professional.rawValue)
                Text("Minimalist").tag(DocumentTheme.minimalist.rawValue)
            }
            .pickerStyle(.segmented)
        }
    }

    // Step 5: Complete
    private var completeStep: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)
                .padding()

            Text("Setup Complete!")
                .font(.title)
                .fontWeight(.bold)

            Text("Your business is now set up and ready to go. You can change any of these settings later in the Settings menu.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "building.2.fill")
                        .frame(width: 30)
                    Text("Business: \(companyName)")
                }

                HStack {
                    Image(systemName: "dollarsign.circle.fill")
                        .frame(width: 30)
                    Text("Currency: \(currencySymbol)")
                }

                HStack {
                    Image(systemName: "percent")
                        .frame(width: 30)
                    Text("Tax Rate: \(defaultTaxRate)%")
                }

                if companyLogo != nil {
                    HStack {
                        Image(systemName: "photo.fill")
                            .frame(width: 30)
                        Text("Logo: Added")
                    }
                }
            }
            .padding()
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(12)
        }
    }

    // Backup password prompt
    private var backupPasswordPrompt: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("This backup is password protected")
                    .font(.headline)

                SecureField("Enter backup password", text: $backupPassword)
                    .textFieldStyle(.roundedBorder)
                    .padding()
            }
            .padding()
            .navigationTitle("Password Required")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showingPasswordPrompt = false
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Restore") {
                        showingPasswordPrompt = false
                        if let url = selectedBackupURL {
                            restoreFromBackup(url: url, password: backupPassword)
                        }
                    }
                    .disabled(backupPassword.isEmpty)
                }
            }
        }
    }

    // MARK: - Helper Methods

    private func completeSetup() {
        // Save any final settings
        saveLogoToUserDefaults(companyLogo)

        // Mark setup as completed
        setupManager.markSetupAsCompleted()
    }

    private func handleBackupSelection(_ result: Result<[URL], Error>) {
        do {
            guard let selectedFile = try result.get().first else {
                return
            }

            // Check if the backup is encrypted
            selectedBackupURL = selectedFile

            let backupService = BackupService(modelContext: modelContext)

            Task { @MainActor in
                do {
                    let isEncrypted = try backupService.isBackupEncrypted(at: selectedFile)

                    if isEncrypted {
                        // Show password prompt
                        backupPassword = ""
                        showingPasswordPrompt = true
                    } else {
                        // Restore without password
                        restoreFromBackup(url: selectedFile, password: nil)
                    }
                } catch {
                    alertMessage = "Failed to check backup file: \(error.localizedDescription)"
                    showingAlert = true
                }
            }
        } catch {
            alertMessage = "Failed to import backup: \(error.localizedDescription)"
            showingAlert = true
        }
    }

    private func restoreFromBackup(url: URL, password: String?) {
        isRestoringBackup = true

        let backupService = BackupService(modelContext: modelContext)

        Task { @MainActor in
            do {
                try await backupService.importAllData(from: url, password: password)

                // Mark setup as completed since we've restored from backup
                setupManager.markSetupAsCompleted()

                // Show success message
                alertMessage = "Backup restored successfully. The app will now restart."
                showingAlert = true

                // Restart app after a delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    exit(0)
                }
            } catch {
                isRestoringBackup = false
                alertMessage = "Failed to restore backup: \(error.localizedDescription)"
                showingAlert = true
            }
        }
    }

    private func loadImage(from item: PhotosPickerItem) {
        item.loadTransferable(type: Data.self) { result in
            switch result {
            case .success(let data):
                if let data = data, let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self.companyLogo = image
                        self.saveLogoToUserDefaults(image)
                    }
                }
            case .failure(let error):
                print("Error loading image: \(error)")
            }
        }
    }

    private func saveLogoToUserDefaults(_ image: UIImage?) {
        if let image = image, let imageData = image.jpegData(compressionQuality: 0.8) {
            UserDefaults.standard.set(imageData, forKey: "companyLogo")
        } else {
            UserDefaults.standard.removeObject(forKey: "companyLogo")
        }
    }
}

// MARK: - Supporting Views

struct StepProgressView: View {
    var currentStep: Int
    var steps: [String]

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                ForEach(0..<steps.count, id: \.self) { index in
                    Circle()
                        .fill(index <= currentStep ? Color.accentColor : Color.gray.opacity(0.3))
                        .frame(width: 12, height: 12)

                    if index < steps.count - 1 {
                        Rectangle()
                            .fill(index < currentStep ? Color.accentColor : Color.gray.opacity(0.3))
                            .frame(height: 2)
                    }
                }
            }
            .padding(.horizontal)

            Text(steps[currentStep])
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    InitialSetupView()
        .environmentObject(AppSetupManager.shared)
}
