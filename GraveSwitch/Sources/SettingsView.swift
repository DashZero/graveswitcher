import SwiftUI

struct SettingsView: View {
    @State private var selection: String? = "General"
    
    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                Label("general_settings", systemImage: "gearshape")
                    .tag("General")
                Label("keyboard_settings", systemImage: "keyboard")
                    .tag("Keyboard")
                Label("about_settings", systemImage: "info.circle")
                    .tag("About")
            }
            .navigationSplitViewColumnWidth(min: 160, ideal: 180, max: 200)
        } detail: {
            switch selection {
            case "General":
                GeneralSettingsView()
            case "Keyboard":
                KeyboardSettingsView()
            case "About":
                AboutView()
            default:
                GeneralSettingsView()
            }
        }
        .frame(width: 620, height: 480)
        .onAppear {
            NSApp.activate(ignoringOtherApps: true)
        }
    }
}

struct GeneralSettingsView: View {
    @EnvironmentObject var settings: SettingsManager
    @State private var sources = InputSourceManager.shared.availableSources()
    @State private var hasPermission = KeyboardEventTapManager.shared.checkPermission()
    
    var body: some View {
        Form {
            // Permission Status Section
            Section("permissions_settings") {
                HStack(spacing: 12) {
                    Image(systemName: hasPermission ? "checkmark.shield.fill" : "exclamationmark.shield.fill")
                        .font(.title2)
                        .foregroundColor(hasPermission ? .green : .orange)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(hasPermission ? "permission_granted" : "permission_title")
                            .font(.subheadline)
                            .bold()
                        Text(hasPermission ? "permission_granted_desc" : "permission_desc_short")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if !hasPermission {
                        Button("open_system_settings") {
                            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent") {
                                NSWorkspace.shared.open(url)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }
                }
                .padding(.vertical, 4)
            }
            
            // Languages Section
            Section("languages_settings") {
                Picker("language_a", selection: $settings.languageA) {
                    ForEach(sources, id: \.id) { source in
                        Text(source.name).tag(source.id)
                    }
                }
                
                Picker("language_b", selection: $settings.languageB) {
                    ForEach(sources, id: \.id) { source in
                        Text(source.name).tag(source.id)
                    }
                }
                
                HStack {
                    Spacer()
                    Button {
                        InputSourceManager.shared.toggle()
                    } label: {
                        Label("test_switch", systemImage: "arrow.triangle.2.circlepath")
                    }
                    .controlSize(.small)
                }
            }
            
            // App Behavior Section
            Section("general_settings") {
                Toggle("enable_graveswitch", isOn: $settings.isEnabled)
                Text("enable_graveswitch_desc")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Toggle("launch_at_login", isOn: $settings.launchAtLogin)
                Text("launch_at_login_desc")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Toggle("menu_bar_indicator", isOn: $settings.showMenuBarText)
            }
        }
        .formStyle(.grouped)
        .onAppear {
            hasPermission = KeyboardEventTapManager.shared.checkPermission()
        }
    }
}

struct KeyboardSettingsView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("keyboard_shortcuts_title")
                        .font(.title3)
                        .bold()
                    Text("help_desc")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // Shortcut Table Card
                VStack(spacing: 0) {
                    ShortcutRow(key: "`", desc: "switch_language_desc")
                    Divider()
                    ShortcutRow(key: "Shift + `", desc: "switch_language_desc")
                    Divider()
                    ShortcutRow(key: "Option + `", desc: "type_backtick_desc")
                    Divider()
                    ShortcutRow(key: "Option + Shift + `", desc: "type_tilde_desc")
                    Divider()
                    ShortcutRow(key: "Command + `", desc: "macos_shortcuts_desc", isProtected: true)
                }
                .background(RoundedRectangle(cornerRadius: 10).fill(Color.primary.opacity(0.03)))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.primary.opacity(0.08), lineWidth: 1))
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("help_how_to_use")
                        .font(.headline)
                    Text("help_how_to_use_desc")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("help_literal_grave")
                        .font(.headline)
                        .padding(.top, 4)
                    Text("help_literal_grave_desc")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding(20)
        }
    }
}

struct ShortcutRow: View {
    let key: String
    let desc: String
    var isProtected: Bool = false
    
    var body: some View {
        HStack {
            Text(key)
                .font(.system(.body, design: .monospaced))
                .bold()
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(RoundedRectangle(cornerRadius: 6).fill(Color.primary.opacity(0.08)))
            
            Spacer()
            
            Text(LocalizedStringKey(desc))
                .font(.subheadline)
                .foregroundColor(isProtected ? .secondary : .primary)
            
            if isProtected {
                Image(systemName: "lock.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }
}

struct AboutView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Image("FamilyImage")
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 180)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
                
                VStack(spacing: 4) {
                    Text("GraveSwitch")
                        .font(.title)
                        .bold()
                    Text("Version 1.0.0")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text("about_desc")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                Divider()
                    .padding(.horizontal)
                
                Text("about_credit")
                    .font(.callout)
                    .italic()
                    .foregroundColor(.secondary)
            }
            .padding(24)
        }
    }
}
