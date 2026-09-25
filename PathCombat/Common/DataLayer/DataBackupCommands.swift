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
        let confirmation = NSAlert()
        confirmation.messageText = "Import Spells from Archive of Nethys?"
        confirmation.informativeText = "Downloads the current Pathfinder 2e spell list (about 1,800 spells) from 2e.aonprd.com and adds them to your Spells Library. Spells already imported from Archive of Nethys are refreshed to match the latest data; spells you created yourself are not affected."
        confirmation.alertStyle = .informational
        confirmation.addButton(withTitle: "Import")
        confirmation.addButton(withTitle: "Cancel")
        guard confirmation.runModal() == .alertFirstButtonReturn else { return }

        Task {
            do {
                let count = try await AoNSpellImportService.importSpells(context: context)
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
