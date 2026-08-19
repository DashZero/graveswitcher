import SwiftUI
import ServiceManagement

@main
struct GraveSwitchApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var settings = SettingsManager.shared

    var body: some Scene {
        MenuBarExtra(isInserted: $settings.showInMenuBar) {
            ContentView()
                .environmentObject(settings)
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "keyboard")
                if settings.showMenuBarText {
                    Text(InputSourceManager.shared.shortLanguageCode())
                        .font(.system(size: 11, weight: .bold))
                }
            }
        }
        
        // The Settings window is standard SwiftUI
        Window("GraveSwitch", id: "settings") {
            SettingsView()
                .environmentObject(settings)
                .onReceive(NotificationCenter.default.publisher(for: Notification.Name("OpenSettingsWindow"))) { _ in
                    NSApp.activate(ignoringOtherApps: true)
                }
        }
        .windowResizability(.contentSize)
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
        
        SettingsManager.shared.updateActivationPolicy()
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        NotificationCenter.default.post(name: Notification.Name("OpenSettingsWindow"), object: nil)
        return true
    }
}

struct ContentView: View {
    @EnvironmentObject var settings: SettingsManager
    @Environment(\.openWindow) private var openWindow
    @State private var hasPermission = KeyboardEventTapManager.shared.checkPermission()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header Card
            HStack {
                Label("GraveSwitch", systemImage: "keyboard.fill")
                    .font(.headline)
                
                Spacer()
                
                // Status Badge
                HStack(spacing: 4) {
                    Circle()
                        .fill(settings.isEnabled ? Color.green : Color.secondary)
                        .frame(width: 7, height: 7)
                    Text(settings.isEnabled ? "status_active_short" : "status_paused_short")
                        .font(.caption2)
                        .bold()
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Capsule().fill(Color.primary.opacity(0.06)))
            }
            
            // Current Language Card
            VStack(alignment: .leading, spacing: 2) {
                Text("current_language_label")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(InputSourceManager.shared.currentSourceLocalizedName() ?? "Unknown")
                    .font(.subheadline)
                    .bold()
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 8).fill(Color.primary.opacity(0.04)))
            
            if !hasPermission {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text("permission_required_warning")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(8)
                .background(RoundedRectangle(cornerRadius: 6).fill(Color.orange.opacity(0.1)))
            }
            
            Divider()
            
            // Main Controls
            Toggle(isOn: $settings.isEnabled) {
                Label("enable_graveswitch", systemImage: "power")
                    .font(.subheadline)
            }
            .onChange(of: settings.isEnabled) { newValue in
                if newValue {
                    try? KeyboardEventTapManager.shared.start()
                } else {
                    KeyboardEventTapManager.shared.stop()
                }
            }
            
            Button {
                InputSourceManager.shared.toggle()
            } label: {
                Label("test_switch", systemImage: "arrow.triangle.2.circlepath")
                    .font(.subheadline)
            }
            .buttonStyle(.plain)
            
            Divider()
            
            // Settings & Quit
            Button {
                openWindow(id: "settings")
                NSApp.activate(ignoringOtherApps: true)
            } label: {
                Label("settings_menu", systemImage: "gearshape")
                    .font(.subheadline)
            }
            .buttonStyle(.plain)
            
            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                Label("quit", systemImage: "power.circle")
                    .font(.subheadline)
                    .foregroundColor(.red)
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .frame(width: 250)
        .onAppear {
            hasPermission = KeyboardEventTapManager.shared.checkPermission()
        }
    }
}
