import SwiftUI
import AppKit

// MARK: - Native Translucent Sidebar Material
struct VisualEffectView: NSViewRepresentable {
    var material: NSVisualEffectView.Material = .sidebar
    var blendingMode: NSVisualEffectView.BlendingMode = .behindWindow

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .followsWindowActiveState
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}

// MARK: - Main Settings View
struct SettingsView: View {
    @State private var selection: String = "General"
    
    var body: some View {
        HStack(spacing: 0) {
            // Sidebar
            VStack(alignment: .leading, spacing: 6) {
                // Header Brand
                HStack(spacing: 10) {
                    Image(systemName: "keyboard.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 30, height: 30)
                        .background(
                            LinearGradient(
                                colors: [Color.blue, Color.purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .shadow(color: Color.blue.opacity(0.3), radius: 3, x: 0, y: 2)
                    
                    VStack(alignment: .leading, spacing: 0) {
                        Text("GraveSwitch")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                        Text("v1.0.0")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.top, 14)
                .padding(.bottom, 12)
                
                // Sidebar Menu Items
                SidebarButton(
                    title: "general_settings",
                    icon: "gearshape.fill",
                    badgeColor: .blue,
                    tag: "General",
                    selection: $selection
                )
                
                SidebarButton(
                    title: "keyboard_settings",
                    icon: "keyboard.fill",
                    badgeColor: .purple,
                    tag: "Keyboard",
                    selection: $selection
                )
                
                SidebarButton(
                    title: "about_settings",
                    icon: "info.circle.fill",
                    badgeColor: .indigo,
                    tag: "About",
                    selection: $selection
                )
                
                Spacer()
            }
            .padding(10)
            .frame(width: 200)
            .background(VisualEffectView(material: .sidebar, blendingMode: .behindWindow))
            
            Divider()
                .opacity(0.4)
            
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
            .background(Color(NSColor.windowBackgroundColor))
        }
        .frame(width: 660, height: 520)
    }
}

// MARK: - Sidebar Button Component
struct SidebarButton: View {
    let title: String
    let icon: String
    let badgeColor: Color
    let tag: String
    @Binding var selection: String
    
    var isSelected: Bool {
        selection == tag
    }
    
    var body: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                selection = tag
            }
        } label: {
            HStack(spacing: 10) {
                // Color Icon Badge (Apple System Settings Style)
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(badgeColor)
                        .frame(width: 24, height: 24)
                    
                    Image(systemName: icon)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                Text(LocalizedStringKey(title))
                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .primary : .secondary)
                
                Spacer()
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.accentColor.opacity(0.15) : Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Modern Card Container
struct ModernCard<Content: View>: View {
    let title: String?
    let icon: String?
    let iconColor: Color?
    let content: Content
    
    init(title: String? = nil, icon: String? = nil, iconColor: Color? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.iconColor = iconColor
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let title = title {
                HStack(spacing: 8) {
                    if let icon = icon, let iconColor = iconColor {
                        Image(systemName: icon)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(iconColor)
                    }
                    Text(LocalizedStringKey(title))
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }
            
            content
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(color: Color.black.opacity(0.04), radius: 2, x: 0, y: 1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
        )
    }
}

// MARK: - Reusable Setting Toggle Row
struct SettingToggleRow: View {
    let titleKey: String
    let descKey: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Toggle("", isOn: $isOn)
                .toggleStyle(.checkbox)
                .labelsHidden()
                .padding(.top, 1)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(LocalizedStringKey(titleKey))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.primary)
                Text(LocalizedStringKey(descKey))
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
        .contentShape(Rectangle())
        .onTapGesture {
            isOn.toggle()
        }
    }
}

// MARK: - General Settings View
struct GeneralSettingsView: View {
    @EnvironmentObject var settings: SettingsManager
    @ObservedObject var tapManager = KeyboardEventTapManager.shared
    @ObservedObject var inputManager = InputSourceManager.shared
    @State private var sources: [InputSourceManager.InputSource] = []
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Live Status Hero Banner (Master Enable/Disable)
                ModernCard {
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill((settings.isEnabled && tapManager.hasPermission) ? Color.green.opacity(0.2) : Color.orange.opacity(0.2))
                                .frame(width: 44, height: 44)
                            
                            Image(systemName: (settings.isEnabled && tapManager.hasPermission) ? "power.circle.fill" : "pause.circle.fill")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor((settings.isEnabled && tapManager.hasPermission) ? .green : .orange)
                        }
                        
                        VStack(alignment: .leading, spacing: 3) {
                            HStack(spacing: 8) {
                                Text("GraveSwitch")
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                
                                // Status Pill Badge
                                Text((settings.isEnabled && tapManager.hasPermission) ? LocalizedStringKey("status_active_short") : LocalizedStringKey("status_paused_short"))
                                    .font(.system(size: 10, weight: .bold))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background((settings.isEnabled && tapManager.hasPermission) ? Color.green.opacity(0.15) : Color.orange.opacity(0.15))
                                    .foregroundColor((settings.isEnabled && tapManager.hasPermission) ? .green : .orange)
                                    .clipShape(Capsule())
                            }
                            
                            Text("current_language_label")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.secondary) +
                            Text(": ") +
                            Text(inputManager.currentLanguageName)
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.primary)
                        }
                        
                        Spacer()
                        
                        // Single Master Enable/Disable Toggle
                        Toggle("", isOn: $settings.isEnabled)
                            .toggleStyle(.switch)
                            .labelsHidden()
                    }
                }
                
                // Permission Status Card
                ModernCard(title: "permissions_settings", icon: "shield.fill", iconColor: tapManager.hasPermission ? .green : .orange) {
                    HStack(spacing: 12) {
                        Image(systemName: tapManager.hasPermission ? "checkmark.shield.fill" : "exclamationmark.shield.fill")
                            .font(.system(size: 26))
                            .foregroundColor(tapManager.hasPermission ? .green : .orange)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(tapManager.hasPermission ? "permission_granted" : "permission_title")
                                .font(.system(size: 13, weight: .semibold))
                            Text(tapManager.hasPermission ? "permission_granted_desc" : "permission_desc_short")
                                .font(.system(size: 11))
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
                }
                
                // Language Selection Pair Card
                ModernCard(title: "languages_settings", icon: "globe", iconColor: .blue) {
                    VStack(spacing: 10) {
                        if sources.isEmpty {
                            HStack {
                                ProgressView()
                                    .controlSize(.small)
                                Text("Loading languages...")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        } else {
                            HStack {
                                Text(LocalizedStringKey("language_a"))
                                    .font(.system(size: 13, weight: .semibold))
                                Spacer()
                                Picker("", selection: $settings.languageA) {
                                    ForEach(sources, id: \.id) { source in
                                        Text(source.name).tag(source.id)
                                    }
                                }
                                .labelsHidden()
                            }
                            
                            Divider()
                            
                            HStack {
                                Text(LocalizedStringKey("language_b"))
                                    .font(.system(size: 13, weight: .semibold))
                                Spacer()
                                Picker("", selection: $settings.languageB) {
                                    ForEach(sources, id: \.id) { source in
                                        Text(source.name).tag(source.id)
                                    }
                                }
                                .labelsHidden()
                            }
                        }
                        
                        Divider()
                        
                        HStack {
                            Spacer()
                            Button {
                                InputSourceManager.shared.toggle()
                            } label: {
                                Label("test_switch", systemImage: "arrow.triangle.2.circlepath")
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                    }
                }
                
                // Startup & Behavior Card (No duplicate Enable toggle!)
                ModernCard(title: "launch_at_login", icon: "rocket.fill", iconColor: .blue) {
                    SettingToggleRow(
                        titleKey: "launch_at_login",
                        descKey: "launch_at_login_desc",
                        isOn: $settings.launchAtLogin
                    )
                }
                
                // Icon & Appearance Card
                ModernCard(title: "icon_settings", icon: "menubar.arrow.up.rectangle", iconColor: .purple) {
                    VStack(alignment: .leading, spacing: 12) {
                        SettingToggleRow(
                            titleKey: "show_in_menu_bar",
                            descKey: "show_in_menu_bar_desc",
                            isOn: $settings.showInMenuBar
                        )
                        
                        Divider()
                        
                        SettingToggleRow(
                            titleKey: "show_in_dock",
                            descKey: "show_in_dock_desc",
                            isOn: $settings.showInDock
                        )
                        
                        if settings.showInMenuBar {
                            Divider()
                            
                            SettingToggleRow(
                                titleKey: "menu_bar_indicator",
                                descKey: "menu_bar_indicator_desc",
                                isOn: $settings.showMenuBarText
                            )
                        }
                    }
                }
                
                // Caps Lock Helper Card
                ModernCard(title: "caps_lock_section_title", icon: "capslock.fill", iconColor: .orange) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(LocalizedStringKey("caps_lock_section_desc"))
                            .font(.system(size: 11))
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
                    }
                }
                
                // Reset & Maintenance Card
                ModernCard(title: "Reset & Maintenance", icon: "trash.fill", iconColor: .red) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Reset App Permissions")
                                .font(.system(size: 13, weight: .medium))
                            Text("Purges TCC permission records if you recompiled or modified the app.")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                        Spacer()
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
                            Label("Reset", systemImage: "trash")
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                }
            }
            .padding(18)
        }
        .onAppear {
            _ = KeyboardEventTapManager.shared.checkPermission()
            if sources.isEmpty {
                self.sources = InputSourceManager.shared.availableSources()
            }
        }
    }
}

// MARK: - Keyboard Settings View
struct KeyboardSettingsView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header Info
                VStack(alignment: .leading, spacing: 4) {
                    Text("keyboard_shortcuts_title")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                    Text("help_desc")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 4)
                
                // Shortcut Table Card
                ModernCard {
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
                }
                
                // Usage Guide Card
                ModernCard(title: "help_how_to_use", icon: "questionmark.circle.fill", iconColor: .blue) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("help_how_to_use_desc")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        
                        Divider()
                        
                        Text("help_literal_grave")
                            .font(.system(size: 13, weight: .bold))
                        Text("help_literal_grave_desc")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }
                
                // Caps Lock Guide Card
                ModernCard(title: "caps_lock_section_title", icon: "capslock.fill", iconColor: .orange) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(LocalizedStringKey("caps_lock_section_desc"))
                            .font(.system(size: 12))
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
                    }
                }
            }
            .padding(18)
        }
    }
}

// MARK: - Apple 3D Keycap Component
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
                .font(.system(size: 12, weight: .bold, design: .rounded))
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(
                    LinearGradient(
                        colors: [Color(NSColor.controlColor), Color(NSColor.controlColor).opacity(0.8)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: Color.black.opacity(0.18), radius: 1, x: 0, y: 1.5)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.primary.opacity(0.14), lineWidth: 1)
        )
    }
}

// MARK: - Shortcut Row Component
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
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(isProtected ? .secondary : .primary)
            
            if isProtected {
                Image(systemName: "lock.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
    }
}

// MARK: - Modern About View
struct AboutView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ModernCard {
                    VStack(spacing: 16) {
                        Image("FamilyImage")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 180)
                            .cornerRadius(12)
                            .shadow(color: .black.opacity(0.18), radius: 6, x: 0, y: 3)
                            .padding(.top, 4)
                        
                        VStack(spacing: 4) {
                            Text("GraveSwitch")
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                            
                            Text("Version 1.0.0 (Build 1)")
                                .font(.system(size: 11, weight: .medium))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 3)
                                .background(Color.primary.opacity(0.08))
                                .clipShape(Capsule())
                                .foregroundColor(.secondary)
                        }
                        
                        Text("about_desc")
                            .font(.system(size: 12))
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                        
                        Divider()
                            .padding(.horizontal)
                        
                        Text("about_credit")
                            .font(.system(size: 12, weight: .medium))
                            .italic()
                            .foregroundColor(.secondary)
                    }
                    .padding(8)
                }
            }
            .padding(18)
        }
    }
}
