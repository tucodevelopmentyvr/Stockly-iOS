import Foundation
import UIKit
import SwiftUI

/// Layout component types for document sections
enum PDFComponentType: String, CaseIterable, Identifiable {
    case companyLogo = "Company Logo"
    case companyInfo = "Company Info"
    case clientInfo = "Client Info"  
    case documentTitle = "Document Title"
    case documentDate = "Document Date"
    case itemsTable = "Items Table"
    case summary = "Summary"
    case notes = "Notes"
    case signature = "Signature"
    case disclaimer = "Disclaimer"
    
    var id: String { rawValue }
}

/// Position and size of a component
struct ComponentLayout: Codable, Identifiable, Equatable {
    var id = UUID()
    var componentType: String
    var rect: CGRect
    var zIndex: Int
    var isVisible: Bool = true
    
    init(componentType: PDFComponentType, rect: CGRect, zIndex: Int = 0, isVisible: Bool = true) {
        self.componentType = componentType.rawValue
        self.rect = rect
        self.zIndex = zIndex
        self.isVisible = isVisible
    }
}

/// Manages the layout of PDF documents
class PDFLayoutService {
    // Default layouts for different document types
    static func defaultLayout() -> [ComponentLayout] {
        return [
            ComponentLayout(componentType: .companyLogo, rect: CGRect(x: 40, y: 40, width: 100, height: 50)),
            ComponentLayout(componentType: .companyInfo, rect: CGRect(x: 395, y: 40, width: 200, height: 80)),
            ComponentLayout(componentType: .documentTitle, rect: CGRect(x: 195, y: 120, width: 200, height: 30)),
            ComponentLayout(componentType: .documentDate, rect: CGRect(x: 395, y: 170, width: 200, height: 40)),
            ComponentLayout(componentType: .clientInfo, rect: CGRect(x: 40, y: 220, width: 200, height: 60)),
            ComponentLayout(componentType: .itemsTable, rect: CGRect(x: 40, y: 320, width: 515, height: 300)),
            ComponentLayout(componentType: .summary, rect: CGRect(x: 355, y: 630, width: 200, height: 100)),
            ComponentLayout(componentType: .notes, rect: CGRect(x: 40, y: 670, width: 300, height: 100)),
            ComponentLayout(componentType: .disclaimer, rect: CGRect(x: 40, y: 780, width: 515, height: 30)),
            ComponentLayout(componentType: .signature, rect: CGRect(x: 40, y: 720, width: 200, height: 60))
        ]
    }
    
    // Save a custom layout to UserDefaults
    static func saveLayout(_ layout: [ComponentLayout], for documentType: DocumentType) {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(layout) {
            UserDefaults.standard.set(encoded, forKey: "customLayout_\(documentType)")
        }
    }
    
    // Load a custom layout from UserDefaults or use default
    static func loadLayout(for documentType: DocumentType) -> [ComponentLayout] {
        if let savedLayoutData = UserDefaults.standard.data(forKey: "customLayout_\(documentType)") {
            let decoder = JSONDecoder()
            if let savedLayout = try? decoder.decode([ComponentLayout].self, from: savedLayoutData) {
                return savedLayout
            }
        }
        return defaultLayout()
    }
}

// MARK: - Layout Editor View
struct PDFLayoutEditorView: View {
    @State private var components: [ComponentLayout]
    @State private var selectedComponent: ComponentLayout?
    @State private var dragOffset = CGSize.zero
    @State private var documentType: DocumentType
    
    private let pageSize = CGSize(width: 595, height: 842) // A4 size
    private let scaleFactor: CGFloat = 0.8 // Scale to fit on screen
    
    init(for documentType: DocumentType) {
        self.documentType = documentType
        self._components = State(initialValue: PDFLayoutService.loadLayout(for: documentType))
    }
    
    var body: some View {
        VStack {
            HStack {
                Text("PDF Layout Editor")
                    .font(.title)
                    .padding()
                Spacer()
                Button("Save Layout") {
                    PDFLayoutService.saveLayout(components, for: documentType)
                }
                .buttonStyle(.borderedProminent)
                .padding(.trailing)
                
                Button("Reset to Default") {
                    components = PDFLayoutService.defaultLayout()
                }
                .buttonStyle(.bordered)
                .padding(.trailing)
            }
            
            // Page canvas
            ZStack {
                // A4 paper background
                Rectangle()
                    .fill(Color.white)
                    .border(Color.black, width: 1)
                    .frame(width: pageSize.width * scaleFactor, height: pageSize.height * scaleFactor)
                
                // Layout components
                ForEach(components.sorted(by: { $0.zIndex < $1.zIndex })) { component in
                    layoutComponentView(for: component)
                        .position(x: (component.rect.midX * scaleFactor), 
                                 y: (component.rect.midY * scaleFactor))
                        .opacity(component.isVisible ? 1.0 : 0.5)
                        .onTapGesture {
                            selectedComponent = component
                        }
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    if selectedComponent?.id == component.id {
                                        dragOffset = value.translation
                                    }
                                }
                                .onEnded { value in
                                    if selectedComponent?.id == component.id {
                                        moveComponent(component, by: value.translation)
                                        dragOffset = .zero
                                    }
                                }
                        )
                        .overlay(
                            Rectangle()
                                .stroke(selectedComponent?.id == component.id ? Color.blue : Color.clear, lineWidth: 2)
                        )
                }
            }
            .frame(width: pageSize.width * scaleFactor, height: pageSize.height * scaleFactor)
            
            // Properties panel for selected component
            if let selected = selectedComponent, let index = components.firstIndex(where: { $0.id == selected.id }) {
                VStack(alignment: .leading) {
                    Text("Edit Component: \(selected.componentType)")
                        .font(.headline)
                        .padding(.bottom, 5)
                    
                    HStack {
                        Text("Visible:")
                        Toggle("", isOn: Binding(
                            get: { components[index].isVisible },
                            set: { components[index].isVisible = $0 }
                        ))
                    }
                    
                    HStack {
                        Text("Z-Index:")
                        Stepper("\(components[index].zIndex)", 
                                value: Binding(
                                    get: { components[index].zIndex },
                                    set: { components[index].zIndex = $0 }
                                ),
                                in: 0...100)
                    }
                    
                    HStack {
                        Text("Position X:")
                        Slider(
                            value: Binding(
                                get: { components[index].rect.origin.x },
                                set: { newVal in
                                    var newRect = components[index].rect
                                    newRect.origin.x = newVal
                                    components[index].rect = newRect
                                }
                            ),
                            in: 0...pageSize.width - components[index].rect.width
                        )
                        Text("\(Int(components[index].rect.origin.x))")
                    }
                    
                    HStack {
                        Text("Position Y:")
                        Slider(
                            value: Binding(
                                get: { components[index].rect.origin.y },
                                set: { newVal in
                                    var newRect = components[index].rect
                                    newRect.origin.y = newVal
                                    components[index].rect = newRect
                                }
                            ),
                            in: 0...pageSize.height - components[index].rect.height
                        )
                        Text("\(Int(components[index].rect.origin.y))")
                    }
                    
                    HStack {
                        Text("Width:")
                        Slider(
                            value: Binding(
                                get: { components[index].rect.width },
                                set: { newVal in
                                    var newRect = components[index].rect
                                    newRect.size.width = max(20, newVal)
                                    components[index].rect = newRect
                                }
                            ),
                            in: 20...pageSize.width
                        )
                        Text("\(Int(components[index].rect.width))")
                    }
                    
                    HStack {
                        Text("Height:")
                        Slider(
                            value: Binding(
                                get: { components[index].rect.height },
                                set: { newVal in
                                    var newRect = components[index].rect
                                    newRect.size.height = max(20, newVal)
                                    components[index].rect = newRect
                                }
                            ),
                            in: 20...pageSize.height
                        )
                        Text("\(Int(components[index].rect.height))")
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .padding(.horizontal)
            }
        }
    }
    
    // Helper function to move a component by a translation offset
    private func moveComponent(_ component: ComponentLayout, by translation: CGSize) {
        guard let index = components.firstIndex(where: { $0.id == component.id }) else { return }
        
        var newRect = components[index].rect
        newRect.origin.x += translation.width / scaleFactor
        newRect.origin.y += translation.height / scaleFactor
        
        // Keep component within page bounds
        newRect.origin.x = max(0, min(pageSize.width - newRect.width, newRect.origin.x))
        newRect.origin.y = max(0, min(pageSize.height - newRect.height, newRect.origin.y))
        
        components[index].rect = newRect
    }
    
    // Creates a visual representation of each component type
    private func layoutComponentView(for component: ComponentLayout) -> some View {
        let size = CGSize(width: component.rect.size.width * scaleFactor, 
                         height: component.rect.size.height * scaleFactor)
        
        let componentName = component.componentType
        let componentType = PDFComponentType(rawValue: componentName) ?? .companyInfo
        
        return Group {
            switch componentType {
            case .companyLogo:
                ZStack {
                    Rectangle()
                        .stroke(Color.gray, lineWidth: 1)
                    Image(systemName: "building.2")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding(8)
                        .foregroundColor(.blue)
                    Text("Logo")
                        .font(.caption)
                        .foregroundColor(.black)
                        .padding(2)
                        .background(Color.white.opacity(0.7))
                        .position(x: size.width/2, y: size.height-10)
                }
                .frame(width: size.width, height: size.height)
                
            case .companyInfo:
                VStack {
                    Text("Company Info")
                        .font(.caption)
                        .foregroundColor(.black)
                    Spacer()
                }
                .frame(width: size.width, height: size.height)
                .background(Color.gray.opacity(0.2))
                .border(Color.gray, width: 1)
                
            case .clientInfo:
                VStack {
                    Text("Client Info")
                        .font(.caption)
                        .foregroundColor(.black)
                    Spacer()
                }
                .frame(width: size.width, height: size.height)
                .background(Color.blue.opacity(0.1))
                .border(Color.blue, width: 1)
                
            case .documentTitle:
                VStack {
                    Text("INVOICE/ESTIMATE")
                        .font(.caption.bold())
                        .foregroundColor(.black)
                }
                .frame(width: size.width, height: size.height)
                .background(Color.yellow.opacity(0.1))
                .border(Color.yellow, width: 1)
                
            case .documentDate:
                VStack {
                    Text("Date Information")
                        .font(.caption)
                        .foregroundColor(.black)
                    Spacer()
                }
                .frame(width: size.width, height: size.height)
                .background(Color.green.opacity(0.1))
                .border(Color.green, width: 1)
                
            case .itemsTable:
                ZStack {
                    Rectangle()
                        .fill(Color.white)
                        .border(Color.black, width: 1)
                    VStack(spacing: 2) {
                        HStack {
                            Text("Item")
                                .font(.caption.bold())
                            Spacer()
                            Text("Qty")
                                .font(.caption.bold())
                            Text("Price")
                                .font(.caption.bold())
                            Text("Total")
                                .font(.caption.bold())
                        }
                        .padding(2)
                        .background(Color.gray.opacity(0.3))
                        
                        Divider()
                        
                        Text("Items will appear here")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    }
                    .padding(4)
                }
                .frame(width: size.width, height: size.height)
                
            case .summary:
                VStack(alignment: .trailing) {
                    Text("Summary")
                        .font(.caption)
                    Divider()
                    HStack {
                        Text("Subtotal:")
                            .font(.caption)
                        Text("$0.00")
                            .font(.caption)
                    }
                    HStack {
                        Text("Tax:")
                            .font(.caption)
                        Text("$0.00")
                            .font(.caption)
                    }
                    HStack {
                        Text("Total:")
                            .font(.caption.bold())
                        Text("$0.00")
                            .font(.caption.bold())
                    }
                }
                .padding(4)
                .frame(width: size.width, height: size.height)
                .background(Color.green.opacity(0.1))
                .border(Color.green, width: 1)
                
            case .notes:
                VStack(alignment: .leading) {
                    Text("Notes")
                        .font(.caption)
                    Rectangle()
                        .fill(Color.gray.opacity(0.1))
                        .border(Color.gray, width: 0.5)
                }
                .padding(4)
                .frame(width: size.width, height: size.height)
                .background(Color.yellow.opacity(0.1))
                .border(Color.yellow, width: 1)
                
            case .signature:
                VStack(alignment: .leading) {
                    Text("Signature")
                        .font(.caption)
                    Spacer()
                    Rectangle()
                        .fill(Color.clear)
                        .frame(height: 1)
                        .border(Color.black, width: 0.5)
                }
                .padding(4)
                .frame(width: size.width, height: size.height)
                .background(Color.gray.opacity(0.1))
                .border(Color.gray, width: 1)
                
            case .disclaimer:
                VStack {
                    Text("Disclaimer text will appear here")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .frame(width: size.width, height: size.height)
                .background(Color.gray.opacity(0.1))
                .border(Color.gray, width: 1)
            }
        }
    }
}