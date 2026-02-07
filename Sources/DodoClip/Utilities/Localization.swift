import Foundation

/// Localization helper for accessing translated strings
enum L10n {
    // Cache the bundle to avoid repeated lookups
    private static var cachedBundle: Bundle?
    private static var cachedLanguageCode: String?
    
    private static var bundle: Bundle {
        // Get current language code
        let currentLanguageCode = UserDefaults.standard.array(forKey: "AppleLanguages")?.first as? String
        
        // Return cached bundle if language hasn't changed
        if let cached = cachedBundle, cachedLanguageCode == currentLanguageCode {
            return cached
        }
        
        // Language changed or first load, find the appropriate bundle
        let loadedBundle = loadLanguageBundle(for: currentLanguageCode)
        
        // Cache the result
        cachedBundle = loadedBundle
        cachedLanguageCode = currentLanguageCode
        
        return loadedBundle
    }
    
    private static func loadLanguageBundle(for languageCode: String?) -> Bundle {
        guard let languageCode = languageCode else {
            // No custom language, use default
            #if SWIFT_PACKAGE
            return Bundle.module
            #else
            return Bundle.main
            #endif
        }
        
        #if SWIFT_PACKAGE
        let mainBundle = Bundle.module
        #else
        let mainBundle = Bundle.main
        #endif
        
        // Try multiple variants of the language code
        var languageCodes: [String] = [languageCode, languageCode.lowercased()]
        
        // If language code contains region (e.g., zh-Hans-CN), also try without region
        if languageCode.contains("-") {
            let components = languageCode.split(separator: "-")
            if components.count > 2 {
                // Try without the last component: zh-Hans-CN -> zh-Hans
                let withoutRegion = components.dropLast().joined(separator: "-")
                languageCodes.append(withoutRegion)
                languageCodes.append(withoutRegion.lowercased())
            }
            if components.count > 1 {
                // Also try just the first component: zh-Hans-CN -> zh
                let baseLanguage = String(components[0])
                languageCodes.append(baseLanguage)
                languageCodes.append(baseLanguage.lowercased())
            }
        }
        
        for code in languageCodes {
            if let path = mainBundle.path(forResource: code, ofType: "lproj"),
               let languageBundle = Bundle(path: path) {
                print("✅ Loaded language bundle: \(code) for requested language: \(languageCode)")
                return languageBundle
            }
        }
        
        print("⚠️ Language bundle not found for: \(languageCode), tried: \(languageCodes), using default")
        
        // Fallback to default bundle
        #if SWIFT_PACKAGE
        return Bundle.module
        #else
        return Bundle.main
        #endif
    }
    
    /// Force reload the language bundle (call this when language changes)
    static func reloadBundle() {
        cachedBundle = nil
        cachedLanguageCode = nil
    }

    fileprivate static func tr(_ key: String) -> String {
        NSLocalizedString(key, bundle: bundle, comment: "")
    }
}

// MARK: - App
extension L10n {
    enum App {
        static var name: String { L10n.tr("app.name") }
        static var description: String { L10n.tr("app.description") }
    }
}

// MARK: - Menu
extension L10n {
    enum Menu {
        static var showPanel: String { L10n.tr("menu.showPanel") }
        static var preferences: String { L10n.tr("menu.preferences") }
        static var pasteStack: String { L10n.tr("menu.pasteStack") }
        static var pauseCapture: String { L10n.tr("menu.pauseCapture") }
        static var resumeCapture: String { L10n.tr("menu.resumeCapture") }
        static var clearHistory: String { L10n.tr("menu.clearHistory") }
        static var quit: String { L10n.tr("menu.quit") }

        enum Pause {
            static var fiveMin: String { L10n.tr("menu.pause.5min") }
            static var fifteenMin: String { L10n.tr("menu.pause.15min") }
            static var oneHour: String { L10n.tr("menu.pause.1hour") }
            static var untilResume: String { L10n.tr("menu.pause.untilResume") }
        }
    }
}

// MARK: - Panel
extension L10n {
    enum Panel {
        static var search: String { L10n.tr("panel.search") }
        static var searchClips: String { L10n.tr("panel.searchClips") }
        static var noItems: String { L10n.tr("panel.noItems") }
        static var noResults: String { L10n.tr("panel.noResults") }
        static var noClipsYet: String { L10n.tr("panel.noClipsYet") }
        static var noMatchesFound: String { L10n.tr("panel.noMatchesFound") }
        static var showPanel: String { L10n.tr("panel.showPanel") }
        static var noClipsOfType: String { L10n.tr("panel.noClipsOfType") }
        static var collectionEmpty: String { L10n.tr("panel.collectionEmpty") }
        static var tryDifferentSearch: String { L10n.tr("panel.tryDifferentSearch") }
        static var noItemsMatchFilter: String { L10n.tr("panel.noItemsMatchFilter") }
        static var copyToSeeHere: String { L10n.tr("panel.copyToSeeHere") }
        static var selected: String { L10n.tr("panel.selected") }
        static var clips: String { L10n.tr("panel.clips") }
        static var more: String { L10n.tr("panel.more") }
    }
}

// MARK: - Sections
extension L10n {
    enum Section {
        static var all: String { L10n.tr("section.all") }
        static var pinned: String { L10n.tr("section.pinned") }
        static var links: String { L10n.tr("section.links") }
        static var images: String { L10n.tr("section.images") }
        static var colors: String { L10n.tr("section.colors") }
    }
}

// MARK: - Context Menu
extension L10n {
    enum Context {
        static var paste: String { L10n.tr("context.paste") }
        static var pastePlainText: String { L10n.tr("context.pastePlainText") }
        static var copy: String { L10n.tr("context.copy") }
        static var copyToClipboard: String { L10n.tr("context.copyToClipboard") }
        static var pin: String { L10n.tr("context.pin") }
        static var unpin: String { L10n.tr("context.unpin") }
        static var delete: String { L10n.tr("context.delete") }
        static var open: String { L10n.tr("context.open") }
        static var addToStack: String { L10n.tr("context.addToStack") }
    }
}

// MARK: - Settings
extension L10n {
    enum Settings {
        static var title: String { L10n.tr("settings.title") }
        static var windowTitle: String { L10n.tr("settings.windowTitle") }
        static var general: String { L10n.tr("settings.general") }
        static var shortcuts: String { L10n.tr("settings.shortcuts") }
        static var rules: String { L10n.tr("settings.rules") }
        static var about: String { L10n.tr("settings.about") }
        static var language: String { L10n.tr("settings.language") }
        static var interfaceLanguage: String { L10n.tr("settings.interfaceLanguage") }
        static var restartRequired: String { L10n.tr("settings.restartRequired") }
        static var languageChanged: String { L10n.tr("settings.languageChanged") }
        static var restartPrompt: String { L10n.tr("settings.restartPrompt") }
        static var restartNow: String { L10n.tr("settings.restartNow") }
        static var later: String { L10n.tr("settings.later") }

        enum General {
            static var launchAtLogin: String { L10n.tr("settings.general.launchAtLogin") }
            static var showInMenuBar: String { L10n.tr("settings.general.showInMenuBar") }
            static var history: String { L10n.tr("settings.general.history") }
            static var keepHistory: String { L10n.tr("settings.general.keepHistory") }
            static func items(_ count: Int) -> String {
                String(format: L10n.tr("settings.general.items"), count)
            }
            static var panel: String { L10n.tr("settings.general.panel") }
            static var closeOnFocusLoss: String { L10n.tr("settings.general.closeOnFocusLoss") }
            static var showCloseButton: String { L10n.tr("settings.general.showCloseButton") }
            static var cleanup: String { L10n.tr("settings.general.cleanup") }
            static var autoDelete: String { L10n.tr("settings.general.autoDelete") }
            static var autoDeleteNever: String { L10n.tr("settings.general.autoDeleteNever") }
            static func autoDeleteDays(_ days: Int) -> String {
                String(format: L10n.tr("settings.general.autoDeleteDays"), days)
            }
            static var export: String { L10n.tr("settings.general.export") }
            static var exportLinks: String { L10n.tr("settings.general.exportLinks") }
            static var exportAll: String { L10n.tr("settings.general.exportAll") }
        }

        enum Shortcuts {
            static var global: String { L10n.tr("settings.shortcuts.global") }
            static var showPanel: String { L10n.tr("settings.shortcuts.showPanel") }
            static var pasteStack: String { L10n.tr("settings.shortcuts.pasteStack") }
        }

        enum Rules {
            static var privacy: String { L10n.tr("settings.rules.privacy") }
            static var ignorePasswordManagers: String { L10n.tr("settings.rules.ignorePasswordManagers") }
            static var ignoreAutoGenerated: String { L10n.tr("settings.rules.ignoreAutoGenerated") }
            static var ignoredApps: String { L10n.tr("settings.rules.ignoredApps") }
            static var noAppsIgnored: String { L10n.tr("settings.rules.noAppsIgnored") }
            static var addApp: String { L10n.tr("settings.rules.addApp") }
        }
    }
}

// MARK: - About
extension L10n {
    enum About {
        static func version(_ version: String) -> String {
            String(format: L10n.tr("about.version"), version)
        }
        static var github: String { L10n.tr("about.github") }
        static var reportIssue: String { L10n.tr("about.reportIssue") }
        static var copyright: String { L10n.tr("about.copyright") }
    }
}

// MARK: - Content Types
extension L10n {
    enum ContentType {
        static var text: String { L10n.tr("type.text") }
        static var richText: String { L10n.tr("type.richText") }
        static var image: String { L10n.tr("type.image") }
        static var file: String { L10n.tr("type.file") }
        static var link: String { L10n.tr("type.link") }
        static var color: String { L10n.tr("type.color") }
    }
}

// MARK: - Time
extension L10n {
    enum Time {
        static var justNow: String { L10n.tr("time.justNow") }
        static func minutesAgo(_ minutes: Int) -> String {
            String(format: L10n.tr("time.minutesAgo"), minutes)
        }
        static func hoursAgo(_ hours: Int) -> String {
            String(format: L10n.tr("time.hoursAgo"), hours)
        }
        static var yesterday: String { L10n.tr("time.yesterday") }
        static func daysAgo(_ days: Int) -> String {
            String(format: L10n.tr("time.daysAgo"), days)
        }
    }
}

// MARK: - Keyboard
extension L10n {
    enum Keyboard {
        static var navigate: String { L10n.tr("keyboard.navigate") }
        static var multiSelect: String { L10n.tr("keyboard.multiSelect") }
        static var paste: String { L10n.tr("keyboard.paste") }
        static var plainText: String { L10n.tr("keyboard.plainText") }
        static var quickPaste: String { L10n.tr("keyboard.quickPaste") }
        static var selectAll: String { L10n.tr("keyboard.selectAll") }
        static var pin: String { L10n.tr("keyboard.pin") }
        static var close: String { L10n.tr("keyboard.close") }
    }
}

// MARK: - Collection
extension L10n {
    enum Collection {
        static var rename: String { L10n.tr("collection.rename") }
        static var create: String { L10n.tr("collection.create") }
        static var name: String { L10n.tr("collection.name") }
        static var icon: String { L10n.tr("collection.icon") }
        static var color: String { L10n.tr("collection.color") }
    }
}

// MARK: - Onboarding
extension L10n {
    enum Onboarding {
        static var welcome: String { L10n.tr("onboarding.welcome") }
        static var pressShortcut: String { L10n.tr("onboarding.pressShortcut") }
        static var skip: String { L10n.tr("onboarding.skip") }
    }
}

// MARK: - Misc
extension L10n {
    enum Misc {
        static var pinned: String { L10n.tr("misc.pinned") }
        static var file: String { L10n.tr("misc.file") }
        static var chars: String { L10n.tr("misc.chars") }
    }
}
