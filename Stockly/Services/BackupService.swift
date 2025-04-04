import Foundation
import SwiftData
import UIKit
import CryptoKit

// Backup errors that can occur during export or import operations
enum BackupError: Error {
    case exportFailed(String)
    case importFailed(String)
    case jsonEncodingFailed
    case jsonDecodingFailed
    case fileCreationFailed
    case zipCreationFailed
    case zipExtractionFailed
    case modelContextMissing
    case invalidData
    case fileNotFound
    case accessDenied
    case encryptionFailed
    case decryptionFailed
    case incompatibleVersion
    case missingData(String)
    case corruptedBackup
}

// Metadata structure for backup files
struct BackupMetadata: Codable {
    let appVersion: String
    let buildNumber: String
    let creationDate: String
    let platform: String
    let encrypted: Bool
}

/// BackupService handles the export and import of all app data
@MainActor
class BackupService {
    private let modelContext: ModelContext
    private let encryptionService = EncryptionService()

    // Current backup version - increment when backup format changes
    private let currentBackupVersion = 1

    // UserDefaults keys
    private let lastBackupDateKey = "lastBackupDate"
    private let backupReminderIntervalKey = "backupReminderInterval"
    private let backupPasswordEnabledKey = "backupPasswordEnabled"
    private let backupPasswordHashKey = "backupPasswordHash"

    // Default backup reminder interval in days
    private let defaultBackupReminderInterval = 7

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Backup Directory Management

    /// Get the URL for the backups directory
    private func getBackupsDirectory() throws -> URL {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let backupsDirectory = documentsDirectory.appendingPathComponent("Backups", isDirectory: true)

        // Create the directory if it doesn't exist
        if !FileManager.default.fileExists(atPath: backupsDirectory.path) {
            try FileManager.default.createDirectory(at: backupsDirectory, withIntermediateDirectories: true)
        }

        return backupsDirectory
    }

    /// Get all backup files in the backups directory
    func getBackupFiles() throws -> [URL] {
        let backupsDirectory = try getBackupsDirectory()
        let fileURLs = try FileManager.default.contentsOfDirectory(at: backupsDirectory, includingPropertiesForKeys: nil)
        return fileURLs.filter { $0.pathExtension == "stocklybackup" }
    }

    /// Delete a backup file
    func deleteBackupFile(at url: URL) throws {
        if FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.removeItem(at: url)
        }
    }

    // MARK: - Backup Password Management

    /// Check if backup password is enabled
    var isBackupPasswordEnabled: Bool {
        UserDefaults.standard.bool(forKey: backupPasswordEnabledKey)
    }

    /// Set backup password
    func setBackupPassword(_ password: String?) {
        if let password = password, !password.isEmpty {
            // Hash the password for storage
            let passwordHash = hashPassword(password)
            UserDefaults.standard.set(true, forKey: backupPasswordEnabledKey)
            UserDefaults.standard.set(passwordHash, forKey: backupPasswordHashKey)
        } else {
            // Disable password protection
            UserDefaults.standard.set(false, forKey: backupPasswordEnabledKey)
            UserDefaults.standard.removeObject(forKey: backupPasswordHashKey)
        }
    }

    /// Verify backup password
    func verifyBackupPassword(_ password: String) -> Bool {
        guard isBackupPasswordEnabled,
              let storedHash = UserDefaults.standard.string(forKey: backupPasswordHashKey) else {
            return false
        }

        let passwordHash = hashPassword(password)
        return passwordHash == storedHash
    }

    /// Hash a password for secure storage
    private func hashPassword(_ password: String) -> String {
        let data = Data(password.utf8)
        let hashed = SHA256.hash(data: data)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }

    // MARK: - Backup Reminder Management

    /// Get the date of the last backup
    var lastBackupDate: Date? {
        UserDefaults.standard.object(forKey: lastBackupDateKey) as? Date
    }

    /// Set the date of the last backup
    private func updateLastBackupDate() {
        UserDefaults.standard.set(Date(), forKey: lastBackupDateKey)
    }

    /// Get the backup reminder interval in days
    var backupReminderInterval: Int {
        get {
            UserDefaults.standard.integer(forKey: backupReminderIntervalKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: backupReminderIntervalKey)
        }
    }

    /// Check if a backup reminder should be shown
    func shouldShowBackupReminder() -> Bool {
        // Initialize backup reminder interval if not set
        if UserDefaults.standard.object(forKey: backupReminderIntervalKey) == nil {
            backupReminderInterval = defaultBackupReminderInterval
        }

        guard let lastBackup = lastBackupDate else {
            return true // No backup ever made
        }

        let daysSinceLastBackup = Calendar.current.dateComponents([.day], from: lastBackup, to: Date()).day ?? 0
        return daysSinceLastBackup >= backupReminderInterval
    }

    // MARK: - Backup/Export

    /// Export all app data to a backup file
    /// - Parameters:
    ///   - password: Optional password for encryption
    /// - Returns: URL of the created backup file
    func exportAllData(password: String? = nil) async throws -> URL {
        // Create a temporary directory for our backup files
        let tempDirURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)

        do {
            try FileManager.default.createDirectory(at: tempDirURL, withIntermediateDirectories: true)

            // Export each data type to its own JSON file
            try await exportItems(to: tempDirURL.appendingPathComponent("items.json"))
            try await exportCategories(to: tempDirURL.appendingPathComponent("categories.json"))
            try await exportClients(to: tempDirURL.appendingPathComponent("clients.json"))
            try await exportSuppliers(to: tempDirURL.appendingPathComponent("suppliers.json"))
            try await exportInvoices(to: tempDirURL.appendingPathComponent("invoices.json"))
            try await exportEstimates(to: tempDirURL.appendingPathComponent("estimates.json"))

            // Export settings and user preferences
            try await exportSettings(to: tempDirURL.appendingPathComponent("settings.json"))

            // Create metadata file with app version and creation date
            let metadata = BackupMetadata(
                appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0",
                buildNumber: Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1",
                creationDate: ISO8601DateFormatter().string(from: Date()),
                platform: "iOS",
                encrypted: password != nil
            )

            let encoder = JSONEncoder()
            try encoder.encode(metadata).write(to: tempDirURL.appendingPathComponent("metadata.json"))

            // Create a combined JSON file instead of a ZIP
            let dateFormatter = DateFormatter()
            // Use a simple date format without special characters
            dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
            dateFormatter.locale = Locale(identifier: "en_US_POSIX")
            let dateString = dateFormatter.string(from: Date())

            // We need to use JSONSerialization for the combined backup
            // Convert metadata to dictionary for JSONSerialization
            let metadataDict = try JSONSerialization.jsonObject(
                with: encoder.encode(metadata)
            ) as! [String: Any]

            // Create a combined backup dictionary with all the data
            var combinedBackup: [String: Any] = [
                "metadata": metadataDict,
                "version": currentBackupVersion
            ]

            // Read each JSON file and add to the combined backup
            if let itemsData = try? Data(contentsOf: tempDirURL.appendingPathComponent("items.json")),
               let itemsJSON = try? JSONSerialization.jsonObject(with: itemsData) {
                combinedBackup["items"] = itemsJSON
            }

            if let categoriesData = try? Data(contentsOf: tempDirURL.appendingPathComponent("categories.json")),
               let categoriesJSON = try? JSONSerialization.jsonObject(with: categoriesData) {
                combinedBackup["categories"] = categoriesJSON
            }

            if let clientsData = try? Data(contentsOf: tempDirURL.appendingPathComponent("clients.json")),
               let clientsJSON = try? JSONSerialization.jsonObject(with: clientsData) {
                combinedBackup["clients"] = clientsJSON
            }

            if let suppliersData = try? Data(contentsOf: tempDirURL.appendingPathComponent("suppliers.json")),
               let suppliersJSON = try? JSONSerialization.jsonObject(with: suppliersData) {
                combinedBackup["suppliers"] = suppliersJSON
            }

            if let invoicesData = try? Data(contentsOf: tempDirURL.appendingPathComponent("invoices.json")),
               let invoicesJSON = try? JSONSerialization.jsonObject(with: invoicesData) {
                combinedBackup["invoices"] = invoicesJSON
            }

            if let estimatesData = try? Data(contentsOf: tempDirURL.appendingPathComponent("estimates.json")),
               let estimatesJSON = try? JSONSerialization.jsonObject(with: estimatesData) {
                combinedBackup["estimates"] = estimatesJSON
            }

            if let settingsData = try? Data(contentsOf: tempDirURL.appendingPathComponent("settings.json")),
               let settingsJSON = try? JSONSerialization.jsonObject(with: settingsData) {
                combinedBackup["settings"] = settingsJSON
            }

            // Get the backups directory
            let backupsDirectory = try getBackupsDirectory()
            // Use a simpler filename format without special characters
            let fileName = "stockly_backup_\(dateString.replacingOccurrences(of: " ", with: "_")).stocklybackup"
            let backupFileURL = backupsDirectory.appendingPathComponent(fileName)

            // Serialize the backup data
            let backupData = try JSONSerialization.data(withJSONObject: combinedBackup, options: .prettyPrinted)

            // Encrypt the data if a password is provided
            if let password = password, !password.isEmpty {
                do {
                    let encryptedData = try encryptionService.encrypt(data: backupData, withPassword: password)
                    try encryptedData.write(to: backupFileURL)
                } catch {
                    throw BackupError.encryptionFailed
                }
            } else {
                // Write unencrypted data
                try backupData.write(to: backupFileURL)
            }

            // Update last backup date
            updateLastBackupDate()

            // Clean up the temporary directory
            try FileManager.default.removeItem(at: tempDirURL)

            return backupFileURL
        } catch {
            // Clean up on error
            try? FileManager.default.removeItem(at: tempDirURL)
            throw BackupError.exportFailed(error.localizedDescription)
        }
    }

    /// Share the backup file using UIActivityViewController
    /// - Parameter backupURL: URL of the backup file to share
    /// - Returns: UIActivityViewController configured for sharing
    func shareBackup(backupURL: URL) -> UIActivityViewController {
        let activityViewController = UIActivityViewController(
            activityItems: [backupURL],
            applicationActivities: nil
        )
        return activityViewController
    }

    // MARK: - Restore/Import

    /// Check if a backup file is encrypted
    /// - Parameter backupURL: URL of the backup file
    /// - Returns: True if the backup is encrypted
    func isBackupEncrypted(at backupURL: URL) throws -> Bool {
        do {
            // Try to read the first part of the file to check for encryption
            let backupData = try Data(contentsOf: backupURL)

            // Try to parse as JSON
            if let backupDict = try? JSONSerialization.jsonObject(with: backupData) as? [String: Any],
               let metadataDict = backupDict["metadata"] as? [String: Any] {
                // Convert dictionary back to data and decode as BackupMetadata
                let metadataData = try JSONSerialization.data(withJSONObject: metadataDict)
                let metadata = try JSONDecoder().decode(BackupMetadata.self, from: metadataData)
                return metadata.encrypted
            }

            // If we can't parse as JSON, it's likely encrypted
            return true
        } catch {
            throw BackupError.invalidData
        }
    }

    /// Import data from a backup file
    /// - Parameters:
    ///   - backupURL: URL of the backup file
    ///   - password: Password for decryption if the backup is encrypted
    func importAllData(from backupURL: URL, password: String? = nil) async throws {
        // Create a temporary directory for extraction
        let extractDirURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)

        do {
            try FileManager.default.createDirectory(at: extractDirURL, withIntermediateDirectories: true)

            // Read the backup file
            var backupData = try Data(contentsOf: backupURL)

            // Check if the backup is encrypted
            let isEncrypted = try isBackupEncrypted(at: backupURL)

            // Decrypt if necessary
            if isEncrypted {
                guard let decryptionPassword = password, !decryptionPassword.isEmpty else {
                    throw BackupError.decryptionFailed
                }

                do {
                    backupData = try encryptionService.decrypt(encryptedData: backupData, withPassword: decryptionPassword)
                } catch {
                    throw BackupError.decryptionFailed
                }
            }

            // Parse the JSON data
            guard let backupDict = try JSONSerialization.jsonObject(with: backupData) as? [String: Any] else {
                throw BackupError.invalidData
            }

            // Validate backup version
            if let version = backupDict["version"] as? Int {
                if version > currentBackupVersion {
                    throw BackupError.incompatibleVersion
                }
            } else {
                throw BackupError.invalidData
            }

            // Extract the data to separate files
            if let items = backupDict["items"] {
                let itemsData = try JSONSerialization.data(withJSONObject: items, options: .prettyPrinted)
                try itemsData.write(to: extractDirURL.appendingPathComponent("items.json"))
            }

            if let categories = backupDict["categories"] {
                let categoriesData = try JSONSerialization.data(withJSONObject: categories, options: .prettyPrinted)
                try categoriesData.write(to: extractDirURL.appendingPathComponent("categories.json"))
            }

            if let clients = backupDict["clients"] {
                let clientsData = try JSONSerialization.data(withJSONObject: clients, options: .prettyPrinted)
                try clientsData.write(to: extractDirURL.appendingPathComponent("clients.json"))
            }

            if let suppliers = backupDict["suppliers"] {
                let suppliersData = try JSONSerialization.data(withJSONObject: suppliers, options: .prettyPrinted)
                try suppliersData.write(to: extractDirURL.appendingPathComponent("suppliers.json"))
            }

            if let invoices = backupDict["invoices"] {
                let invoicesData = try JSONSerialization.data(withJSONObject: invoices, options: .prettyPrinted)
                try invoicesData.write(to: extractDirURL.appendingPathComponent("invoices.json"))
            }

            if let estimates = backupDict["estimates"] {
                let estimatesData = try JSONSerialization.data(withJSONObject: estimates, options: .prettyPrinted)
                try estimatesData.write(to: extractDirURL.appendingPathComponent("estimates.json"))
            }

            if let settings = backupDict["settings"] {
                let settingsData = try JSONSerialization.data(withJSONObject: settings, options: .prettyPrinted)
                try settingsData.write(to: extractDirURL.appendingPathComponent("settings.json"))
            }

            // For metadata, either use from backup or create a minimal version
            if let metadata = backupDict["metadata"] {
                let metadataData = try JSONSerialization.data(withJSONObject: metadata, options: .prettyPrinted)
                try metadataData.write(to: extractDirURL.appendingPathComponent("metadata.json"))
            } else {
                // Create a minimal metadata file if none exists
                let metadata = ["importDate": ISO8601DateFormatter().string(from: Date())]
                try JSONEncoder().encode(metadata).write(to: extractDirURL.appendingPathComponent("metadata.json"))
            }

            // Verify metadata file exists
            let metadataURL = extractDirURL.appendingPathComponent("metadata.json")
            guard FileManager.default.fileExists(atPath: metadataURL.path) else {
                throw BackupError.invalidData
            }

            // Process each data file in order (considering dependencies)
            try await importCategories(from: extractDirURL.appendingPathComponent("categories.json"))
            try await importItems(from: extractDirURL.appendingPathComponent("items.json"))
            try await importClients(from: extractDirURL.appendingPathComponent("clients.json"))
            try await importSuppliers(from: extractDirURL.appendingPathComponent("suppliers.json"))
            try await importInvoices(from: extractDirURL.appendingPathComponent("invoices.json"))
            try await importEstimates(from: extractDirURL.appendingPathComponent("estimates.json"))

            // Import settings
            try await importSettings(from: extractDirURL.appendingPathComponent("settings.json"))

            // Clean up
            try FileManager.default.removeItem(at: extractDirURL)
        } catch {
            // Clean up on error
            try? FileManager.default.removeItem(at: extractDirURL)
            throw BackupError.importFailed(error.localizedDescription)
        }
    }

    // MARK: - Individual Export Methods

    private func exportItems(to fileURL: URL) async throws {
        let descriptor = FetchDescriptor<Item>()
        let items = try modelContext.fetch(descriptor)

        // Convert to JSON-friendly dictionaries
        let itemDicts = items.map { item -> [String: Any] in
            var dict: [String: Any] = [
                "id": item.id.uuidString,
                "name": item.name,
                "description": item.itemDescription,
                "category": item.category,
                "sku": item.sku,
                "price": item.price,
                "buyPrice": item.buyPrice,
                "stockQuantity": item.stockQuantity,
                "minStockLevel": item.minStockLevel,
                "measurementUnit": item.measurementUnit,
                "taxRate": item.taxRate,
                "createdAt": item.createdAt.timeIntervalSince1970,
                "updatedAt": item.updatedAt.timeIntervalSince1970,
                "inventoryAddedAt": item.inventoryAddedAt.timeIntervalSince1970
            ]

            if let barcode = item.barcode {
                dict["barcode"] = barcode
            }

            if let imageURL = item.imageURL {
                dict["imageURL"] = imageURL
            }

            if let imageData = item.imageData {
                dict["imageData"] = imageData.base64EncodedString()
            }

            return dict
        }

        // Save to file
        let jsonData = try JSONSerialization.data(withJSONObject: itemDicts, options: .prettyPrinted)
        try jsonData.write(to: fileURL)
    }

    private func exportCategories(to fileURL: URL) async throws {
        let descriptor = FetchDescriptor<Category>()
        let categories = try modelContext.fetch(descriptor)

        // Convert to JSON-friendly dictionaries
        let categoryDicts = categories.map { category -> [String: Any] in
            var dict: [String: Any] = [
                "id": category.id.uuidString,
                "name": category.name,
                "createdAt": category.createdAt.timeIntervalSince1970,
                "updatedAt": category.updatedAt.timeIntervalSince1970
            ]

            if let description = category.categoryDescription {
                dict["description"] = description
            }

            // Export custom fields if any
            if let customFields = category.customFields, !customFields.isEmpty {
                dict["customFields"] = customFields.map { field -> [String: Any] in
                    var fieldDict: [String: Any] = [
                        "id": field.id.uuidString,
                        "name": field.name,
                        "fieldType": field.fieldType,
                        "required": field.required,
                        "createdAt": field.createdAt.timeIntervalSince1970,
                        "updatedAt": field.updatedAt.timeIntervalSince1970
                    ]

                    if let options = field.options, !options.isEmpty {
                        fieldDict["options"] = options
                    }

                    return fieldDict
                }
            }

            return dict
        }

        // Save to file
        let jsonData = try JSONSerialization.data(withJSONObject: categoryDicts, options: .prettyPrinted)
        try jsonData.write(to: fileURL)
    }

    private func exportClients(to fileURL: URL) async throws {
        // Fetch all clients from the database
        let descriptor = FetchDescriptor<Client>()

        do {
            let clients = try modelContext.fetch(descriptor)

            // Convert to JSON-friendly dictionaries
            let clientDicts = clients.map { client -> [String: Any] in
                let dict: [String: Any] = [
                    "id": client.id.uuidString,
                    "name": client.name,
                    "email": client.email ?? "",
                    "phone": client.phone ?? "",
                    "address": client.address,
                    "city": client.city,
                    "country": client.country,
                    "postalCode": client.postalCode,
                    "notes": client.notes ?? "",
                    "createdAt": client.createdAt.timeIntervalSince1970,
                    "updatedAt": client.updatedAt.timeIntervalSince1970
                ]

                return dict
            }

            // Save to file
            let jsonData = try JSONSerialization.data(withJSONObject: clientDicts, options: .prettyPrinted)
            try jsonData.write(to: fileURL)
        } catch {
            print("Error exporting clients: \(error)")
            throw BackupError.exportFailed("Failed to export clients: \(error.localizedDescription)")
        }
    }

    private func exportSuppliers(to fileURL: URL) async throws {
        // Fetch all suppliers from the database
        let descriptor = FetchDescriptor<Supplier>()

        do {
            let suppliers = try modelContext.fetch(descriptor)

            // Convert to JSON-friendly dictionaries
            let supplierDicts = suppliers.map { supplier -> [String: Any] in
                let dict: [String: Any] = [
                    "id": supplier.id.uuidString,
                    "name": supplier.name,
                    "email": supplier.email ?? "",
                    "phone": supplier.phone ?? "",
                    "address": supplier.address,
                    "city": supplier.city,
                    "country": supplier.country,
                    "postalCode": supplier.postalCode,
                    "contactPerson": supplier.contactPerson ?? "",
                    "notes": supplier.notes ?? "",
                    "createdAt": supplier.createdAt.timeIntervalSince1970,
                    "updatedAt": supplier.updatedAt.timeIntervalSince1970
                ]

                return dict
            }

            // Save to file
            let jsonData = try JSONSerialization.data(withJSONObject: supplierDicts, options: .prettyPrinted)
            try jsonData.write(to: fileURL)
        } catch {
            print("Error exporting suppliers: \(error)")
            throw BackupError.exportFailed("Failed to export suppliers: \(error.localizedDescription)")
        }
    }

    private func exportInvoices(to fileURL: URL) async throws {
        let descriptor = FetchDescriptor<Invoice>()
        let invoices = try modelContext.fetch(descriptor)

        // Convert to JSON-friendly dictionaries
        let invoiceDicts = invoices.map { invoice -> [String: Any] in
            var dict: [String: Any] = [
                "id": invoice.id.uuidString,
                "number": invoice.number,
                "clientName": invoice.clientName,
                "clientAddress": invoice.clientAddress,
                "clientEmail": invoice.clientEmail ?? "",
                "clientPhone": invoice.clientPhone ?? "",
                "status": invoice.status.rawValue,
                "paymentMethod": invoice.paymentMethod ?? "",
                "documentType": invoice.documentType,
                "dateCreated": invoice.dateCreated.timeIntervalSince1970,
                "dueDate": invoice.dueDate.timeIntervalSince1970,
                "subtotal": invoice.subtotal,
                "discount": invoice.discount,
                "discountType": invoice.discountType,
                "tax": invoice.tax,
                "taxRate": invoice.taxRate,
                "totalAmount": invoice.totalAmount,
                "notes": invoice.notes,
                "headerNote": invoice.headerNote ?? "",
                "footerNote": invoice.footerNote ?? "",
                "bankingInfo": invoice.bankingInfo ?? "",
                "barcodeData": invoice.barcodeData ?? "",
                "qrCodeData": invoice.qrCodeData ?? "",
                "templateType": invoice.templateType,
                "createdAt": invoice.createdAt.timeIntervalSince1970,
                "updatedAt": invoice.updatedAt.timeIntervalSince1970
            ]

            // Convert signature to base64 if present
            if let signature = invoice.signature {
                dict["signature"] = signature.base64EncodedString()
            }

            // Include items
            dict["items"] = invoice.items.map { item -> [String: Any] in
                var itemDict: [String: Any] = [
                    "id": item.id.uuidString,
                    "name": item.name,
                    "quantity": item.quantity,
                    "unitPrice": item.unitPrice,
                    "tax": item.tax,
                    "discount": item.discount,
                    "totalAmount": item.totalAmount
                ]

                if let description = item.itemDescription {
                    itemDict["description"] = description
                }

                return itemDict
            }

            // Include custom fields if any
            if let customFields = invoice.customFields, !customFields.isEmpty {
                dict["customFields"] = customFields.map { field -> [String: Any] in
                    [
                        "id": field.id.uuidString,
                        "name": field.name,
                        "value": field.value
                    ]
                }
            }

            return dict
        }

        // Save to file
        let jsonData = try JSONSerialization.data(withJSONObject: invoiceDicts, options: .prettyPrinted)
        try jsonData.write(to: fileURL)
    }

    private func exportEstimates(to fileURL: URL) async throws {
        let descriptor = FetchDescriptor<Estimate>()
        let estimates = try modelContext.fetch(descriptor)

        // Convert to JSON-friendly dictionaries
        let estimateDicts = estimates.map { estimate -> [String: Any] in
            var dict: [String: Any] = [
                "id": estimate.id.uuidString,
                "number": estimate.number,
                "clientName": estimate.clientName,
                "clientAddress": estimate.clientAddress,
                "clientEmail": estimate.clientEmail ?? "",
                "clientPhone": estimate.clientPhone ?? "",
                "status": estimate.status.rawValue,
                "dateCreated": estimate.dateCreated.timeIntervalSince1970,
                "expiryDate": estimate.expiryDate.timeIntervalSince1970,
                "subtotal": estimate.subtotal,
                "discount": estimate.discount,
                "discountType": estimate.discountType,
                "tax": estimate.tax,
                "taxRate": estimate.taxRate,
                "totalAmount": estimate.totalAmount,
                "notes": estimate.notes,
                "headerNote": estimate.headerNote ?? "",
                "footerNote": estimate.footerNote ?? "",
                "templateType": estimate.templateType,
                "createdAt": estimate.createdAt.timeIntervalSince1970,
                "updatedAt": estimate.updatedAt.timeIntervalSince1970
            ]

            // Include items
            dict["items"] = estimate.items.map { item -> [String: Any] in
                var itemDict: [String: Any] = [
                    "id": item.id.uuidString,
                    "name": item.name,
                    "quantity": item.quantity,
                    "unitPrice": item.unitPrice,
                    "tax": item.tax,
                    "discount": item.discount,
                    "totalAmount": item.totalAmount
                ]

                if let description = item.itemDescription {
                    itemDict["description"] = description
                }

                return itemDict
            }

            // Include custom fields if any
            if let customFields = estimate.customFields, !customFields.isEmpty {
                dict["customFields"] = customFields.map { field -> [String: Any] in
                    [
                        "id": field.id.uuidString,
                        "name": field.name,
                        "value": field.value
                    ]
                }
            }

            return dict
        }

        // Save to file
        let jsonData = try JSONSerialization.data(withJSONObject: estimateDicts, options: .prettyPrinted)
        try jsonData.write(to: fileURL)
    }

    private func exportSettings(to fileURL: URL) async throws {
        // Collect all app settings from UserDefaults
        let userDefaults = UserDefaults.standard

        // List of keys to include in the backup
        let settingsKeys = [
            "darkModeEnabled",
            "selectedTheme",
            "companyName",
            "companyAddress",
            "companyPhone",
            "companyEmail",
            "companyWebsite",
            "companyLogo",
            "taxRate",
            "currencySymbol",
            "invoicePrefix",
            "estimatePrefix",
            "nextInvoiceNumber",
            "nextEstimateNumber",
            "invoiceTerms",
            "estimateTerms",
            "invoiceFooter",
            "estimateFooter",
            "bankingDetails",
            // Add any other settings keys here
        ]

        var settingsDict: [String: Any] = [:]

        // Extract values for each key
        for key in settingsKeys {
            if let value = userDefaults.object(forKey: key) {
                // Handle special cases like Data
                if let imageData = value as? Data {
                    settingsDict[key] = imageData.base64EncodedString()
                } else {
                    settingsDict[key] = value
                }
            }
        }

        // Save to file
        let jsonData = try JSONSerialization.data(withJSONObject: settingsDict, options: .prettyPrinted)
        try jsonData.write(to: fileURL)
    }

    // MARK: - Individual Import Methods

    private func importItems(from fileURL: URL) async throws {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            print("Items file not found, skipping import")
            return
        }

        do {
            let jsonData = try Data(contentsOf: fileURL)
            guard let itemsArray = try JSONSerialization.jsonObject(with: jsonData) as? [[String: Any]] else {
                throw BackupError.invalidData
            }

            // Clear existing items (optional - could be a setting)
            try clearExistingItems()

            // Process and insert each item
            for itemDict in itemsArray {
                guard let idString = itemDict["id"] as? String,
                      let id = UUID(uuidString: idString),
                      let name = itemDict["name"] as? String,
                      let description = itemDict["description"] as? String,
                      let category = itemDict["category"] as? String,
                      let sku = itemDict["sku"] as? String,
                      let price = itemDict["price"] as? Double,
                      let buyPrice = itemDict["buyPrice"] as? Double,
                      let stockQuantity = itemDict["stockQuantity"] as? Int,
                      let minStockLevel = itemDict["minStockLevel"] as? Int,
                      let measurementUnit = itemDict["measurementUnit"] as? String,
                      let taxRate = itemDict["taxRate"] as? Double,
                      let createdAtTimestamp = itemDict["createdAt"] as? Double,
                      let updatedAtTimestamp = itemDict["updatedAt"] as? Double,
                      let inventoryAddedAtTimestamp = itemDict["inventoryAddedAt"] as? Double
                else {
                    print("Skipping invalid item entry")
                    continue
                }

                // Create item
                let item = Item(
                    name: name,
                    description: description,
                    category: category,
                    sku: sku,
                    price: price,
                    buyPrice: buyPrice,
                    stockQuantity: stockQuantity,
                    minStockLevel: minStockLevel,
                    measurementUnit: MeasurementUnitType(rawValue: measurementUnit) ?? .piece,
                    taxRate: taxRate,
                    barcode: itemDict["barcode"] as? String,
                    imageURL: itemDict["imageURL"] as? String
                )

                // Handle image data
                if let imageDataString = itemDict["imageData"] as? String,
                   let imageData = Data(base64Encoded: imageDataString) {
                    item.imageData = imageData
                }

                // Restore dates
                item.id = id
                item.createdAt = Date(timeIntervalSince1970: createdAtTimestamp)
                item.updatedAt = Date(timeIntervalSince1970: updatedAtTimestamp)
                item.inventoryAddedAt = Date(timeIntervalSince1970: inventoryAddedAtTimestamp)

                // Insert into database
                modelContext.insert(item)
            }

            try modelContext.save()
        } catch {
            print("Error importing items: \(error)")
            throw BackupError.importFailed("Failed to import items: \(error.localizedDescription)")
        }
    }

    private func importCategories(from fileURL: URL) async throws {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            print("Categories file not found, skipping import")
            return
        }

        do {
            let jsonData = try Data(contentsOf: fileURL)
            guard let categoriesArray = try JSONSerialization.jsonObject(with: jsonData) as? [[String: Any]] else {
                throw BackupError.invalidData
            }

            // Clear existing categories (optional)
            try clearExistingCategories()

            // Process and insert each category
            for categoryDict in categoriesArray {
                guard let idString = categoryDict["id"] as? String,
                      let id = UUID(uuidString: idString),
                      let name = categoryDict["name"] as? String,
                      let createdAtTimestamp = categoryDict["createdAt"] as? Double,
                      let updatedAtTimestamp = categoryDict["updatedAt"] as? Double
                else {
                    print("Skipping invalid category entry")
                    continue
                }

                // Create category
                let category = Category(
                    name: name,
                    description: categoryDict["description"] as? String
                )

                // Restore ID and dates
                category.id = id
                category.createdAt = Date(timeIntervalSince1970: createdAtTimestamp)
                category.updatedAt = Date(timeIntervalSince1970: updatedAtTimestamp)

                // Process custom fields if any
                if let customFieldsArray = categoryDict["customFields"] as? [[String: Any]] {
                    var customFields: [CustomField] = []

                    for fieldDict in customFieldsArray {
                        guard let fieldIdString = fieldDict["id"] as? String,
                              let fieldId = UUID(uuidString: fieldIdString),
                              let fieldName = fieldDict["name"] as? String,
                              let fieldType = fieldDict["fieldType"] as? String,
                              let required = fieldDict["required"] as? Bool,
                              let fieldCreatedAtTimestamp = fieldDict["createdAt"] as? Double,
                              let fieldUpdatedAtTimestamp = fieldDict["updatedAt"] as? Double
                        else {
                            continue
                        }

                        let customField = CustomField(
                            name: fieldName,
                            fieldType: FieldType(rawValue: fieldType) ?? .text,
                            required: required,
                            options: fieldDict["options"] as? [String]
                        )

                        // Restore ID and dates
                        customField.id = fieldId
                        customField.createdAt = Date(timeIntervalSince1970: fieldCreatedAtTimestamp)
                        customField.updatedAt = Date(timeIntervalSince1970: fieldUpdatedAtTimestamp)
                        customField.category = category

                        customFields.append(customField)
                    }

                    category.customFields = customFields
                }

                // Insert into database
                modelContext.insert(category)
            }

            try modelContext.save()
        } catch {
            print("Error importing categories: \(error)")
            throw BackupError.importFailed("Failed to import categories: \(error.localizedDescription)")
        }
    }

    private func importClients(from fileURL: URL) async throws {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            print("Clients file not found, skipping import")
            return
        }

        do {
            let jsonData = try Data(contentsOf: fileURL)
            guard let clientsArray = try JSONSerialization.jsonObject(with: jsonData) as? [[String: Any]] else {
                throw BackupError.invalidData
            }

            // Clear existing clients (optional)
            try clearExistingClients()

            // Process and insert each client
            for clientDict in clientsArray {
                guard let idString = clientDict["id"] as? String,
                      let id = UUID(uuidString: idString),
                      let name = clientDict["name"] as? String,
                      let createdAtTimestamp = clientDict["createdAt"] as? Double,
                      let updatedAtTimestamp = clientDict["updatedAt"] as? Double
                else {
                    print("Skipping invalid client entry")
                    continue
                }

                // Create client
                let client = Client(
                    name: name,
                    email: clientDict["email"] as? String,
                    phone: clientDict["phone"] as? String,
                    address: (clientDict["address"] as? String) ?? ""
                )

                // Set additional fields
                client.city = (clientDict["city"] as? String) ?? ""
                client.country = (clientDict["country"] as? String) ?? "United States"
                client.postalCode = (clientDict["postalCode"] as? String) ?? (clientDict["zipCode"] as? String) ?? ""
                client.notes = clientDict["notes"] as? String

                // Restore ID and dates
                client.id = id
                client.createdAt = Date(timeIntervalSince1970: createdAtTimestamp)
                client.updatedAt = Date(timeIntervalSince1970: updatedAtTimestamp)

                // Insert into database
                modelContext.insert(client)
            }

            try modelContext.save()
        } catch {
            print("Error importing clients: \(error)")
            throw BackupError.importFailed("Failed to import clients: \(error.localizedDescription)")
        }
    }

    private func importSuppliers(from fileURL: URL) async throws {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            print("Suppliers file not found, skipping import")
            return
        }

        do {
            let jsonData = try Data(contentsOf: fileURL)
            guard let suppliersArray = try JSONSerialization.jsonObject(with: jsonData) as? [[String: Any]] else {
                throw BackupError.invalidData
            }

            // Clear existing suppliers (optional)
            try clearExistingSuppliers()

            // Process and insert each supplier
            for supplierDict in suppliersArray {
                guard let idString = supplierDict["id"] as? String,
                      let id = UUID(uuidString: idString),
                      let name = supplierDict["name"] as? String,
                      let createdAtTimestamp = supplierDict["createdAt"] as? Double,
                      let updatedAtTimestamp = supplierDict["updatedAt"] as? Double
                else {
                    print("Skipping invalid supplier entry")
                    continue
                }

                // Create supplier
                let supplier = Supplier(
                    name: name,
                    email: supplierDict["email"] as? String,
                    phone: supplierDict["phone"] as? String,
                    address: (supplierDict["address"] as? String) ?? ""
                )

                // Set additional fields
                supplier.city = (supplierDict["city"] as? String) ?? ""
                supplier.country = (supplierDict["country"] as? String) ?? "United States"
                supplier.postalCode = (supplierDict["postalCode"] as? String) ?? (supplierDict["zipCode"] as? String) ?? ""
                supplier.contactPerson = supplierDict["contactPerson"] as? String
                supplier.notes = supplierDict["notes"] as? String

                // Restore ID and dates
                supplier.id = id
                supplier.createdAt = Date(timeIntervalSince1970: createdAtTimestamp)
                supplier.updatedAt = Date(timeIntervalSince1970: updatedAtTimestamp)

                // Insert into database
                modelContext.insert(supplier)
            }

            try modelContext.save()
        } catch {
            print("Error importing suppliers: \(error)")
            throw BackupError.importFailed("Failed to import suppliers: \(error.localizedDescription)")
        }
    }

    private func importInvoices(from fileURL: URL) async throws {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            print("Invoices file not found, skipping import")
            return
        }

        do {
            let jsonData = try Data(contentsOf: fileURL)
            guard let invoicesArray = try JSONSerialization.jsonObject(with: jsonData) as? [[String: Any]] else {
                throw BackupError.invalidData
            }

            // Clear existing invoices (optional)
            try clearExistingInvoices()

            // Process and insert each invoice
            for invoiceDict in invoicesArray {
                guard let idString = invoiceDict["id"] as? String,
                      let id = UUID(uuidString: idString),
                      let number = invoiceDict["number"] as? String,
                      let clientName = invoiceDict["clientName"] as? String,
                      let clientAddress = invoiceDict["clientAddress"] as? String,
                      let statusRawValue = invoiceDict["status"] as? String,
                      let status = Invoice.Status(rawValue: statusRawValue),
                      let documentType = invoiceDict["documentType"] as? String,
                      let dateCreatedTimestamp = invoiceDict["dateCreated"] as? Double,
                      let dueDateTimestamp = invoiceDict["dueDate"] as? Double,
                      let discount = invoiceDict["discount"] as? Double,
                      let discountType = invoiceDict["discountType"] as? String,
                      let taxRate = invoiceDict["taxRate"] as? Double,
                      // Unused variables replaced with _
                      let _ = invoiceDict["subtotal"] as? Double,
                      let _ = invoiceDict["tax"] as? Double,
                      let _ = invoiceDict["totalAmount"] as? Double,
                      let notes = invoiceDict["notes"] as? String,
                      let templateType = invoiceDict["templateType"] as? String,
                      let createdAtTimestamp = invoiceDict["createdAt"] as? Double,
                      let updatedAtTimestamp = invoiceDict["updatedAt"] as? Double,
                      let itemsArray = invoiceDict["items"] as? [[String: Any]]
                else {
                    print("Skipping invalid invoice entry")
                    continue
                }

                // Process invoice items first
                var invoiceItems: [InvoiceItem] = []

                for itemDict in itemsArray {
                    guard let itemIdString = itemDict["id"] as? String,
                          let itemId = UUID(uuidString: itemIdString),
                          let itemName = itemDict["name"] as? String,
                          let quantity = itemDict["quantity"] as? Int,
                          let unitPrice = itemDict["unitPrice"] as? Double,
                          let itemTax = itemDict["tax"] as? Double,
                          let itemDiscount = itemDict["discount"] as? Double,
                          let itemTotalAmount = itemDict["totalAmount"] as? Double
                    else {
                        continue
                    }

                    let invoiceItem = InvoiceItem(
                        name: itemName,
                        description: itemDict["description"] as? String,
                        quantity: quantity,
                        unitPrice: unitPrice,
                        tax: itemTax,
                        discount: itemDiscount
                    )

                    // Restore ID and total
                    invoiceItem.id = itemId
                    invoiceItem.totalAmount = itemTotalAmount

                    invoiceItems.append(invoiceItem)
                }

                // Now create the invoice
                let invoice = Invoice(
                    number: number,
                    clientName: clientName,
                    clientAddress: clientAddress,
                    clientEmail: invoiceDict["clientEmail"] as? String,
                    clientPhone: invoiceDict["clientPhone"] as? String,
                    status: status,
                    paymentMethod: invoiceDict["paymentMethod"] as? String,
                    documentType: documentType,
                    dateCreated: Date(timeIntervalSince1970: dateCreatedTimestamp),
                    dueDate: Date(timeIntervalSince1970: dueDateTimestamp),
                    items: invoiceItems,
                    discount: discount,
                    discountType: discountType,
                    taxRate: taxRate,
                    notes: notes,
                    headerNote: invoiceDict["headerNote"] as? String,
                    footerNote: invoiceDict["footerNote"] as? String,
                    bankingInfo: invoiceDict["bankingInfo"] as? String,
                    templateType: templateType
                )

                // Restore ID and dates
                invoice.id = id
                invoice.createdAt = Date(timeIntervalSince1970: createdAtTimestamp)
                invoice.updatedAt = Date(timeIntervalSince1970: updatedAtTimestamp)

                // Restore linking relationship to invoice for each item
                for item in invoiceItems {
                    item.invoice = invoice
                }

                // Handle signature if present
                if let signatureString = invoiceDict["signature"] as? String,
                   let signatureData = Data(base64Encoded: signatureString) {
                    invoice.signature = signatureData
                }

                // Process custom fields if any
                if let customFieldsArray = invoiceDict["customFields"] as? [[String: Any]] {
                    var customFields: [CustomInvoiceField] = []

                    for fieldDict in customFieldsArray {
                        guard let fieldIdString = fieldDict["id"] as? String,
                              let fieldId = UUID(uuidString: fieldIdString),
                              let fieldName = fieldDict["name"] as? String,
                              let fieldValue = fieldDict["value"] as? String
                        else {
                            continue
                        }

                        let customField = CustomInvoiceField(
                            name: fieldName,
                            value: fieldValue
                        )

                        // Restore ID and link to invoice
                        customField.id = fieldId
                        customField.invoice = invoice

                        customFields.append(customField)
                    }

                    invoice.customFields = customFields
                }

                // Restore QR code and barcode data
                invoice.qrCodeData = invoiceDict["qrCodeData"] as? String
                invoice.barcodeData = invoiceDict["barcodeData"] as? String

                // Insert into database
                modelContext.insert(invoice)
            }

            try modelContext.save()
        } catch {
            print("Error importing invoices: \(error)")
            throw BackupError.importFailed("Failed to import invoices: \(error.localizedDescription)")
        }
    }

    private func importEstimates(from fileURL: URL) async throws {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            print("Estimates file not found, skipping import")
            return
        }

        do {
            let jsonData = try Data(contentsOf: fileURL)
            guard let estimatesArray = try JSONSerialization.jsonObject(with: jsonData) as? [[String: Any]] else {
                throw BackupError.invalidData
            }

            // Clear existing estimates (optional)
            try clearExistingEstimates()

            // Process and insert each estimate
            for estimateDict in estimatesArray {
                guard let idString = estimateDict["id"] as? String,
                      let id = UUID(uuidString: idString),
                      let number = estimateDict["number"] as? String,
                      let clientName = estimateDict["clientName"] as? String,
                      let clientAddress = estimateDict["clientAddress"] as? String,
                      let statusRawValue = estimateDict["status"] as? String,
                      let status = Estimate.Status(rawValue: statusRawValue),
                      let dateCreatedTimestamp = estimateDict["dateCreated"] as? Double,
                      let expiryDateTimestamp = estimateDict["expiryDate"] as? Double,
                      let discount = estimateDict["discount"] as? Double,
                      let discountType = estimateDict["discountType"] as? String,
                      let taxRate = estimateDict["taxRate"] as? Double,
                      // Unused variables replaced with _
                      let _ = estimateDict["subtotal"] as? Double,
                      let _ = estimateDict["tax"] as? Double,
                      let _ = estimateDict["totalAmount"] as? Double,
                      let notes = estimateDict["notes"] as? String,
                      let templateType = estimateDict["templateType"] as? String,
                      let createdAtTimestamp = estimateDict["createdAt"] as? Double,
                      let updatedAtTimestamp = estimateDict["updatedAt"] as? Double,
                      let itemsArray = estimateDict["items"] as? [[String: Any]]
                else {
                    print("Skipping invalid estimate entry")
                    continue
                }

                // Process estimate items first
                var estimateItems: [EstimateItem] = []

                for itemDict in itemsArray {
                    guard let itemIdString = itemDict["id"] as? String,
                          let itemId = UUID(uuidString: itemIdString),
                          let itemName = itemDict["name"] as? String,
                          let quantity = itemDict["quantity"] as? Int,
                          let unitPrice = itemDict["unitPrice"] as? Double,
                          let itemTax = itemDict["tax"] as? Double,
                          let itemDiscount = itemDict["discount"] as? Double,
                          let itemTotalAmount = itemDict["totalAmount"] as? Double
                    else {
                        continue
                    }

                    let estimateItem = EstimateItem(
                        name: itemName,
                        description: itemDict["description"] as? String,
                        quantity: quantity,
                        unitPrice: unitPrice,
                        tax: itemTax,
                        discount: itemDiscount
                    )

                    // Restore ID and total
                    estimateItem.id = itemId
                    estimateItem.totalAmount = itemTotalAmount

                    estimateItems.append(estimateItem)
                }

                // Now create the estimate
                let estimate = Estimate(
                    number: number,
                    clientName: clientName,
                    clientAddress: clientAddress,
                    clientEmail: estimateDict["clientEmail"] as? String,
                    clientPhone: estimateDict["clientPhone"] as? String,
                    status: status,
                    dateCreated: Date(timeIntervalSince1970: dateCreatedTimestamp),
                    expiryDate: Date(timeIntervalSince1970: expiryDateTimestamp),
                    items: estimateItems,
                    discount: discount,
                    discountType: discountType,
                    taxRate: taxRate,
                    notes: notes,
                    headerNote: estimateDict["headerNote"] as? String,
                    footerNote: estimateDict["footerNote"] as? String,
                    templateType: templateType
                )

                // Restore ID and dates
                estimate.id = id
                estimate.createdAt = Date(timeIntervalSince1970: createdAtTimestamp)
                estimate.updatedAt = Date(timeIntervalSince1970: updatedAtTimestamp)

                // Restore linking relationship to estimate for each item
                for item in estimateItems {
                    item.estimate = estimate
                }

                // Process custom fields if any
                if let customFieldsArray = estimateDict["customFields"] as? [[String: Any]] {
                    var customFields: [CustomEstimateField] = []

                    for fieldDict in customFieldsArray {
                        guard let fieldIdString = fieldDict["id"] as? String,
                              let fieldId = UUID(uuidString: fieldIdString),
                              let fieldName = fieldDict["name"] as? String,
                              let fieldValue = fieldDict["value"] as? String
                        else {
                            continue
                        }

                        let customField = CustomEstimateField(
                            name: fieldName,
                            value: fieldValue
                        )

                        // Restore ID and link to estimate
                        customField.id = fieldId
                        customField.estimate = estimate

                        customFields.append(customField)
                    }

                    estimate.customFields = customFields
                }

                // Insert into database
                modelContext.insert(estimate)
            }

            try modelContext.save()
        } catch {
            print("Error importing estimates: \(error)")
            throw BackupError.importFailed("Failed to import estimates: \(error.localizedDescription)")
        }
    }

    private func importSettings(from fileURL: URL) async throws {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            print("Settings file not found, skipping import")
            return
        }

        do {
            let jsonData = try Data(contentsOf: fileURL)
            guard let settingsDict = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
                throw BackupError.invalidData
            }

            let userDefaults = UserDefaults.standard

            // Restore each setting
            for (key, value) in settingsDict {
                // Handle special cases
                if key == "companyLogo", let logoDataString = value as? String,
                   let logoData = Data(base64Encoded: logoDataString) {
                    userDefaults.set(logoData, forKey: key)
                } else {
                    userDefaults.set(value, forKey: key)
                }
            }

            // Make sure settings are saved
            userDefaults.synchronize()
        } catch {
            print("Error importing settings: \(error)")
            throw BackupError.importFailed("Failed to import settings: \(error.localizedDescription)")
        }
    }

    // MARK: - Helper Methods

    private func clearExistingItems() throws {
        let itemDescriptor = FetchDescriptor<Item>()
        let items = try modelContext.fetch(itemDescriptor)

        for item in items {
            modelContext.delete(item)
        }

        try modelContext.save()
    }

    private func clearExistingCategories() throws {
        let categoryDescriptor = FetchDescriptor<Category>()
        let categories = try modelContext.fetch(categoryDescriptor)

        for category in categories {
            // This will also delete related custom fields due to cascade relationship
            modelContext.delete(category)
        }

        try modelContext.save()
    }

    private func clearExistingClients() throws {
        let clientDescriptor = FetchDescriptor<Client>()
        let clients = try modelContext.fetch(clientDescriptor)

        for client in clients {
            modelContext.delete(client)
        }

        try modelContext.save()
    }

    private func clearExistingSuppliers() throws {
        let supplierDescriptor = FetchDescriptor<Supplier>()
        let suppliers = try modelContext.fetch(supplierDescriptor)

        for supplier in suppliers {
            modelContext.delete(supplier)
        }

        try modelContext.save()
    }

    private func clearExistingInvoices() throws {
        let invoiceDescriptor = FetchDescriptor<Invoice>()
        let invoices = try modelContext.fetch(invoiceDescriptor)

        for invoice in invoices {
            modelContext.delete(invoice)
        }

        try modelContext.save()
    }

    private func clearExistingEstimates() throws {
        let estimateDescriptor = FetchDescriptor<Estimate>()
        let estimates = try modelContext.fetch(estimateDescriptor)

        for estimate in estimates {
            modelContext.delete(estimate)
        }

        try modelContext.save()
    }
}