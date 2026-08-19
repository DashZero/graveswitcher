import Cocoa
import CoreGraphics
import Carbon
import OSLog
import ApplicationServices
import IOKit.hid

private let logger = Logger(subsystem: "com.example.GraveSwitch", category: "EventTap")

class KeyboardEventTapManager: ObservableObject {
    static let shared = KeyboardEventTapManager()
    
    @Published var hasPermission: Bool = false
    
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var consumedGravePress = false
    
    private var permissionCheckTimer: Timer?
    
    init() {
        updatePermissionStatus()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: NSApplication.didBecomeActiveNotification,
            object: nil
        )
    }
    
    @objc private func appDidBecomeActive() {
        DispatchQueue.main.async { [weak self] in
            _ = self?.checkPermission()
        }
    }
    
    func updatePermissionStatus() {
        let isPermitted = (eventTap != nil) || AXIsProcessTrusted() || CGPreflightListenEventAccess()
        if self.hasPermission != isPermitted {
            DispatchQueue.main.async {
                self.hasPermission = isPermitted
            }
        }
    }
    
    func startPermissionMonitoring() {
        permissionCheckTimer?.invalidate()
        permissionCheckTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.updatePermissionStatus()
            if self.eventTap == nil && SettingsManager.shared.isEnabled {
                if AXIsProcessTrusted() || CGPreflightListenEventAccess() {
                    try? self.start()
                    if self.eventTap != nil {
                        self.permissionCheckTimer?.invalidate()
                        self.permissionCheckTimer = nil
                    }
                }
            }
        }
    }
    
    func checkPermission() -> Bool {
        updatePermissionStatus()
        if eventTap != nil {
            return true
        }
        let trusted = AXIsProcessTrusted()
        let listenAccess = CGPreflightListenEventAccess()
        let granted = trusted || listenAccess
        
        if granted && SettingsManager.shared.isEnabled {
            try? start()
        } else if !granted {
            startPermissionMonitoring()
        }
        updatePermissionStatus()
        return eventTap != nil
    }
    
    func resetStalePermissions() {
        let bundleID = Bundle.main.bundleIdentifier ?? "com.example.GraveSwitch"
        let task1 = Process()
        task1.executableURL = URL(fileURLWithPath: "/usr/bin/tccutil")
        task1.arguments = ["reset", "Accessibility", bundleID]
        try? task1.run()
        task1.waitUntilExit()

        let task2 = Process()
        task2.executableURL = URL(fileURLWithPath: "/usr/bin/tccutil")
        task2.arguments = ["reset", "ListenEvent", bundleID]
        try? task2.run()
        task2.waitUntilExit()
    }

    func requestPermission() {
        resetStalePermissions()
        _ = CGRequestListenEventAccess()
        _ = IOHIDRequestAccess(kIOHIDRequestTypeListenEvent)
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }
    
    func start() throws {
        logger.info("Starting event tap...")
        if eventTap != nil {
            logger.info("Event tap is already running")
            return
        }
        
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
            let trusted = AXIsProcessTrusted()
            logger.error("CGEvent.tapCreate failed (returned nil). AXIsProcessTrusted = \(trusted)")
            throw NSError(domain: "GraveSwitch", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to create event tap. Accessibility trusted = \(trusted)"])
        }
        
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        logger.info("Event tap started and enabled successfully on main runloop!")
        updatePermissionStatus()
    }
    
    func stop() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
            if let runLoopSource = runLoopSource {
                CFRunLoopRemoveSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
            }
            eventTap = nil
            self.runLoopSource = nil
            logger.info("Event tap stopped")
            updatePermissionStatus()
        }
    }
    
    private func handleEvent(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            logger.warning("Event tap disabled by timeout/user input, re-enabling...")
            if let tap = eventTap {
                CGEvent.tapEnable(tap: tap, enable: true)
            }
            return Unmanaged.passUnretained(event)
        }
        
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        let flags = event.flags
        
        // Pass through if not Grave (ANSI 50 or ISO 10)
        if keyCode != CGKeyCode(kVK_ANSI_Grave) && keyCode != 10 {
            return Unmanaged.passUnretained(event)
        }
        
        logger.info("Grave key event detected! type: \(type.rawValue), flags: \(flags.rawValue)")
        
        // Let macOS native window switching pass through untouched
        if flags.contains(.maskCommand) || flags.contains(.maskControl) || flags.contains(.maskSecondaryFn) {
            logger.info("Passing through modifier+Grave")
            return Unmanaged.passUnretained(event)
        }
        
        // Literal emission via Option shortcut
        if flags.contains(.maskAlternate) {
            logger.info("Passing through Option+Grave")
            return Unmanaged.passUnretained(event)
        }
        
        if type == .keyDown {
            if event.getIntegerValueField(.keyboardEventAutorepeat) == 0 {
                consumedGravePress = true
                logger.info("Consuming Grave keyDown and triggering input source toggle")
                DispatchQueue.main.async {
                    InputSourceManager.shared.toggle()
                }
            }
            return nil
        } else if type == .keyUp {
            if consumedGravePress {
                consumedGravePress = false
                logger.info("Consuming Grave keyUp")
                return nil
            }
        }
        
        return Unmanaged.passUnretained(event)
    }
}
