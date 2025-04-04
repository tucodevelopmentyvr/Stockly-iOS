import Foundation
import SwiftData

@Model
final class Category {
    var id: UUID
    var name: String
    var categoryDescription: String? // Changed from 'description' to avoid conflicts
    var createdAt: Date
    var updatedAt: Date
    
    // SwiftData relationships
    @Relationship(deleteRule: .cascade) var customFields: [CustomField]?
    
    init(name: String, description: String? = nil) {
        self.id = UUID()
        self.name = name
        self.categoryDescription = description
        self.createdAt = Date()
        self.updatedAt = Date()
        self.customFields = []
    }
}

enum FieldType: String, Codable {
    case text
    case number
    case date
    case boolean
    case dropdown
}

@Model
final class CustomField {
    var id: UUID
    var name: String
    var fieldType: String
    var required: Bool
    var options: [String]? // For dropdown type
    var createdAt: Date
    var updatedAt: Date
    
    // SwiftData relationship
    @Relationship(deleteRule: .nullify) var category: Category?
    
    init(name: String, fieldType: FieldType, required: Bool = false, options: [String]? = nil) {
        self.id = UUID()
        self.name = name
        self.fieldType = fieldType.rawValue
        self.required = required
        self.options = options
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    var type: FieldType {
        return FieldType(rawValue: fieldType) ?? .text
    }
}