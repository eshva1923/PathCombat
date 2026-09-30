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

    /// Imports spells, conditions, and actions/activities from Archive of Nethys in one go.
    /// Blocked once any of the three libraries already contains AoN-imported content (an
    /// entry with an `aonID`), so a re-run never hits Archive of Nethys's search index just to
    /// discover there's nothing new to do. Libraries containing only hand-made entries (no
    /// `aonID`) don't count, so a first import is always available.
    static func importDataFromAoN(context: ModelContext) {
        guard !hasImportedAoNData(context: context) else {
            let alert = NSAlert()
            alert.messageText = "Already Imported"
            alert.informativeText = "Your Spells, Conditions, or Rules library already contains content imported from Archive of Nethys. Wipe the relevant library from File → Wipe Data first if you want to re-import."
            alert.alertStyle = .informational
            alert.runModal()
            return
        }

        guard confirmAoNImport(
            title: "Import Data from Archive of Nethys?",
            message: "Downloads the current, ORC-licensed Pathfinder 2e spells, conditions, and actions/activities from 2e.aonprd.com and adds them to your libraries. Legacy (pre-remaster OGL) entries with no ORC equivalent are skipped. Anything already in your libraries, including your own entries, is not affected."
        ) else { return }

        Task {
            do {
                let spells = try await AoNSpellImportService.importSpells(context: context)
                let conditions = try await AoNConditionImportService.importConditions(context: context)
                let actions = try await AoNActionImportService.importActions(context: context)
                await MainActor.run {
                    let alert = NSAlert()
                    alert.messageText = "Import Complete"
                    alert.informativeText = """
                    Imported \(spells.imported) spells, \(conditions.imported) conditions, and \(actions.actions) actions and \(actions.activities) activities from Archive of Nethys.
                    Skipped \(spells.skipped + conditions.skipped + actions.skipped) legacy (non-ORC) entries.
                    """
                    alert.runModal()
                }
            } catch {
                await MainActor.run {
                    presentError(error, title: "Import Failed")
                }
            }
        }
    }

    private static func hasImportedAoNData(context: ModelContext) -> Bool {
        let spellCount = (try? context.fetchCount(FetchDescriptor<Spell>(predicate: #Predicate { $0.aonID != nil }))) ?? 0
        let conditionCount = (try? context.fetchCount(FetchDescriptor<Condition>(predicate: #Predicate { $0.aonID != nil }))) ?? 0
        let actionCount = (try? context.fetchCount(FetchDescriptor<RuleAction>(predicate: #Predicate { $0.aonID != nil }))) ?? 0
        return spellCount > 0 || conditionCount > 0 || actionCount > 0
    }

    /// Shows the shared AoN import confirmation alert. Returns whether the user confirmed.
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
