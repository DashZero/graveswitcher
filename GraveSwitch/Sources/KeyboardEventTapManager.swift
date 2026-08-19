import Cocoa
import CoreGraphics
import Carbon

class KeyboardEventTapManager {
    static let shared = KeyboardEventTapManager()
    
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var consumedGravePress = false
    
    func checkPermission() -> Bool {
        return CGPreflightListenEventAccess()
    }
    
    func requestPermission() {
        _ = CGRequestListenEventAccess()
    }
    
    func start() throws {
        guard checkPermission() else {
            print("No permission")
            return
        }
        
        if eventTap != nil { return } // already running
        
        let mask = (1 << CGEventType.keyDown.rawValue) |
                   (1 << CGEventType.keyUp.rawValue) |
                   (1 << CGEventType.flagsChanged.rawValue)
        
        let userInfo = Unmanaged.passUnretained(self).toOpaque()
        
        eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(mask),
            callback: { proxy, type, event, refcon in
                let manager = Unmanaged<KeyboardEventTapManager>.fromOpaque(refcon!).takeUnretainedValue()
                return manager.handleEvent(proxy: proxy, type: type, event: event)
            },
            userInfo: userInfo
        )
        
        guard let tap = eventTap else {
            throw NSError(domain: "GraveSwitch", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to create event tap"])
        }
        
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
    }
    
    func stop() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
            if let runLoopSource = runLoopSource {
                CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
            }
            eventTap = nil
            self.runLoopSource = nil
        }
    }
    
    private func handleEvent(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let tap = eventTap {
                CGEvent.tapEnable(tap: tap, enable: true)
            }
            return Unmanaged.passUnretained(event)
        }
        
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        let flags = event.flags
        
        // Pass through if not Grave (ANSI 50)
        if keyCode != CGKeyCode(kVK_ANSI_Grave) {
            return Unmanaged.passUnretained(event)
        }
        
        // Let macOS native window switching pass through untouched
        if flags.contains(.maskCommand) || flags.contains(.maskControl) || flags.contains(.maskSecondaryFn) {
            return Unmanaged.passUnretained(event)
        }
        
        // Literal emission via Option shortcut
        if flags.contains(.maskAlternate) {
            // Emitting literal ` or ~
            // The simplest way to not consume it is to clear the option flag or generate new events.
            // But actually returning original event acts as dead key. Let's pass through option+` for now.
            return Unmanaged.passUnretained(event)
        }
        
        if type == .keyDown {
            if event.getIntegerValueField(.keyboardEventAutorepeat) == 0 {
                consumedGravePress = true
                DispatchQueue.main.async {
                    InputSourceManager.shared.toggle()
                }
            }
            return nil
        } else if type == .keyUp {
            if consumedGravePress {
                consumedGravePress = false
                return nil
            }
        }
        
        return Unmanaged.passUnretained(event)
    }
}
