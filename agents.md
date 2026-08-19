# GraveSwitch for macOS
## Product Requirements, Technical Architecture, Implementation Specification, Testing Plan, and AI-Agent Development Brief

**Document purpose:** This file is intended to be given directly to an AI coding agent (Codex, Claude Code, Gemini, Cursor, Roo/Kilo, etc.) to build a complete native macOS utility.

**Working product name:** GraveSwitch  
**Target platform:** macOS  
**Primary language:** Swift  
**UI framework:** SwiftUI + AppKit where required  
**Application type:** Lightweight menu-bar utility  
**Primary use case:** Make the top-left Grave/Backtick key behave like the common Windows Thai keyboard language-toggle setup.

---

# 1. Executive Summary

GraveSwitch is a tiny native macOS menu-bar application that allows the user to press the physical **Grave/Backtick key (`)** to toggle between two configured macOS keyboard input sources, for example:

- English / ABC
- Thai / Kedmanee

The app exists primarily to reproduce Windows muscle memory commonly used by Thai bilingual users.

Default behavior:

```text
Bare ` key          -> Toggle configured input source A <-> B
Shift + `            -> Toggle configured input source A <-> B
Command + `          -> PASS THROUGH unchanged
Option + `           -> Type a literal ` character
Option + Shift + `   -> Type a literal ~ character
All other keys       -> PASS THROUGH unchanged
```

The application must:

- run in the macOS menu bar;
- not require a Dock icon by default;
- launch automatically at login if enabled;
- detect the Grave key globally;
- selectively consume only the events that are explicitly mapped;
- switch input sources directly rather than simulating Control+Space or another shortcut;
- never interfere with Command+Grave, which macOS uses to switch windows within an application;
- recover gracefully if macOS disables the event tap;
- provide a simple first-run permission experience;
- work with built-in and external keyboards where possible;
- support user-selectable input sources rather than hard-coding English and Thai IDs.

The MVP should remain intentionally small. Do not turn this into a general keyboard-remapping product unless a later requirement explicitly asks for it.

---

# 2. Product Philosophy

The application solves one narrowly defined problem:

> "On Windows I press the top-left Grave key to change between English and Thai. Make my Mac behave the same way."

Design priorities, in order:

1. **Reliability**
2. **Low latency**
3. **Never break normal macOS shortcuts**
4. **Minimal UI**
5. **Minimal battery / CPU usage**
6. **Easy first-run setup**
7. **No cloud dependency**
8. **No telemetry by default**
9. **No account**
10. **No unnecessary framework**

This should feel like an operating-system behavior rather than an application.

---

# 3. Scope

## 3.1 MVP — Required

The MVP must include:

- Native macOS application
- Menu-bar status item
- Global Grave-key detection
- Input-source A / B selection
- Direct input-source switching
- Bare Grave toggle
- Shift+Grave toggle
- Command+Grave passthrough
- Option+Grave literal backtick escape
- Option+Shift+Grave literal tilde escape
- Event tap health monitoring / re-enable handling
- Input Monitoring permission onboarding
- Launch at Login
- Enable / Disable toggle
- Current input-source status in menu
- Persistent settings using `UserDefaults`
- Logging using `OSLog`
- Clean app termination
- Support for current supported macOS versions as defined below

## 3.2 Recommended for v1.0

- Option to disable Shift+Grave toggle
- Option to show menu-bar indicator:
  - `EN`
  - `TH`
  - generic keyboard icon
  - current input-source short label
- Optional brief HUD when switching
- "Test key" screen / diagnostic view
- "Open Input Monitoring Settings" helper button
- Reset settings
- Export diagnostic information to clipboard
- Detect missing configured input source and prompt user

## 3.3 Explicitly Out of Scope for MVP

Do NOT add these unless requested later:

- General-purpose arbitrary key remapping
- Per-application keyboard profiles
- Cloud sync
- User login
- Analytics
- Network access
- Auto-update framework
- Keyboard layout editor
- Custom IME
- Accessibility-based UI automation
- Mouse remapping
- Window management
- Clipboard manager
- Snippet expansion
- AI integration
- Electron
- React Native
- Flutter

---

# 4. Target User

Primary user:

- bilingual English/Thai macOS user;
- previously used Windows;
- accustomed to pressing the Grave key to switch keyboard language;
- rarely or never types a backtick directly;
- wants Windows muscle memory on macOS.

Secondary users:

- bilingual users of any two macOS input sources;
- users who want a dedicated physical toggle key.

The implementation must therefore **not assume Thai/English internally**. Thai/English should be the recommended default configuration, but the underlying architecture should handle any two selectable keyboard input sources.

---

# 5. Key Interaction Model

## 5.1 Default mapping table

| Input | Action |
|---|---|
| Bare Grave key down | Consume; toggle source A/B |
| Bare Grave key up | Consume |
| Shift + Grave key down | Consume; toggle source A/B |
| Shift + Grave key up | Consume |
| Command + Grave | Pass through completely |
| Command + Shift + Grave | Pass through completely |
| Option + Grave | Do not switch; emit/type literal backtick |
| Option + Shift + Grave | Do not switch; emit/type literal tilde |
| Control + Grave | Default: pass through |
| Fn + Grave | Default: pass through |
| Any other key | Pass through |

Important:

- Never intercept `Command + Grave`.
- Never intercept a combination containing Command unless a future user-configurable rule explicitly says to.
- The app must inspect modifier flags before consuming the event.

## 5.2 Why Command+Grave must survive

macOS commonly uses:

```text
Command + `
```

to cycle through windows of the current application.

The utility must not destroy this native behavior.

## 5.3 Literal backtick escape

Even if the user rarely uses backtick, developers may occasionally need it for:

- Markdown inline code
- Markdown fenced code blocks
- JavaScript / TypeScript template literals
- shell syntax
- SQL identifiers

Therefore the app must provide an escape route.

Recommended defaults:

```text
Option + `          -> `
Option + Shift + `  -> ~
```

If implementing literal emission by returning the original Option-modified event produces an accent/dead-key behavior on some layout, synthesize a Unicode keyboard event instead.

The literal-emission implementation must be tested with:

- ABC
- U.S.
- Thai Kedmanee
- Thai Pattachote if available
- active Thai source at time of escape
- Terminal
- VS Code
- TextEdit
- browser text fields

---

# 6. UX Specification

## 6.1 Application style

Use a menu-bar application.

Default state:

- no normal app window;
- no Dock icon;
- menu-bar item visible.

Suggested menu:

```text
[ EN ] or [ TH ]

GraveSwitch                 Enabled
Current Input:              English
Toggle Pair:                English <-> Thai

Enable GraveSwitch          [✓]
Settings...
Launch at Login             [✓]

Input Monitoring            Granted / Required
Open Privacy Settings

Quit GraveSwitch
```

Do not overload the menu.

## 6.2 Settings window

A compact settings window is acceptable.

Suggested sections:

### General

```text
GraveSwitch
Use the ` key to switch between two keyboard input sources.

[✓] Enable GraveSwitch
[✓] Launch at Login
[✓] Show current input source in menu bar
[ ] Show switch indicator
```

### Input Sources

```text
Input Source A: [ ABC / English       v ]
Input Source B: [ Thai - Kedmanee     v ]
```

Only list selectable keyboard input sources.

### Key Behavior

```text
Bare `            Switch input source
Shift + `         [ Switch input source v ]
Command + `       macOS default (protected)
Option + `        Type `
Option+Shift+`     Type ~
```

For MVP, most of these may be fixed rather than configurable, but show the user what will happen.

### Permissions

```text
Input Monitoring: [Granted]

GraveSwitch needs Input Monitoring to detect the ` key
while other apps are active.

[Open Privacy & Security]
```

## 6.3 First-run flow

On first launch:

1. Show welcome/settings window.
2. Explain exactly why Input Monitoring is required.
3. Check `CGPreflightListenEventAccess()`.
4. If permission not granted:
   - call `CGRequestListenEventAccess()`;
   - show instructions if system prompt does not appear;
   - provide button to open the appropriate System Settings Privacy & Security pane.
5. Detect available keyboard input sources.
6. Preselect sensible pair if possible:
   - English/ABC as A;
   - Thai as B.
7. If two suitable sources cannot be inferred, require user selection.
8. Start event tap only after permission is available.
9. Offer Launch at Login.

Do not repeatedly bombard the user with permission dialogs.

---

# 7. Technical Architecture

Recommended architecture:

```text
GraveSwitchApp
│
├── AppDelegate / application lifecycle
│
├── MenuBarController
│   ├── status item
│   └── menu commands
│
├── KeyboardEventTapManager
│   ├── permission check
│   ├── event tap creation
│   ├── event callback
│   ├── modifier filtering
│   ├── consume/pass-through decision
│   └── disabled-tap recovery
│
├── InputSourceManager
│   ├── enumerate selectable input sources
│   ├── identify current source
│   ├── select source
│   ├── toggle A/B
│   └── monitor source changes
│
├── LiteralKeyEmitter
│   ├── emit `
│   └── emit ~
│
├── PreferencesStore
│   └── UserDefaults / @AppStorage
│
├── LoginItemManager
│   └── SMAppService.mainApp
│
├── PermissionManager
│   ├── input monitoring
│   └── open System Settings
│
├── SettingsView
│
└── Diagnostics
    └── Logger / OSLog
```

Keep services separated. Do not put the entire event logic inside `AppDelegate`.

---

# 8. Recommended Project Configuration

## 8.1 Xcode

Create:

```text
macOS App
Language: Swift
Interface: SwiftUI
Lifecycle: SwiftUI App
```

AppKit interoperability is expected.

Suggested deployment target:

```text
macOS 13 Ventura or later
```

Reason:

- `SMAppService` is available for modern Launch at Login implementation from macOS 13 onward.
- Reduces legacy complexity.

If there is a strong reason to support macOS 12, isolate Launch at Login behind availability checks and implement a legacy fallback. Do not do that in MVP unless explicitly requested.

## 8.2 Framework imports likely needed

```swift
import SwiftUI
import AppKit
import CoreGraphics
import Carbon
import ServiceManagement
import OSLog
```

Notes:

- Carbon is old but Text Input Source Services (`TIS*`) remain the conventional macOS API surface used for input-source enumeration and selection.
- Do not use Carbon global hot-key registration for this feature.
- Use Quartz / CoreGraphics event taps for keyboard interception.

---

# 9. Keyboard Event Interception

## 9.1 API

Use:

```swift
CGEvent.tapCreate(...)
```

or equivalent Swift API spelling.

Quartz Event Services allows an event tap to monitor/filter events before delivery to the foreground application.

The event tap must include:

```text
keyDown
keyUp
tapDisabledByTimeout
tapDisabledByUserInput
```

The exact callback handling must account for the disabled-event types even if they are outside the normal event mask semantics.

## 9.2 Critical design choice: listen-only is insufficient

A `.listenOnly` event tap can observe, but cannot suppress the original Grave key.

This application needs to prevent the original Grave event from reaching the foreground app when Grave is being used as a language switch.

Therefore investigate and use an active event tap option that allows returning `nil` for events that should be consumed.

Expected approach:

```swift
options: .defaultTap
```

not:

```swift
options: .listenOnly
```

The agent must confirm behavior on the target macOS version.

Permission implications must be validated during implementation. Do not assume that observation-only permission behavior and event-filtering permission behavior are identical.

If active filtering requires Accessibility permission on a target macOS release, the app must clearly request the correct permission and document why.

This is a mandatory implementation spike before finalizing distribution assumptions.

## 9.3 Event location

Preferred starting point:

```swift
tap: .cgSessionEventTap
place: .headInsertEventTap
```

Rationale:

- session-wide;
- early enough to filter;
- avoids lower-level privileged HID interception.

Do not use an IOKit kernel-level keyboard driver for MVP.

## 9.4 Grave key identification

Do not compare generated characters such as:

```swift
event.characters == "`"
```

That is layout-dependent and unreliable.

Use the physical virtual key code:

```swift
event.getIntegerValueField(.keyboardEventKeycode)
```

The commonly expected ANSI Grave physical key code on macOS is:

```text
kVK_ANSI_Grave
```

from Carbon/HIToolbox.

Use the symbolic constant, not a magic number.

Example concept:

```swift
let keyCode = CGKeyCode(
    event.getIntegerValueField(.keyboardEventKeycode)
)

if keyCode == CGKeyCode(kVK_ANSI_Grave) {
    ...
}
```

Validate on:

- MacBook built-in keyboard
- Apple Magic Keyboard
- at least one PC-layout external USB/Bluetooth keyboard

Do not assume every international keyboard exposes the identical physical key position.

## 9.5 Modifier inspection

Read flags:

```swift
let flags = event.flags
```

Important flags:

```text
.maskCommand
.maskShift
.maskAlternate
.maskControl
.maskSecondaryFn
```

Normalize flags to ignore irrelevant state flags where appropriate, for example:

- Caps Lock
- numeric pad
- non-coalesced/internal flags

The decision logic should prioritize Command passthrough.

Recommended pseudocode:

```text
if key != Grave:
    pass through

if Command is pressed:
    pass through

if Option is pressed:
    if Shift:
        consume and emit "~"
    else:
        consume and emit "`"
    return

if Control is pressed:
    pass through

if only Shift is pressed:
    if setting.shiftGraveToggles:
        consume and toggle
    else:
        pass through
    return

if no relevant modifiers:
    consume and toggle
    return

otherwise:
    pass through
```

## 9.6 KeyDown / KeyUp handling

If the Grave `keyDown` is consumed, its corresponding `keyUp` should also normally be consumed so the foreground application does not receive an unmatched key-up event.

Track whether a Grave key press was captured.

Possible state:

```swift
private var consumedGravePress = false
```

On keyDown that triggers switching:

```text
consumedGravePress = true
return nil
```

On matching keyUp:

```text
if consumedGravePress:
    consumedGravePress = false
    return nil
```

Do not leave modifier state stuck.

## 9.7 Auto-repeat

Holding the Grave key must not rapidly toggle input languages.

Inspect:

```swift
.keyboardEventAutorepeat
```

or maintain pressed-state tracking.

Only toggle once per physical press.

Expected behavior:

```text
press and hold `
=> one language change only
```

not:

```text
EN TH EN TH EN TH ...
```

## 9.8 Event-tap timeout recovery

macOS can disable event taps if the callback blocks too long.

Handle:

```text
tapDisabledByTimeout
tapDisabledByUserInput
```

When encountered:

```swift
CGEvent.tapEnable(tap: eventTap, enable: true)
```

or appropriate equivalent.

The callback must do very little work.

Never:

- perform network calls;
- sleep;
- block on locks;
- show UI synchronously;
- perform slow enumeration;
- run expensive logging.

Input sources should be cached.

---

# 10. Event Callback Performance

The callback is on a latency-sensitive input path.

Target behavior:

```text
Event received
   ↓
Check keycode
   ↓
Check modifiers
   ↓
Fast toggle request / consume decision
   ↓
Return immediately
```

Aim for sub-millisecond decision time where practical.

Input-source switching may be dispatched to an appropriate queue if direct switching inside the callback risks latency, but this introduces a subtle race:

- If event is consumed immediately and toggle occurs asynchronously, acceptable.
- Ensure multiple presses do not queue uncontrolled toggles.

Possible solution:

```swift
toggleQueue.async {
    inputSourceManager.toggle()
}
```

Use a serial queue.

Do not dispatch everything to the main actor unnecessarily.

---

# 11. Input Source Management

## 11.1 Goal

Select input sources directly.

Do not simulate:

```text
Control + Space
Fn / Globe
Caps Lock
```

Simulated shortcuts depend on the user's Keyboard settings and can conflict with other shortcuts.

Use Text Input Source Services.

## 11.2 APIs

Research and use these APIs as appropriate:

```text
TISCopyCurrentKeyboardInputSource
TISCreateInputSourceList
TISGetInputSourceProperty
TISSelectInputSource
kTISPropertyInputSourceID
kTISPropertyLocalizedName
kTISPropertyInputSourceType
kTISPropertyInputSourceIsSelectCapable
kTISPropertyInputSourceIsEnabled
```

Potential notification:

```text
kTISNotifySelectedKeyboardInputSourceChanged
```

If practical, subscribe to input-source changes so the menu-bar label stays correct when the user changes language through another mechanism.

## 11.3 Input source model

Create:

```swift
struct KeyboardInputSource: Identifiable, Equatable, Hashable {
    let id: String
    let localizedName: String
    let languageCodes: [String]
    let isSelectable: Bool
    let isEnabled: Bool
}
```

Do not persist raw `TISInputSource` references across launches.

Persist stable source IDs.

At runtime, resolve IDs back to current `TISInputSource` objects.

## 11.4 Enumeration

Enumerate input sources that are:

- enabled;
- keyboard-capable;
- selectable.

Filter out:

- palettes;
- character viewers;
- non-keyboard services;
- disabled/unselectable sources.

Show localized names in UI.

Possible examples:

```text
ABC
U.S.
Thai
Thai - Kedmanee
Thai - Pattachote
```

The actual names and IDs vary by macOS release and installed sources, so never hard-code display names as identity.

## 11.5 Toggle algorithm

Preferred deterministic behavior:

```text
current == sourceA -> switch to sourceB
current == sourceB -> switch to sourceA
current == anythingElse -> switch to lastUsedOfAorB
```

For MVP, simpler fallback is acceptable:

```text
current not A/B -> switch to sourceA
```

Better v1 behavior:

Maintain:

```swift
lastPairSourceID
```

Whenever A or B becomes active, update it.

If current source is outside pair:

```text
switch to opposite of lastPairSourceID
```

This produces intuitive cycling after a temporary third input source.

## 11.6 Failure handling

`TISSelectInputSource()` returns a status.

Check it.

On failure:

- log OSStatus;
- do not crash;
- optionally show menu-bar error state;
- allow user to re-select input source.

If source A or B disappears:

- disable keyboard interception or leave Grave passthrough;
- show "Input source missing";
- do not consume Grave and leave user unable to type it.

Safety rule:

> If GraveSwitch cannot guarantee a successful switch, prefer passing the key through rather than silently swallowing user input.

---

# 12. Detecting Input Source Changes

The menu bar should update when the current source changes through:

- GraveSwitch;
- Control+Space;
- Caps Lock;
- Globe;
- macOS input menu;
- another utility.

Preferred implementation:

- observe the Text Input Source notification if stable;
- otherwise refresh current source when menu opens and after every internal toggle.

Do not poll aggressively.

If polling is required as a fallback, use a low frequency such as 0.5–1 second only while necessary, but event-based notification is preferred.

---

# 13. Permission Model

## 13.1 Input Monitoring

Apple's current guidance for global keyboard listening via `CGEventTap` points to Input Monitoring APIs:

```swift
CGPreflightListenEventAccess()
CGRequestListenEventAccess()
```

Use those APIs for onboarding/permission detection where they match the implemented event-tap mode.

## 13.2 Important active-filtering validation

The app does more than listen: it consumes selected events.

The coding agent must perform an explicit validation spike:

1. build a minimal event-tap prototype;
2. use `.defaultTap`;
3. return `nil` for Grave;
4. test on a clean macOS user account;
5. identify exactly which TCC permission is requested;
6. test sandbox ON;
7. test sandbox OFF;
8. document results.

Do not ship based on assumptions copied from a `.listenOnly` example.

## 13.3 System Settings deep link

Provide an "Open Privacy & Security" button.

Use a supported or commonly accepted System Settings URL only after validating it on the minimum OS.

If a deep link is unreliable, open System Settings generally and provide textual navigation:

```text
System Settings
> Privacy & Security
> Input Monitoring
```

or Accessibility if active filtering proves to require it.

Do not hard-code instructions that are false for the final permission model.

## 13.4 Permission denied behavior

If permission is unavailable:

```text
Event tap OFF
Grave key untouched
Menu status: Permission Required
```

The app must never create a broken partial state where Grave is swallowed but switching cannot occur.

---

# 14. Sandboxing and Distribution

This needs an implementation spike.

Possible channels:

## Option A — Direct distribution

- signed with Developer ID;
- notarized;
- distributed as `.dmg` or `.zip`;
- potentially simpler for low-level keyboard utility behavior.

## Option B — Mac App Store

Potentially possible depending on sandbox / event filtering behavior and review acceptance.

Apple DTS has stated that `CGEventTap` for monitoring can work in a sandbox and be distributed through the Mac App Store, particularly with Input Monitoring. However this application requires event filtering, not merely listening.

Therefore:

> Do not promise Mac App Store compatibility until active suppression has been tested in a sandboxed release build and App Review requirements are understood.

For a personal/internal utility, prioritize direct Developer ID distribution.

---

# 15. Launch at Login

Minimum deployment target macOS 13+:

Use:

```swift
SMAppService.mainApp
```

Expected logic:

```swift
try SMAppService.mainApp.register()
```

To disable:

```swift
try SMAppService.mainApp.unregister()
```

Read current status and reflect it in settings.

Do not use deprecated:

```text
LSSharedFileList
```

Do not install a helper executable merely for startup if `SMAppService.mainApp` is sufficient.

---

# 16. Menu-Bar Application Lifecycle

## 16.1 Dock icon

Recommended:

```text
Application is agent / LSUIElement = YES
```

or an appropriate SwiftUI/AppKit activation policy.

Desired behavior:

- no Dock icon during normal usage;
- settings window can become active/frontmost when opened.

Ensure settings window activation works even in accessory/agent mode.

## 16.2 Status item

Possible implementation:

- SwiftUI `MenuBarExtra` for macOS 13+, or
- `NSStatusItem` if more lifecycle/control is required.

Recommendation:

Start with SwiftUI `MenuBarExtra` for simple UI.

Use `NSStatusItem` if dynamic label or detailed AppKit control is more robust.

Avoid mixing both unnecessarily.

## 16.3 Icon/label

Preferred user setting:

```text
Automatic label
```

When English source active:

```text
EN
```

When Thai source active:

```text
TH
```

When another source is active:

```text
⌨
```

If deriving abbreviations automatically is unreliable, allow each selected source to have a short configurable label.

---

# 17. Literal Character Emission

This is one of the trickier parts.

## 17.1 Requirement

When user presses:

```text
Option + Grave
```

the foreground application should receive:

```text
`
```

without switching input source.

Option+Shift+Grave should produce:

```text
~
```

## 17.2 Possible implementation strategies

### Strategy A — Unicode CGEvent injection

Create a keyboard event and call:

```swift
keyboardSetUnicodeString(...)
```

Then post it.

Pros:

- independent of currently active input source.

Cons:

- some applications may interpret key events themselves;
- Apple documentation notes that frameworks may ignore the overridden Unicode string and perform their own translation.

### Strategy B — Temporarily pass a transformed physical event

Alter modifier flags and return/post the event.

Pros:

- behaves more like hardware.

Cons:

- generated character depends on current keyboard layout;
- Thai layout may not produce desired Latin backtick.

### Strategy C — Clipboard/paste

Reject for MVP.

It mutates user clipboard or requires preserving/restoring it and generates paste shortcuts. Too invasive.

Recommended:

Implement Strategy A first and test broadly.

If a target application ignores Unicode event strings, add a tested fallback.

## 17.3 Avoid recursion

Synthesized events may re-enter the event tap.

Set a custom `CGEventSource` user data marker:

```text
eventSourceUserData = unique magic value
```

or equivalent.

At the top of callback:

```text
if event was generated by GraveSwitch:
    pass through
```

Never intercept your own synthetic character event.

---

# 18. Input Event State Machine

Use a small explicit state machine.

Example:

```swift
enum GravePressAction {
    case passThrough
    case toggle
    case emitBacktick
    case emitTilde
    case consumeKeyUp
}
```

Pure decision function:

```swift
func classify(
    type: CGEventType,
    keyCode: CGKeyCode,
    flags: CGEventFlags,
    isRepeat: Bool,
    state: KeyboardState,
    settings: Settings
) -> GravePressAction
```

This decision function should be unit-testable without a live event tap.

Separate:

- deciding what an event means;
- performing side effects.

This is important for reliability.

---

# 19. Example Decision Matrix

| Grave? | Cmd | Opt | Shift | Ctrl | Repeat | Result |
|---|---:|---:|---:|---:|---:|---|
| No | any | any | any | any | any | Pass |
| Yes | 1 | any | any | any | any | Pass |
| Yes | 0 | 1 | 0 | 0 | 0 | Emit ` |
| Yes | 0 | 1 | 1 | 0 | 0 | Emit ~ |
| Yes | 0 | 0 | 0 | 1 | 0 | Pass |
| Yes | 0 | 0 | 0 | 0 | 0 | Toggle |
| Yes | 0 | 0 | 1 | 0 | 0 | Toggle if enabled |
| Yes | 0 | 0 | 0/1 | 0 | 1 | Consume/no second toggle |

Command always wins.

---

# 20. Race Conditions

Potential race:

```text
User taps Grave twice rapidly
```

Expected:

```text
EN -> TH -> EN
```

Do not debounce away legitimate fast taps.

However, do prevent key-repeat toggles.

Use key-up state rather than arbitrary timer debouncing.

Potential asynchronous queue:

```text
keydown #1 toggle queued
keydown #2 toggle queued before #1 completes
```

Use a serial queue or main actor for input-source selection to preserve order.

---

# 21. Secure Input Considerations

macOS can enable Secure Keyboard Entry / secure input contexts, particularly around password entry or terminal configuration.

The app must test behavior when secure input is active.

Safety requirement:

- if the event tap does not receive events, do nothing;
- never attempt to bypass secure-input protections;
- no privileged helper;
- no kernel extension.

Document that language switching may not function in protected contexts if macOS deliberately suppresses event monitoring.

---

# 22. Full-Screen Apps, Games, Remote Desktop, VMs

Test:

- full-screen Safari
- full-screen video
- VS Code
- Terminal
- Microsoft Remote Desktop / Windows App if available
- Parallels/VMware if available
- games, where practical

Default policy:

GraveSwitch is global.

However, future enhancement may support exclusions.

Do not add exclusions in MVP unless a concrete conflict is observed.

Important remote-desktop implication:

Bare Grave will be consumed by the Mac before it reaches the remote machine.

That is intentional for global language switching but may surprise users.

A future per-app bypass can solve this.

---

# 23. External Keyboards

Test at least:

- built-in MacBook keyboard
- Apple Magic Keyboard
- standard PC ANSI USB keyboard
- Bluetooth PC keyboard

Detect by keycode, not label.

Some ISO/JIS keyboards may put Grave elsewhere or use a different physical key.

MVP can explicitly support ANSI Grave first.

Document unsupported physical layouts rather than adding heuristic complexity.

---

# 24. Settings Data Model

Example:

```swift
struct AppSettings: Codable, Equatable {
    var isEnabled: Bool = true
    var sourceAID: String?
    var sourceBID: String?
    var shiftGraveToggles: Bool = true
    var launchAtLogin: Bool = true
    var showStatusLabel: Bool = true
    var showHUD: Bool = false
}
```

Prefer individual `UserDefaults` keys or `@AppStorage` for simple data.

Do not persist secrets.

---

# 25. Logging

Use Apple's unified logging:

```swift
Logger
```

Categories:

```text
app
eventTap
inputSource
permission
loginItem
literalEmitter
```

Never log raw typed characters or arbitrary keyboard input.

Safe logs:

```text
Event tap created
Event tap disabled by timeout
Toggle requested
Input source changed from <ID> to <ID>
Permission denied
TISSelectInputSource returned -xxxx
```

Privacy principle:

> The app must never function as a keylogger.

Only process enough event metadata to recognize the configured hotkey.

---

# 26. Privacy

The app monitors keyboard events because global hotkey interception requires it.

This is sensitive.

Required product behavior:

- no network access;
- no analytics by default;
- no key logging;
- no storage of key history;
- no typed-content inspection;
- no clipboard inspection;
- open-source-friendly design.

Permission explanation should say:

```text
GraveSwitch uses Input Monitoring only to detect the configured
language-switch key. It does not record what you type.
```

Do not make unverifiable privacy claims if future features add telemetry.

---

# 27. Accessibility

Settings UI should support:

- VoiceOver labels
- keyboard navigation
- sufficient contrast
- Dynamic Type where applicable
- descriptive toggle labels

A keyboard utility should itself be operable from the keyboard.

---

# 28. Visual Design

Keep it native.

Use macOS system controls.

Avoid:

- custom gradients;
- giant cards;
- mobile-looking toggles;
- animated marketing UI;
- unnecessary onboarding carousel.

Desired aesthetic:

```text
small
native
quiet
utility-like
```

Use SF Symbols where helpful:

- `keyboard`
- `globe`
- `checkmark.circle`
- `exclamationmark.triangle`
- `gearshape`

---

# 29. Error States

## Permission missing

```text
GraveSwitch is paused.
Allow Input Monitoring to use the ` key for language switching.
[Open System Settings]
```

## Input source missing

```text
One of your selected input sources is no longer available.
Choose another source.
```

## Event tap failed

```text
Keyboard monitor could not start.
[Retry]
```

## Input source switch failed

Prefer temporarily letting Grave pass through if repeated failures occur.

Never silently swallow the key indefinitely.

---

# 30. Event Tap Watchdog

Implement health state:

```swift
enum EventTapStatus {
    case stopped
    case starting
    case active
    case permissionRequired
    case failed(String)
}
```

When the OS disables the tap by timeout:

1. log;
2. re-enable;
3. confirm status;
4. do not recreate multiple taps.

If invalidated completely:

1. tear down run-loop source;
2. create a fresh tap once;
3. rate-limit retries.

Avoid retry loops consuming CPU.

---

# 31. Threading

Suggested:

- UI: `MainActor`
- Event tap: dedicated thread/run loop or carefully managed run-loop source
- Toggle operations: serial queue / actor
- TIS state access: synchronize where necessary

A robust design could use:

```swift
actor InputSourceController
```

but confirm TIS APIs behave correctly from the selected thread.

Do not introduce Swift concurrency purely for style.

---

# 32. Suggested File Structure

```text
GraveSwitch/
├── GraveSwitchApp.swift
├── AppDelegate.swift
│
├── Models/
│   ├── AppSettings.swift
│   ├── KeyboardInputSource.swift
│   └── EventTapStatus.swift
│
├── Services/
│   ├── KeyboardEventTapManager.swift
│   ├── GraveEventClassifier.swift
│   ├── InputSourceManager.swift
│   ├── LiteralKeyEmitter.swift
│   ├── PermissionManager.swift
│   ├── LoginItemManager.swift
│   └── SettingsStore.swift
│
├── UI/
│   ├── MenuBarContentView.swift
│   ├── SettingsView.swift
│   ├── GeneralSettingsView.swift
│   ├── InputSourceSettingsView.swift
│   └── PermissionView.swift
│
├── Utilities/
│   ├── Constants.swift
│   └── Log.swift
│
├── Resources/
│   └── Assets.xcassets
│
└── GraveSwitchTests/
    ├── GraveEventClassifierTests.swift
    ├── ToggleLogicTests.swift
    └── SettingsTests.swift
```

---

# 33. Core Implementation Pseudocode

## 33.1 Event tap manager

```swift
final class KeyboardEventTapManager {
    private var tap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var graveDownWasConsumed = false

    func start() throws {
        // 1. Check permission
        // 2. Create CGEvent tap
        // 3. Listen for keyDown and keyUp
        // 4. Add tap run-loop source
        // 5. Enable tap
    }

    func stop() {
        // invalidate and clean up
    }

    private func handle(
        proxy: CGEventTapProxy,
        type: CGEventType,
        event: CGEvent
    ) -> Unmanaged<CGEvent>? {

        // Re-enable if disabled by timeout
        // Ignore synthesized GraveSwitch events
        // Ignore non-Grave keys
        // Protect Command+Grave
        // Classify
        // Toggle / emit literal / pass / consume
    }
}
```

## 33.2 Input source manager

```swift
final class InputSourceManager {
    func availableSources() -> [KeyboardInputSource]

    func currentSourceID() -> String?

    func select(sourceID: String) -> Bool

    func toggle(sourceAID: String, sourceBID: String) -> Bool
}
```

## 33.3 Toggle

```text
current = currentSourceID()

if current == A:
    select B
else if current == B:
    select A
else:
    select A
```

Upgrade to last-pair behavior later.

---

# 34. Unit Tests

The pure event classifier should have exhaustive tests.

Examples:

```text
Grave no modifiers -> toggle
Grave Shift -> toggle
Grave Command -> pass
Grave Command+Shift -> pass
Grave Option -> emitBacktick
Grave Option+Shift -> emitTilde
Grave Control -> pass
Non-Grave -> pass
Grave autorepeat -> consume without toggle
KeyUp after consumed Grave -> consume
KeyUp after passed Command+Grave -> pass
```

Test modifier flags with unrelated flags present, such as Caps Lock.

---

# 35. Integration Tests

Manual/integration matrix:

## Apps

- Finder
- Safari
- Chrome
- TextEdit
- Notes
- Microsoft Word
- VS Code
- Xcode
- Terminal
- iTerm2 if available

## Behaviors

For every application:

1. type English;
2. press Grave;
3. verify Thai active;
4. type Thai;
5. press Grave;
6. verify English active;
7. press Command+Grave with two windows;
8. confirm window switching still works;
9. press Option+Grave;
10. confirm literal backtick appears;
11. press Option+Shift+Grave;
12. confirm tilde appears.

---

# 36. Stress Tests

Run:

```text
100 rapid Grave press cycles
```

Verify:

- no missed pair transitions;
- no double toggle;
- no event tap timeout;
- no stuck key;
- no rising memory;
- no CPU spike.

Hold Grave for 5 seconds.

Expected:

```text
one toggle
```

not repeated switching.

---

# 37. Permission Test Matrix

Test on a clean macOS account.

Cases:

1. First launch, permission absent
2. User accepts permission
3. User rejects permission
4. User enables permission later in Settings
5. User revokes permission while app is running
6. App updated/re-signed
7. App moved from Downloads to Applications
8. App launched from Xcode
9. Release build outside Xcode
10. Sandboxed build
11. Non-sandboxed build

Record exact macOS behavior.

---

# 38. Login Item Tests

- Enable launch at login
- Restart Mac
- Confirm app starts
- Confirm no unwanted settings window appears
- Confirm event tap starts
- Disable launch at login
- Restart
- Confirm app does not start
- Check macOS Login Items UI reflects expected state

---

# 39. Resource Usage Targets

Idle:

```text
CPU approximately 0%
```

Memory:

```text
Prefer < 50 MB
```

Network:

```text
0 requests
```

Disk writes:

```text
only preferences/logging managed by OS
```

Do not poll keyboard state in a tight loop.

---

# 40. Security Review

Before release verify:

- no network entitlement unless necessary;
- no microphone;
- no camera;
- no contacts;
- no location;
- no Files access beyond default app requirements;
- no shell execution;
- no privileged helper;
- no key history;
- no clipboard access;
- no Accessibility API use unless proven necessary;
- only required TCC permission requested.

---

# 41. Code Quality Rules for AI Agent

The coding agent must follow these rules:

1. Do not invent Apple APIs.
2. Compile after each meaningful implementation stage.
3. Resolve all warnings where practical.
4. Do not use private APIs.
5. Do not use undocumented TCC database manipulation.
6. Never run `tccutil` automatically in the product.
7. Do not shell out to change input sources.
8. Do not use AppleScript/System Events for switching.
9. Do not fake Control+Space.
10. Do not use Karabiner as a dependency.
11. Do not use an external package unless necessary.
12. Prefer Foundation/AppKit/CoreGraphics/Carbon/ServiceManagement.
13. Keep event callback minimal.
14. Do not swallow Grave unless the action can be completed safely.
15. Preserve Command+Grave at all costs.
16. Prevent autorepeat toggling.
17. Do not log user keystrokes.
18. Add tests for pure decision logic.
19. Use symbolic key constants.
20. Document any unavoidable OS-specific limitation.

---

# 42. Development Milestones

## Milestone 0 — Technical Spike

Goal:

Prove the core mechanism before building UI.

Build a minimal test app that:

- creates active `CGEventTap`;
- recognizes `kVK_ANSI_Grave`;
- consumes bare Grave;
- does not consume Command+Grave;
- logs event;
- toggles two hard-coded test input-source IDs.

Deliverable:

```text
Core mechanism proven on target macOS.
Exact permission requirement documented.
Sandbox behavior documented.
```

DO NOT proceed with polished UI until this passes.

## Milestone 1 — Input Source Service

Implement:

- enumeration;
- current source;
- selection;
- source IDs;
- toggle logic;
- tests where possible.

## Milestone 2 — Event Classifier

Implement pure event decision logic and unit tests.

## Milestone 3 — Global Event Tap

Connect classifier to active event tap.

Implement:

- keyDown;
- keyUp;
- modifiers;
- repeat protection;
- tap recovery;
- synthetic event marker.

## Milestone 4 — Literal Escape

Implement:

- Option+Grave -> backtick;
- Option+Shift+Grave -> tilde.

Test in developer apps.

## Milestone 5 — Menu Bar

Add:

- status item;
- enable toggle;
- current source;
- settings;
- quit.

## Milestone 6 — Settings

Add:

- source A/B;
- launch at login;
- shift toggle;
- menu label;
- permission state.

## Milestone 7 — Login at Startup

Implement `SMAppService.mainApp`.

## Milestone 8 — Hardening

Test:

- sleep/wake;
- lock/unlock;
- fast user switching where possible;
- external keyboards;
- permission revocation;
- event tap disable;
- rapid switching.

## Milestone 9 — Release

- Release build
- Developer ID signing
- Hardened Runtime as required
- notarization
- `.dmg` or `.zip`
- README
- privacy statement

---

# 43. Sleep / Wake Handling

After sleep/wake:

- event tap may need validation/re-enabling;
- current input source may have changed;
- menu state should refresh.

Observe workspace/power notifications if required.

Do not blindly recreate event taps on every notification without checking existing state.

---

# 44. Fast User Switching / Session Changes

Event tap is session-scoped.

On session transitions:

- ensure app remains within current logged-in user session;
- reinitialize event tap if necessary.

For MVP, document if not fully supported.

---

# 45. App Updates

MVP can be manually updated.

Do not include Sparkle initially.

If auto-update is added later:

- ensure code signing remains stable;
- verify TCC permission persistence behavior;
- avoid changing bundle identifier.

---

# 46. Bundle Identity

Choose one stable identifier before testing permissions, for example:

```text
com.devco.GraveSwitch
```

Do not change bundle ID between release builds because TCC/login-item behavior may be tied to application identity.

Use a real organization/team identifier appropriate to the developer account when signing.

---

# 47. Suggested Minimum macOS Version

Recommended:

```text
macOS 13+
```

If user machines are all newer, consider:

```text
macOS 14+
```

for simpler testing.

Do not set the deployment target to the newest macOS merely because the development Mac is new.

---

# 48. Product Naming

Working names:

1. GraveSwitch
2. Backtick Switch
3. WinGrave
4. KeyLang
5. LangTick

Recommendation:

```text
GraveSwitch
```

Clear to technical users, but "KeyLang" may be more understandable to non-developers.

Internal bundle name can remain GraveSwitch even if product name changes.

---

# 49. Optional Future Features

Only after MVP is stable.

## 49.1 Custom toggle key

Allow user to choose:

- Grave
- Caps Lock
- Right Command
- Right Option
- Function key

This would require significantly more remapping logic.

## 49.2 More than two languages

Possible cycle:

```text
EN -> TH -> JP -> EN
```

But binary A/B is much faster and easier to reason about.

## 49.3 Per-app bypass

Example:

```text
Do not intercept Grave in:
- Terminal
- VS Code
- Remote Desktop
```

Would require obtaining frontmost bundle ID.

## 49.4 Per-app input source

Automatically use:

```text
Terminal -> English
LINE -> Thai
```

Not part of original product.

## 49.5 HUD

Brief center-screen display:

```text
EN
```

or:

```text
ไทย
```

for 300–500 ms.

Keep optional.

---

# 50. Acceptance Criteria

The build is accepted only if all of these pass:

## Core

- [ ] Bare Grave toggles A -> B
- [ ] Bare Grave toggles B -> A
- [ ] Original Grave does not appear when used for switching
- [ ] Shift+Grave toggles if setting enabled
- [ ] Holding Grave does not repeatedly toggle
- [ ] Command+Grave works exactly as normal macOS behavior
- [ ] Command+Shift+Grave is not broken
- [ ] Option+Grave produces literal backtick
- [ ] Option+Shift+Grave produces literal tilde
- [ ] Other keyboard input is unaffected

## Input sources

- [ ] User can choose source A
- [ ] User can choose source B
- [ ] Current input source is correctly detected
- [ ] Invalid/missing source is handled safely
- [ ] External change of input source updates UI

## Reliability

- [ ] Event tap recovers after timeout disable
- [ ] Sleep/wake does not permanently break app
- [ ] Rapid switching does not crash
- [ ] No stuck key event observed
- [ ] No significant idle CPU usage

## Permissions

- [ ] First-run permission process works
- [ ] Permission denial does not swallow keys
- [ ] Permission revocation is handled
- [ ] Correct System Settings instructions shown

## App

- [ ] Menu bar UI works
- [ ] Quit works
- [ ] Settings persist
- [ ] Launch at Login works
- [ ] No Dock icon during normal operation
- [ ] Settings window can be brought forward

## Privacy

- [ ] No keystroke history stored
- [ ] No network access
- [ ] No unnecessary permissions

---

# 51. Definition of Done

"Done" means:

1. a clean Xcode project exists;
2. Release build compiles with no critical warnings;
3. the app works outside Xcode;
4. permission flow works on a clean user account;
5. language switching is reliable;
6. Command+Grave remains untouched;
7. literal backtick escape works;
8. app launches at login;
9. event tap survives typical daily use;
10. a signed/notarized distributable can be produced;
11. README explains installation and permissions;
12. tests cover the event classifier.

---

# 52. Required README

The repository README should include:

```text
# GraveSwitch

Use the ` key on macOS to switch between two keyboard input sources.

## Features
## Requirements
## Installation
## First Run
## Choosing Input Sources
## Key Mapping
## Privacy
## Troubleshooting
## Building from Source
```

Privacy section:

```text
GraveSwitch needs macOS keyboard monitoring permission to detect the configured
switch key globally. It does not store or transmit keystrokes.
```

Only use that statement if code audit confirms it.

---

# 53. Troubleshooting Guide

## Grave does nothing

Check:

1. GraveSwitch enabled?
2. input-source A/B configured?
3. Input Monitoring permission granted?
4. app restarted after permission grant if macOS requires it?
5. event tap active?

## Grave types ` instead of switching

Likely:

- event tap not active;
- permission missing;
- physical keyboard keycode differs.

## Command+Grave stops working

This is a critical bug.

Fix modifier filtering before release.

## Language changes twice

Likely:

- autorepeat not filtered;
- keyDown and keyUp both trigger;
- duplicate event taps running.

Toggle only on non-repeat keyDown.

## App works in Xcode but not Release

Investigate:

- sandbox entitlement;
- signing;
- TCC identity;
- hardened runtime;
- permission database entry.

Do not solve by disabling security globally.

---

# 54. Diagnostic Mode

Optional but useful during development.

Display:

```text
Event Tap: Active
Permission: Granted
Last Grave Keycode: 50
Last Action: Toggle
Current Source ID: ...
Source A: ...
Source B: ...
Generated Event Recursion: No
```

Do NOT display arbitrary last characters typed.

Diagnostic logging should be opt-in in production.

---

# 55. AI Agent Execution Instructions

When this document is given to an AI coding agent, use the following process.

## Phase A — Inspect environment

The agent must determine:

- macOS version;
- Xcode version;
- Swift version;
- signing team availability;
- target Mac architecture(s).

Do not require clarification if defaults are obvious.

## Phase B — Build minimal spike first

Before building UI, create the smallest runnable macOS target proving:

```text
Grave detected
Command+Grave passed
Bare Grave consumed
Input source switched
```

Compile and run it.

## Phase C — Report technical findings

Record in `TECHNICAL_FINDINGS.md`:

```text
macOS tested:
Event tap mode:
Permission required:
Sandbox:
Input source APIs:
Known limitations:
```

## Phase D — Implement production architecture

Only after spike works.

## Phase E — Test

Run automated unit tests and provide a manual test checklist.

## Phase F — Package

Generate a Release app.

Do not claim notarization succeeded unless the actual signing credentials exist and notarization was performed.

---

# 56. Agent Prompt — Copy/Paste Version

Use this prompt together with this specification:

```text
You are implementing GraveSwitch, a native macOS menu-bar utility.

Read GRAVESWITCH_SPEC.md completely before coding.

Your priority is to build a reliable, minimal macOS application that makes the
physical ANSI Grave/Backtick key switch between two configured macOS keyboard
input sources.

Critical rules:

1. Use Swift.
2. Use native Apple frameworks.
3. Use CGEventTap for global key interception.
4. Do not use NSEvent global monitoring as the primary mechanism.
5. Do not simulate Control+Space.
6. Switch input sources directly using macOS Text Input Source Services.
7. Bare Grave must toggle and be consumed.
8. Shift+Grave toggles by default.
9. Command+Grave MUST pass through unchanged.
10. Option+Grave must provide a way to type a literal backtick.
11. Prevent auto-repeat from repeatedly toggling.
12. Handle event-tap timeout/disable conditions.
13. Do not log typed content.
14. Do not use private APIs.
15. Do not use shell commands or AppleScript to change keyboard language.
16. Use SMAppService for Launch at Login on macOS 13+.
17. Keep the app a menu-bar utility with no Dock icon by default.
18. Perform a technical spike on active CGEventTap permissions before assuming
    Mac App Store/sandbox behavior.
19. Compile and test after each milestone.
20. Do not silently swallow Grave when switching cannot be performed.

First deliverable:
Build the minimal technical spike and document the exact event-tap permission
behavior on the installed macOS version.

Then continue through the milestones in GRAVESWITCH_SPEC.md.
```

---

# 57. Research Notes and Primary Sources

The development agent should prefer Apple's current official documentation over blog posts.

## Quartz Event Services

Apple — Quartz Event Services:

https://developer.apple.com/documentation/coregraphics/quartz-event-services

Apple — `CGEvent`:

https://developer.apple.com/documentation/coregraphics/cgevent

Apple — `CGEvent.tapCreate`:

https://developer.apple.com/documentation/coregraphics/cgevent/tapcreate(tap:place:options:eventsofinterest:callback:userinfo:)

Apple — `CGEventTapCallBack`:

https://developer.apple.com/documentation/coregraphics/cgeventtapcallback

Key point:

Quartz event taps can monitor and filter system input events before delivery to the foreground application.

## Permission guidance

Apple Developer Forums — Apple DTS engineer explanation of using `CGEventTap`
instead of `NSEvent` global monitor for a sandboxed app:

https://developer.apple.com/forums/thread/707680

Relevant APIs:

https://developer.apple.com/documentation/coregraphics/cgpreflightlisteneventaccess()

https://developer.apple.com/documentation/coregraphics/cgrequestlisteneventaccess()

Important:

The Apple DTS example shown publicly uses `.listenOnly`. GraveSwitch must consume
selected events, so the development spike must establish the permission requirements
for an active/default event tap rather than assuming identical behavior.

## Service Management / Launch at Login

Apple — `SMAppService`:

https://developer.apple.com/documentation/servicemanagement/smappservice

Apple — `SMAppService.mainApp`:

https://developer.apple.com/documentation/servicemanagement/smappservice/mainapp

Apple states that on macOS 13 and later, `SMAppService` is used to register/control
login items, LaunchAgents, and LaunchDaemons. `mainApp` can configure the main app
to launch at login.

## Input Sources

Apple — `NSTextInputContext.keyboardInputSources`:

https://developer.apple.com/documentation/appkit/nstextinputcontext/keyboardinputsources

Apple archived QA showing Text Input Source Services concepts including:

- `TISCreateInputSourceList`
- `TISGetInputSourceProperty`
- `kTISPropertyInputSourceID`

https://developer.apple.com/library/archive/qa/qa1810/_index.html

The coding agent should inspect the current SDK headers for Text Input Source Services
and use available public functions/constants rather than relying solely on archived
documentation.

---

# 58. Important Technical Uncertainties to Resolve Early

There are several areas where an AI agent must **test rather than assume**.

## 58.1 Permission needed for active event suppression

Known:

- Apple DTS explicitly recommends `CGEventTap` + Input Monitoring for global keyboard listening in sandboxed apps.
- Their published sample uses `.listenOnly`.

Unknown until tested:

- exact current TCC behavior when using `.defaultTap` and returning `nil` to suppress keyboard events on the target macOS version;
- whether Accessibility permission is additionally required;
- whether sandboxed Mac App Store distribution is viable for this exact filtering behavior.

Treat this as the first technical spike.

## 58.2 Literal Unicode event behavior

Apple notes that applications may perform their own keyboard translation even when a Unicode string is assigned to a generated keyboard event.

Therefore test literal backtick output across major apps.

## 58.3 Input-source APIs

Text Input Source Services are mature APIs with older documentation.

Compile against the current SDK and inspect official headers for exact Swift bridging.

Do not invent Swift signatures.

---

# 59. Recommended Product Decision

For the initial personal/internal release:

```text
Distribution: Direct
Minimum OS: macOS 13+
Architecture: Universal if practical (arm64 + x86_64)
App type: Menu bar
Sandbox: Decide after spike
Auto-update: No
Network: None
Telemetry: None
```

This minimizes complexity.

---

# 60. Final Architecture Recommendation

```text
                           macOS Keyboard Event Stream
                                      |
                                      v
                           +-----------------------+
                           |   CGEventTap Manager  |
                           +-----------------------+
                                      |
                          Is physical Grave key?
                              /               \
                            No                 Yes
                            |                   |
                       Pass event        Inspect modifiers
                                                |
                +-------------+-------------+---+------------+
                |             |             |                |
             Command        Option        Shift/bare       Other
                |             |             |                |
             PASS        emit ` / ~      TOGGLE            PASS
                                            |
                                            v
                                +-----------------------+
                                | InputSourceManager    |
                                | TISSelectInputSource  |
                                +-----------------------+
                                            |
                                            v
                                      EN <-> TH

                           +-----------------------+
                           | Menu Bar / Settings   |
                           +-----------------------+
                              |      |        |
                           A/B pair  Login   Permission
```

The event-classification layer must remain independent from UI and input-source side
effects.

---

# 61. Final Product Behavior

Once configured, normal daily use should be this simple:

```text
User is typing English
        |
        v
      presses `
        |
        v
      Thai active

User types Thai
        |
        v
      presses `
        |
        v
     English active
```

No pop-up.

No animation required.

No audible feedback.

No modifier.

No application switching.

No fake keyboard shortcut.

The utility should disappear into the operating system and feel like the Mac simply
supports the user's existing Windows language-switch muscle memory.


---

# 62. User-Facing Information Architecture

The production application must expose three clear user-facing areas:

```text
GraveSwitch
├── Menu Bar Menu
├── Settings
└── About & Help
```

The application must not assume the user understands terms such as:

- Grave key
- Backtick
- Input source
- Event tap
- Keyboard layout

Use plain language first and technical terms second.

For example:

```text
` key (Grave / Backtick)
```

rather than only:

```text
Grave
```

---

# 63. Main Menu Bar Menu

The menu-bar menu is the fastest place to control the app.

Recommended structure:

```text
GraveSwitch

Status: Active
Current Language: English

✓ Enable GraveSwitch

Switch Between
  English
  Thai

Settings...
Keyboard Shortcuts...
About GraveSwitch

Launch at Login        ✓

Quit GraveSwitch
```

If the app is disabled:

```text
GraveSwitch

Status: Paused
Current Language: English

  Enable GraveSwitch

Settings...
Keyboard Shortcuts...
About GraveSwitch

Launch at Login        ✓

Quit GraveSwitch
```

## 63.1 Enable / Disable Behavior

The user must be able to temporarily turn GraveSwitch off without quitting the app.

When enabled:

```text
Bare `     -> language switch
```

When disabled:

```text
Bare `     -> normal macOS key behavior
```

Disabling GraveSwitch must:

- stop consuming the Grave key immediately;
- preserve the menu-bar app;
- preserve all settings;
- preserve Launch at Login configuration;
- update menu-bar state to indicate the app is paused;
- not require permission changes;
- not quit the app.

Recommended setting:

```text
[✓] Enable GraveSwitch
```

Recommended menu command:

```text
Enable GraveSwitch
```

This is important for:

- development;
- gaming;
- remote desktop;
- troubleshooting;
- temporarily typing backticks normally;
- applications with unusual keyboard behavior.

The enabled state should persist across launches unless the user explicitly chooses a "Start Enabled" behavior later.

Default:

```text
Enabled = true
```

---

# 64. Settings Window — Complete UX

The Settings window should use a native macOS sidebar or tab structure.

Recommended sections:

```text
General
Languages
Keyboard
Appearance
Permissions
About
```

For a tiny utility, a simple toolbar/tab layout is also acceptable.

Do not create an oversized preferences window.

Recommended size:

```text
Approximately 520 x 430 points
```

Use standard macOS form spacing.

---

# 65. Settings — General

Suggested UI:

```text
General

GraveSwitch

[✓] Enable GraveSwitch

[✓] Launch at Login

[✓] Show current language in menu bar

[ ] Show a small language indicator when switching

Start behavior
[ Use previous state                v ]
```

Optional explanatory text:

```text
When GraveSwitch is enabled, pressing the ` key switches between
your two selected keyboard languages.
```

## 65.1 Enable GraveSwitch

Control:

```text
Toggle
```

Label:

```text
Enable GraveSwitch
```

Help text:

```text
Turn this off temporarily if you want the ` key to behave normally.
```

## 65.2 Launch at Login

Control:

```text
Toggle
```

Label:

```text
Launch at Login
```

Help text:

```text
Start GraveSwitch automatically when you sign in to your Mac.
```

## 65.3 Menu Bar Language Indicator

Control:

```text
Toggle
```

Label:

```text
Show current language in menu bar
```

Behavior:

```text
English -> EN
Thai    -> TH
Other   -> keyboard icon
```

If disabled:

```text
show generic GraveSwitch icon
```

---

# 66. Settings — Languages

Suggested UI:

```text
Languages

Choose the two keyboard languages GraveSwitch should switch between.

Language A
[ ABC / English                     v ]

Language B
[ Thai - Kedmanee                   v ]

Current Language
English

[Test Switch]
```

Use labels:

```text
Language A
Language B
```

rather than only:

```text
Input Source A
Input Source B
```

Technical wording can appear as secondary text:

```text
macOS Input Source
```

## 66.1 Validation

Do not allow the same source to be selected in both fields.

If user chooses the same value:

```text
Choose two different keyboard languages.
```

If one source becomes unavailable:

```text
Thai - Kedmanee is no longer available on this Mac.
Choose another keyboard language.
```

## 66.2 Test Switch

Button:

```text
Test Switch
```

Behavior:

- immediately switches to the other configured source;
- shows success/failure feedback;
- does not require pressing Grave.

This helps isolate configuration issues from keyboard-monitoring issues.

---

# 67. Settings — Keyboard

This screen must clearly explain the keyboard behavior.

Recommended UI:

```text
Keyboard

Language Switch Key

`  Grave / Backtick

[✓] Bare ` switches language
[✓] Shift + ` switches language

Protected macOS shortcuts

Command + `      Keep normal macOS behavior
Command + Shift + ` Keep normal macOS behavior

Typing the actual symbols

Option + `             Type `
Option + Shift + `     Type ~

These shortcuts let you keep using the actual Grave/Backtick
and Tilde characters even while GraveSwitch is enabled.
```

This screen is important. The user should not need to read documentation to understand how the remapping works.

---

# 68. Explanation of the Grave / Backtick Key

The app must explicitly explain what key is being remapped.

Recommended wording:

```text
What is the ` key?

The ` key is the key at the top-left of many keyboards, usually below Esc
and to the left of the number 1 key.

It is also called:
• Grave
• Grave Accent
• Backtick
```

Optional keyboard illustration:

```text
┌─────┬─────┬─────┬─────┐
│ Esc │ F1  │ F2  │ ... │
├─────┼─────┼─────┼─────┤
│  `  │  1  │  2  │  3  │
└─────┴─────┴─────┴─────┘
   ↑
Language switch
```

Do not assume the user knows the word "grave."

---

# 69. Actual Grave / Backtick Escape Explanation

This explanation is mandatory.

Recommended text:

```text
Need to type an actual ` character?

Press:

Option + `

GraveSwitch will type the real backtick instead of changing your keyboard language.
```

For tilde:

```text
Need to type ~ ?

Press:

Option + Shift + `
```

Important examples:

```text
Markdown:
`code`

JavaScript:
const message = `Hello ${name}`;
```

The help text should explain:

```text
You do not lose access to the ` key.
GraveSwitch simply gives it a new default action.

Use Option + ` whenever you need the actual backtick character.
```

This should appear:

1. during onboarding;
2. in Keyboard settings;
3. in Keyboard Shortcuts / Help;
4. optionally as a tooltip or info button near the main toggle.

---

# 70. Keyboard Shortcuts Screen

The app must include a dedicated keyboard-shortcut reference.

Menu item:

```text
Keyboard Shortcuts...
```

Recommended screen:

```text
Keyboard Shortcuts

Language Switching
`                        Switch language
Shift + `                Switch language

Type Symbols
Option + `               Type `
Option + Shift + `       Type ~

macOS Shortcuts Preserved
Command + `              Next window in current app
Command + Shift + `      Previous window in current app

Application
No global app shortcut is required for opening Settings.
```

Use a proper shortcut-row layout.

Example:

| Action | Shortcut |
|---|---|
| Switch language | ` |
| Switch language | Shift + ` |
| Type backtick | Option + ` |
| Type tilde | Option + Shift + ` |
| macOS next window | Command + ` |
| macOS previous window | Command + Shift + ` |

The UI should distinguish:

```text
GraveSwitch shortcuts
```

from:

```text
macOS shortcuts that GraveSwitch intentionally leaves untouched
```

---

# 71. Contextual Help

Use small information buttons where useful.

Example next to:

```text
Bare ` switches language     (i)
```

Tooltip/popover:

```text
The ` key is below Esc and to the left of 1 on most keyboards.
```

Example next to:

```text
Option + ` types `
```

Tooltip:

```text
Use this whenever you need the actual backtick character.
```

Avoid excessive tooltips.

---

# 72. First-Run Onboarding — Revised

The first-run experience should explain the product before asking for permission.

Recommended sequence:

## Screen 1 — Welcome

```text
Welcome to GraveSwitch

Use the ` key on your Mac to switch keyboard languages,
similar to the common Windows language-switch setup.

[Continue]
```

Add small visual:

```text
`  -> English <-> Thai
```

## Screen 2 — Choose Languages

```text
Choose Your Languages

Language A
[ English / ABC          v ]

Language B
[ Thai - Kedmanee        v ]

[Back] [Continue]
```

## Screen 3 — Important Shortcut Explanation

```text
You Can Still Type `

GraveSwitch uses the ` key for language switching.

When you need the actual backtick character, press:

Option + `

To type ~, press:

Option + Shift + `

Command + ` continues to work normally in macOS.

[Back] [Continue]
```

This screen is mandatory.

## Screen 4 — Permission

```text
Allow Keyboard Monitoring

GraveSwitch needs macOS permission to detect the ` key while
you are using other applications.

GraveSwitch does not record what you type.

[Open System Settings]
```

Only make the privacy statement if implementation matches it.

## Screen 5 — Finish

```text
You're Ready

`                       Switch language
Option + `              Type `
Command + `             Normal macOS window switching

[✓] Launch GraveSwitch at Login

[Start GraveSwitch]
```

Do not make onboarding longer than necessary.

---

# 73. About GraveSwitch Screen

The application needs an About screen.

Menu item:

```text
About GraveSwitch
```

Recommended content:

```text
[App Icon]

GraveSwitch
Version 1.0.0 (100)

Switch keyboard languages on macOS using the ` key.

Designed for users who prefer the Windows-style Grave-key
language switching workflow.

Website
GitHub
Privacy
Licenses

© 2026 <Developer / Company Name>
```

Do not hard-code the year if the build system can derive or maintain it more safely.

## 73.1 About Screen Fields

Required:

- app icon;
- app name;
- semantic version;
- build number;
- short product description;
- copyright;
- privacy information.

Optional:

- website;
- source code;
- support link;
- license;
- acknowledgements.

---

# 74. "About the App" Description

Recommended short description:

```text
GraveSwitch is a lightweight macOS menu-bar utility that lets you use
the ` key to switch between two keyboard languages.

It is designed for people who are used to the Windows-style Grave-key
language switch and want the same muscle memory on a Mac.
```

Recommended longer explanation:

```text
GraveSwitch changes only the keyboard shortcut used to switch languages.
It does not replace your keyboard layouts or install a custom input method.

Your existing macOS keyboard languages remain unchanged.

When GraveSwitch is enabled:
• ` switches between your two selected languages.
• Option + ` types the actual backtick character.
• Option + Shift + ` types ~.
• Command + ` continues to use the normal macOS window-switch shortcut.
```

---

# 75. "About Me" / Developer Section

The app may include a developer/about-author section.

Do not force personal information into the main About screen.

Recommended structure:

```text
Developer

Created by <Name / Company>

<One or two sentence description>

[Website]
[GitHub]
[Contact]
```

If this application is released by a company:

```text
Developed by DEVCO
```

If released personally:

```text
Created by Pititul Chavanachid
```

The development agent must not invent biography, job title, company details, email address, website, or social links.

Use placeholders unless the repository already contains verified values.

Example placeholder:

```text
Created by <Developer Name>
<Developer Website>
<Support Email>
```

---

# 76. Help / Instructions Screen

Add:

```text
Help
```

or:

```text
How to Use GraveSwitch
```

Recommended sections:

## Switching Language

```text
Press the ` key.

Each press switches between your two selected keyboard languages.
```

## Typing Backtick

```text
Press Option + `

This types the actual ` character instead of switching language.
```

## Typing Tilde

```text
Press Option + Shift + `

This types ~.
```

## Switching Windows on macOS

```text
Command + ` is not changed by GraveSwitch.

You can continue using it to move between windows of the current application.
```

## Temporarily Turn GraveSwitch Off

```text
Click the GraveSwitch menu-bar icon and turn off:

Enable GraveSwitch

The ` key will immediately return to normal.
```

## Change Languages

```text
Open:
GraveSwitch > Settings > Languages

Choose Language A and Language B.
```

## Start Automatically

```text
Open:
GraveSwitch > Settings > General

Turn on:
Launch at Login
```

## Permission Problems

```text
Open:
System Settings
> Privacy & Security
> Input Monitoring

Make sure GraveSwitch is allowed.
```

The exact permission name must match the final tested implementation.

---

# 77. Shortcut Cheat Sheet

A small cheat sheet can appear at the bottom of the settings window.

```text
Quick Reference

`                      EN <-> TH
Option + `             `
Option + Shift + `     ~
Command + `            macOS next window
```

For non-Thai configurations, use:

```text
`                      Language A <-> Language B
```

rather than:

```text
EN <-> TH
```

---

# 78. Status and Feedback

The app should make state obvious without being noisy.

## Enabled

Menu status:

```text
Active
```

or:

```text
GraveSwitch On
```

## Disabled

Menu status:

```text
Paused
```

or:

```text
GraveSwitch Off
```

## Permission missing

```text
Permission Required
```

## Missing language

```text
Setup Required
```

Avoid persistent notifications.

---

# 79. Optional Switch HUD

If enabled:

```text
┌─────────────┐
│     TH      │
│    ไทย      │
└─────────────┘
```

or:

```text
EN
```

Display:

```text
300–500 ms
```

Rules:

- no sound;
- no bouncing Dock icon;
- no Notification Center entry;
- do not steal focus.

Default:

```text
Off
```

---

# 80. Keyboard Shortcut Safety Rules

The implementation must obey this priority order:

```text
1. Command shortcuts are protected.
2. Explicit literal-character escape shortcuts are handled.
3. Configured language-switch combinations are handled.
4. Unknown combinations pass through.
```

Formally:

```text
if Command:
    PASS

else if Option:
    HANDLE literal escape if exact supported combination
    otherwise PASS

else if Control:
    PASS

else if bare Grave:
    TOGGLE if enabled

else if Shift+Grave:
    TOGGLE if enabled and configured

else:
    PASS
```

Do not interpret:

```text
Command + Option + `
```

as a GraveSwitch action.

Pass it through.

---

# 81. Disabled-State Event Rules

When:

```text
settings.isEnabled == false
```

the event tap may remain installed for fast re-enabling, but it must return every normal keyboard event untouched.

Recommended:

```text
if !settings.isEnabled {
    return event
}
```

Exception:

The event tap should still handle its own disabled-by-timeout maintenance events.

Do not consume:

```text
`
Option + `
Shift + `
```

while GraveSwitch is disabled.

All keys become native macOS behavior.

---

# 82. Menu Bar Contextual Status

Recommended status item presentation:

If current source is Language A:

```text
EN
```

If current source is Language B:

```text
TH
```

If app disabled:

```text
EN ·
```

or use a generic disabled visual.

Do not rely on color alone to show disabled state.

If permission missing:

```text
!
```

or warning badge is acceptable.

Accessibility labels must say:

```text
GraveSwitch, active, English
```

or:

```text
GraveSwitch, paused
```

---

# 83. Settings Persistence Requirements

Persist:

```text
isEnabled
sourceAID
sourceBID
shiftGraveToggles
launchAtLogin
showStatusLabel
showHUD
hasCompletedOnboarding
```

Do NOT reset these on application update.

If stored source IDs become invalid:

- retain values for diagnostics;
- flag configuration invalid;
- ask user to select replacements;
- do not silently pick an unrelated keyboard language.

---

# 84. About / Version Implementation

Read app version dynamically from:

```text
CFBundleShortVersionString
CFBundleVersion
```

Do not duplicate version strings in Swift source.

Example display:

```text
Version 1.0.0 (100)
```

---

# 85. Help Content Implementation

The initial release can store help text locally in SwiftUI views or bundled Markdown.

No web connection is required.

Recommended:

```text
HelpView.swift
```

or:

```text
Resources/Help.md
```

If using Markdown:

- render locally;
- no remote content;
- maintain versioned instructions with the application.

---

# 86. User-Facing Terminology

Use these preferred terms:

```text
Keyboard language
Language
` key
Grave / Backtick
Switch language
```

Avoid using these as primary UI labels:

```text
TISInputSource
Input source identifier
CGEventTap
virtual keycode
event interception
```

Those belong in diagnostics/developer documentation only.

---

# 87. UX Acceptance Criteria

The app is not UX-complete until all of these pass:

- [ ] User can turn GraveSwitch on and off from menu bar.
- [ ] User can turn GraveSwitch on and off from Settings.
- [ ] Disabled state immediately restores normal ` behavior.
- [ ] User can see which two languages are configured.
- [ ] User can change both languages.
- [ ] User can see current language.
- [ ] User is explicitly told how to type a real backtick.
- [ ] User is explicitly told how to type a tilde.
- [ ] User is explicitly told that Command + ` remains unchanged.
- [ ] Keyboard Shortcuts screen exists.
- [ ] About screen exists.
- [ ] Help / Instructions screen exists.
- [ ] Version and build number are shown.
- [ ] Launch at Login can be toggled.
- [ ] Permission status is visible.
- [ ] Missing permission has a recovery action.
- [ ] First-run onboarding explains Option + ` before enabling the remap.
- [ ] UI uses plain-language terminology.
- [ ] No user has to know what "CGEventTap" means.

---

# 88. Revised Final Menu Structure

Recommended production menu:

```text
EN

GraveSwitch
──────────────
Status: Active
Current Language: English

✓ Enable GraveSwitch

Switch Now

Settings...
Keyboard Shortcuts...
Help
About GraveSwitch
──────────────
✓ Launch at Login

Quit GraveSwitch
```

`Switch Now` is optional but useful for troubleshooting.

If included:

```text
Switch Now
```

performs the same A/B toggle as pressing Grave.

---

# 89. Revised Final Settings Structure

Recommended:

```text
┌──────────────────────────────────────────────┐
│ GraveSwitch Settings                        │
├──────────────────────────────────────────────┤
│ General | Languages | Keyboard | Permissions│
├──────────────────────────────────────────────┤
│                                              │
│ Selected settings content                    │
│                                              │
└──────────────────────────────────────────────┘
```

About and Help can be separate windows/sheets rather than settings tabs.

This keeps the primary Settings UI focused.

---

# 90. Final User Instruction Copy

Use concise language close to the following:

```text
Switch Language
Press `

Type the actual backtick
Press Option + `

Type a tilde
Press Option + Shift + `

Switch windows in the current Mac app
Press Command + `

Temporarily turn GraveSwitch off
Click the menu-bar icon and disable GraveSwitch.
```

This exact information must be easily discoverable inside the app.

---

# 91. Revised Definition of Done — User Experience

In addition to the technical Definition of Done, release is blocked until:

1. the app can be paused without quitting;
2. the settings window contains enable/disable;
3. the two languages are user-selectable;
4. the app explains what the ` key is;
5. the app explains that Option + ` types the real backtick;
6. the app explains Option + Shift + ` types tilde;
7. the app explains Command + ` remains a native macOS shortcut;
8. Keyboard Shortcuts documentation is built into the app;
9. Help/Instructions are built into the app;
10. About GraveSwitch is built into the app;
11. version and build information are visible;
12. first-run onboarding explains all critical behavior before remapping starts.

