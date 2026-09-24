import AppKit
import SwiftData
import UniformTypeIdentifiers

/// Drives the Export/Import Data menu commands: presents the native file panels,
/// confirms the destructive import, and reports failures via NSAlert.
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

    private static func presentError(_ error: Error, title: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = error.localizedDescription
        alert.alertStyle = .critical
        alert.runModal()
    }
}
