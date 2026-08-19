import SwiftUI
import ServiceManagement

@main
struct GraveSwitchApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var settings = SettingsManager.shared

    var body: some Scene {
        // We use MenuBarExtra directly for macOS 13+.
        // The spec recommends an icon in the menu bar.
        MenuBarExtra {
            ContentView()
                .environmentObject(settings)
        } label: {
            Image(systemName: "keyboard")
        }
        
        // The Settings window is standard SwiftUI
        Settings {
            SettingsView()
                .environmentObject(settings)
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Request permissions on startup if not already granted
        KeyboardEventTapManager.shared.requestPermission()
        
        if SettingsManager.shared.isEnabled {
            do {
                try KeyboardEventTapManager.shared.start()
            } catch {
                print("Failed to start event tap: \(error)")
            }
        }
        
        // Hide from Dock initially
        NSApp.setActivationPolicy(.accessory)
    }
}

struct ContentView: View {
    @EnvironmentObject var settings: SettingsManager
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(alignment: .leading) {
            Text(settings.isEnabled ? "status_active" : "status_paused")
                .font(.headline)
            Text("current_language \(InputSourceManager.shared.currentSourceLocalizedName() ?? "?")")
            
            Divider()
            
            Toggle("enable_graveswitch", isOn: $settings.isEnabled)
                .onChange(of: settings.isEnabled) { newValue in
                    if newValue {
                        try? KeyboardEventTapManager.shared.start()
                    } else {
                        KeyboardEventTapManager.shared.stop()
                    }
                }
            
            Divider()
            
            Button("settings") {
                NSApp.sendAction(Selector("showSettingsWindow:"), to: nil, from: nil)
                NSApp.activate(ignoringOtherApps: true)
            }
            
            Divider()
            
            Toggle("launch_at_login", isOn: $settings.launchAtLogin)
            
            Divider()
            
            Button("quit") {
                NSApplication.shared.terminate(nil)
            }
        }
        .padding()
    }
}
