//
//  PathCombatApp.swift
//  PathCombat
//
//  Created by Federico Brandani on 19/09/2026.
//

import SwiftUI
import SwiftData

@main
struct PathCombatApp: App {
    @Environment(\.openWindow) private var openWindow

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Encounter.self,
            Condition.self,
            CombatEntity.self,
            EncounterCombatEntity.self,
            Spell.self,
            RuleAction.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            MainView()
        }
        .modelContainer(sharedModelContainer)
        .commands {
            CommandGroup(after: .newItem) {
                Divider()
                Button("Export Data...") {
                    DataBackupCommands.exportData(context: sharedModelContainer.mainContext)
                }
                Button("Import Data...") {
                    DataBackupCommands.importData(context: sharedModelContainer.mainContext)
                }
                Button("Import Data from Archive of Nethys...") {
                    DataBackupCommands.importDataFromAoN(context: sharedModelContainer.mainContext)
                }
                Divider()
                Menu("Wipe Data") {
                    Button("Wipe Encounters") {
                        DataBackupCommands.wipeEncounters(context: sharedModelContainer.mainContext)
                    }
                    Button("Wipe Entities") {
                        DataBackupCommands.wipeEntities(context: sharedModelContainer.mainContext)
                    }
                    Button("Wipe Conditions") {
                        DataBackupCommands.wipeConditions(context: sharedModelContainer.mainContext)
                    }
                    Button("Wipe Spells") {
                        DataBackupCommands.wipeSpells(context: sharedModelContainer.mainContext)
                    }
                    Button("Wipe Actions and Activities") {
                        DataBackupCommands.wipeActions(context: sharedModelContainer.mainContext)
                    }
                    Divider()
                    Button("Wipe All") {
                        DataBackupCommands.wipeAll(context: sharedModelContainer.mainContext)
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

        WindowGroup(id: "help") {
            HelpView()
        }
        .defaultSize(width: 700, height: 520)

        WindowGroup(id: "licenses") {
            LicensesView()
        }
        .defaultSize(width: 480, height: 420)
    }
}
