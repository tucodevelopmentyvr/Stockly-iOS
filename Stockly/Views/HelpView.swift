import SwiftUI

struct HelpView: View {
    @State private var selectedSection = "General"

    let sections = ["General", "Inventory", "Invoices", "Estimates", "Backup & Restore", "CSV Import"]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Section selector
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(sections, id: \.self) { section in
                            Button(action: {
                                selectedSection = section
                            }) {
                                Text(section)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 12)
                                    .background(selectedSection == section ? Color.accentColor : Color.clear)
                                    .foregroundColor(selectedSection == section ? .white : .primary)
                                    .cornerRadius(16)
                            }
                        }
                    }
                    .padding()
                }

                // Content area
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        switch selectedSection {
                        case "General":
                            generalHelpContent
                        case "Inventory":
                            inventoryHelpContent
                        case "Invoices":
                            invoicesHelpContent
                        case "Estimates":
                            estimatesHelpContent
                        case "Backup & Restore":
                            backupRestoreHelpContent
                        case "CSV Import":
                            csvImportHelpContent
                        default:
                            generalHelpContent
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Help Guide")
        }
    }

    // Help content sections

    var generalHelpContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            helpSection(
                title: "Getting Started",
                content: "Welcome to Stockly! This guide will help you learn how to use the app effectively. Start by setting up your business profile in the Settings page to customize your invoices and estimates."
            )

            helpSection(
                title: "Navigation",
                content: "Use the tabs at the bottom of the screen to navigate between different sections of the app: Dashboard, Inventory, Invoices, Estimates, and Settings. You can also use the home button to quickly return to the main menu."
            )

            helpSection(
                title: "Data Management",
                content: "Your data is stored locally on your device. You can back up and restore your data using the Backup & Restore option in the Settings page. Regular backups are recommended to prevent data loss."
            )

            helpSection(
                title: "Backup & Restore",
                content: "Stockly provides a comprehensive backup and restore system to protect your data. You can create encrypted backups, set backup reminders, and restore your data if needed. See the 'Backup & Restore Guide' section for detailed instructions."
            )

            helpSection(
                title: "Customization",
                content: "Stockly offers extensive customization options. You can customize your business profile, invoice/estimate layouts, tax rates, and more from the Settings page."
            )

            helpSection(
                title: "Support",
                content: "If you need additional help, please contact our support team at tucodevelopmentyvr@gmail.com"
            )
        }
    }

    var inventoryHelpContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            helpSection(
                title: "Adding Items",
                content: "Tap the + button in the Inventory page to add a new item. Fill in the required fields and optional information as needed."
            )

            helpSection(
                title: "Managing Inventory",
                content: "You can edit, delete, or adjust stock levels for any item by tapping on it. Use the search bar to find specific items, and use the filter and sort options to organize your inventory."
            )

            helpSection(
                title: "Barcode Scanning",
                content: "Tap the barcode icon in the Inventory page to scan barcodes. This allows you to quickly find existing items or add new ones."
            )

            helpSection(
                title: "Bulk Import",
                content: "Use the Import button to import inventory items from a CSV file. See the CSV Import section for more details."
            )

            helpSection(
                title: "Categories",
                content: "Organize your inventory using categories. You can create and manage categories from the Inventory section."
            )
        }
    }

    var invoicesHelpContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            helpSection(
                title: "Creating Invoices",
                content: "To create a new invoice, go to the Invoices tab and tap the + button. Select a client, add items, apply discounts or taxes if needed, and save."
            )

            helpSection(
                title: "Managing Invoices",
                content: "View, edit, or delete existing invoices by tapping on them in the Invoices list. You can also mark invoices as paid, partially paid, or unpaid."
            )

            helpSection(
                title: "Sharing Invoices",
                content: "Open an invoice and tap the Share button to send it as a PDF via email, message, or other sharing options."
            )

            helpSection(
                title: "Payment Tracking",
                content: "Keep track of invoice payments by updating the payment status. You can view paid and unpaid invoices separately using the filter option."
            )
        }
    }

    var estimatesHelpContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            helpSection(
                title: "Creating Estimates",
                content: "To create a new estimate, go to the Estimates tab and tap the + button. Select a client, add items, apply discounts or taxes if needed, and save."
            )

            helpSection(
                title: "Managing Estimates",
                content: "View, edit, or delete existing estimates by tapping on them in the Estimates list. You can also mark estimates as accepted, rejected, or pending."
            )

            helpSection(
                title: "Converting to Invoice",
                content: "To convert an estimate to an invoice, open the estimate and tap 'Convert to Invoice'. Review the information and tap 'Create Invoice'."
            )

            helpSection(
                title: "Sharing Estimates",
                content: "Open an estimate and tap the Share button to send it as a PDF via email, message, or other sharing options."
            )
        }
    }

    var csvImportHelpContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            helpSection(
                title: "CSV Import Overview",
                content: "The CSV Import feature allows you to import multiple inventory items at once using a CSV (Comma Separated Values) file."
            )

            helpSection(
                title: "Accessing CSV Import",
                content: "To access the CSV Import feature, go to the Inventory page and tap the Import button in the top-right corner."
            )

            helpSection(
                title: "CSV File Format",
                content: """
                Your CSV file should include the following columns:

                Required columns:
                - Name: Item name
                - Description: Item description
                - Category: Item category
                - SKU: Product code/SKU
                - Price: Sales unit price
                - Buy_Price: Buy unit price
                - Stock_Quantity: Current stock quantity
                - Min_Stock_Level: Minimum stock level
                - Measurement_Unit: Unit type (PCS, KG, LTR, etc.)

                Optional columns:
                - Tax_Rate: Item tax rate
                - Barcode: Item barcode
                """
            )

            helpSection(
                title: "Sample File",
                content: "To see an example of the correct CSV format, tap the 'Get Sample CSV' button in the CSV Import screen. This will generate a sample file with data for 'Brunelo Jewellers' that you can use as a template."
            )

            helpSection(
                title: "Import Process",
                content: """
                1. Prepare your CSV file according to the required format
                2. Tap 'Select CSV File' and choose your file
                3. The system will validate and import your data
                4. You'll see a summary of successfully imported items and any errors

                Note: Duplicate SKUs will be rejected during import.
                """
            )

            helpSection(
                title: "Creating CSV Files",
                content: "You can create CSV files using spreadsheet software like Microsoft Excel, Google Sheets, or Apple Numbers. Save or export your spreadsheet as a CSV file when ready to import."
            )
        }
    }

    // Helper function for consistent help section formatting
    var backupRestoreHelpContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            helpSection(
                title: "Backup & Restore Overview",
                content: "Stockly provides a comprehensive backup and restore system to protect your data. You can create encrypted backups, set backup reminders, and restore your data if needed."
            )

            helpSection(
                title: "Creating a Backup",
                content: "To create a backup, go to Settings > Backup & Restore and tap the 'Export' button. You can choose to password-protect your backup for added security. After creating a backup, you can share it via email, save it to Files, or use any other sharing option."
            )

            helpSection(
                title: "Password Protection",
                content: "Password-protected backups are encrypted using industry-standard encryption. This ensures that your sensitive business data remains secure. Remember your password! If you forget it, you won't be able to restore from that backup."
            )

            helpSection(
                title: "Backup Settings",
                content: "In the Backup Settings, you can configure backup reminders and password protection options. Regular backups are recommended to prevent data loss."
            )

            helpSection(
                title: "Restoring from a Backup",
                content: "To restore from a backup, go to Settings > Backup & Restore and tap the 'Select Backup' button. Choose the backup file you want to restore from. If the backup is password-protected, you'll need to enter the password. WARNING: Restoring will replace all current data with the backup data."
            )

            helpSection(
                title: "After App Deletion",
                content: "If you delete the app and reinstall it, you can still restore your data from a backup. Make sure to save your backup files outside the app (e.g., in Files, iCloud, or email) before deleting the app."
            )

            helpSection(
                title: "Backup File Location",
                content: "Backup files are stored in the app's Documents directory. You can access them through the 'Manage Backup Files' option in the Backup & Restore screen."
            )

            helpSection(
                title: "Troubleshooting",
                content: "If you encounter issues with backup or restore, ensure you have sufficient storage space on your device and that you're using the correct password for encrypted backups. For further assistance, contact our support team at tucodevelopmentyvr@gmail.com"
            )
        }
    }

    func helpSection(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)

            if content.contains("tucodevelopmentyvr@gmail.com") {
                VStack(alignment: .leading) {
                    Text(content.replacingOccurrences(of: "tucodevelopmentyvr@gmail.com", with: ""))
                        .font(.body)
                        .foregroundColor(.secondary)

                    Button("tucodevelopmentyvr@gmail.com") {
                        if let url = URL(string: "mailto:tucodevelopmentyvr@gmail.com") {
                            UIApplication.shared.open(url)
                        }
                    }
                    .font(.body)
                    .foregroundColor(.blue)
                }
            } else {
                Text(content)
                    .font(.body)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    HelpView()
}