import SwiftUI
import SwiftData
import UniformTypeIdentifiers
import MobileCoreServices

struct BackupRestoreView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var isExporting = false
    @State private var isImporting = false
    @State private var alertMessage = ""
    @State private var showingAlert = false
    @State private var showingConfirmation = false
    @State private var operationMessage = ""
    @State private var progressValue: Double = 0
    @State private var isProcessing = false
    @State private var backupURL: URL?
    @State private var showingShareSheet = false
    @State private var showingPasswordPrompt = false
    @State private var backupPassword = ""
    @State private var confirmBackupPassword = ""
    @State private var decryptionPassword = ""
    @State private var isPasswordProtected = false
    @State private var passwordError = ""
    @State private var showingPasswordError = false
    @State private var showingBackupFiles = false
    @State private var backupFiles: [URL] = []
    @State private var selectedBackupFile: URL?

    // Computed property to get the backup service
    private var backupService: BackupService {
        BackupService(modelContext: modelContext)
    }

    // Computed property to check if a backup reminder should be shown
    private var shouldShowBackupReminder: Bool {
        backupService.shouldShowBackupReminder()
    }

    // Computed property to get the last backup date
    private var lastBackupDate: Date? {
        backupService.lastBackupDate
    }

    // Computed property to get the backup reminder interval
    private var backupReminderInterval: Int {
        get { backupService.backupReminderInterval }
        set { backupService.backupReminderInterval = newValue }
    }

    var body: some View {
        NavigationStack {
            List {
                // Backup reminder section
                if shouldShowBackupReminder {
                    Section {
                        HStack {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundColor(.orange)
                                .font(.title2)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Backup Reminder")
                                    .font(.headline)

                                if let lastBackup = lastBackupDate {
                                    Text("Last backup was \(timeAgoString(from: lastBackup))")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                } else {
                                    Text("You haven't created a backup yet")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }

                            Spacer()

                            Button(action: {
                                showingPasswordPrompt = true
                            }) {
                                Text("Backup Now")
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(Color.orange)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }

                Section {
                    HStack {
                        Image(systemName: "arrow.up.doc")
                            .foregroundColor(.blue)
                            .font(.title2)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Export Data")
                                .font(.headline)

                            Text("Create a full backup of all your data")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            if let lastBackup = lastBackupDate {
                                Text("Last backup: \(dateFormatter.string(from: lastBackup))")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }

                        Spacer()

                        Button(action: {
                            showingPasswordPrompt = true
                        }) {
                            Text("Export")
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                        .disabled(isProcessing)
                    }
                    .padding(.vertical, 8)

                    // Backup settings
                    NavigationLink(destination: BackupSettingsView(backupService: backupService)) {
                        HStack {
                            Image(systemName: "gear")
                                .foregroundColor(.gray)
                                .font(.title2)

                            Text("Backup Settings")
                                .font(.headline)

                            Spacer()
                        }
                        .padding(.vertical, 8)
                    }

                    // Manage backups
                    Button(action: {
                        loadBackupFiles()
                        showingBackupFiles = true
                    }) {
                        HStack {
                            Image(systemName: "folder")
                                .foregroundColor(.gray)
                                .font(.title2)

                            Text("Manage Backup Files")
                                .font(.headline)

                            Spacer()

                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                        .padding(.vertical, 8)
                    }
                } header: {
                    Text("Backup")
                }

                Section {
                    HStack {
                        Image(systemName: "arrow.down.doc")
                            .foregroundColor(.red)
                            .font(.title2)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Import Data")
                                .font(.headline)

                            Text("Restore from a backup file")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Text("This will replace all current data")
                                .font(.caption2)
                                .foregroundColor(.red)
                        }

                        Spacer()

                        Button(action: {
                            loadBackupFiles()
                            showingBackupFiles = true
                        }) {
                            Text("Select Backup")
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.red)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                        .disabled(isProcessing)
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("Restore")
                } footer: {
                    Text("Warning: Restoring will replace all current data with the backup data.")
                }

                if isProcessing {
                    Section {
                        VStack(alignment: .center, spacing: 16) {
                            ProgressView(value: progressValue, total: 1.0)
                                .progressViewStyle(LinearProgressViewStyle())

                            Text(operationMessage)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .navigationTitle("Backup & Restore")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert(isPresented: $showingAlert) {
                Alert(
                    title: Text("Notification"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
            .confirmationDialog(
                "Are you sure you want to restore data?",
                isPresented: $showingConfirmation,
                titleVisibility: .visible
            ) {
                Button("Restore", role: .destructive) {
                    startRestore()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This will replace all existing data with the backup. This action cannot be undone.")
            }
            .sheet(isPresented: $showingShareSheet) {
                if let url = backupURL {
                    ShareSheet(items: [url])
                }
            }
            .sheet(isPresented: $showingPasswordPrompt) {
                PasswordPromptView(
                    isPasswordProtected: $isPasswordProtected,
                    password: $backupPassword,
                    confirmPassword: $confirmBackupPassword,
                    passwordError: $passwordError,
                    showingError: $showingPasswordError,
                    onCancel: { showingPasswordPrompt = false },
                    onConfirm: {
                        showingPasswordPrompt = false
                        startBackup()
                    }
                )
            }
            .sheet(isPresented: $showingBackupFiles) {
                BackupFilesView(
                    backupFiles: backupFiles,
                    onSelect: { url in
                        selectedBackupFile = url
                        showingBackupFiles = false
                        // Check if backup is encrypted
                        checkBackupEncryption(url: url)
                    },
                    onCancel: { showingBackupFiles = false }
                )
            }
        }
    }

    private func startBackup() {
        isProcessing = true
        operationMessage = "Creating backup..."
        progressValue = 0.1

        // Determine if we should use password protection
        let password = isPasswordProtected ? backupPassword : nil

        Task {
            do {
                // Simulate progress for better UX
                for i in 2...8 {
                    try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
                    await MainActor.run {
                        progressValue = Double(i) / 10.0
                    }
                }

                // Perform the actual backup with optional password
                let url = try await backupService.exportAllData(password: password)

                // Final update on main thread
                await MainActor.run {
                    progressValue = 1.0
                    backupURL = url
                    isProcessing = false

                    // Reset password fields
                    backupPassword = ""
                    confirmBackupPassword = ""

                    // Show share sheet
                    showingShareSheet = true

                    // Show success message
                    alertMessage = "Backup created successfully" + (isPasswordProtected ? " (Password Protected)" : "")
                    showingAlert = true
                }
            } catch {
                await MainActor.run {
                    isProcessing = false
                    alertMessage = "Failed to create backup: \(error.localizedDescription)"
                    showingAlert = true
                }
            }
        }
    }

    private func startRestore() {
        // Load backup files and show the backup files view
        loadBackupFiles()
        showingBackupFiles = true
    }

    private func loadBackupFiles() {
        Task { @MainActor in
            do {
                backupFiles = try backupService.getBackupFiles().sorted { $0.lastPathComponent > $1.lastPathComponent }
            } catch {
                alertMessage = "Failed to load backup files: \(error.localizedDescription)"
                showingAlert = true
            }
        }
    }

    private func checkBackupEncryption(url: URL) {
        Task { @MainActor in
            do {
                let isEncrypted = try backupService.isBackupEncrypted(at: url)

                if isEncrypted {
                    // Show password prompt for decryption
                    decryptionPassword = ""
                    showingPasswordPrompt = true
                } else {
                    // Proceed with restore without password
                    showingConfirmation = true
                }
            } catch {
                alertMessage = "Failed to check backup file: \(error.localizedDescription)"
                showingAlert = true
            }
        }
    }

    private func performRestore(from url: URL) {
        guard let selectedFile = selectedBackupFile else {
            alertMessage = "No backup file selected"
            showingAlert = true
            return
        }

        isProcessing = true
        operationMessage = "Restoring data from backup..."
        progressValue = 0.2

        // Get the password if needed
        let password = decryptionPassword.isEmpty ? nil : decryptionPassword

        Task { @MainActor in
            do {
                // Simulate progress for better UX
                for i in 3...8 {
                    try await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
                    progressValue = Double(i) / 10.0
                }

                // Perform the actual restore with optional password
                try await backupService.importAllData(from: selectedFile, password: password)

                // Final update
                progressValue = 1.0
                isProcessing = false
                alertMessage = "Data restored successfully. The app will now close."
                showingAlert = true

                // Let user see the success message before closing app
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    // Force app to restart to apply restored data completely
                    exit(0)
                }
            } catch {
                isProcessing = false
                alertMessage = "Failed to restore backup: \(error.localizedDescription)"
                showingAlert = true
            }
        }
    }
}

// MARK: - Helper Methods

private extension BackupRestoreView {
    // Format a date as a time ago string (e.g., "2 days ago")
    func timeAgoString(from date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.day, .hour, .minute], from: date, to: now)

        if let days = components.day, days > 0 {
            return days == 1 ? "yesterday" : "\(days) days ago"
        } else if let hours = components.hour, hours > 0 {
            return hours == 1 ? "1 hour ago" : "\(hours) hours ago"
        } else if let minutes = components.minute, minutes > 0 {
            return minutes == 1 ? "1 minute ago" : "\(minutes) minutes ago"
        } else {
            return "just now"
        }
    }

    // Date formatter for displaying dates
    var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }
}

// MARK: - Helper Views

// Helper for sharing files
struct ShareSheet: UIViewControllerRepresentable {
    var items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// Password prompt view for backup encryption/decryption
struct PasswordPromptView: View {
    @Binding var isPasswordProtected: Bool
    @Binding var password: String
    @Binding var confirmPassword: String
    @Binding var passwordError: String
    @Binding var showingError: Bool

    var onCancel: () -> Void
    var onConfirm: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("Password Protect Backup", isOn: $isPasswordProtected)
                        .padding(.vertical, 8)
                } footer: {
                    Text("Password protection adds an extra layer of security to your backup file.")
                }

                if isPasswordProtected {
                    Section {
                        SecureField("Password", text: $password)
                            .textContentType(.newPassword)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)

                        SecureField("Confirm Password", text: $confirmPassword)
                            .textContentType(.newPassword)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                    } footer: {
                        Text("Remember this password! If you forget it, you won't be able to restore your data.")
                            .foregroundColor(.red)
                    }
                }

                if showingError && !passwordError.isEmpty {
                    Section {
                        Text(passwordError)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Backup Options")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Continue") {
                        if isPasswordProtected {
                            // Validate password
                            if password.isEmpty {
                                passwordError = "Password cannot be empty"
                                showingError = true
                                return
                            }

                            if password != confirmPassword {
                                passwordError = "Passwords do not match"
                                showingError = true
                                return
                            }

                            if password.count < 6 {
                                passwordError = "Password must be at least 6 characters"
                                showingError = true
                                return
                            }
                        }

                        onConfirm()
                    }
                }
            }
        }
    }
}

// Backup files list view
struct BackupFilesView: View {
    var backupFiles: [URL]
    var onSelect: (URL) -> Void
    var onCancel: () -> Void

    @State private var showingDeleteConfirmation = false
    @State private var fileToDelete: URL?
    @Environment(\.modelContext) private var modelContext

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }

    var body: some View {
        NavigationStack {
            List {
                if backupFiles.isEmpty {
                    Section {
                        Text("No backup files found")
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    }
                } else {
                    Section {
                        ForEach(backupFiles, id: \.lastPathComponent) { file in
                            Button(action: {
                                onSelect(file)
                            }) {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(file.lastPathComponent)
                                            .font(.headline)

                                        if let attributes = try? FileManager.default.attributesOfItem(atPath: file.path),
                                           let creationDate = attributes[.creationDate] as? Date {
                                            Text(dateFormatter.string(from: creationDate))
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.gray)
                                }
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    fileToDelete = file
                                    showingDeleteConfirmation = true
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Backup File")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                    }
                }
            }
            .confirmationDialog(
                "Are you sure you want to delete this backup?",
                isPresented: $showingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    if let fileURL = fileToDelete {
                        deleteBackupFile(fileURL)
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This action cannot be undone.")
            }
        }
    }

    private func deleteBackupFile(_ fileURL: URL) {
        // Create a backup service to delete the file
        let backupService = BackupService(modelContext: modelContext)

        Task { @MainActor in
            do {
                try backupService.deleteBackupFile(at: fileURL)
                // Notify the parent view to refresh the list
                onCancel()
            } catch {
                print("Error deleting backup file: \(error)")
            }
        }
    }
}

// Backup settings view
struct BackupSettingsView: View {
    var backupService: BackupService

    @State private var reminderInterval: Int
    @State private var isPasswordEnabled: Bool
    @State private var showingPasswordSheet = false
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var passwordError = ""
    @State private var showingPasswordError = false

    init(backupService: BackupService) {
        self.backupService = backupService
        _reminderInterval = State(initialValue: backupService.backupReminderInterval)
        _isPasswordEnabled = State(initialValue: backupService.isBackupPasswordEnabled)
    }

    var body: some View {
        Form {
            Section {
                Picker("Remind me to backup", selection: $reminderInterval) {
                    Text("Every day").tag(1)
                    Text("Every 3 days").tag(3)
                    Text("Every week").tag(7)
                    Text("Every 2 weeks").tag(14)
                    Text("Every month").tag(30)
                    Text("Never").tag(0)
                }
                .onChange(of: reminderInterval) { oldValue, newValue in
                    backupService.backupReminderInterval = newValue
                }
            } header: {
                Text("Backup Reminders")
            }

            Section {
                Toggle("Password Protection", isOn: $isPasswordEnabled)
                    .onChange(of: isPasswordEnabled) { oldValue, newValue in
                        if newValue {
                            // Show password setup sheet
                            showingPasswordSheet = true
                        } else {
                            // Disable password protection
                            backupService.setBackupPassword(nil)
                        }
                    }

                if isPasswordEnabled {
                    Button("Change Password") {
                        showingPasswordSheet = true
                    }
                }
            } header: {
                Text("Backup Security")
            } footer: {
                Text("Password protection encrypts your backup files. You'll need the password to restore your data.")
            }

            if let lastBackup = backupService.lastBackupDate {
                Section {
                    HStack {
                        Text("Date")
                        Spacer()
                        Text(dateFormatter.string(from: lastBackup))
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("Last Backup")
                }
            }
        }
        .navigationTitle("Backup Settings")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingPasswordSheet) {
            PasswordSetupView(onSave: { password in
                backupService.setBackupPassword(password)
                isPasswordEnabled = backupService.isBackupPasswordEnabled
            }, onCancel: {
                isPasswordEnabled = backupService.isBackupPasswordEnabled
            })
        }
    }

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }
}

// Password setup view
struct PasswordSetupView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showingError = false
    @State private var errorMessage = ""

    var onSave: (String) -> Void
    var onCancel: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    SecureField("Password", text: $password)
                        .textContentType(.newPassword)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)

                    SecureField("Confirm Password", text: $confirmPassword)
                        .textContentType(.newPassword)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                } footer: {
                    Text("Remember this password! If you forget it, you won't be able to restore your data.")
                        .foregroundColor(.red)
                }

                if showingError {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Set Backup Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if validatePassword() {
                            onSave(password)
                            dismiss()
                        }
                    }
                }
            }
        }
    }

    private func validatePassword() -> Bool {
        if password.isEmpty {
            errorMessage = "Password cannot be empty"
            showingError = true
            return false
        }

        if password != confirmPassword {
            errorMessage = "Passwords do not match"
            showingError = true
            return false
        }

        if password.count < 6 {
            errorMessage = "Password must be at least 6 characters"
            showingError = true
            return false
        }

        return true
    }
}

// Document picker for selecting backup files
struct DocumentPicker: UIViewControllerRepresentable {
    var callback: (URL) -> Void

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.item])
        picker.allowsMultipleSelection = false
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPicker

        init(_ parent: DocumentPicker) {
            self.parent = parent
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            parent.callback(url)
        }
    }
}