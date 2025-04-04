import Foundation
import SwiftUI

// Enum to track the setup state of the app
enum SetupState: String {
    case notStarted
    case inProgress
    case completed
}

// Class to manage the app setup state
class AppSetupManager: ObservableObject {
    static let shared = AppSetupManager()
    
    @AppStorage("setupState") private var setupStateRaw = SetupState.notStarted.rawValue
    @Published var setupState: SetupState = .notStarted
    
    private init() {
        setupState = SetupState(rawValue: setupStateRaw) ?? .notStarted
    }
    
    func markSetupAsCompleted() {
        setupState = .completed
        setupStateRaw = setupState.rawValue
    }
    
    func markSetupAsInProgress() {
        setupState = .inProgress
        setupStateRaw = setupState.rawValue
    }
    
    func resetSetup() {
        setupState = .notStarted
        setupStateRaw = setupState.rawValue
    }
    
    func isSetupRequired() -> Bool {
        return setupState != .completed
    }
}
