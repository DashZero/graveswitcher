import Foundation
import Carbon

class InputSourceManager: ObservableObject {
    static let shared = InputSourceManager()
    
    @Published var currentLanguageCode: String = "⌨"
    @Published var currentLanguageName: String = "Unknown"
    
    struct InputSource: Identifiable, Hashable {
        let id: String
        let name: String
        let sourceRef: TISInputSource
    }
    
    init() {
        updateCurrentSourceInfo()
        
        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(inputSourceChanged),
            name: NSNotification.Name(kTISNotifySelectedKeyboardInputSourceChanged as String),
            object: nil
        )
    }
    
    @objc private func inputSourceChanged() {
        DispatchQueue.main.async {
            self.updateCurrentSourceInfo()
        }
    }
    
    func updateCurrentSourceInfo() {
        guard let name = currentSourceLocalizedName() else {
            self.currentLanguageCode = "⌨"
            self.currentLanguageName = "Unknown"
            return
        }
        
        self.currentLanguageName = name
        let lower = name.lowercased()
        if lower.contains("thai") || lower.contains("ไทย") {
            self.currentLanguageCode = "🇹🇭"
        } else if lower.contains("abc") || lower.contains("english") || lower.contains("u.s.") || lower.contains("us") {
            self.currentLanguageCode = "🇺🇸"
        } else {
            self.currentLanguageCode = String(name.prefix(2)).uppercased()
        }
    }
    
    func availableSources() -> [InputSource] {
        let properties = [
            kTISPropertyInputSourceIsSelectCapable: true,
            kTISPropertyInputSourceCategory: kTISCategoryKeyboardInputSource
        ] as CFDictionary
        
        guard let sourceList = TISCreateInputSourceList(properties, false)?.takeRetainedValue() as? [TISInputSource] else {
            return []
        }
        
        return sourceList.compactMap { source in
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
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            self.updateCurrentSourceInfo()
        }
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
