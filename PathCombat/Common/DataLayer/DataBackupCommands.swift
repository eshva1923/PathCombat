import AppKit
import SwiftData
import UniformTypeIdentifiers

enum DataBackupCommands {
    static func exportData(context: ModelContext) {
        let panel = NSSavePanel()
        panel.title = "Export PathCombat Data"
        panel.nameFieldStringValue = "PathCombat Backup.csv"
        panel.allowedContentTypes = [.commaSeparatedText]

        guard panel.runModal() == .OK, let url = panel.url else { return }

        do {
            let csv = try DataBackupService.exportCSV(context: context)
            try csv.write(to: url, atomically: true, encoding: .utf8)
        } catch {
            presentError(error, title: "Export Failed")
        }
    }

    static func importData(context: ModelContext) {
        let panel = NSOpenPanel()
        panel.title = "Import PathCombat Data"
        panel.allowedContentTypes = [.commaSeparatedText]
        panel.allowsMultipleSelection = false

        guard panel.runModal() == .OK, let url = panel.url else { return }

        let confirmation = NSAlert()
        confirmation.messageText = "Replace all existing data?"
        confirmation.informativeText = "Importing will permanently delete all current encounters, entities, and conditions, replacing them with the contents of \"\(url.lastPathComponent)\"."
        confirmation.alertStyle = .warning
        confirmation.addButton(withTitle: "Import and Replace")
        confirmation.addButton(withTitle: "Cancel")
        guard confirmation.runModal() == .alertFirstButtonReturn else { return }

        do {
            let csv = try String(contentsOf: url, encoding: .utf8)
            try DataBackupService.importCSV(csv, context: context)
        } catch {
            presentError(error, title: "Import Failed")
        }
    }

    static func importSpellsFromAoN(context: ModelContext) {
        guard let includeLegacyDescriptions = confirmAoNImport(
            title: "Import Spells from Archive of Nethys?",
            message: "Downloads the current Pathfinder 2e spell list (about 1,800 spells) from 2e.aonprd.com and adds them to your Spells Library. Spells already imported from Archive of Nethys are refreshed to match the latest data; spells you created yourself are not affected."
        ) else { return }

        Task {
            do {
                let count = try await AoNSpellImportService.importSpells(context: context, includeLegacyDescriptions: includeLegacyDescriptions)
                await MainActor.run {
                    let alert = NSAlert()
                    alert.messageText = "Import Complete"
                    alert.informativeText = "Imported \(count) spells from Archive of Nethys."
                    alert.runModal()
                }
            } catch {
                await MainActor.run {
                    presentError(error, title: "Import Failed")
                }
            }
        }
    }

    static func importConditionsFromAoN(context: ModelContext) {
        guard let includeLegacyDescriptions = confirmAoNImport(
            title: "Import Conditions from Archive of Nethys?",
            message: "Downloads the current Pathfinder 2e condition list (about 56 conditions) from 2e.aonprd.com and adds them to your Conditions Library. Conditions already imported from Archive of Nethys are refreshed to match the latest data; conditions you created yourself are not affected."
        ) else { return }

        Task {
            do {
                let count = try await AoNConditionImportService.importConditions(context: context, includeLegacyDescriptions: includeLegacyDescriptions)
                await MainActor.run {
                    let alert = NSAlert()
                    alert.messageText = "Import Complete"
                    alert.informativeText = "Imported \(count) conditions from Archive of Nethys."
                    alert.runModal()
                }
            } catch {
                await MainActor.run {
                    presentError(error, title: "Import Failed")
                }
            }
        }
    }

    /// Shows the shared AoN import confirmation alert with a "merge legacy description" checkbox
    /// (defaulted off). Returns the checkbox state if the user confirmed, or `nil` if cancelled.
    private static func confirmAoNImport(title: String, message: String) -> Bool? {
        let confirmation = NSAlert()
        confirmation.messageText = title
        confirmation.informativeText = message
        confirmation.alertStyle = .informational
        confirmation.addButton(withTitle: "Import")
        confirmation.addButton(withTitle: "Cancel")

        let checkbox = NSButton(checkboxWithTitle: "Allow merging description from legacy content", target: nil, action: nil)
        checkbox.state = .off
        confirmation.accessoryView = checkbox

        guard confirmation.runModal() == .alertFirstButtonReturn else { return nil }
        return checkbox.state == .on
    }

    static func wipeEncounters(context: ModelContext) {
        confirmAndWipe(
            title: "Wipe all encounters?",
            message: "This will permanently delete every encounter. Entities and conditions are not affected.",
            context: context) { context in
                try DataBackupService.wipeEncounters(context: context)
            }
    }

    static func wipeEntities(context: ModelContext) {
        confirmAndWipe(
            title: "Wipe all entities?",
            message: "This will permanently delete every entity in the library, including any copies currently in encounters.",
            context: context) { context in
                try DataBackupService.wipeEntities(context: context)
            }
    }

    static func wipeConditions(context: ModelContext) {
        confirmAndWipe(
            title: "Wipe all conditions?",
            message: "This will permanently delete every condition definition, and remove any applied conditions that reference them.",
            context: context) { context in
                try DataBackupService.wipeConditions(context: context)
            }
    }

    static func wipeSpells(context: ModelContext) {
        confirmAndWipe(
            title: "Wipe all spells?",
            message: "This will permanently delete every spell definition, and remove any entity references to them.",
            context: context) { context in
                try DataBackupService.wipeSpells(context: context)
            }
    }

    static func wipeAll(context: ModelContext) {
        confirmAndWipe(
            title: "Wipe all data?",
            message: "This will permanently delete every encounter, entity, and condition.",
            context: context) { context in
                try DataBackupService.wipeAll(context: context)
            }
    }

    private static func confirmAndWipe(title: String, message: String, context: ModelContext, wipe: @MainActor (ModelContext) throws -> Void) {
        let confirmation = NSAlert()
        confirmation.messageText = title
        confirmation.informativeText = message
        confirmation.alertStyle = .warning
        confirmation.addButton(withTitle: "Wipe")
        confirmation.addButton(withTitle: "Cancel")
        guard confirmation.runModal() == .alertFirstButtonReturn else { return }

        do {
            try wipe(context)
        } catch {
            presentError(error, title: "Wipe Failed")
        }
    }

    private static func presentError(_ error: Error, title: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = error.localizedDescription
        alert.alertStyle = .critical
        alert.runModal()
    }
}
