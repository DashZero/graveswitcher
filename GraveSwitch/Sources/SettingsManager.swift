import SwiftUI
import ServiceManagement

class SettingsManager: ObservableObject {
    static let shared = SettingsManager()
    
    @AppStorage("isEnabled") var isEnabled: Bool = true
    @AppStorage("languageA") var languageA: String = "com.apple.keylayout.ABC"
    @AppStorage("languageB") var languageB: String = "com.apple.keylayout.Thai"
    @AppStorage("showMenuBarText") var showMenuBarText: Bool = true
    
    @Published var launchAtLogin: Bool = false {
        didSet {
            do {
                if launchAtLogin {
                    if SMAppService.mainApp.status == .notRegistered {
                        try SMAppService.mainApp.register()
                    }
                } else {
                    if SMAppService.mainApp.status == .enabled {
                        try SMAppService.mainApp.unregister()
                    }
                }
            } catch {
                print("Failed to toggle launch at login: \(error)")
            }
        }
    }
    
    init() {
        self.launchAtLogin = SMAppService.mainApp.status == .enabled
    }
}
