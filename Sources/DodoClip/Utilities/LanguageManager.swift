import Foundation

/// Supported languages in the app
enum AppLanguage: String, CaseIterable, Codable {
    case system = "system"
    case english = "en"
    case german = "de"
    case turkish = "tr"
    case french = "fr"
    case spanish = "es"
    case simplifiedChinese = "zh-Hans"
    case traditionalChinese = "zh-Hant"

    var displayName: String {
        switch self {
        case .system:
            return "System Default"
        case .english:
            return "English"
        case .german:
            return "Deutsch"
        case .turkish:
            return "Türkçe"
        case .french:
            return "Français"
        case .spanish:
            return "Español"
        case .simplifiedChinese:
            return "简体中文"
        case .traditionalChinese:
            return "繁體中文"
        }
    }

    /// Get the language code for NSLocalizedString
    var languageCode: String? {
        switch self {
        case .system:
            return nil  // Use system default
        default:
            return self.rawValue
        }
    }
}

/// Manager for handling app language changes
@MainActor
final class LanguageManager: ObservableObject {
    static let shared = LanguageManager()

    @Published private(set) var currentLanguage: AppLanguage

    private let languageKey = "AppLanguage"
    private var languageBundle: Bundle?

    private init() {
        // Load saved language preference
        if let savedLanguage = UserDefaults.standard.string(forKey: languageKey),
           let language = AppLanguage(rawValue: savedLanguage) {
            self.currentLanguage = language
        } else {
            self.currentLanguage = .system
        }

        // Apply the language at startup
        applyLanguage(currentLanguage)

        // Setup the language bundle for runtime use
        setupLanguageBundle()
    }

    /// Change the app language
    func setLanguage(_ language: AppLanguage) {
        currentLanguage = language

        // Save preference
        UserDefaults.standard.set(language.rawValue, forKey: languageKey)

        // Apply the language
        applyLanguage(language)

        // Clear L10n bundle cache to force reload
        L10n.reloadBundle()

        // Notify observers
        objectWillChange.send()
    }

    /// Apply language setting to UserDefaults
    private func applyLanguage(_ language: AppLanguage) {
        if let languageCode = language.languageCode {
            // Set the language preference for the app
            UserDefaults.standard.set([languageCode], forKey: "AppleLanguages")
        } else {
            // Remove custom language setting to use system default
            UserDefaults.standard.removeObject(forKey: "AppleLanguages")
        }
    }

    /// Setup the language bundle for current language
    private func setupLanguageBundle() {
        guard let languageCode = currentLanguage.languageCode else { return }

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
                let withoutRegion = components.dropLast().joined(separator: "-")
                languageCodes.append(withoutRegion)
                languageCodes.append(withoutRegion.lowercased())
            }
            if components.count > 1 {
                let baseLanguage = String(components[0])
                languageCodes.append(baseLanguage)
                languageCodes.append(baseLanguage.lowercased())
            }
        }

        for code in languageCodes {
            if let path = mainBundle.path(forResource: code, ofType: "lproj") {
                languageBundle = Bundle(path: path)
                return
            }
        }
    }

    /// Get localized string with current language
    func localizedString(_ key: String) -> String {
        if let bundle = languageBundle {
            return NSLocalizedString(key, bundle: bundle, comment: "")
        }
        return NSLocalizedString(key, comment: "")
    }
}
