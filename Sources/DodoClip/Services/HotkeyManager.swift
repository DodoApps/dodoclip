import Carbon
import AppKit
import Combine

/// Manages global hotkey registration using Carbon API
@MainActor
final class HotkeyManager: ObservableObject {
    static let shared = HotkeyManager()

    // Hotkey references
    private var panelHotkeyRef: EventHotKeyRef?
    private var pasteStackHotkeyRef: EventHotKeyRef?
    private var quickPasteHotkeyRefs: [EventHotKeyRef?] = Array(repeating: nil, count: 9)

    // Callbacks
    var onPanelHotkey: (() -> Void)?
    var onPasteStackHotkey: (() -> Void)?
    /// Called with the quick paste index (0-8) corresponding to Cmd+1 through Cmd+9
    var onQuickPasteHotkey: ((Int) -> Void)?

    // Hotkey IDs
    private let panelHotkeyID: UInt32 = 1
    private let pasteStackHotkeyID: UInt32 = 2
    // Quick paste IDs: 10-18 for Cmd+1 through Cmd+9
    private let quickPasteBaseID: UInt32 = 10

    private init() {}

    // MARK: - Registration

    func registerDefaultHotkeys() {
        // ⇧⌘V for panel
        registerPanelHotkey(keyCode: UInt32(kVK_ANSI_V), modifiers: shiftCmdModifiers)

        // ⇧⌘C for paste stack
        registerPasteStackHotkey(keyCode: UInt32(kVK_ANSI_C), modifiers: shiftCmdModifiers)

        // ⌃⌘1-9 for quick paste
        registerQuickPasteHotkeys()
    }

    private var shiftCmdModifiers: UInt32 {
        UInt32(cmdKey | shiftKey)
    }

    func registerPanelHotkey(keyCode: UInt32, modifiers: UInt32) {
        unregisterPanelHotkey()

        var hotkeyID = EventHotKeyID(signature: OSType(0x444F444F), id: panelHotkeyID) // "DODO"
        var hotkeyRef: EventHotKeyRef?

        let status = RegisterEventHotKey(
            keyCode,
            modifiers,
            hotkeyID,
            GetApplicationEventTarget(),
            0,
            &hotkeyRef
        )

        if status == noErr {
            panelHotkeyRef = hotkeyRef
            print("Panel hotkey registered successfully")
        } else {
            print("Failed to register panel hotkey: \(status)")
        }
    }

    func registerPasteStackHotkey(keyCode: UInt32, modifiers: UInt32) {
        unregisterPasteStackHotkey()

        var hotkeyID = EventHotKeyID(signature: OSType(0x444F444F), id: pasteStackHotkeyID)
        var hotkeyRef: EventHotKeyRef?

        let status = RegisterEventHotKey(
            keyCode,
            modifiers,
            hotkeyID,
            GetApplicationEventTarget(),
            0,
            &hotkeyRef
        )

        if status == noErr {
            pasteStackHotkeyRef = hotkeyRef
            print("Paste stack hotkey registered successfully")
        } else {
            print("Failed to register paste stack hotkey: \(status)")
        }
    }

    // Key codes for number keys 1-9
    private static let numberKeyCodes: [UInt32] = [
        UInt32(kVK_ANSI_1), UInt32(kVK_ANSI_2), UInt32(kVK_ANSI_3),
        UInt32(kVK_ANSI_4), UInt32(kVK_ANSI_5), UInt32(kVK_ANSI_6),
        UInt32(kVK_ANSI_7), UInt32(kVK_ANSI_8), UInt32(kVK_ANSI_9)
    ]

    func registerQuickPasteHotkeys() {
        unregisterQuickPasteHotkeys()

        let modifiers = UInt32(controlKey | cmdKey)

        for i in 0..<9 {
            var hotkeyID = EventHotKeyID(signature: OSType(0x444F444F), id: quickPasteBaseID + UInt32(i))
            var hotkeyRef: EventHotKeyRef?

            let status = RegisterEventHotKey(
                Self.numberKeyCodes[i],
                modifiers,
                hotkeyID,
                GetApplicationEventTarget(),
                0,
                &hotkeyRef
            )

            if status == noErr {
                quickPasteHotkeyRefs[i] = hotkeyRef
            } else {
                print("Failed to register quick paste hotkey Ctrl+Cmd+\(i + 1): \(status)")
            }
        }
    }

    func unregisterQuickPasteHotkeys() {
        for i in 0..<9 {
            if let ref = quickPasteHotkeyRefs[i] {
                UnregisterEventHotKey(ref)
                quickPasteHotkeyRefs[i] = nil
            }
        }
    }

    // MARK: - Unregistration

    func unregisterPanelHotkey() {
        if let ref = panelHotkeyRef {
            UnregisterEventHotKey(ref)
            panelHotkeyRef = nil
        }
    }

    func unregisterPasteStackHotkey() {
        if let ref = pasteStackHotkeyRef {
            UnregisterEventHotKey(ref)
            pasteStackHotkeyRef = nil
        }
    }

    func unregisterAll() {
        unregisterPanelHotkey()
        unregisterPasteStackHotkey()
        unregisterQuickPasteHotkeys()
    }

    // MARK: - Event Handling

    func setupEventHandler() {
        var eventSpec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))

        InstallEventHandler(
            GetApplicationEventTarget(),
            { (_, event, _) -> OSStatus in
                var hotkeyID = EventHotKeyID()
                GetEventParameter(
                    event,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &hotkeyID
                )

                Task { @MainActor in
                    HotkeyManager.shared.handleHotkey(id: hotkeyID.id)
                }

                return noErr
            },
            1,
            &eventSpec,
            nil,
            nil
        )
    }

    private func handleHotkey(id: UInt32) {
        switch id {
        case panelHotkeyID:
            onPanelHotkey?()
        case pasteStackHotkeyID:
            onPasteStackHotkey?()
        case quickPasteBaseID...(quickPasteBaseID + 8):
            let index = Int(id - quickPasteBaseID)
            onQuickPasteHotkey?(index)
        default:
            break
        }
    }
}

// MARK: - Key Code Constants

extension HotkeyManager {
    // Common key codes for reference
    static let keyCodeV: UInt32 = UInt32(kVK_ANSI_V)
    static let keyCodeC: UInt32 = UInt32(kVK_ANSI_C)
    static let keyCodeT: UInt32 = UInt32(kVK_ANSI_T)
    static let keyCodeF: UInt32 = UInt32(kVK_ANSI_F)

    // Modifier masks
    static let cmdModifier: UInt32 = UInt32(cmdKey)
    static let shiftModifier: UInt32 = UInt32(shiftKey)
    static let optionModifier: UInt32 = UInt32(optionKey)
    static let controlModifier: UInt32 = UInt32(controlKey)
    static let shiftCmdModifier: UInt32 = UInt32(cmdKey | shiftKey)
}
