import SwiftUI
import ServiceManagement

class SettingsManager: ObservableObject {
    static let shared = SettingsManager()
    
    @Published var isEnabled: Bool = UserDefaults.standard.object(forKey: "isEnabled") as? Bool ?? true {
        didSet { UserDefaults.standard.set(isEnabled, forKey: "isEnabled") }
    }
    @Published var languageA: String = UserDefaults.standard.string(forKey: "languageA") ?? "com.apple.keylayout.ABC" {
        didSet { UserDefaults.standard.set(languageA, forKey: "languageA") }
    }
    @Published var languageB: String = UserDefaults.standard.string(forKey: "languageB") ?? "com.apple.keylayout.Thai" {
        didSet { UserDefaults.standard.set(languageB, forKey: "languageB") }
    }
    @Published var showMenuBarText: Bool = UserDefaults.standard.object(forKey: "showMenuBarText") as? Bool ?? true {
        didSet { UserDefaults.standard.set(showMenuBarText, forKey: "showMenuBarText") }
    }
    @Published var showInMenuBar: Bool = UserDefaults.standard.object(forKey: "showInMenuBar") as? Bool ?? true {
        didSet { UserDefaults.standard.set(showInMenuBar, forKey: "showInMenuBar") }
    }
    @Published var showInDock: Bool = UserDefaults.standard.object(forKey: "showInDock") as? Bool ?? false {
        didSet {
            UserDefaults.standard.set(showInDock, forKey: "showInDock")
            updateActivationPolicy()
        }
    }
    @Published var launchAtLogin: Bool = UserDefaults.standard.object(forKey: "launchAtLogin") as? Bool ?? false {
        didSet {
            UserDefaults.standard.set(launchAtLogin, forKey: "launchAtLogin")
            let enabled = launchAtLogin
            DispatchQueue.global(qos: .utility).async {
                do {
                    if enabled {
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
    }
    
    func updateActivationPolicy() {
        if self.showInDock {
            NSApp.setActivationPolicy(.regular)
        } else {
            NSApp.setActivationPolicy(.accessory)
        }
    }
    
    init() {
        updateActivationPolicy()
    }
}
