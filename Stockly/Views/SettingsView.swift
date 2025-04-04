import SwiftUI

// Extension for theme colors
extension Color {
    static let navy = Color(red: 0, green: 0.18, blue: 0.39)
    static let darkBlue = Color(red: 0, green: 0.32, blue: 0.65)
}

// Theme styling options
enum HeaderStyle {
    case plain, curved, angled, bordered, gradient
}

enum LineStyle {
    case solid, dotted, thin, doubleRule, coloredRule
}

enum FontStyle {
    case standard, rounded, light, serif, custom
}

// Theme preview component
struct ThemePreviewView: View {
    let headerColor: Color
    let accentColor: Color
    let name: String
    let headerStyle: HeaderStyle
    let lineStyle: LineStyle
    let fontStyle: FontStyle

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with different styles
            headerView

            // Content preview with different styles
            VStack(alignment: .leading, spacing: 8) {
                // Company info
                HStack {
                    logoView

                    VStack(alignment: .leading) {
                        Text("Company Name")
                            .font(fontForStyle(size: 7))
                            .fontWeight(fontWeightForStyle)

                        Text("123 Business St")
                            .font(fontForStyle(size: 6))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.bottom, 2)

                // Line items example with styled dividers
                VStack(spacing: 4) {
                    HStack {
                        Text("Item")
                            .font(fontForStyle(size: 6))
                            .fontWeight(fontWeightForStyle)
                        Spacer()
                        Text("Total")
                            .font(fontForStyle(size: 6))
                            .fontWeight(fontWeightForStyle)
                    }
                    .padding(.horizontal, 5)
                    .padding(.vertical, 3)
                    .background(accentColor.opacity(0.1))

                    dividerView

                    ForEach(1...2, id: \.self) { i in
                        HStack {
                            Text("Product \(i)")
                                .font(fontForStyle(size: 6))
                            Spacer()
                            Text("$\(i)00.00")
                                .font(fontForStyle(size: 6))
                        }
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                    }
                }

                Spacer()

                // Total section with styled elements
                HStack {
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text("Total: $300.00")
                            .font(fontForStyle(size: 7))
                            .fontWeight(.bold)
                            .foregroundColor(accentColor)
                            .padding(4)
                            .background(
                                totalBackgroundView
                            )
                    }
                }
            }
            .padding(8)
            .background(Color.white)
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
        .frame(height: 130)
    }

    // Custom header view based on style
    private var headerView: some View {
        Group {
            switch headerStyle {
            case .plain:
                plainHeaderView
            case .curved:
                curvedHeaderView
            case .angled:
                angledHeaderView
            case .bordered:
                borderedHeaderView
            case .gradient:
                gradientHeaderView
            }
        }
    }

    // Different header styles
    private var plainHeaderView: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("INVOICE")
                .font(fontForStyle(size: 8))
                .fontWeight(.bold)
                .foregroundColor(.white)

            Text(name + " Theme")
                .font(fontForStyle(size: 6))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(headerColor)
    }

    private var curvedHeaderView: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("INVOICE")
                .font(fontForStyle(size: 8))
                .fontWeight(.bold)
                .foregroundColor(.white)

            Text(name + " Theme")
                .font(fontForStyle(size: 6))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(headerColor)
                .padding(.top, -10)
                .padding(.bottom, -5)
        )
    }

    private var angledHeaderView: some View {
        ZStack(alignment: .topLeading) {
            Path { path in
                path.move(to: CGPoint(x: 0, y: 0))
                path.addLine(to: CGPoint(x: 1000, y: 0))
                path.addLine(to: CGPoint(x: 1000, y: 30))
                path.addLine(to: CGPoint(x: 0, y: 50))
                path.closeSubpath()
            }
            .fill(headerColor)

            VStack(alignment: .leading, spacing: 5) {
                Text("INVOICE")
                    .font(fontForStyle(size: 8))
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Text(name + " Theme")
                    .font(fontForStyle(size: 6))
                    .foregroundColor(.white)
            }
            .padding(8)
        }
        .frame(height: 40)
    }

    private var borderedHeaderView: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("INVOICE")
                .font(fontForStyle(size: 8))
                .fontWeight(.bold)
                .foregroundColor(.white)

            Text(name + " Theme")
                .font(fontForStyle(size: 6))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(headerColor)
        .overlay(
            Rectangle()
                .strokeBorder(accentColor, lineWidth: 2)
        )
    }

    private var gradientHeaderView: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("INVOICE")
                .font(fontForStyle(size: 8))
                .fontWeight(.bold)
                .foregroundColor(.white)

            Text(name + " Theme")
                .font(fontForStyle(size: 6))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(
            LinearGradient(gradient: Gradient(colors: [headerColor, accentColor]), startPoint: .leading, endPoint: .trailing)
        )
    }

    // Divider style based on LineStyle
    private var dividerView: some View {
        Group {
            switch lineStyle {
            case .solid:
                Divider()
            case .dotted:
                DottedLine(color: accentColor)
                    .frame(height: 1)
                    .padding(.vertical, 2)
            case .thin:
                Divider()
                    .background(Color.gray.opacity(0.3))
                    .frame(height: 0.5)
            case .doubleRule:
                VStack(spacing: 2) {
                    Divider()
                    Divider()
                }
                .padding(.vertical, 2)
            case .coloredRule:
                Rectangle()
                    .fill(accentColor)
                    .frame(height: 2)
                    .padding(.vertical, 2)
            }
        }
    }

    // Logo style
    private var logoView: some View {
        Group {
            switch headerStyle {
            case .plain, .bordered:
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 25, height: 25)
            case .curved:
                Circle()
                    .fill(headerColor.opacity(0.2))
                    .frame(width: 25, height: 25)
            case .angled:
                Diamond()
                    .fill(headerColor.opacity(0.2))
                    .frame(width: 25, height: 25)
            case .gradient:
                RoundedRectangle(cornerRadius: 3)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [headerColor.opacity(0.5), accentColor.opacity(0.5)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 25, height: 25)
            }
        }
    }

    // Total background based on theme
    private var totalBackgroundView: some View {
        Group {
            switch headerStyle {
            case .plain, .bordered:
                EmptyView()
            case .curved:
                RoundedRectangle(cornerRadius: 4)
                    .fill(accentColor.opacity(0.1))
            case .angled:
                Rectangle()
                    .fill(accentColor.opacity(0.1))
            case .gradient:
                LinearGradient(
                    gradient: Gradient(colors: [headerColor.opacity(0.1), accentColor.opacity(0.1)]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            }
        }
    }

    // Font style helpers
    private func fontForStyle(size: CGFloat) -> Font {
        switch fontStyle {
        case .standard:
            return .system(size: size)
        case .rounded:
            return .system(size: size, design: .rounded)
        case .light:
            return .system(size: size, design: .default).weight(.light)
        case .serif:
            return .system(size: size, design: .serif)
        case .custom:
            return .system(size: size, design: .rounded).italic()
        }
    }

    private var fontWeightForStyle: Font.Weight {
        switch fontStyle {
        case .standard: return .medium
        case .rounded: return .semibold
        case .light: return .light
        case .serif: return .regular
        case .custom: return .bold
        }
    }
}

// Custom shapes for theme previews
struct Diamond: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)

        path.move(to: CGPoint(x: center.x, y: 0))
        path.addLine(to: CGPoint(x: rect.maxX, y: center.y))
        path.addLine(to: CGPoint(x: center.x, y: rect.maxY))
        path.addLine(to: CGPoint(x: 0, y: center.y))
        path.closeSubpath()

        return path
    }
}

struct DottedLine: View {
    let color: Color

    var body: some View {
        GeometryReader { geometry in
            Path { path in
                path.move(to: CGPoint(x: 0, y: 0))
                path.addLine(to: CGPoint(x: geometry.size.width, y: 0))
            }
            .stroke(style: StrokeStyle(lineWidth: 1, dash: [3]))
            .foregroundColor(color)
        }
    }
}
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
    @State private var showingBackupRestoreView = false
    @State private var showingPrivacyView = false

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

                    VStack {
                        Picker("Default Document Theme", selection: $defaultDocumentTheme) {
                            ForEach(DocumentTheme.allCases, id: \.self) { theme in
                                Text(theme.rawValue.capitalized).tag(theme.rawValue)
                            }
                        }

                        // Theme preview display
                        GroupBox(label: Text("Theme Preview")) {
                            VStack(alignment: .leading, spacing: 10) {
                                // Display a small preview image based on the selected theme
                                switch DocumentTheme(rawValue: defaultDocumentTheme) ?? .classic {
                                case .classic:
                                    // CLASSIC: Traditional centered layout with title at top
                                    ZStack {
                                        Rectangle()
                                            .fill(Color.white)
                                            .shadow(radius: 2)

                                        VStack(spacing: 0) {
                                            // Classic centered header
                                            Rectangle()
                                                .fill(Color.blue)
                                                .frame(height: 30)
                                                .overlay(
                                                    Text("INVOICE")
                                                        .font(.system(size: 14, weight: .bold))
                                                        .foregroundColor(.white)
                                                )

                                            // Content layout
                                            VStack(spacing: 4) {
                                                // Company info at top
                                                HStack {
                                                    // Logo placeholder left-aligned
                                                    RoundedRectangle(cornerRadius: 4)
                                                        .fill(Color.gray.opacity(0.2))
                                                        .frame(width: 20, height: 20)

                                                    // Company info
                                                    VStack(alignment: .leading, spacing: 1) {
                                                        Text("Your Company")
                                                            .font(.system(size: 8, weight: .medium))
                                                        Text("123 Main St")
                                                            .font(.system(size: 6))
                                                            .foregroundColor(.secondary)
                                                    }
                                                    Spacer()

                                                    // Invoice number
                                                    Text("#1001")
                                                        .font(.system(size: 8, weight: .bold))
                                                }
                                                .padding(.horizontal, 10)
                                                .padding(.top, 8)

                                                // Client info below company info
                                                HStack {
                                                    VStack(alignment: .leading, spacing: 1) {
                                                        Text("Bill To:")
                                                            .font(.system(size: 7, weight: .medium))
                                                        Text("Client Name")
                                                            .font(.system(size: 6))
                                                    }
                                                    Spacer()

                                                    // Date
                                                    VStack(alignment: .trailing, spacing: 1) {
                                                        Text("Date:")
                                                            .font(.system(size: 7))
                                                        Text("01/01/2025")
                                                            .font(.system(size: 6))
                                                    }
                                                }
                                                .padding(.horizontal, 10)
                                                .padding(.top, 4)

                                                Divider()
                                                    .padding(.horizontal, 10)
                                                    .padding(.vertical, 4)

                                                // Items
                                                VStack(spacing: 2) {
                                                    // Header
                                                    HStack {
                                                        Text("Item")
                                                            .font(.system(size: 7, weight: .bold))
                                                        Spacer()
                                                        Text("Total")
                                                            .font(.system(size: 7, weight: .bold))
                                                    }
                                                    .padding(.horizontal, 10)

                                                    // Items
                                                    ForEach(1...2, id: \.self) { i in
                                                        HStack {
                                                            Text("Product \(i)")
                                                                .font(.system(size: 6))
                                                            Spacer()
                                                            Text("$\(i)00.00")
                                                                .font(.system(size: 6))
                                                        }
                                                        .padding(.horizontal, 10)
                                                    }

                                                    // Total
                                                    HStack {
                                                        Spacer()
                                                        Text("Total: $300.00")
                                                            .font(.system(size: 8, weight: .bold))
                                                            .foregroundColor(.blue)
                                                    }
                                                    .padding(6)
                                                    .padding(.trailing, 4)
                                                }
                                            }
                                        }
                                    }
                                    .frame(width: 200, height: 140)

                                case .modern:
                                    // MODERN: Side-by-side company/client with angled header
                                    ZStack {
                                        Color.white

                                        VStack(spacing: 0) {
                                            // Modern left-aligned title with angled design
                                            ZStack(alignment: .leading) {
                                                Path { path in
                                                    path.move(to: CGPoint(x: 0, y: 0))
                                                    path.addLine(to: CGPoint(x: 200, y: 0))
                                                    path.addLine(to: CGPoint(x: 190, y: 30))
                                                    path.addLine(to: CGPoint(x: 0, y: 30))
                                                    path.closeSubpath()
                                                }
                                                .fill(Color.indigo)

                                                Text("INVOICE #1001")
                                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                                                    .foregroundColor(.white)
                                                    .padding(.leading, 10)
                                            }
                                            .frame(height: 30)

                                            // Modern content layout
                                            VStack(spacing: 5) {
                                                // Side-by-side company & client - modern horizontal layout
                                                HStack(alignment: .top, spacing: 0) {
                                                    // Company block (left)
                                                    VStack(alignment: .leading, spacing: 1) {
                                                        // Company
                                                        Text("FROM")
                                                            .font(.system(size: 6, weight: .bold))
                                                            .foregroundColor(Color.indigo)
                                                        Text("Your Company")
                                                            .font(.system(size: 7, weight: .medium, design: .rounded))
                                                        Text("123 Main St")
                                                            .font(.system(size: 6, design: .rounded))
                                                        Text("contact@email.com")
                                                            .font(.system(size: 6, design: .rounded))
                                                    }
                                                    .frame(width: 95, alignment: .leading)
                                                    .padding(5)
                                                    .background(Color.indigo.opacity(0.05))

                                                    Divider()
                                                        .background(Color.indigo)

                                                    // Client block (right)
                                                    VStack(alignment: .leading, spacing: 1) {
                                                        // Client
                                                        Text("TO")
                                                            .font(.system(size: 6, weight: .bold))
                                                            .foregroundColor(Color.purple)
                                                        Text("Client Name")
                                                            .font(.system(size: 7, weight: .medium, design: .rounded))
                                                        Text("456 Client Ave")
                                                            .font(.system(size: 6, design: .rounded))
                                                        Text("01/01/2025")
                                                            .font(.system(size: 6, design: .rounded))
                                                    }
                                                    .frame(width: 95, alignment: .leading)
                                                    .padding(5)
                                                    .background(Color.purple.opacity(0.05))
                                                }

                                                // Items with unique dotted line style
                                                VStack(spacing: 4) {
                                                    ForEach(1...2, id: \.self) { i in
                                                        HStack {
                                                            Text("Product \(i)")
                                                                .font(.system(size: 7, design: .rounded))
                                                            Spacer()
                                                            Text("$\(i)00.00")
                                                                .font(.system(size: 7, design: .rounded))
                                                        }
                                                        .padding(.horizontal, 10)

                                                        if i == 1 {
                                                            // Dotted divider
                                                            Path { path in
                                                                path.move(to: CGPoint(x: 10, y: 0))
                                                                path.addLine(to: CGPoint(x: 190, y: 0))
                                                            }
                                                            .stroke(style: StrokeStyle(lineWidth: 1, dash: [2, 2]))
                                                            .frame(height: 1)
                                                            .foregroundColor(Color.purple.opacity(0.5))
                                                        }
                                                    }

                                                    // Total - modern style
                                                    ZStack {
                                                        Rectangle()
                                                            .fill(LinearGradient(
                                                                gradient: Gradient(colors: [.indigo, .purple]),
                                                                startPoint: .leading,
                                                                endPoint: .trailing
                                                            ))
                                                            .frame(height: 24)

                                                        HStack {
                                                            Spacer()
                                                            Text("TOTAL: $300.00")
                                                                .font(.system(size: 9, weight: .bold, design: .rounded))
                                                                .foregroundColor(.white)
                                                                .padding(.trailing, 10)
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                    .frame(width: 200, height: 140)
                                    .shadow(color: Color.purple.opacity(0.3), radius: 8, x: 4, y: 4)

                                case .minimalist:
                                    // MINIMALIST: Horizontal design with right-aligned title
                                    ZStack {
                                        Color.white

                                        VStack(alignment: .leading, spacing: 0) {
                                            // Minimal header styling with right-aligned title
                                            HStack {
                                                // Left - Company name
                                                VStack(alignment: .leading) {
                                                    Text("YOUR COMPANY")
                                                        .font(.system(size: 9, weight: .light))
                                                        .kerning(1)
                                                    Text("123 Main St")
                                                        .font(.system(size: 6, weight: .light))
                                                }

                                                Spacer()

                                                // Right - Invoice title
                                                VStack(alignment: .trailing) {
                                                    Text("INVOICE")
                                                        .font(.system(size: 14, weight: .thin))
                                                        .kerning(2)
                                                    Text("#1001")
                                                        .font(.system(size: 8, weight: .light))
                                                }
                                            }
                                            .padding(.horizontal, 12)
                                            .padding(.top, 12)

                                            // Thin horizontal line
                                            Rectangle()
                                                .fill(Color.black)
                                                .frame(height: 0.5)
                                                .padding(.top, 5)

                                            // Bill To / Date section
                                            HStack(alignment: .top) {
                                                // Client info
                                                VStack(alignment: .leading, spacing: 1) {
                                                    Text("CLIENT")
                                                        .font(.system(size: 6, weight: .light))
                                                        .foregroundColor(.gray)
                                                    Text("Client Name")
                                                        .font(.system(size: 8, weight: .light))
                                                    Text("456 Client Ave")
                                                        .font(.system(size: 6, weight: .light))
                                                }

                                                Spacer()

                                                // Date info
                                                VStack(alignment: .trailing, spacing: 1) {
                                                    Text("DATE")
                                                        .font(.system(size: 6, weight: .light))
                                                        .foregroundColor(.gray)
                                                    Text("01/01/2025")
                                                        .font(.system(size: 8, weight: .light))
                                                }
                                            }
                                            .padding(.horizontal, 12)
                                            .padding(.top, 6)

                                            // Items with minimal styling
                                            VStack(spacing: 5) {
                                                // Item header
                                                HStack {
                                                    Text("ITEM")
                                                        .font(.system(size: 6, weight: .light))
                                                        .kerning(1)
                                                        .foregroundColor(.gray)
                                                    Spacer()
                                                    Text("AMOUNT")
                                                        .font(.system(size: 6, weight: .light))
                                                        .kerning(1)
                                                        .foregroundColor(.gray)
                                                }
                                                .padding(.horizontal, 12)
                                                .padding(.top, 8)

                                                // Items
                                                ForEach(1...2, id: \.self) { i in
                                                    HStack {
                                                        Text("Product \(i)")
                                                            .font(.system(size: 8, weight: .light))
                                                        Spacer()
                                                        Text("$\(i)00.00")
                                                            .font(.system(size: 8, weight: .light))
                                                    }
                                                    .padding(.horizontal, 12)
                                                }

                                                Spacer()

                                                // Minimalist total
                                                HStack {
                                                    Spacer()
                                                    VStack(alignment: .trailing) {
                                                        Rectangle()
                                                            .fill(Color.black)
                                                            .frame(width: 40, height: 0.5)

                                                        Text("$300.00")
                                                            .font(.system(size: 10, weight: .light))
                                                    }
                                                }
                                                .padding(.horizontal, 12)
                                                .padding(.bottom, 8)
                                            }
                                        }
                                    }
                                    .frame(width: 200, height: 140)
                                    .overlay(
                                        Rectangle()
                                            .stroke(Color.black, lineWidth: 0.5)
                                    )

                                case .professional:
                                    // PROFESSIONAL: Traditional business layout with header on top
                                    ZStack {
                                        // Background with subtle texture
                                        Color(red: 0.98, green: 0.98, blue: 0.98)

                                        VStack(spacing: 0) {
                                            // Professional top header with logo area
                                            HStack(spacing: 0) {
                                                // Logo box
                                                Rectangle()
                                                    .fill(Color.navy)
                                                    .frame(width: 40, height: 30)
                                                    .overlay(
                                                        Image(systemName: "building.columns")
                                                            .font(.system(size: 14))
                                                            .foregroundColor(.white)
                                                    )

                                                // Title section
                                                ZStack {
                                                    Rectangle()
                                                        .fill(Color.darkBlue)
                                                        .frame(height: 30)

                                                    HStack {
                                                        Spacer()
                                                        Text("INVOICE")
                                                            .font(.system(size: 14, weight: .bold, design: .serif))
                                                            .foregroundColor(.white)
                                                        Spacer()
                                                    }
                                                }
                                            }

                                            // Document content
                                            VStack(spacing: 0) {
                                                // Company info and invoice number in two-column layout
                                                HStack(alignment: .top) {
                                                    // Company info
                                                    VStack(alignment: .leading, spacing: 1) {
                                                        Text("Your Company, Inc.")
                                                            .font(.system(size: 9, weight: .semibold, design: .serif))
                                                        Text("123 Main Street")
                                                            .font(.system(size: 7, design: .serif))
                                                        Text("contact@email.com")
                                                            .font(.system(size: 7, design: .serif))
                                                    }

                                                    Spacer()

                                                    // Invoice details
                                                    VStack(alignment: .trailing, spacing: 1) {
                                                        Text("Invoice #1001")
                                                            .font(.system(size: 8, weight: .semibold, design: .serif))
                                                        Text("Date: 01/01/2025")
                                                            .font(.system(size: 7, design: .serif))
                                                        Text("Due: 01/31/2025")
                                                            .font(.system(size: 7, design: .serif))
                                                    }
                                                }
                                                .padding(.horizontal, 10)
                                                .padding(.vertical, 6)

                                                // Double rule divider
                                                HStack {
                                                    Rectangle()
                                                        .fill(Color.gray.opacity(0.5))
                                                        .frame(height: 0.5)
                                                }
                                                .padding(.horizontal, 10)

                                                HStack {
                                                    Rectangle()
                                                        .fill(Color.gray.opacity(0.5))
                                                        .frame(height: 0.5)
                                                }
                                                .padding(.horizontal, 10)
                                                .padding(.top, 1)

                                                // Client info box
                                                HStack {
                                                    VStack(alignment: .leading, spacing: 1) {
                                                        Text("Bill To:")
                                                            .font(.system(size: 8, weight: .semibold, design: .serif))
                                                            .foregroundColor(Color.navy)
                                                        Text("Client Name")
                                                            .font(.system(size: 7, design: .serif))
                                                        Text("456 Client Avenue")
                                                            .font(.system(size: 7, design: .serif))
                                                    }
                                                    Spacer()
                                                }
                                                .padding(.horizontal, 10)
                                                .padding(.top, 4)

                                                // Items table with bordered header
                                                VStack(spacing: 0) {
                                                    // Header
                                                    HStack {
                                                        Text("Description")
                                                            .font(.system(size: 7, weight: .semibold, design: .serif))
                                                        Spacer()
                                                        Text("Amount")
                                                            .font(.system(size: 7, weight: .semibold, design: .serif))
                                                    }
                                                    .padding(.horizontal, 10)
                                                    .padding(.vertical, 2)
                                                    .background(Color.gray.opacity(0.1))
                                                    .overlay(
                                                        Rectangle()
                                                            .stroke(Color.gray.opacity(0.3), lineWidth: 0.5)
                                                    )

                                                    // Items
                                                    ForEach(1...2, id: \.self) { i in
                                                        HStack {
                                                            Text("Product \(i)")
                                                                .font(.system(size: 7, design: .serif))
                                                            Spacer()
                                                            Text("$\(i)00.00")
                                                                .font(.system(size: 7, design: .serif))
                                                        }
                                                        .padding(.horizontal, 10)
                                                        .padding(.vertical, 3)
                                                    }

                                                    // Total
                                                    HStack {
                                                        Spacer()
                                                        Text("Total:")
                                                            .font(.system(size: 7, weight: .semibold, design: .serif))
                                                        Text("$300.00")
                                                            .font(.system(size: 8, weight: .bold, design: .serif))
                                                            .foregroundColor(Color.navy)
                                                    }
                                                    .padding(.horizontal, 10)
                                                    .padding(.top, 4)
                                                }
                                                .padding(.top, 6)
                                            }
                                        }
                                    }
                                    .frame(width: 200, height: 140)
                                    .overlay(
                                        Rectangle()
                                            .stroke(Color.gray.opacity(0.5), lineWidth: 0.5)
                                    )

                                case .custom:
                                    // CUSTOM: Creative asymmetrical layout with unique elements
                                    ZStack {
                                        // Gradient background
                                        LinearGradient(
                                            gradient: Gradient(colors: [.white, Color.mint.opacity(0.1)]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )

                                        // Diagonal accent
                                        Path { path in
                                            path.move(to: CGPoint(x: 0, y: 0))
                                            path.addLine(to: CGPoint(x: 60, y: 0))
                                            path.addLine(to: CGPoint(x: 0, y: 60))
                                            path.closeSubpath()
                                        }
                                        .fill(
                                            LinearGradient(
                                                gradient: Gradient(colors: [.green, .mint]),
                                                startPoint: .top,
                                                endPoint: .bottom
                                            )
                                        )

                                        // Content layout - asymmetrical and creative
                                        VStack(spacing: 0) {
                                            // Header with offset title
                                            ZStack(alignment: .topTrailing) {
                                                // Empty space for offset title
                                                Rectangle()
                                                    .fill(Color.clear)
                                                    .frame(height: 35)

                                                // Title with accent color
                                                Text("INVOICE")
                                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                                    .italic()
                                                    .foregroundColor(.green)
                                                    .padding(.trailing, 15)
                                                    .padding(.top, 10)

                                                // Invoice number badge
                                                Text("#1001")
                                                    .font(.system(size: 10, weight: .bold, design: .rounded))
                                                    .foregroundColor(.white)
                                                    .padding(.horizontal, 8)
                                                    .padding(.vertical, 3)
                                                    .background(
                                                        Capsule()
                                                            .fill(
                                                                LinearGradient(
                                                                    gradient: Gradient(colors: [.green, .mint]),
                                                                    startPoint: .leading,
                                                                    endPoint: .trailing
                                                                )
                                                            )
                                                    )
                                                    .offset(x: -10, y: 40)
                                            }

                                            // Creative layout with offset elements
                                            ZStack {
                                                // Company info - offset to right
                                                VStack(alignment: .trailing, spacing: 1) {
                                                    Text("Your Company")
                                                        .font(.system(size: 9, weight: .semibold, design: .rounded))
                                                    Text("123 Main St")
                                                        .font(.system(size: 7, design: .rounded))
                                                    Text("contact@email.com")
                                                        .font(.system(size: 7, design: .rounded))
                                                        .italic()
                                                }
                                                .padding(8)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 6)
                                                        .fill(Color.white)
                                                        .shadow(color: Color.green.opacity(0.2), radius: 3)
                                                )
                                                .offset(x: 50, y: -25)

                                                // Client info - offset to left
                                                VStack(alignment: .leading, spacing: 1) {
                                                    Text("CLIENT")
                                                        .font(.system(size: 7, weight: .bold, design: .rounded))
                                                        .foregroundColor(.mint)
                                                    Text("Client Name")
                                                        .font(.system(size: 8, design: .rounded))
                                                    Text("456 Client Ave")
                                                        .font(.system(size: 7, design: .rounded))
                                                }
                                                .padding(8)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 6)
                                                        .stroke(
                                                            LinearGradient(
                                                                gradient: Gradient(colors: [.green, .mint]),
                                                                startPoint: .leading,
                                                                endPoint: .trailing
                                                            ),
                                                            lineWidth: 1
                                                        )
                                                )
                                                .offset(x: -40, y: 10)

                                                // Items - overlapping at bottom
                                                VStack(spacing: 3) {
                                                    ForEach(1...2, id: \.self) { i in
                                                        HStack {
                                                            Text("Product \(i)")
                                                                .font(.system(size: 8, design: .rounded))
                                                            Spacer()
                                                            Text("$\(i)00.00")
                                                                .font(.system(size: 8, design: .rounded))
                                                        }

                                                        // Colored rule divider
                                                        if i == 1 {
                                                            Rectangle()
                                                                .fill(
                                                                    LinearGradient(
                                                                        gradient: Gradient(colors: [.clear, .mint, .clear]),
                                                                        startPoint: .leading,
                                                                        endPoint: .trailing
                                                                    )
                                                                )
                                                                .frame(height: 1)
                                                        }
                                                    }

                                                    // Creative total style
                                                    HStack {
                                                        Spacer()
                                                        Text("TOTAL")
                                                            .font(.system(size: 9, weight: .bold, design: .rounded))
                                                            .italic()
                                                            .foregroundColor(.green)
                                                        Text("$300.00")
                                                            .font(.system(size: 10, weight: .bold, design: .rounded))
                                                            .foregroundColor(.green)
                                                    }
                                                    .padding(.top, 5)
                                                }
                                                .padding(10)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 8)
                                                        .fill(Color.white.opacity(0.8))
                                                )
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 8)
                                                        .stroke(
                                                            LinearGradient(
                                                                gradient: Gradient(colors: [.clear, .mint.opacity(0.5), .green.opacity(0.5), .clear]),
                                                                startPoint: .topLeading,
                                                                endPoint: .bottomTrailing
                                                            ),
                                                            lineWidth: 1
                                                        )
                                                )
                                                .offset(x: 0, y: 40)
                                                .rotationEffect(Angle(degrees: -2))
                                            }
                                        }
                                    }
                                    .frame(width: 200, height: 140)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .shadow(color: Color.green.opacity(0.3), radius: 5)
                                }
                            }
                            .frame(height: 150)
                            .padding(.vertical, 5)
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
                        showingBackupRestoreView = true
                    }) {
                        HStack {
                            Image(systemName: "arrow.triangle.2.circlepath.circle.fill")
                                .foregroundColor(.blue)
                            Text("Backup & Restore")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }

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

                    Button {
                        showingPrivacyView = true
                    } label: {
                        HStack {
                            Text("Privacy Policy")
                            Spacer()
                            Image(systemName: "lock.shield")
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

                    Button {
                        // Open email client with the contact email
                        if let url = URL(string: "mailto:tucodevelopmentyvr@gmail.com") {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        HStack {
                            Text("Contact Support")
                            Spacer()
                            Text("tucodevelopmentyvr@gmail.com")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                }

                // Empty space at the bottom for better scrolling
                Section {
                    EmptyView()
                }
                .padding(.bottom, 20)
                .listRowBackground(Color.clear)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
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
                        .default(Text("Clients")) { exportData(type: "clients", format: "csv") },
                        .default(Text("Suppliers")) { exportData(type: "suppliers", format: "csv") },
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
            .sheet(isPresented: $showingBackupRestoreView) {
                BackupRestoreView()
            }
            .sheet(isPresented: $showingPrivacyView) {
                PrivacyView()
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