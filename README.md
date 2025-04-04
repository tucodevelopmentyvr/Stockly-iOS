# Stockly - Inventory Management iOS App

Stockly is a comprehensive inventory management iOS application designed for businesses to efficiently track, manage, and organize their product inventory. Built with SwiftUI and following the MVVM architecture pattern, Stockly provides a modern, user-friendly interface with powerful features.

## Features

- **User Authentication**
  - Simple authentication system
  - Role-based access control (Manager, Employee)

- **Product Management**
  - Add, edit, view, and delete products
  - Track stock levels with automatic alerts for low inventory
  - Barcode/QR code scanning for quick product lookup
  - Upload and manage product photos

- **Dashboard**
  - Overview of total stock value
  - Low stock and out-of-stock items
  - Recent activity tracking
  - Category distribution

- **Search & Filtering**
  - Search by name, description, or barcode
  - Filter by category or stock level
  - Sort by various parameters

- **Document Generation**
  - Create professional invoices
  - Generate consignment documents
  - Customizable templates and themes
  - Export as PDF

- **Local Data Storage**
  - All data stored securely on your device
  - No cloud storage or external data transmission
  - Complete privacy and data ownership

- **Data Export**
  - Export inventory as CSV

- **Customization**
  - Company profile settings
  - Customizable product categories and fields
  - Measurement units and currency settings

## Privacy

Stockly is designed with your privacy in mind. All data is stored locally on your device, and we do not collect or transmit any of your information. For more details, please see our [Privacy Policy](PRIVACY.md).

## Technical Details

- **Architecture**: MVVM (Model-View-ViewModel)
- **UI Framework**: SwiftUI
- **Data Persistence**: SwiftData
- **PDF Generation**: PDFKit
- **Barcode Scanning**: AVFoundation

## Getting Started

### Prerequisites

- Xcode 15.0+
- iOS 17.0+
- Swift 5.9+
- Apple Developer Account (for App Store distribution)

### Installation

1. Clone the repository:

   ```bash
   git clone https://github.com/yourusername/stockly.git
   cd stockly
   ```

2. Open the project in Xcode:

   ```bash
   open Stockly.xcodeproj
   ```

3. Build and run the project

## Data Model

### Data Structure

Stockly uses SwiftData for local data storage with the following model structure:

```swift
// User model
class User {
  - email: String
  - name: String
  - role: UserRole
  - lastLoginAt: Date?
}

// Item model
class Item {
  - name: String
  - description: String
  - category: String
  - price: Double
  - stockQuantity: Int
  - minStockLevel: Int
  - barcode: String?
  - imageURL: String?
  - createdAt: Date
  - updatedAt: Date
}

// Category model
class Category {
  - name: String
  - description: String?
  - customFields: [CustomField]?
  - createdAt: Date
  - updatedAt: Date
}
```

## App Store Distribution

To distribute the app on the App Store:

1. Configure your App Store Connect account
2. Create a new app listing
3. Upload the app binary using Xcode
4. Submit for review

## Customization

- Company logo and information can be set in the Settings tab
- Customize document templates in the Settings tab
- Add and manage categories in the Inventory tab

## License

This project is proprietary software. All rights reserved.

## Contact

For support or inquiries, please contact us at: [tucodevelopmentyvr@gmail.com](mailto:tucodevelopmentyvr@gmail.com)

## Acknowledgments

- SwiftUI and SwiftData for the app architecture
- Apple's PDFKit for document generation
- Apple's AVFoundation for barcode scanning
