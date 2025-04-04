import Foundation
import SwiftData

// Service to generate sample data for demo purposes
class SampleDataService {
    static func createMontecristoJewellersSampleData(modelContext: ModelContext) async -> Bool {
        // Create categories
        let categories = ["Rings", "Pendants", "Necklaces", "Earrings", "Bracelets", "Watches"]
        
        for categoryName in categories {
            let category = Category(name: categoryName)
            modelContext.insert(category)
        }
        
        // Create some sample inventory items
        let items = [
            Item(name: "Diamond Solitaire Ring", description: "14K Gold Diamond Solitaire Ring", category: "Rings", sku: "MC-R001", price: 1299.99, buyPrice: 750.00, stockQuantity: 5, minStockLevel: 2, measurementUnit: .piece, taxRate: 7.5, barcode: "4901234567890"),
            Item(name: "Sapphire Pendant", description: "18K White Gold Sapphire Pendant", category: "Pendants", sku: "MC-P001", price: 899.99, buyPrice: 450.00, stockQuantity: 8, minStockLevel: 3, measurementUnit: .piece, taxRate: 7.5, barcode: "4901234567891"),
            Item(name: "Pearl Stud Earrings", description: "Freshwater Pearl Stud Earrings", category: "Earrings", sku: "MC-E001", price: 199.99, buyPrice: 80.00, stockQuantity: 15, minStockLevel: 5, measurementUnit: .pair, taxRate: 7.5, barcode: "4901234567892"),
            Item(name: "Gold Chain Necklace", description: "18K Gold Chain Necklace, 18 inch", category: "Necklaces", sku: "MC-N001", price: 599.99, buyPrice: 300.00, stockQuantity: 10, minStockLevel: 4, measurementUnit: .piece, taxRate: 7.5, barcode: "4901234567893"),
            Item(name: "Silver Bangle", description: "Sterling Silver Bangle with Diamonds", category: "Bracelets", sku: "MC-B001", price: 249.99, buyPrice: 120.00, stockQuantity: 12, minStockLevel: 4, measurementUnit: .piece, taxRate: 7.5, barcode: "4901234567894"),
            Item(name: "Emerald Drop Earrings", description: "Emerald and Diamond Drop Earrings", category: "Earrings", sku: "MC-E002", price: 1499.99, buyPrice: 800.00, stockQuantity: 3, minStockLevel: 1, measurementUnit: .pair, taxRate: 7.5, barcode: "4901234567895"),
            Item(name: "Rose Gold Wedding Band", description: "14K Rose Gold Wedding Band", category: "Rings", sku: "MC-R002", price: 799.99, buyPrice: 400.00, stockQuantity: 7, minStockLevel: 3, measurementUnit: .piece, taxRate: 7.5, barcode: "4901234567896"),
            Item(name: "Diamond Tennis Bracelet", description: "18K White Gold Diamond Tennis Bracelet", category: "Bracelets", sku: "MC-B002", price: 2499.99, buyPrice: 1200.00, stockQuantity: 2, minStockLevel: 1, measurementUnit: .piece, taxRate: 7.5, barcode: "4901234567897"),
            Item(name: "Ruby Pendant", description: "Ruby and Diamond Pendant in 14K Gold", category: "Pendants", sku: "MC-P002", price: 1099.99, buyPrice: 550.00, stockQuantity: 4, minStockLevel: 2, measurementUnit: .piece, taxRate: 7.5, barcode: "4901234567898"),
            Item(name: "Pearl Necklace", description: "Freshwater Pearl Necklace, 16 inch", category: "Necklaces", sku: "MC-N002", price: 349.99, buyPrice: 170.00, stockQuantity: 6, minStockLevel: 2, measurementUnit: .piece, taxRate: 7.5, barcode: "4901234567899"),
            Item(name: "Platinum Watch", description: "Luxury Platinum Watch with Diamonds", category: "Watches", sku: "MC-W001", price: 3999.99, buyPrice: 2200.00, stockQuantity: 3, minStockLevel: 1, measurementUnit: .piece, taxRate: 7.5, barcode: "4901234567900"),
            Item(name: "Gold Cufflinks", description: "18K Gold Cufflinks with Onyx", category: "Accessories", sku: "MC-A001", price: 499.99, buyPrice: 250.00, stockQuantity: 8, minStockLevel: 2, measurementUnit: .pair, taxRate: 7.5, barcode: "4901234567901")
        ]
        
        for item in items {
            modelContext.insert(item)
        }
        
        // Create sample clients
        let clients = [
            Client(name: "John Smith", email: "john.smith@example.com", phone: "555-1234", address: "123 Main St", city: "New York", country: "United States", postalCode: "10001", notes: "Long-time customer since 2018"),
            Client(name: "Emma Johnson", email: "emma.j@example.com", phone: "555-2345", address: "456 Oak Ave", city: "Los Angeles", country: "United States", postalCode: "90001", notes: "Wedding jewelry client"),
            Client(name: "Michael Brown", email: "mbrown@example.com", phone: "555-3456", address: "789 Pine Rd", city: "Chicago", country: "United States", postalCode: "60007", notes: "Anniversary gift purchaser"),
            Client(name: "Sophia Martinez", email: "smartinez@example.com", phone: "555-4567", address: "101 Elm Blvd", city: "Miami", country: "United States", postalCode: "33101", notes: "Interested in diamond investments"),
            Client(name: "Robert Wilson", email: "rwilson@example.com", phone: "555-5678", address: "202 Cedar St", city: "Boston", country: "United States", postalCode: "02108", notes: "Collector of vintage watches"),
            Client(name: "Jennifer Garcia", email: "jgarcia@example.com", phone: "555-6789", address: "303 Maple Dr", city: "San Francisco", country: "United States", postalCode: "94109", notes: "Corporate gifting client"),
            Client(name: "David Lee", email: "dlee@example.com", phone: "555-7890", address: "404 Birch Ln", city: "Seattle", country: "United States", postalCode: "98101", notes: "Regular customer for anniversary gifts")
        ]
        
        for client in clients {
            modelContext.insert(client)
        }
        
        // Create sample suppliers
        let suppliers = [
            Supplier(name: "Diamond Direct", email: "orders@diamonddirect.com", phone: "800-123-4567", address: "1 Diamond Way", city: "Antwerp", country: "Belgium", postalCode: "2000", contactPerson: "Johan Van Houten", notes: "Premium diamond supplier with fast international shipping"),
            Supplier(name: "GoldCraft Inc.", email: "sales@goldcraft.com", phone: "877-765-4321", address: "555 Gold Ave", city: "New York", country: "United States", postalCode: "10016", contactPerson: "Maria Sanchez", notes: "Gold and silver raw materials"),
            Supplier(name: "Gem World", email: "wholesale@gemworld.com", phone: "888-555-1212", address: "78 Jewel Street", city: "Mumbai", country: "India", postalCode: "400001", contactPerson: "Raj Patel", notes: "Specialized in colored gemstones"),
            Supplier(name: "Luxury Watch Parts", email: "parts@luxurywatchparts.com", phone: "415-999-8888", address: "200 Clockwork Blvd", city: "Geneva", country: "Switzerland", postalCode: "1201", contactPerson: "Hans Mueller", notes: "Watch movements and repair parts"),
            Supplier(name: "Pearl Paradise", email: "info@pearlparadise.com", phone: "808-222-3333", address: "42 Ocean Drive", city: "Honolulu", country: "United States", postalCode: "96815", contactPerson: "Leilani Wong", notes: "Freshwater and saltwater pearls direct from farms")
        ]
        
        for supplier in suppliers {
            modelContext.insert(supplier)
        }
        
        // Create some invoices
        let invoiceItems1 = [
            InvoiceItem(name: "Diamond Solitaire Ring", description: "14K Gold Diamond Solitaire Ring", quantity: 1, unitPrice: 1299.99),
            InvoiceItem(name: "Pearl Stud Earrings", description: "Freshwater Pearl Stud Earrings", quantity: 1, unitPrice: 199.99)
        ]
        
        let invoiceItems2 = [
            InvoiceItem(name: "Gold Chain Necklace", description: "18K Gold Chain Necklace, 18 inch", quantity: 1, unitPrice: 599.99),
            InvoiceItem(name: "Silver Bangle", description: "Sterling Silver Bangle with Diamonds", quantity: 1, unitPrice: 249.99)
        ]
        
        let invoiceItems3 = [
            InvoiceItem(name: "Ruby Pendant", description: "Ruby and Diamond Pendant in 14K Gold", quantity: 1, unitPrice: 1099.99)
        ]
        
        let invoiceItems4 = [
            InvoiceItem(name: "Platinum Watch", description: "Luxury Platinum Watch with Diamonds", quantity: 1, unitPrice: 3999.99),
            InvoiceItem(name: "Gold Cufflinks", description: "18K Gold Cufflinks with Onyx", quantity: 1, unitPrice: 499.99)
        ]
        
        let invoice1 = Invoice(
            number: "INV-2025-001", 
            clientName: "John Smith", 
            clientAddress: "123 Main St, New York, USA 10001", 
            clientEmail: "john.smith@example.com",
            clientPhone: "555-1234",
            status: .paid,
            paymentMethod: "Credit Card",
            dateCreated: Calendar.current.date(byAdding: .day, value: -15, to: Date())!,
            dueDate: Calendar.current.date(byAdding: .day, value: 15, to: Date())!,
            items: invoiceItems1,
            discount: 50.00,
            discountType: "Fixed",
            taxRate: 7.5,
            notes: "Thank you for your business!",
            headerNote: "Montecristo Jewellers - Fine Jewelry Since 1985",
            footerNote: "All items come with a 30-day warranty",
            bankingInfo: "Account: Montecristo Jewellers, Bank: First National Bank, Account #: 5678901234",
            templateType: "classic"
        )
        
        let invoice2 = Invoice(
            number: "INV-2025-002", 
            clientName: "Emma Johnson", 
            clientAddress: "456 Oak Ave, Los Angeles, USA 90001", 
            clientEmail: "emma.j@example.com",
            clientPhone: "555-2345",
            status: .pending,
            paymentMethod: "Bank Transfer",
            dateCreated: Calendar.current.date(byAdding: .day, value: -5, to: Date())!,
            dueDate: Calendar.current.date(byAdding: .day, value: 25, to: Date())!,
            items: invoiceItems2,
            discount: 0.00,
            discountType: "None",
            taxRate: 7.5,
            notes: "Thank you for your business!",
            headerNote: "Montecristo Jewellers - Fine Jewelry Since 1985",
            footerNote: "All items come with a 30-day warranty",
            bankingInfo: "Account: Montecristo Jewellers, Bank: First National Bank, Account #: 5678901234",
            templateType: "modern"
        )
        
        let invoice3 = Invoice(
            number: "INV-2025-003", 
            clientName: "Michael Brown", 
            clientAddress: "789 Pine Rd, Chicago, USA 60007", 
            clientEmail: "mbrown@example.com",
            clientPhone: "555-3456",
            status: .pending,
            paymentMethod: "Cash",
            dateCreated: Calendar.current.date(byAdding: .day, value: -3, to: Date())!,
            dueDate: Calendar.current.date(byAdding: .day, value: 27, to: Date())!,
            items: invoiceItems3,
            discount: 100.00,
            discountType: "Fixed",
            taxRate: 7.5,
            notes: "Thank you for your business!",
            headerNote: "Montecristo Jewellers - Fine Jewelry Since 1985",
            footerNote: "All items come with a 30-day warranty",
            bankingInfo: "Account: Montecristo Jewellers, Bank: First National Bank, Account #: 5678901234",
            templateType: "minimalist"
        )
        
        let invoice4 = Invoice(
            number: "INV-2025-004", 
            clientName: "Robert Wilson", 
            clientAddress: "202 Cedar St, Boston, USA 02108", 
            clientEmail: "rwilson@example.com",
            clientPhone: "555-5678",
            status: .overdue,
            paymentMethod: "Credit Card",
            dateCreated: Calendar.current.date(byAdding: .day, value: -45, to: Date())!,
            dueDate: Calendar.current.date(byAdding: .day, value: -15, to: Date())!,
            items: invoiceItems4,
            discount: 200.00,
            discountType: "Fixed",
            taxRate: 7.5,
            notes: "Payment overdue. Please contact us to arrange payment.",
            headerNote: "Montecristo Jewellers - Fine Jewelry Since 1985",
            footerNote: "All items come with a 30-day warranty",
            bankingInfo: "Account: Montecristo Jewellers, Bank: First National Bank, Account #: 5678901234",
            templateType: "classic"
        )
        
        modelContext.insert(invoice1)
        modelContext.insert(invoice2)
        modelContext.insert(invoice3)
        modelContext.insert(invoice4)
        
        // Create some estimates
        let estimateItems1 = [
            EstimateItem(name: "Diamond Tennis Bracelet", description: "18K White Gold Diamond Tennis Bracelet", quantity: 1, unitPrice: 2499.99),
            EstimateItem(name: "Emerald Drop Earrings", description: "Emerald and Diamond Drop Earrings", quantity: 1, unitPrice: 1499.99)
        ]
        
        let estimateItems2 = [
            EstimateItem(name: "Rose Gold Wedding Band", description: "14K Rose Gold Wedding Band", quantity: 2, unitPrice: 799.99),
            EstimateItem(name: "Pearl Necklace", description: "Freshwater Pearl Necklace, 16 inch", quantity: 1, unitPrice: 349.99)
        ]
        
        let estimateItems3 = [
            EstimateItem(name: "Platinum Watch", description: "Luxury Platinum Watch with Diamonds", quantity: 1, unitPrice: 3999.99),
            EstimateItem(name: "Gold Cufflinks", description: "18K Gold Cufflinks with Onyx", quantity: 1, unitPrice: 499.99),
            EstimateItem(name: "Diamond Solitaire Ring", description: "14K Gold Diamond Solitaire Ring", quantity: 1, unitPrice: 1299.99)
        ]
        
        let estimate1 = Estimate(
            number: "EST-2025-001",
            clientName: "Sophia Martinez",
            clientAddress: "101 Elm Blvd, Miami, USA 33101",
            clientEmail: "smartinez@example.com",
            clientPhone: "555-4567",
            status: .sent,
            dateCreated: Calendar.current.date(byAdding: .day, value: -10, to: Date())!,
            expiryDate: Calendar.current.date(byAdding: .day, value: 20, to: Date())!,
            items: estimateItems1,
            discount: 300.00,
            discountType: "Fixed",
            taxRate: 7.5,
            notes: "This estimate is valid for 30 days.",
            headerNote: "Montecristo Jewellers - Fine Jewelry Since 1985",
            footerNote: "All items come with a 30-day warranty",
            templateType: "classic"
        )
        
        let estimate2 = Estimate(
            number: "EST-2025-002",
            clientName: "John Smith",
            clientAddress: "123 Main St, New York, USA 10001",
            clientEmail: "john.smith@example.com",
            clientPhone: "555-1234",
            status: .accepted,
            dateCreated: Calendar.current.date(byAdding: .day, value: -20, to: Date())!,
            expiryDate: Calendar.current.date(byAdding: .day, value: 10, to: Date())!,
            items: estimateItems2,
            discount: 10.00,
            discountType: "Percentage",
            taxRate: 7.5,
            notes: "This estimate is valid for 30 days.",
            headerNote: "Montecristo Jewellers - Fine Jewelry Since 1985",
            footerNote: "All items come with a 30-day warranty",
            templateType: "modern"
        )
        
        let estimate3 = Estimate(
            number: "EST-2025-003",
            clientName: "Jennifer Garcia",
            clientAddress: "303 Maple Dr, San Francisco, USA 94109",
            clientEmail: "jgarcia@example.com",
            clientPhone: "555-6789",
            status: .draft,
            dateCreated: Calendar.current.date(byAdding: .day, value: -2, to: Date())!,
            expiryDate: Calendar.current.date(byAdding: .day, value: 28, to: Date())!,
            items: estimateItems3,
            discount: 15.00,
            discountType: "Percentage",
            taxRate: 7.5,
            notes: "Corporate pricing estimate. This estimate is valid for 30 days.",
            headerNote: "Montecristo Jewellers - Fine Jewelry Since 1985",
            footerNote: "All items come with a 30-day warranty",
            templateType: "minimalist"
        )
        
        modelContext.insert(estimate1)
        modelContext.insert(estimate2)
        modelContext.insert(estimate3)
        
        do {
            try modelContext.save()
            return true
        } catch {
            print("Failed to save sample data: \(error)")
            return false
        }
    }
}