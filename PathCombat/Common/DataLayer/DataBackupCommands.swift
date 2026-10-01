import AppKit
import SwiftData
import UniformTypeIdentifiers

enum DataBackupCommands {
    static func exportData(scope: DataBackupScope, context: ModelContext) {
        let panel = NSSavePanel()
        panel.title = "Export \(scope.title)"
        panel.nameFieldStringValue = "PathCombat \(scope.fileNameSuffix).csv"
        panel.allowedContentTypes = [.commaSeparatedText]

        guard panel.runModal() == .OK, let url = panel.url else { return }

        do {
            let csv = try DataBackupService.exportCSV(context: context, scope: scope)
            try csv.write(to: url, atomically: true, encoding: .utf8)
        } catch {
            presentError(error, title: "Export Failed")
        }
    }

    static func importData(scope: DataBackupScope, context: ModelContext) {
        let panel = NSOpenPanel()
        panel.title = "Import \(scope.title)"
        panel.allowedContentTypes = [.commaSeparatedText]
        panel.allowsMultipleSelection = false

        guard panel.runModal() == .OK, let url = panel.url else { return }

        let confirmation = NSAlert()
        confirmation.messageText = "Replace \(scope.title.lowercased())?"
        confirmation.informativeText = "Importing will permanently delete \(scope.replaceDescription), replacing them with the contents of \"\(url.lastPathComponent)\". Nothing else in your library is affected."
        confirmation.alertStyle = .warning
        confirmation.addButton(withTitle: "Import and Replace")
        confirmation.addButton(withTitle: "Cancel")
        guard confirmation.runModal() == .alertFirstButtonReturn else { return }

        do {
            let csv = try String(contentsOf: url, encoding: .utf8)
            try DataBackupService.importCSV(csv, context: context, scope: scope)
        } catch {
            presentError(error, title: "Import Failed")
        }
    }

    static func importDataFromAoN(context: ModelContext) {
        let shouldImportConditionsAndActions = !hasImportedConditionsOrActions(context: context)

        guard confirmAoNImport(
            title: "Import Data from Archive of Nethys?",
            message: "Downloads the current, ORC-licensed Pathfinder 2e spells, conditions, and actions/activities from 2e.aonprd.com. Spells only ever add new entries, so this is safe to re-run later. Conditions and actions/activities are a one-time import, skipped here if already done. Legacy (pre-remaster OGL) entries with no ORC equivalent are skipped. Anything already in your libraries, including your own entries, is not affected."
        ) else { return }

        let progress = ImportProgressWindow(message: "Importing from Archive of Nethys…")

        Task {
            do {
                let spells = try await AoNSpellImportService.importSpells(context: context)
                var conditions: AoNImportResult?
                var actions: AoNActionImportService.ImportCounts?
                if shouldImportConditionsAndActions {
                    conditions = try await AoNConditionImportService.importConditions(context: context)
                    actions = try await AoNActionImportService.importActions(context: context)
                }
                await MainActor.run {
                    progress.close()
                    let alert = NSAlert()
                    alert.messageText = "Import Complete"
                    var lines = ["Added \(spells.added) new spells (\(spells.alreadyPresent) already in your library)."]
                    if let conditions, let actions {
                        lines.append("Imported \(conditions.imported) conditions, \(actions.actions) actions, and \(actions.activities) activities.")
                    } else {
                        lines.append("Conditions and actions/activities were already imported, so they were skipped.")
                    }
                    let skippedLegacy = spells.skippedLegacy + (conditions?.skipped ?? 0) + (actions?.skipped ?? 0)
                    if skippedLegacy > 0 {
                        lines.append("Skipped \(skippedLegacy) legacy (non-ORC) entries.")
                    }
                    alert.informativeText = lines.joined(separator: "\n")
                    alert.runModal()
                }
            } catch {
                await MainActor.run {
                    progress.close()
                    presentError(error, title: "Import Failed")
                }
            }
        }
    }

    private static func hasImportedConditionsOrActions(context: ModelContext) -> Bool {
        let conditionCount = (try? context.fetchCount(FetchDescriptor<Condition>(predicate: #Predicate { $0.aonID != nil }))) ?? 0
        let actionCount = (try? context.fetchCount(FetchDescriptor<RuleAction>(predicate: #Predicate { $0.aonID != nil }))) ?? 0
        return conditionCount > 0 || actionCount > 0
    }

    private static func confirmAoNImport(title: String, message: String) -> Bool {
        let confirmation = NSAlert()
        confirmation.messageText = title
        confirmation.informativeText = message
        confirmation.alertStyle = .informational
        confirmation.addButton(withTitle: "Import")
        confirmation.addButton(withTitle: "Cancel")
        return confirmation.runModal() == .alertFirstButtonReturn
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

    static func wipeActions(context: ModelContext) {
        confirmAndWipe(
            title: "Wipe all actions and activities?",
            message: "This will permanently delete every action and activity definition in the Rules Library.",
            context: context) { context in
                try DataBackupService.wipeActions(context: context)
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
