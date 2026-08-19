import Foundation
import Carbon

class InputSourceSpike {
    static func toggleInputSource(appState: AppState?) {
        guard let sourceList = TISCreateInputSourceList(nil, false)?.takeRetainedValue() as? [TISInputSource] else {
            appState?.appendLog("Failed to get input sources")
            return
        }
        
        // Filter to selectable keyboard input sources
        let selectableSources = sourceList.filter { source in
            guard let typePtr = TISGetInputSourceProperty(source, kTISPropertyInputSourceType) else { return false }
            let type = Unmanaged<CFString>.fromOpaque(typePtr).takeUnretainedValue() as String
            if type != kTISTypeKeyboardLayout as String {
                return false
            }
            
            guard let selectPtr = TISGetInputSourceProperty(source, kTISPropertyInputSourceIsSelectCapable) else { return false }
            let isSelectable = Unmanaged<CFBoolean>.fromOpaque(selectPtr).takeUnretainedValue()
            return CFBooleanGetValue(isSelectable)
        }
        
        guard selectableSources.count >= 2 else {
            appState?.appendLog("Need at least 2 keyboard sources to toggle")
            return
        }
        
        guard let currentSource = TISCopyCurrentKeyboardInputSource()?.takeRetainedValue() else { return }
        
        let currentIDPtr = TISGetInputSourceProperty(currentSource, kTISPropertyInputSourceID)
        let currentID = Unmanaged<CFString>.fromOpaque(currentIDPtr!).takeUnretainedValue() as String
        
        // Find a source that isn't the current one
        if let nextSource = selectableSources.first(where: {
            let idPtr = TISGetInputSourceProperty($0, kTISPropertyInputSourceID)
            let id = Unmanaged<CFString>.fromOpaque(idPtr!).takeUnretainedValue() as String
            return id != currentID
        }) {
            let nextIDPtr = TISGetInputSourceProperty(nextSource, kTISPropertyInputSourceID)
            let nextID = Unmanaged<CFString>.fromOpaque(nextIDPtr!).takeUnretainedValue() as String
            
            appState?.appendLog("Switching to: \(nextID)")
            
            let status = TISSelectInputSource(nextSource)
            if status != noErr {
                appState?.appendLog("TISSelectInputSource failed with status: \(status)")
            } else {
                appState?.appendLog("Successfully switched")
            }
        }
    }
}
