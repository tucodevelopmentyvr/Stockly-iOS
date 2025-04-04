import SwiftUI
import PhotosUI

enum DateFormat: String, CaseIterable, Identifiable {
    case mmddyyyy = "MM-DD-YYYY"
    case ddmmyyyy = "DD-MM-YYYY"
    
    var id: String { self.rawValue }
}

enum NumberFormat: String, CaseIterable, Identifiable {
    case standard = "1,234.56"
    case european = "1.234,56"
    
    var id: String { self.rawValue }
}

enum OverdueReminderFrequency: String, CaseIterable, Identifiable {
    case daily = "Daily"
    case weekly = "Weekly"
    case monthly = "Monthly"
    case none = "None"
    
    var id: String { self.rawValue }
}

struct SettingsView: View {
    // Company Profile
    @AppStorage("companyName") private var companyName = ""
    @AppStorage("companyAddress") private var companyAddress = ""
    @AppStorage("companyEmail") private var companyEmail = ""
    @AppStorage("companyPhone") private var companyPhone = ""
    
    // Units & Formatting
    @AppStorage("currencySymbol") private var currencySymbol = "$"
    @AppStorage("measurementUnit") private var measurementUnit = "pcs"
    @AppStorage("invoiceDisclaimer") private var invoiceDisclaimer = "Thank you for your business."
    @AppStorage("defaultTaxRate") private var defaultTaxRate = "0.0"
    @AppStorage("defaultDiscountValue") private var defaultDiscountValue = "0.0"
    @AppStorage("defaultDiscountType") private var defaultDiscountType = "percentage" // percentage or fixed
    @AppStorage("defaultDocumentTheme") private var defaultDocumentTheme = DocumentTheme.classic.rawValue
    
    // Basic Settings
    @AppStorage("pinProtectionEnabled") private var pinProtectionEnabled = false
    @AppStorage("pinCode") private var pinCode = ""
    @AppStorage("nextInvoiceNumber") private var nextInvoiceNumber = 1001
    @AppStorage("nextEstimateNumber") private var nextEstimateNumber = 5001
    @AppStorage("country") private var country = "United States"
    @AppStorage("dateFormat") private var dateFormat = DateFormat.mmddyyyy.rawValue
    @AppStorage("numberFormat") private var numberFormat = NumberFormat.standard.rawValue
    @AppStorage("savePageReminder") private var savePageReminder = true
    @AppStorage("overdueReminderFrequency") private var overdueReminderFrequency = OverdueReminderFrequency.weekly.rawValue
    @AppStorage("overdueReminderTime") private var overdueReminderTime = Calendar.current.date(from: DateComponents(hour: 9, minute: 0)) ?? Date()
    
    // Payment & Banking
    @AppStorage("paymentModeEnabled") private var paymentModeEnabled = false
    @AppStorage("bankingDetailsEnabled") private var bankingDetailsEnabled = false
    @AppStorage("bankName") private var bankName = ""
    @AppStorage("accountNumber") private var accountNumber = ""
    @AppStorage("routingNumber") private var routingNumber = ""
    @AppStorage("swiftCode") private var swiftCode = ""
    
    // Appearance
    @AppStorage("darkModeEnabled") private var darkModeEnabled = false
    
    // State variables
    @State private var companyLogo: UIImage?
    @State private var showingImagePicker = false
    @State private var showingPINSetup = false
    @State private var showingNumberManagement = false
    @State private var showingCountryPicker = false
    @State private var showingBankingDetails = false
    @State private var showingExportOptions = false
    @State private var isExporting = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var temporaryPIN = ""
    @State private var confirmPIN = ""
    @State private var isGeneratingSampleData = false
    @State private var showingHelpView = false
    @State private var showingInvoiceLayoutCustomizer = false
    @State private var showingEstimateLayoutCustomizer = false
    
    // Environment
    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var navigationRouter: NavigationRouter
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.modelContext) private var modelContext
    @Environment(\.presentationMode) private var presentationMode
    
    var body: some View {
        NavigationStack {
            Form {
                // Basic Settings
                Section {
                    Toggle("PIN Protection", isOn: $pinProtectionEnabled)
                        .onChange(of: pinProtectionEnabled) { _, newValue in
                            if newValue && pinCode.isEmpty {
                                showingPINSetup = true
                            }
                        }
                    
                    Button(action: {
                        showingNumberManagement = true
                    }) {
                        HStack {
                            Text("Manage Document Numbers")
                            Spacer()
                            Text("Invoice: \(nextInvoiceNumber)")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                    
                    HStack {
                        Text("Country")
                        Spacer()
                        Text(country)
                            .foregroundColor(.secondary)
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        showingCountryPicker = true
                    }
                    
                    Picker("Number Format", selection: $numberFormat) {
                        ForEach(NumberFormat.allCases) { format in
                            Text(format.rawValue).tag(format.rawValue)
                        }
                    }
                    
                    Picker("Date Format", selection: $dateFormat) {
                        ForEach(DateFormat.allCases) { format in
                            Text(format.rawValue).tag(format.rawValue)
                        }
                    }
                    
                    Toggle("Save Page Reminder", isOn: $savePageReminder)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Picker("Overdue Reminder", selection: $overdueReminderFrequency) {
                            ForEach(OverdueReminderFrequency.allCases) { frequency in
                                Text(frequency.rawValue).tag(frequency.rawValue)
                            }
                        }
                        
                        if overdueReminderFrequency != OverdueReminderFrequency.none.rawValue {
                            DatePicker("Reminder Time", selection: $overdueReminderTime, displayedComponents: [.hourAndMinute])
                                .padding(.top, 8)
                        }
                    }
                }
                
                // Company Profile Section
                Section(header: Text("Company Profile")) {
                    HStack {
                        Spacer()
                        ZStack {
                            if let logo = companyLogo {
                                Image(uiImage: logo)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 100)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            } else {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.secondary.opacity(0.2))
                                    .frame(height: 100)
                                    .overlay(
                                        Image(systemName: "building.2")
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
                                        Image(systemName: "pencil.circle.fill")
                                            .font(.title)
                                            .foregroundColor(.accentColor)
                                            .background(Circle().fill(Color.white))
                                    }
                                    .offset(x: 5, y: 5)
                                }
                            }
                            .frame(height: 100)
                        }
                        .frame(maxWidth: 200)
                        Spacer()
                    }
                    .padding(.vertical, 10)
                    .listRowInsets(EdgeInsets())
                    
                    TextField("Company Name", text: $companyName)
                    
                    ZStack(alignment: .topLeading) {
                        if companyAddress.isEmpty {
                            Text("Company Address")
                                .foregroundColor(.secondary)
                                .padding(.top, 8)
                        }
                        
                        TextEditor(text: $companyAddress)
                            .frame(minHeight: 60)
                    }
                    
                    TextField("Email", text: $companyEmail)
                        .keyboardType(.emailAddress)
                    
                    TextField("Phone", text: $companyPhone)
                        .keyboardType(.phonePad)
                }
                
                // Payment & Banking
                Section(header: Text("Payment & Banking")) {
                    Toggle("Enable Payment Mode on Invoice", isOn: $paymentModeEnabled)
                        .onChange(of: paymentModeEnabled) { _, _ in
                            showAlert("Payment mode options will appear on invoices")
                        }
                    
                    Toggle("Show Banking Details on Invoice", isOn: $bankingDetailsEnabled)
                    
                    if bankingDetailsEnabled {
                        Button(action: {
                            showingBankingDetails = true
                        }) {
                            HStack {
                                Text("Manage Banking Details")
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                // Units & Formatting
                Section(header: Text("Units & Formatting")) {
                    Picker("Currency", selection: $currencySymbol) {
                        Text("$ (USD)").tag("$")
                        Text("€ (EUR)").tag("€")
                        Text("£ (GBP)").tag("£")
                        Text("¥ (JPY)").tag("¥")
                        Text("₹ (INR)").tag("₹")
                    }
                    
                    Picker("Measurement Unit", selection: $measurementUnit) {
                        Text("Pieces (pcs)").tag("pcs")
                        Text("Kilograms (kg)").tag("kg")
                        Text("Pounds (lb)").tag("lb")
                        Text("Units (units)").tag("units")
                        Text("Count (count)").tag("count")
                    }
                    
                    Picker("Default Document Theme", selection: $defaultDocumentTheme) {
                        ForEach(DocumentTheme.allCases, id: \.self) { theme in
                            Text(theme.rawValue.capitalized).tag(theme.rawValue)
                        }
                    }
                    
                    ZStack(alignment: .topLeading) {
                        if invoiceDisclaimer.isEmpty {
                            Text("Invoice/Document Disclaimer")
                                .foregroundColor(.secondary)
                                .padding(.top, 8)
                        }
                        
                        TextEditor(text: $invoiceDisclaimer)
                            .frame(minHeight: 60)
                    }
                }
                
                // Document Layout Customization
                Section(header: Text("Document Layout Customization")) {
                    Button(action: {
                        showingInvoiceLayoutCustomizer = true
                    }) {
                        HStack {
                            Image(systemName: "doc.text.fill")
                                .foregroundColor(.purple)
                            Text("Customize Invoice Layout")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                    
                    Button(action: {
                        showingEstimateLayoutCustomizer = true
                    }) {
                        HStack {
                            Image(systemName: "doc.plaintext.fill")
                                .foregroundColor(.indigo)
                            Text("Customize Estimate Layout")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                    
                    Text("Customize where information appears on your invoices and estimates.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Default Tax & Discount Settings
                Section(header: Text("Default Tax & Discount")) {
                    HStack {
                        Text("Default Tax Rate (%)")
                        Spacer()
                        TextField("0.0", text: $defaultTaxRate)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }
                    
                    Picker("Default Discount Type", selection: $defaultDiscountType) {
                        Text("Percentage (%)").tag("percentage")
                        Text("Fixed Amount ($)").tag("fixed")
                    }
                    
                    HStack {
                        Text(defaultDiscountType == "percentage" ? "Default Discount (%)" : "Default Discount ($)")
                        Spacer()
                        TextField("0.0", text: $defaultDiscountValue)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }
                    
                    Text("These values will be used as defaults when creating new invoices and estimates.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Appearance
                Section(header: Text("Appearance")) {
                    Toggle("Dark Mode", isOn: $darkModeEnabled)
                        .onChange(of: darkModeEnabled) { _, _ in
                            showAlert("App appearance will change when you restart the app")
                        }
                }
                
                // Data Management
                Section(header: Text("Data Management")) {
                    Button(action: {
                        showingExportOptions = true
                    }) {
                        Label("Export Data", systemImage: "square.and.arrow.up")
                    }
                    
                    Button(action: syncData) {
                        if isExporting {
                            HStack {
                                Text("Syncing...")
                                Spacer()
                                ProgressView()
                            }
                        } else {
                            Label("Sync with Cloud", systemImage: "arrow.triangle.2.circlepath.circle")
                        }
                    }
                    .disabled(isExporting)
                }
                
                // Demo Data
                Section(header: Text("Demo Data")) {
                    Button(action: {
                        createSampleData()
                    }) {
                        if isGeneratingSampleData {
                            HStack {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                                Text("Generating sample data...")
                            }
                        } else {
                            Text("Generate Montecristo Jewellers Demo Data")
                        }
                    }
                    .disabled(isGeneratingSampleData)
                    
                    Text("This will create sample inventory, clients, suppliers, invoices, and estimates for a fictional jewelry store.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // App Information
                Section(header: Text("App Information")) {
                    Button {
                        showingHelpView = true
                    } label: {
                        HStack {
                            Text("Help & User Guide")
                            Spacer()
                            Image(systemName: "questionmark.circle")
                        }
                    }
                    
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Premium Access")
                        Spacer()
                        Text("Enabled (Development)")
                            .foregroundColor(.green)
                    }
                }
                
                // Account Management
                Section {
                    Button(role: .destructive, action: logout) {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                // Only show home button if not shown from tab view
                ToolbarItem(placement: .principal) {
                    // Check if we're in a tab view by looking at presentation mode
                    if !UIDevice.isRunningInTabView {
                        Button(action: {
                            // Simple approach - just dismiss this view
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Image(systemName: "house.fill")
                                .imageScale(.large)
                                .foregroundColor(.accentColor)
                        }
                    } else {
                        // Empty spacer when shown in tab view
                        EmptyView()
                    }
                }
            }
            .sheet(isPresented: $showingImagePicker) {
                PHPickerView(image: $companyLogo)
            }
            .sheet(isPresented: $showingPINSetup) {
                PINSetupView(pinCode: $pinCode, pinEnabled: $pinProtectionEnabled)
            }
            .sheet(isPresented: $showingNumberManagement) {
                NumberManagementView(
                    nextInvoiceNumber: $nextInvoiceNumber,
                    nextEstimateNumber: $nextEstimateNumber
                )
            }
            .sheet(isPresented: $showingCountryPicker) {
                CountryPickerView(selectedCountry: $country)
            }
            .sheet(isPresented: $showingBankingDetails) {
                BankingDetailsView(
                    bankName: $bankName,
                    accountNumber: $accountNumber,
                    routingNumber: $routingNumber,
                    swiftCode: $swiftCode
                )
            }
            .actionSheet(isPresented: $showingExportOptions) {
                ActionSheet(
                    title: Text("Export Data"),
                    message: Text("Choose what to export"),
                    buttons: [
                        .default(Text("Inventory")) { exportData(type: "inventory", format: "csv") },
                        .default(Text("Invoices")) { exportData(type: "invoices", format: "csv") },
                        .default(Text("Estimates")) { exportData(type: "estimates", format: "csv") },
                        .default(Text("All Data")) { exportData(type: "all", format: "csv") },
                        .cancel()
                    ]
                )
            }
            .alert(isPresented: $showingAlert) {
                Alert(
                    title: Text("Notification"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
            .sheet(isPresented: $showingHelpView) {
                HelpView()
            }
            .sheet(isPresented: $showingInvoiceLayoutCustomizer) {
                PDFDocumentCustomizerView(for: .invoice)
            }
            .sheet(isPresented: $showingEstimateLayoutCustomizer) {
                PDFDocumentCustomizerView(for: .estimate)
            }
        }
        .onAppear {
            loadCompanyLogo()
        }
        .onAppear {
            saveCompanyLogo()
        }
        .preferredColorScheme(darkModeEnabled ? .dark : .light)
    }
    
    private func loadCompanyLogo() {
        if let logoData = UserDefaults.standard.data(forKey: "companyLogo"),
           let logo = UIImage(data: logoData) {
            companyLogo = logo
        }
    }
    
    private func saveCompanyLogo() {
        if let logo = companyLogo, let logoData = logo.jpegData(compressionQuality: 0.8) {
            UserDefaults.standard.set(logoData, forKey: "companyLogo")
        }
    }
    
    private func exportData(type: String, format: String) {
        isExporting = true
        
        // Simulate export process
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isExporting = false
            showAlert("\(type.capitalized) exported successfully as \(format.uppercased()) file")
        }
    }
    
    private func syncData() {
        isExporting = true
        
        // Simulate sync process
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isExporting = false
            showAlert("Data synced successfully")
        }
    }
    
    private func logout() {
        authViewModel.logout()
    }
    
    private func showAlert(_ message: String) {
        alertMessage = message
        showingAlert = true
    }
    
    private func createSampleData() {
        isGeneratingSampleData = true
        
        Task {
            let success = await SampleDataService.createMontecristoJewellersSampleData(modelContext: modelContext)
            
            DispatchQueue.main.async {
                isGeneratingSampleData = false
                if success {
                    showAlert("Montecristo Jewellers sample data has been created successfully.")
                } else {
                    showAlert("Failed to create sample data. Please try again.")
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct PINSetupView: View {
    @Binding var pinCode: String
    @Binding var pinEnabled: Bool
    @Environment(\.dismiss) private var dismiss
    
    @State private var tempPIN = ""
    @State private var confirmPIN = ""
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Create PIN")) {
                    SecureField("Enter PIN (4-6 digits)", text: $tempPIN)
                        .keyboardType(.numberPad)
                    
                    SecureField("Confirm PIN", text: $confirmPIN)
                        .keyboardType(.numberPad)
                }
                
                if showError {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                }
                
                Section {
                    Button("Save PIN") {
                        savePin()
                    }
                    .disabled(tempPIN.isEmpty || confirmPIN.isEmpty)
                }
                
                Section {
                    Button("Cancel", role: .destructive) {
                        pinEnabled = false
                        dismiss()
                    }
                }
            }
            .navigationTitle("Set PIN Protection")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func savePin() {
        // Validate PIN
        if tempPIN.count < 4 || tempPIN.count > 6 {
            showError = true
            errorMessage = "PIN must be 4-6 digits"
            return
        }
        
        if !tempPIN.allSatisfy({ $0.isNumber }) {
            showError = true
            errorMessage = "PIN must contain only numbers"
            return
        }
        
        if tempPIN != confirmPIN {
            showError = true
            errorMessage = "PINs do not match"
            return
        }
        
        // Save PIN
        pinCode = tempPIN
        dismiss()
    }
}

struct NumberManagementView: View {
    @Binding var nextInvoiceNumber: Int
    @Binding var nextEstimateNumber: Int
    @Environment(\.dismiss) private var dismiss
    
    @State private var newInvoiceNumber: String = ""
    @State private var newEstimateNumber: String = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Invoice Numbering")) {
                    HStack {
                        Text("Current Invoice #")
                        Spacer()
                        Text("\(nextInvoiceNumber)")
                            .foregroundColor(.secondary)
                    }
                    
                    TextField("New Invoice Number", text: $newInvoiceNumber)
                        .keyboardType(.numberPad)
                }
                
                Section(header: Text("Estimate Numbering")) {
                    HStack {
                        Text("Current Estimate #")
                        Spacer()
                        Text("\(nextEstimateNumber)")
                            .foregroundColor(.secondary)
                    }
                    
                    TextField("New Estimate Number", text: $newEstimateNumber)
                        .keyboardType(.numberPad)
                }
                
                Section {
                    Button("Save Changes") {
                        saveChanges()
                    }
                    .disabled(newInvoiceNumber.isEmpty && newEstimateNumber.isEmpty)
                }
            }
            .navigationTitle("Document Numbers")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                newInvoiceNumber = "\(nextInvoiceNumber)"
                newEstimateNumber = "\(nextEstimateNumber)"
            }
        }
    }
    
    private func saveChanges() {
        if let invoiceNum = Int(newInvoiceNumber), invoiceNum > 0 {
            nextInvoiceNumber = invoiceNum
        }
        
        if let estimateNum = Int(newEstimateNumber), estimateNum > 0 {
            nextEstimateNumber = estimateNum
        }
        
        dismiss()
    }
}

struct CountryPickerView: View {
    @Binding var selectedCountry: String
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    
    // Comprehensive list of countries
    let countries = [
        "Afghanistan", "Albania", "Algeria", "Andorra", "Angola", "Antigua and Barbuda", 
        "Argentina", "Armenia", "Australia", "Austria", "Azerbaijan", "Bahamas", "Bahrain", 
        "Bangladesh", "Barbados", "Belarus", "Belgium", "Belize", "Benin", "Bhutan", 
        "Bolivia", "Bosnia and Herzegovina", "Botswana", "Brazil", "Brunei", "Bulgaria", 
        "Burkina Faso", "Burundi", "Cabo Verde", "Cambodia", "Cameroon", "Canada", 
        "Central African Republic", "Chad", "Chile", "China", "Colombia", "Comoros", 
        "Congo", "Costa Rica", "Croatia", "Cuba", "Cyprus", "Czech Republic", "Denmark", 
        "Djibouti", "Dominica", "Dominican Republic", "Ecuador", "Egypt", "El Salvador", 
        "Equatorial Guinea", "Eritrea", "Estonia", "Eswatini", "Ethiopia", "Fiji", 
        "Finland", "France", "Gabon", "Gambia", "Georgia", "Germany", "Ghana", "Greece", 
        "Grenada", "Guatemala", "Guinea", "Guinea-Bissau", "Guyana", "Haiti", "Honduras", 
        "Hungary", "Iceland", "India", "Indonesia", "Iran", "Iraq", "Ireland", "Israel", 
        "Italy", "Jamaica", "Japan", "Jordan", "Kazakhstan", "Kenya", "Kiribati", 
        "Korea, North", "Korea, South", "Kosovo", "Kuwait", "Kyrgyzstan", "Laos", "Latvia", 
        "Lebanon", "Lesotho", "Liberia", "Libya", "Liechtenstein", "Lithuania", "Luxembourg", 
        "Madagascar", "Malawi", "Malaysia", "Maldives", "Mali", "Malta", "Marshall Islands", 
        "Mauritania", "Mauritius", "Mexico", "Micronesia", "Moldova", "Monaco", "Mongolia", 
        "Montenegro", "Morocco", "Mozambique", "Myanmar", "Namibia", "Nauru", "Nepal", 
        "Netherlands", "New Zealand", "Nicaragua", "Niger", "Nigeria", "North Macedonia", 
        "Norway", "Oman", "Pakistan", "Palau", "Palestine", "Panama", "Papua New Guinea", 
        "Paraguay", "Peru", "Philippines", "Poland", "Portugal", "Qatar", "Romania", 
        "Russia", "Rwanda", "Saint Kitts and Nevis", "Saint Lucia", 
        "Saint Vincent and the Grenadines", "Samoa", "San Marino", "Sao Tome and Principe", 
        "Saudi Arabia", "Senegal", "Serbia", "Seychelles", "Sierra Leone", "Singapore", 
        "Slovakia", "Slovenia", "Solomon Islands", "Somalia", "South Africa", "South Sudan", 
        "Spain", "Sri Lanka", "Sudan", "Suriname", "Sweden", "Switzerland", "Syria", 
        "Taiwan", "Tajikistan", "Tanzania", "Thailand", "Timor-Leste", "Togo", "Tonga", 
        "Trinidad and Tobago", "Tunisia", "Turkey", "Turkmenistan", "Tuvalu", "Uganda", 
        "Ukraine", "United Arab Emirates", "United Kingdom", "United States", "Uruguay", 
        "Uzbekistan", "Vanuatu", "Vatican City", "Venezuela", "Vietnam", "Yemen", "Zambia", 
        "Zimbabwe"
    ].sorted()
    
    var filteredCountries: [String] {
        if searchText.isEmpty {
            return countries
        } else {
            return countries.filter { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredCountries, id: \.self) { country in
                    HStack {
                        Text(country)
                        Spacer()
                        if country == selectedCountry {
                            Image(systemName: "checkmark")
                                .foregroundColor(.accentColor)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedCountry = country
                        dismiss()
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search countries")
            .navigationTitle("Select Country")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct BankingDetailsView: View {
    @Binding var bankName: String
    @Binding var accountNumber: String
    @Binding var routingNumber: String
    @Binding var swiftCode: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Banking Information")) {
                    TextField("Bank Name", text: $bankName)
                    
                    TextField("Account Number", text: $accountNumber)
                        .keyboardType(.numberPad)
                    
                    TextField("Routing Number", text: $routingNumber)
                        .keyboardType(.numberPad)
                    
                    TextField("SWIFT/BIC Code (International)", text: $swiftCode)
                        .autocapitalization(.allCharacters)
                }
                
                Section {
                    Button("Save Details") {
                        dismiss()
                    }
                }
            }
            .navigationTitle("Banking Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}