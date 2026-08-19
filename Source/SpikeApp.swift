import SwiftUI
import AppKit

@main
struct SpikeApp: App {
    @StateObject private var appState = AppState()
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
        }
    }
}

class AppState: ObservableObject {
    @Published var log: String = ""
    @Published var isTapActive = false
    
    func appendLog(_ text: String) {
        DispatchQueue.main.async {
            self.log += "\(text)\n"
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
    }
}

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack {
            Text("GraveSwitch Spike")
                .font(.largeTitle)
                .padding()
            
            Text("Event Tap Status: \(appState.isTapActive ? "Active" : "Inactive")")
                .foregroundColor(appState.isTapActive ? .green : .red)
            
            HStack {
                Button("Start Event Tap") {
                    do {
                        try KeyboardEventTapManager.shared.start(appState: appState)
                    } catch {
                        appState.appendLog("Error: \(error.localizedDescription)")
                    }
                }
                
                Button("Stop Event Tap") {
                    KeyboardEventTapManager.shared.stop()
                    appState.isTapActive = false
                    appState.appendLog("Event tap stopped.")
                }
            }
            .padding()
            
            ScrollView {
                Text(appState.log)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            }
            .background(Color(NSColor.textBackgroundColor))
            .border(Color.gray, width: 1)
        }
        .padding()
        .frame(width: 500, height: 400)
    }
}
