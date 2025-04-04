import SwiftUI

struct PrivacyView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    privacySection(
                        title: "Privacy Policy",
                        content: "This Privacy Policy explains how Stockly handles your data when you use our application."
                    )

                    privacySection(
                        title: "No Data Collection",
                        content: "Stockly does NOT collect, transmit, or store any of your data on our servers. All data you enter into the app (including inventory, invoices, estimates, client information, and business details) is stored locally on your device only."
                    )

                    privacySection(
                        title: "Local Storage Only",
                        content: "All your data is stored exclusively on your device using Apple's SwiftData framework. We do not have access to your data, nor do we transmit it to any external servers or third parties."
                    )

                    privacySection(
                        title: "No Analytics or Tracking",
                        content: "Stockly does not include any analytics, tracking, or monitoring tools. We do not collect usage statistics, crash reports, or any other information about how you use the app."
                    )

                    privacySection(
                        title: "Backups",
                        content: "Any backups you create using the app's backup feature are stored locally on your device. You are responsible for managing and securing these backup files."
                    )

                    privacySection(
                        title: "Your Responsibility",
                        content: "Since all data is stored locally on your device, you are responsible for the security of your data. We recommend using device-level security features (such as passcodes, Face ID, or Touch ID) to protect access to your device and the app."
                    )

                    privacySection(
                        title: "Data Loss Disclaimer",
                        content: "THE DEVELOPER OF STOCKLY TAKES NO RESPONSIBILITY FOR ANY DATA LOSS OR CORRUPTION THAT MAY OCCUR WHILE USING THE APP. You are solely responsible for creating regular backups of your data. In the event of app malfunction, device failure, or any other issue that results in data loss, the developer cannot and will not be held liable."
                    )

                    privacySection(
                        title: "Third-Party Services",
                        content: "Stockly does not integrate with any third-party services that would collect your data. Any future integrations will be clearly communicated, and you will have the option to opt out."
                    )

                    privacySection(
                        title: "Changes to This Policy",
                        content: "We may update our Privacy Policy from time to time. It is your responsibility to check this Privacy Policy periodically for changes. Your continued use of the app after any changes to this Privacy Policy will constitute your acceptance of such changes."
                    )

                    privacySection(
                        title: "Contact Us",
                        content: "If you have any questions about this Privacy Policy, please contact us at:\n\ntucodevelopmentyvr@gmail.com"
                    )

                    Text("Last updated: \(formattedDate())")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 20)
                }
                .padding()
            }
            .navigationTitle("Privacy Policy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }

    // Helper function for consistent privacy section formatting
    private func privacySection(title: String, content: String) -> some View {
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
            } else if title == "Data Loss Disclaimer" {
                Text(content)
                    .font(.body)
                    .foregroundColor(.red)
                    .fontWeight(.medium)
            } else {
                Text(content)
                    .font(.body)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
    }

    // Helper function to format the current date
    private func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: Date())
    }
}

#Preview {
    PrivacyView()
}
