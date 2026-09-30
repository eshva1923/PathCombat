//
//  MainMenu.swift
//  PathCombat
//
//  Created by Federico Brandani on 30/09/2026.
//

import SwiftUI
import SwiftData

struct MainMenu: Commands {
    let modelContext: ModelContext
    @Environment(\.openWindow) private var openWindow

    var body: some Commands {
        CommandGroup(replacing: .newItem) {
            Menu("Data Export") {
                Button("Export Encounters and Entities...") {
                    DataBackupCommands.exportData(scope: .encountersAndEntities, context: modelContext)
                }
                Button("Export Spells, Conditions and Actions...") {
                    DataBackupCommands.exportData(scope: .referenceLibraries, context: modelContext)
                }
                Divider()
                Button("Export Everything...") {
                    DataBackupCommands.exportData(scope: .everything, context: modelContext)
                }
            }
            Divider()
            Menu("Data Import") {
                Button("Import Encounters and Entities...") {
                    DataBackupCommands.importData(scope: .encountersAndEntities, context: modelContext)
                }
                Button("Import Spells, Conditions and Actions...") {
                    DataBackupCommands.importData(scope: .referenceLibraries, context: modelContext)
                }
                Divider()
                Button("Import Everything...") {
                    DataBackupCommands.importData(scope: .everything, context: modelContext)
                }
            }
            Divider()
            Button("Import Data from Archive of Nethys...") {
                DataBackupCommands.importDataFromAoN(context: modelContext)
            }
            Divider()
            Menu("Wipe Data") {
                Button("Wipe Encounters") {
                    DataBackupCommands.wipeEncounters(context: modelContext)
                }
                Button("Wipe Entities") {
                    DataBackupCommands.wipeEntities(context: modelContext)
                }
                Button("Wipe Conditions") {
                    DataBackupCommands.wipeConditions(context: modelContext)
                }
                Button("Wipe Spells") {
                    DataBackupCommands.wipeSpells(context: modelContext)
                }
                Button("Wipe Actions and Activities") {
                    DataBackupCommands.wipeActions(context: modelContext)
                }
                Divider()
                Button("Wipe All") {
                    DataBackupCommands.wipeAll(context: modelContext)
                }
            }
        }
        CommandGroup(replacing: .help) {
            Button("PathCombat Help") {
                openWindow(id: "help")
            }
            Button("Licenses") {
                openWindow(id: "licenses")
            }
        }
    }
}
