import SwiftUI

struct SettingsView: View {
    @State private var selection: String = "General"
    
    var body: some View {
        HStack(spacing: 0) {
            // Sidebar
            VStack(alignment: .leading, spacing: 4) {
                SidebarButton(title: "general_settings", icon: "gearshape", tag: "General", selection: $selection)
                SidebarButton(title: "keyboard_settings", icon: "keyboard", tag: "Keyboard", selection: $selection)
                SidebarButton(title: "about_settings", icon: "info.circle", tag: "About", selection: $selection)
                Spacer()
            }
            .padding(12)
            .frame(width: 170)
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Detail Content
            Group {
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
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: 620, height: 480)
    }
}

struct SidebarButton: View {
    let title: String
    let icon: String
    let tag: String
    @Binding var selection: String
    
    var isSelected: Bool {
        selection == tag
    }
    
    var body: some View {
        Button {
            selection = tag
        } label: {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(isSelected ? .accentColor : .secondary)
                    .frame(width: 20)
                Text(LocalizedStringKey(title))
                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .primary : .secondary)
                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isSelected ? Color.primary.opacity(0.1) : Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

struct GeneralSettingsView: View {
    @EnvironmentObject var settings: SettingsManager
    @ObservedObject var tapManager = KeyboardEventTapManager.shared
    @State private var sources: [InputSourceManager.InputSource] = []
    
    var body: some View {
        Form {
            // Permission Status Section
            Section("permissions_settings") {
                HStack(spacing: 12) {
                    Image(systemName: tapManager.hasPermission ? "checkmark.shield.fill" : "exclamationmark.shield.fill")
                        .font(.title2)
                        .foregroundColor(tapManager.hasPermission ? .green : .orange)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(tapManager.hasPermission ? "permission_granted" : "permission_title")
                            .font(.subheadline)
                            .bold()
                        Text(tapManager.hasPermission ? "permission_granted_desc" : "permission_desc_short")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if !tapManager.hasPermission {
                        Button {
                            tapManager.requestPermission()
                            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                                NSWorkspace.shared.open(url)
                            }
                        } label: {
                            Text(LocalizedStringKey("grant_permission_button"))
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.regular)
                    }
                }
                .padding(.vertical, 4)
            }
            
            // Languages Section
            Section("languages_settings") {
                if sources.isEmpty {
                    Text("Loading languages...")
                        .foregroundColor(.secondary)
                } else {
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
            }
            
            // Icon & Appearance Section
            Section("icon_settings") {
                Toggle("show_in_menu_bar", isOn: $settings.showInMenuBar)
                Text("show_in_menu_bar_desc")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Toggle("show_in_dock", isOn: $settings.showInDock)
                Text("show_in_dock_desc")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if settings.showInMenuBar {
                    Toggle("menu_bar_indicator", isOn: $settings.showMenuBarText)
                }
            }
            
            Section(LocalizedStringKey("caps_lock_section_title")) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(LocalizedStringKey("caps_lock_section_desc"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Button {
                        if let url = URL(string: "x-apple.systempreferences:com.apple.Keyboard-Settings.extension") {
                            if !NSWorkspace.shared.open(url) {
                                if let fallbackUrl = URL(string: "x-apple.systempreferences:com.apple.preference.keyboard") {
                                    NSWorkspace.shared.open(fallbackUrl)
                                }
                            }
                        }
                    } label: {
                        Label(LocalizedStringKey("open_keyboard_settings"), systemImage: "keyboard")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .padding(.top, 2)
                }
            }
            
            Section("Reset & Uninstall") {
                Button(role: .destructive) {
                    KeyboardEventTapManager.shared.stop()
                    let task1 = Process()
                    task1.executableURL = URL(fileURLWithPath: "/usr/bin/tccutil")
                    task1.arguments = ["reset", "Accessibility", "com.example.GraveSwitch"]
                    try? task1.run()
                    
                    let task2 = Process()
                    task2.executableURL = URL(fileURLWithPath: "/usr/bin/tccutil")
                    task2.arguments = ["reset", "ListenEvent", "com.example.GraveSwitch"]
                    try? task2.run()
                } label: {
                    Label("Reset App Permissions", systemImage: "trash")
                }
            }
        }
        .formStyle(.grouped)
        .onAppear {
            _ = KeyboardEventTapManager.shared.checkPermission()
            if sources.isEmpty {
                self.sources = InputSourceManager.shared.availableSources()
            }
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
                    ShortcutRow(keys: [("`", nil)], desc: "switch_language_desc")
                    Divider()
                    ShortcutRow(keys: [("Shift", "shift"), ("`", nil)], desc: "switch_language_desc")
                    Divider()
                    ShortcutRow(keys: [("Option", "option"), ("`", nil)], desc: "type_backtick_desc")
                    Divider()
                    ShortcutRow(keys: [("Option", "option"), ("Shift", "shift"), ("`", nil)], desc: "type_tilde_desc")
                    Divider()
                    ShortcutRow(keys: [("Command", "command"), ("`", nil)], desc: "macos_shortcuts_desc", isProtected: true)
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
                    
                    Text(LocalizedStringKey("caps_lock_section_title"))
                        .font(.headline)
                        .padding(.top, 4)
                    Text(LocalizedStringKey("caps_lock_section_desc"))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Button {
                        if let url = URL(string: "x-apple.systempreferences:com.apple.Keyboard-Settings.extension") {
                            if !NSWorkspace.shared.open(url) {
                                if let fallbackUrl = URL(string: "x-apple.systempreferences:com.apple.preference.keyboard") {
                                    NSWorkspace.shared.open(fallbackUrl)
                                }
                            }
                        }
                    } label: {
                        Label(LocalizedStringKey("open_keyboard_settings"), systemImage: "keyboard")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.regular)
                    .padding(.top, 4)
                }
            }
            .padding(20)
        }
    }
}

struct KeyCapView: View {
    let title: String
    var sfSymbol: String? = nil
    
    var body: some View {
        HStack(spacing: 4) {
            if let symbol = sfSymbol {
                Image(systemName: symbol)
                    .font(.system(size: 11, weight: .medium))
            }
            Text(title)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(NSColor.controlColor))
                .shadow(color: Color.black.opacity(0.15), radius: 1, x: 0, y: 1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.primary.opacity(0.12), lineWidth: 1)
        )
    }
}

struct ShortcutRow: View {
    let keys: [(title: String, symbol: String?)]
    let desc: String
    var isProtected: Bool = false
    
    var body: some View {
        HStack {
            HStack(spacing: 6) {
                ForEach(0..<keys.count, id: \.self) { index in
                    if index > 0 {
                        Text("+")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.secondary)
                    }
                    KeyCapView(title: keys[index].0, sfSymbol: keys[index].1)
                }
            }
            
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
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 160)
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
                    .padding(.top, 10)
                
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
