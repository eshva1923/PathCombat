# PathCombat

A macOS combat tracker for tabletop RPGs (Pathfinder/D&D-style), built with SwiftUI and SwiftData. Track initiative, HP, conditions, and encounters without leaving the table.

## Features

- **Combat Tracker** — Create encounters, add entities, and roll/track initiative order.
  - Auto-rolls initiative for NPCs with a single click, skipping entities that already have one.
  - Advances turn order automatically, skipping dead entities and counting elapsed rounds.
  - Color-coded initiative list: red for zero initiative, and wound severity coloring (green at 25–50% HP lost, orange at 50–75%, red above 75%).
  - PC and Boss tags are enforced as unique per encounter and highlighted with distinct colors (purple/dark red) in both the entity view and initiative list.
- **Entities Library** — Reusable templates for monsters, NPCs, and PCs (stats, tags, saves, AC/DC). Adding a template to an encounter creates an independent copy, auto-numbered if added more than once (e.g. "Skeleton", "Skeleton 2").
- **Conditions Library** — Manage condition definitions (name + description) and apply them to entities in combat with an optional numeric value (e.g. "Frightened 2").
- **Data Export/Import** — Back up all encounters, entities, and conditions to a single CSV file (File menu → Export Data...), and restore from a backup (File menu → Import Data...). Importing replaces all existing data after confirmation.

## Requirements

- macOS with Xcode (latest version recommended)
- No external dependencies — pure SwiftUI + SwiftData



Data is persisted locally via SwiftData; no account or network connection is required.

## Architecture

The app follows MVVM:

- `Models/` — SwiftData models (`Encounter`, `CombatEntity`, `Condition`) and supporting types (`AppliedCondition`).
- `ViewModels/` — `@Observable` view models per feature (`CombatTracker`, `CombatEntity`, `EntitiesLibrary`, `ConditionsLibrary`), holding presentation logic and mutations.
- `Views/` — SwiftUI views per feature, delegating logic to their view model.
- `Common/` — Shared utilities: dice rolling, CSV read/write, and the data backup service.
