import Foundation
import Carbon

class InputSourceManager {
    static let shared = InputSourceManager()
    
    struct InputSource: Identifiable, Hashable {
        let id: String
        let name: String
        let sourceRef: TISInputSource
    }
    
    func availableSources() -> [InputSource] {
        let properties = [kTISPropertyInputSourceIsSelectCapable: true] as CFDictionary
        guard let sourceList = TISCreateInputSourceList(properties, false)?.takeRetainedValue() as? [TISInputSource] else {
            return []
        }
        
        return sourceList.compactMap { source in
            guard let typePtr = TISGetInputSourceProperty(source, kTISPropertyInputSourceType) else { return nil }
            let type = Unmanaged<CFString>.fromOpaque(typePtr).takeUnretainedValue() as String
            
            if type != kTISTypeKeyboardLayout as String {
                return nil
            }
            
            guard let idPtr = TISGetInputSourceProperty(source, kTISPropertyInputSourceID) else { return nil }
            let id = Unmanaged<CFString>.fromOpaque(idPtr).takeUnretainedValue() as String
            
            guard let namePtr = TISGetInputSourceProperty(source, kTISPropertyLocalizedName) else { return nil }
            let name = Unmanaged<CFString>.fromOpaque(namePtr).takeUnretainedValue() as String
            
            return InputSource(id: id, name: name, sourceRef: source)
        }
    }
    
    func toggle() {
        let current = currentSourceID()
        let settings = SettingsManager.shared
        
        let targetID: String
        if current == settings.languageA {
            targetID = settings.languageB
        } else {
            targetID = settings.languageA
        }
        
        selectSource(id: targetID)
    }
    
    func currentSourceID() -> String? {
        let current = TISCopyCurrentKeyboardInputSource().takeRetainedValue()
        guard let idPtr = TISGetInputSourceProperty(current, kTISPropertyInputSourceID) else { return nil }
        return Unmanaged<CFString>.fromOpaque(idPtr).takeUnretainedValue() as String
    }
    
    func currentSourceLocalizedName() -> String? {
        let current = TISCopyCurrentKeyboardInputSource().takeRetainedValue()
        guard let namePtr = TISGetInputSourceProperty(current, kTISPropertyLocalizedName) else { return nil }
        return Unmanaged<CFString>.fromOpaque(namePtr).takeUnretainedValue() as String
    }
    
    private func selectSource(id: String) {
        if let source = availableSources().first(where: { $0.id == id }) {
            TISSelectInputSource(source.sourceRef)
        }
    }
}
