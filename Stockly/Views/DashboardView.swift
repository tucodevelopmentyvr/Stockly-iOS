import SwiftUI
import SwiftData
import Charts

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel: InventoryViewModel
    @State private var refreshID = UUID()
    @Query private var invoices: [Invoice]
    @State private var selectedTimePeriod: TimePeriod = .month
    
    enum TimePeriod: String, CaseIterable, Identifiable {
        case week = "Week"
        case month = "Month"
        case quarter = "Quarter"
        case year = "Year"
        
        var id: String { self.rawValue }
        
        var days: Int {
            switch self {
            case .week: return 7
            case .month: return 30
            case .quarter: return 90
            case .year: return 365
            }
        }
    }
    
    init(modelContext: ModelContext) {
        let inventoryService = InventoryService(modelContext: modelContext)
        _viewModel = StateObject(wrappedValue: InventoryViewModel(inventoryService: inventoryService))
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Time Period Selector
                    Picker("Time Period", selection: $selectedTimePeriod) {
                        ForEach(TimePeriod.allCases) { period in
                            Text(period.rawValue).tag(period)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    
                    // Summary Cards
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                        // Total Items Card
                        SummaryCard(
                            title: "Total Items",
                            value: "\(viewModel.items.count)",
                            icon: "cube.box.fill",
                            color: .blue
                        )
                        
                        // Total Value Card
                        SummaryCard(
                            title: "Stock Value",
                            value: "$\(String(format: "%.2f", viewModel.getTotalStockValue()))",
                            icon: "dollarsign.circle.fill",
                            color: .green
                        )
                        
                        // Low Stock Card
                        SummaryCard(
                            title: "Low Stock",
                            value: "\(viewModel.getLowStockItems().count)",
                            icon: "exclamationmark.triangle.fill",
                            color: .orange
                        )
                        
                        // Out of Stock Card
                        SummaryCard(
                            title: "Out of Stock",
                            value: "\(viewModel.getOutOfStockItems().count)",
                            icon: "xmark.circle.fill",
                            color: .red
                        )
                    }
                    .padding(.horizontal)
                    
                    // Sales Performance Chart
                    SalesPerformanceChart(invoices: filteredInvoices, period: selectedTimePeriod)
                    
                    // Top Selling Products
                    TopSellingProductsSection(invoices: filteredInvoices)
                    
                    // Category Sales Breakdown
                    CategorySalesSection(invoices: filteredInvoices, viewModel: viewModel)
                    
                    // Low Stock Items
                    LowStockSection(items: viewModel.getLowStockItems())
                    
                    // Recent Activity
                    RecentActivitySection(items: viewModel.items)
                }
                .padding(.vertical)
                .id(refreshID) // Force refresh
            }
            .navigationTitle("Dashboard")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        refreshID = UUID()
                        viewModel.loadItems()
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .refreshable {
                refreshID = UUID()
                viewModel.loadItems()
            }
        }
        .onAppear {
            viewModel.loadItems()
        }
    }
    
    // Filter invoices based on selected time period
    private var filteredInvoices: [Invoice] {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -selectedTimePeriod.days, to: Date()) ?? Date()
        return invoices.filter { $0.dateCreated >= cutoffDate }
    }
}

struct SummaryCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Image(systemName: icon)
                    .font(.headline)
                    .foregroundColor(color)
            }
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
        .frame(maxWidth: .infinity)
    }
}

struct RecentActivitySection: View {
    let items: [Item]
    
    private var recentItems: [Item] {
        items.sorted { $0.updatedAt > $1.updatedAt }.prefix(5).map { $0 }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Recent Activity")
                .font(.headline)
                .padding(.bottom, 5)
            
            if recentItems.isEmpty {
                Text("No recent activity")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(recentItems) { item in
                    HStack {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 8, height: 8)
                        
                        Text(item.name)
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        Text(formatDate(item.updatedAt))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 5)
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct LowStockSection: View {
    let items: [Item]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Low Stock Alerts")
                .font(.headline)
                .padding(.bottom, 5)
            
            if items.isEmpty {
                Text("No low stock items")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(items) { item in
                    HStack {
                        Text(item.name)
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        Text("\(item.stockQuantity)/\(item.minStockLevel)")
                            .font(.subheadline)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(item.stockQuantity == 0 ? Color.red : Color.orange)
                            .foregroundColor(.white)
                            .cornerRadius(4)
                    }
                    .padding(.vertical, 5)
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Sales Performance Chart
struct SalesPerformanceChart: View {
    let invoices: [Invoice]
    let period: DashboardView.TimePeriod
    
    private var salesData: [(date: Date, amount: Double)] {
        // Group sales by day
        let calendar = Calendar.current
        var salesByDay: [Date: Double] = [:]
        
        for invoice in invoices where invoice.status == .paid {
            let dateComponents = calendar.dateComponents([.year, .month, .day], from: invoice.dateCreated)
            if let date = calendar.date(from: dateComponents) {
                salesByDay[date, default: 0] += invoice.totalAmount
            }
        }
        
        // Convert to array and sort by date
        return salesByDay.map { (date: $0.key, amount: $0.value) }
            .sorted { $0.date < $1.date }
    }
    
    var totalSales: Double {
        invoices.filter { $0.status == .paid }.reduce(0) { $0 + $1.totalAmount }
    }
    
    var averageSale: Double {
        let paidInvoices = invoices.filter { $0.status == .paid }
        return paidInvoices.isEmpty ? 0 : paidInvoices.reduce(0) { $0 + $1.totalAmount } / Double(paidInvoices.count)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Sales Performance")
                    .font(.headline)
                
                Spacer()
                
                HStack(spacing: 15) {
                    VStack(alignment: .leading) {
                        Text("Total")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("$\(String(format: "%.2f", totalSales))")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Average")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("$\(String(format: "%.2f", averageSale))")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                }
            }
            .padding(.bottom, 5)
            
            if salesData.isEmpty {
                Text("No sales data available")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 30)
            } else {
                Chart(salesData, id: \.date) { item in
                    LineMark(
                        x: .value("Date", item.date),
                        y: .value("Amount", item.amount)
                    )
                    .foregroundStyle(Color.blue.gradient)
                    
                    AreaMark(
                        x: .value("Date", item.date),
                        y: .value("Amount", item.amount)
                    )
                    .foregroundStyle(Color.blue.opacity(0.1).gradient)
                    
                    PointMark(
                        x: .value("Date", item.date),
                        y: .value("Amount", item.amount)
                    )
                    .foregroundStyle(Color.blue)
                }
                .frame(height: 200)
                .chartXAxis {
                    AxisMarks(values: .automatic) { _ in
                        AxisValueLabel(format: .dateTime.month().day())
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

// MARK: - Top Selling Products Section
struct TopSellingProductsSection: View {
    let invoices: [Invoice]
    
    private var topProducts: [(name: String, quantity: Int, revenue: Double)] {
        // Collect all invoice items
        var productCounts: [String: (quantity: Int, revenue: Double)] = [:]
        
        for invoice in invoices {
            for item in invoice.items {
                productCounts[item.name, default: (0, 0)].quantity += item.quantity
                productCounts[item.name, default: (0, 0)].revenue += item.totalAmount
            }
        }
        
        // Convert to array and sort by quantity sold (descending)
        return productCounts.map { (name: $0.key, quantity: $0.value.quantity, revenue: $0.value.revenue) }
            .sorted { $0.quantity > $1.quantity }
            .prefix(5)
            .map { $0 } // Convert to Array
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Top Selling Products")
                .font(.headline)
                .padding(.bottom, 5)
            
            if topProducts.isEmpty {
                Text("No sales data available")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                // Bar chart for top products
                Chart(topProducts, id: \.name) { product in
                    BarMark(
                        x: .value("Quantity", product.quantity),
                        y: .value("Product", product.name)
                    )
                    .foregroundStyle(Color.green.gradient)
                    .annotation(position: .trailing) {
                        Text("\(product.quantity)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(height: CGFloat(topProducts.count * 40))
                .chartYAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let name = value.as(String.self) {
                                Text(name)
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                            }
                        }
                    }
                }
                
                Divider()
                    .padding(.vertical, 5)
                
                // List with additional details
                ForEach(topProducts, id: \.name) { product in
                    HStack {
                        Text(product.name)
                            .fontWeight(.medium)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        VStack(alignment: .trailing) {
                            Text("\(product.quantity) sold")
                                .font(.subheadline)
                            
                            Text("$\(String(format: "%.2f", product.revenue))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 5)
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

// MARK: - Category Sales Section
struct CategorySalesSection: View {
    let invoices: [Invoice]
    @ObservedObject var viewModel: InventoryViewModel
    
    private var categorySales: [(category: String, amount: Double, count: Int)] {
        var categories: [String: (amount: Double, count: Int)] = [:]
        
        // Create a product name -> category mapping
        var productCategories: [String: String] = [:]
        for item in viewModel.items {
            productCategories[item.name] = item.category
        }
        
        // Track sales by category
        for invoice in invoices {
            for item in invoice.items {
                if let category = productCategories[item.name] {
                    categories[category, default: (0, 0)].amount += item.totalAmount
                    categories[category, default: (0, 0)].count += item.quantity
                }
            }
        }
        
        // Convert to array and sort by amount
        return categories.map { (category: $0.key, amount: $0.value.amount, count: $0.value.count) }
            .sorted { $0.amount > $1.amount }
    }
    
    // Color palette for chart
    private let colors: [Color] = [.blue, .green, .orange, .purple, .pink, .yellow, .cyan, .mint, .indigo, .teal]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Category Sales")
                .font(.headline)
                .padding(.bottom, 5)
            
            if categorySales.isEmpty {
                Text("No category sales data available")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                HStack(alignment: .top) {
                    // Pie chart
                    Chart(categorySales.prefix(5), id: \.category) { item in
                        SectorMark(
                            angle: .value("Sales", item.amount),
                            innerRadius: .ratio(0.5),
                            angularInset: 1
                        )
                        .foregroundStyle(by: .value("Category", item.category))
                        .cornerRadius(3)
                    }
                    .chartForegroundStyleScale(
                        domain: categorySales.prefix(5).map { $0.category },
                        range: colors.prefix(categorySales.prefix(5).count).map { $0 }
                    )
                    .frame(height: 200)
                    
                    // Legend
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(Array(categorySales.prefix(5).enumerated()), id: \.element.category) { index, item in
                            HStack(spacing: 8) {
                                Rectangle()
                                    .fill(colors[index % colors.count])
                                    .frame(width: 12, height: 12)
                                    .cornerRadius(3)
                                
                                Text(item.category)
                                    .font(.caption)
                                    .lineLimit(1)
                                
                                Spacer()
                                
                                Text("$\(String(format: "%.0f", item.amount))")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                            }
                        }
                    }
                    .padding(.leading, 8)
                }
                
                Divider()
                    .padding(.vertical, 5)
                
                // Category list with sales numbers
                ForEach(categorySales, id: \.category) { category in
                    HStack {
                        Text(category.category)
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        VStack(alignment: .trailing) {
                            Text("$\(String(format: "%.2f", category.amount))")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            
                            Text("\(category.count) items")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 5)
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}