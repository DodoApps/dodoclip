import SwiftUI
import SwiftData

@main
struct DodoClipApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    init() {
        // Initialize language manager to apply saved language preference
        _ = LanguageManager.shared
    }

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            ClipItem.self,
            Collection.self,
            AppSettings.self
        ])

        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )

        do {
            return try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        // Settings window (opened via menu)
        Settings {
            SettingsView()
        }
        .modelContainer(sharedModelContainer)
    }
}

/// Placeholder settings view
struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralSettingsTab()
                .tabItem {
                    Label(L10n.Settings.general, systemImage: "gear")
                }

            ShortcutsSettingsTab()
                .tabItem {
                    Label(L10n.Settings.shortcuts, systemImage: "keyboard")
                }

            RulesSettingsTab()
                .tabItem {
                    Label(L10n.Settings.rules, systemImage: "checklist")
                }

            AboutSettingsTab()
                .tabItem {
                    Label(L10n.Settings.about, systemImage: "info.circle")
                }
        }
        .frame(width: 500, height: 350)
    }
}

struct GeneralSettingsTab: View {
    @ObservedObject private var settingsService = SettingsService.shared
    @ObservedObject private var languageManager = LanguageManager.shared

    var body: some View {
        Form {
            Section(L10n.Settings.language) {
                Picker(L10n.Settings.interfaceLanguage, selection: Binding(
                    get: { languageManager.currentLanguage },
                    set: { newLanguage in
                        languageManager.setLanguage(newLanguage)
                        // Show alert that restart is required
                        showRestartAlert()
                    }
                )) {
                    ForEach(AppLanguage.allCases, id: \.self) { language in
                        Text(language.displayName).tag(language)
                    }
                }
                .pickerStyle(.menu)
                
                Text(L10n.Settings.restartRequired)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Section {
                Toggle(L10n.Settings.General.launchAtLogin, isOn: Binding(
                    get: { settingsService.launchAtLogin },
                    set: { settingsService.launchAtLogin = $0 }
                ))
                Toggle(L10n.Settings.General.showInMenuBar, isOn: .constant(true))
            }

            Section(L10n.Settings.General.history) {
                Picker(L10n.Settings.General.keepHistory, selection: Binding(
                    get: { settingsService.historyLimit },
                    set: { settingsService.historyLimit = $0 }
                )) {
                    Text(L10n.Settings.General.items(100)).tag(100)
                    Text(L10n.Settings.General.items(500)).tag(500)
                    Text(L10n.Settings.General.items(1000)).tag(1000)
                    Text(L10n.Settings.General.items(5000)).tag(5000)
                }
            }

            Section(L10n.Settings.General.panel) {
                Toggle(L10n.Settings.General.closeOnFocusLoss, isOn: Binding(
                    get: { settingsService.closeOnFocusLoss },
                    set: { settingsService.closeOnFocusLoss = $0 }
                ))
                Toggle(L10n.Settings.General.showCloseButton, isOn: Binding(
                    get: { settingsService.showCloseButton },
                    set: { settingsService.showCloseButton = $0 }
                ))
            }

            Section(L10n.Settings.General.cleanup) {
                Picker(L10n.Settings.General.autoDelete, selection: Binding(
                    get: { settingsService.autoDeleteAfterDays },
                    set: { settingsService.autoDeleteAfterDays = $0 }
                )) {
                    Text(L10n.Settings.General.autoDeleteNever).tag(0)
                    Text(L10n.Settings.General.autoDeleteDays(7)).tag(7)
                    Text(L10n.Settings.General.autoDeleteDays(14)).tag(14)
                    Text(L10n.Settings.General.autoDeleteDays(30)).tag(30)
                    Text(L10n.Settings.General.autoDeleteDays(90)).tag(90)
                }
            }

            Section(L10n.Settings.General.export) {
                Button(L10n.Settings.General.exportLinks) {
                    ExportService.shared.exportLinks(
                        items: ClipboardMonitor.shared.items,
                        format: .text
                    )
                }
                Button(L10n.Settings.General.exportAll) {
                    ExportService.shared.exportAll(
                        items: ClipboardMonitor.shared.items,
                        format: .csv
                    )
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }
    
    private func showRestartAlert() {
        let alert = NSAlert()
        alert.messageText = L10n.Settings.languageChanged
        alert.informativeText = L10n.Settings.restartPrompt
        alert.alertStyle = .informational
        alert.addButton(withTitle: L10n.Settings.restartNow)
        alert.addButton(withTitle: L10n.Settings.later)
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            // Restart the app
            restartApp()
        }
    }
    
    private func restartApp() {
        let url = URL(fileURLWithPath: Bundle.main.resourcePath!)
        let path = url.deletingLastPathComponent().deletingLastPathComponent().absoluteString
        let task = Process()
        task.launchPath = "/usr/bin/open"
        task.arguments = [path]
        task.launch()
        NSApplication.shared.terminate(nil)
    }
}

struct ShortcutsSettingsTab: View {
    var body: some View {
        Form {
            Section(L10n.Settings.Shortcuts.global) {
                HStack {
                    Text(L10n.Settings.Shortcuts.showPanel)
                    Spacer()
                    Text("⇧⌘V")
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text(L10n.Settings.Shortcuts.pasteStack)
                    Spacer()
                    Text("⇧⌘C")
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

struct RulesSettingsTab: View {
    @ObservedObject private var settingsService = SettingsService.shared

    var body: some View {
        Form {
            Section(L10n.Settings.Rules.privacy) {
                Toggle(L10n.Settings.Rules.ignorePasswordManagers, isOn: Binding(
                    get: { settingsService.ignorePasswordManagers },
                    set: { settingsService.ignorePasswordManagers = $0 }
                ))
                Toggle(L10n.Settings.Rules.ignoreAutoGenerated, isOn: Binding(
                    get: { settingsService.ignoreAutoGenerated },
                    set: { settingsService.ignoreAutoGenerated = $0 }
                ))
            }

            Section(L10n.Settings.Rules.ignoredApps) {
                if settingsService.ignoredAppBundleIDs.isEmpty {
                    Text(L10n.Settings.Rules.noAppsIgnored)
                        .foregroundColor(.secondary)
                } else {
                    ForEach(settingsService.ignoredAppBundleIDs, id: \.self) { bundleID in
                        IgnoredAppRow(bundleID: bundleID) {
                            settingsService.removeIgnoredApp(bundleID)
                        }
                    }
                }

                Button(L10n.Settings.Rules.addApp) {
                    showAppPicker()
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    private func showAppPicker() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [.application]
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        panel.message = "Select an application to ignore"
        panel.prompt = "Add"

        if panel.runModal() == .OK, let url = panel.url {
            if let bundle = Bundle(url: url), let bundleID = bundle.bundleIdentifier {
                settingsService.addIgnoredApp(bundleID)
            }
        }
    }
}

struct IgnoredAppRow: View {
    let bundleID: String
    let onRemove: () -> Void

    private var appName: String {
        if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) {
            return appURL.deletingPathExtension().lastPathComponent
        }
        return bundleID
    }

    private var appIcon: NSImage? {
        if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) {
            return NSWorkspace.shared.icon(forFile: appURL.path)
        }
        return nil
    }

    var body: some View {
        HStack(spacing: 8) {
            if let icon = appIcon {
                Image(nsImage: icon)
                    .resizable()
                    .frame(width: 20, height: 20)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(appName)
                    .font(.body)
                Text(bundleID)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button {
                onRemove()
            } label: {
                Image(systemName: "minus.circle.fill")
                    .foregroundColor(.red)
            }
            .buttonStyle(.plain)
        }
    }
}

struct AboutSettingsTab: View {
    private let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            // App icon
            if let appIcon = NSApp.applicationIconImage {
                Image(nsImage: appIcon)
                    .resizable()
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            } else {
                Image(systemName: "clipboard")
                    .font(.system(size: 64))
                    .foregroundColor(.accentColor)
            }

            // App name and version
            VStack(spacing: 4) {
                Text(L10n.App.name)
                    .font(.system(size: 24, weight: .bold))

                Text(L10n.About.version(appVersion))
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }

            // Description
            Text(L10n.App.description)
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Spacer()

            // Links
            HStack(spacing: 16) {
                Link(destination: URL(string: "https://github.com/bluewave-labs/dodoclip")!) {
                    Label(L10n.About.github, systemImage: "link")
                }

                Link(destination: URL(string: "https://github.com/bluewave-labs/dodoclip/issues")!) {
                    Label(L10n.About.reportIssue, systemImage: "exclamationmark.bubble")
                }
            }
            .font(.system(size: 12))

            // Copyright
            Text(L10n.About.copyright)
                .font(.system(size: 11))
                .foregroundColor(.secondary.opacity(0.7))

            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Previews

#Preview("Settings") {
    SettingsView()
}
