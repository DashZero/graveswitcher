import Foundation
import CoreGraphics
import Carbon.HIToolbox

enum TapError: Error {
    case permissionDenied
    case failedToCreateTap
}

class KeyboardEventTapManager {
    static let shared = KeyboardEventTapManager()
    
    private var tap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var appState: AppState?
    
    private let kVK_ANSI_Grave: UInt16 = 0x32 // 50
    
    func start(appState: AppState) throws {
        self.appState = appState
        
        let hasAccess = CGPreflightListenEventAccess()
        if !hasAccess {
            let requestResult = CGRequestListenEventAccess()
            appState.appendLog("Requested access: \(requestResult)")
            if !requestResult {
                throw TapError.permissionDenied
            }
        } else {
            appState.appendLog("Permission already granted.")
        }
        
        let eventMask = (1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.keyUp.rawValue)
        
        let userInfo = Unmanaged.passUnretained(self).toOpaque()
        
        guard let eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap, // Active filtering
            eventsOfInterest: CGEventMask(eventMask),
            callback: eventTapCallback,
            userInfo: userInfo
        ) else {
            throw TapError.failedToCreateTap
        }
        
        self.tap = eventTap
        self.runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)
        
        appState.isTapActive = true
        appState.appendLog("Event tap successfully started.")
    }
    
    func stop() {
        if let runLoopSource = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
            self.runLoopSource = nil
        }
        if let tap = tap {
            CGEvent.tapEnable(tap: tap, enable: false)
            self.tap = nil
        }
    }
    
    func handleEvent(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let tap = tap {
                appState?.appendLog("Tap disabled by OS, attempting to re-enable...")
                CGEvent.tapEnable(tap: tap, enable: true)
            }
            return Unmanaged.passRetained(event)
        }
        
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        
        if keyCode == kVK_ANSI_Grave {
            let flags = event.flags
            
            // Command+Grave MUST pass through unchanged
            if flags.contains(.maskCommand) {
                appState?.appendLog("Passed through Command+Grave")
                return Unmanaged.passRetained(event)
            }
            
            // For spike, we'll consume Bare Grave and Option+Grave and Shift+Grave
            // Just to prove consumption works.
            if type == .keyDown {
                // Ignore autorepeat
                if event.getIntegerValueField(.keyboardEventAutorepeat) != 0 {
                    return nil
                }
                
                appState?.appendLog("Grave key pressed. Consuming and toggling.")
                InputSourceSpike.toggleInputSource(appState: appState)
            }
            
            return nil // Consume event
        }
        
        return Unmanaged.passRetained(event)
    }
}

func eventTapCallback(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent, refcon: UnsafeMutableRawPointer?) -> Unmanaged<CGEvent>? {
    guard let refcon = refcon else { return Unmanaged.passRetained(event) }
    let manager = Unmanaged<KeyboardEventTapManager>.fromOpaque(refcon).takeUnretainedValue()
    return manager.handleEvent(proxy: proxy, type: type, event: event)
}
