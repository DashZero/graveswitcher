import SwiftUI

struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem {
                    Label("general_settings", systemImage: "gearshape")
                }
            
            LanguageSettingsView()
                .tabItem {
                    Label("languages_settings", systemImage: "globe")
                }
            
            KeyboardSettingsView()
                .tabItem {
                    Label("keyboard_settings", systemImage: "keyboard")
                }
                
            PermissionsSettingsView()
                .tabItem {
                    Label("permissions_settings", systemImage: "lock.shield")
                }
            
            AboutView()
                .tabItem {
                    Label("about_settings", systemImage: "info.circle")
                }
        }
        .padding()
        .frame(width: 500, height: 400)
    }
}

struct GeneralSettingsView: View {
    @EnvironmentObject var settings: SettingsManager
    
    var body: some View {
        Form {
            Section {
                Toggle("enable_graveswitch", isOn: $settings.isEnabled)
                Text("enable_graveswitch_desc")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Section {
                Toggle("launch_at_login", isOn: $settings.launchAtLogin)
                Text("launch_at_login_desc")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
    }
}

struct LanguageSettingsView: View {
    @EnvironmentObject var settings: SettingsManager
    @State private var sources = InputSourceManager.shared.availableSources()
    
    var body: some View {
        Form {
            Text("choose_languages")
                .padding(.bottom, 10)
            
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
            
            Button("test_switch") {
                InputSourceManager.shared.toggle()
            }
            .padding(.top, 10)
        }
        .padding()
    }
}

struct KeyboardSettingsView: View {
    var body: some View {
        Form {
            Text("keyboard_shortcuts_title").font(.headline)
            
            Grid(alignment: .leading, horizontalSpacing: 20, verticalSpacing: 10) {
                GridRow {
                    Text("`")
                    Text("switch_language_desc")
                }
                GridRow {
                    Text("Shift + `")
                    Text("switch_language_desc")
                }
                GridRow {
                    Text("Option + `")
                    Text("type_backtick_desc")
                }
                GridRow {
                    Text("Option + Shift + `")
                    Text("type_tilde_desc")
                }
            }
            .padding()
            
            Text("macos_shortcuts_desc").font(.headline)
            Text("macos_shortcuts_info")
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

struct PermissionsSettingsView: View {
    @State private var hasPermission = KeyboardEventTapManager.shared.checkPermission()
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: hasPermission ? "checkmark.shield.fill" : "exclamationmark.shield.fill")
                .resizable()
                .frame(width: 50, height: 60)
                .foregroundColor(hasPermission ? .green : .yellow)
            
            Text("permission_title")
                .font(.headline)
            
            if hasPermission {
                Text("permission_granted")
                    .foregroundColor(.green)
            } else {
                Text("permission_desc")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                
                Button("open_system_settings") {
                    if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent") {
                        NSWorkspace.shared.open(url)
                    }
                }
            }
            
            Spacer()
        }
        .padding()
        .onAppear {
            hasPermission = KeyboardEventTapManager.shared.checkPermission()
        }
    }
}

struct AboutView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image("FamilyImage")
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 150)
                .cornerRadius(10)
                .shadow(radius: 5)
            
            Text("GraveSwitch")
                .font(.largeTitle)
                .bold()
            
            Text("about_desc")
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Text("about_credit")
                .font(.callout)
                .italic()
                .foregroundColor(.secondary)
                .padding(.top)
        }
        .padding()
    }
}
