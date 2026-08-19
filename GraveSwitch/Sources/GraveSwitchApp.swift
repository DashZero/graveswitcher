import SwiftUI
import ServiceManagement

@main
struct GraveSwitchApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var settings = SettingsManager.shared
    @StateObject private var inputSource = InputSourceManager.shared

    var body: some Scene {
        MenuBarExtra {
            ContentView()
                .environmentObject(settings)
                .environmentObject(inputSource)
        } label: {
            if settings.showMenuBarText {
                Text(inputSource.currentLanguageCode)
            } else {
                Image(systemName: "keyboard")
            }
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        if SettingsManager.shared.isEnabled {
            try? KeyboardEventTapManager.shared.start()
        }
        SettingsManager.shared.updateActivationPolicy()
    }
    
    func applicationDidBecomeActive(_ notification: Notification) {
        if SettingsManager.shared.isEnabled {
            try? KeyboardEventTapManager.shared.start()
        }
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        NotificationCenter.default.post(name: Notification.Name("OpenSettingsWindow"), object: nil)
        return true
    }
}

struct ContentView: View {
    @EnvironmentObject var settings: SettingsManager
    @ObservedObject var inputSource = InputSourceManager.shared
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Text(inputSource.currentLanguageName)
        
        Divider()
        
        Toggle("enable_graveswitch", isOn: $settings.isEnabled)
            .onChange(of: settings.isEnabled) { newValue in
                if newValue {
                    try? KeyboardEventTapManager.shared.start()
                } else {
                    KeyboardEventTapManager.shared.stop()
                }
            }
        
        Button("test_switch") {
            InputSourceManager.shared.toggle()
        }
        
        Divider()
        
        Button("settings_menu") {
            SettingsWindowManager.shared.showSettings()
        }
        .keyboardShortcut(",", modifiers: .command)
        
        Button("quit") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q", modifiers: .command)
    }
}

class SettingsWindowManager: NSObject, NSWindowDelegate {
    static let shared = SettingsWindowManager()
    private var window: NSWindow?
    
    func showSettings() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            if self.window == nil {
                let view = SettingsView().environmentObject(SettingsManager.shared)
                let hostingController = NSHostingController(rootView: view)
                let newWindow = NSWindow(
                    contentRect: NSRect(x: 0, y: 0, width: 620, height: 480),
                    styleMask: [.titled, .closable, .miniaturizable],
                    backing: .buffered,
                    defer: false
                )
                newWindow.title = NSLocalizedString("settings_title", comment: "GraveSwitch Settings")
                newWindow.contentViewController = hostingController
                newWindow.center()
                newWindow.isReleasedWhenClosed = false
                newWindow.delegate = self
                self.window = newWindow
            }
            
            self.window?.orderFrontRegardless()
            self.window?.makeKey()
            NSApp.activate(ignoringOtherApps: true)
        }
    }
}
