import Foundation
import SwiftData

enum UserRole: String, Codable {
    case admin
    case manager
    case employee
}

@Model
final class User {
    var id: UUID
    var email: String
    var name: String
    var role: String
    var country: String
    var postalCode: String
    var createdAt: Date
    var lastLoginAt: Date?
    
    init(email: String, name: String, role: UserRole, country: String = "United States", postalCode: String = "") {
        self.id = UUID()
        self.email = email
        self.name = name
        self.role = role.rawValue
        self.country = country
        self.postalCode = postalCode
        self.createdAt = Date()
    }
    
    var userRole: UserRole {
        return UserRole(rawValue: role) ?? .employee
    }
    
    var isAdmin: Bool {
        return userRole == .admin
    }
    
    var isManager: Bool {
        return userRole == .manager || userRole == .admin
    }
}

@Model
final class Client {
    var id: UUID
    var name: String
    var email: String?
    var phone: String?
    var address: String
    var city: String
    var country: String
    var postalCode: String
    var notes: String?
    var createdAt: Date
    var updatedAt: Date
    
    init(name: String, email: String? = nil, phone: String? = nil, address: String, city: String = "", country: String = "United States", postalCode: String = "", notes: String? = nil) {
        self.id = UUID()
        self.name = name
        self.email = email
        self.phone = phone
        self.address = address
        self.city = city
        self.country = country
        self.postalCode = postalCode
        self.notes = notes
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

@Model
final class Supplier {
    var id: UUID
    var name: String
    var email: String?
    var phone: String?
    var address: String
    var city: String
    var country: String
    var postalCode: String
    var contactPerson: String?
    var notes: String?
    var createdAt: Date
    var updatedAt: Date
    
    init(name: String, email: String? = nil, phone: String? = nil, address: String, city: String = "", country: String = "United States", postalCode: String = "", contactPerson: String? = nil, notes: String? = nil) {
        self.id = UUID()
        self.name = name
        self.email = email
        self.phone = phone
        self.address = address
        self.city = city
        self.country = country
        self.postalCode = postalCode
        self.contactPerson = contactPerson
        self.notes = notes
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}