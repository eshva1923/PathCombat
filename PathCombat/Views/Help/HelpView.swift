import SwiftUI

enum HelpSection: String, CaseIterable, Identifiable {
    case overview = "Overview"
    case encounters = "Encounters"
    case entities = "Combat Entities"
    case spells = "Spells"
    case conditions = "Rules and Conditions"
    case licenses = "Licenses & Attribution"

    var id: Self { self }

    var systemImage: String {
        switch self {
        case .overview: return "questionmark.circle"
        case .encounters: return "shield.lefthalf.filled"
        case .entities: return "person.3.fill"
        case .spells: return "wand.and.stars"
        case .conditions: return "books.vertical.fill"
        case .licenses: return "scroll"
        }
    }

    var content: String {
        switch self {
        case .overview: return """
        PathCombat is a combat tracker built for running Pathfinder 2e encounters at the table. It's organized into four sections, switchable from the icons at the top of the window:

        • **Combat Tracker** — where you run encounters: initiative, HP, and conditions during a session.
        • **Entities Library** — reusable templates for the creatures and characters you fight with (PCs, NPCs, bosses, hazards).
        • **Spells** — your spell reference, and the catalog Combat Entities pick known spells from.
        • **Rules and Conditions** — your reference for conditions (Frightened, Prone, etc.) and for actions and activities, and the catalog entities' applied conditions draw from.

        Every library follows the same pattern: a sidebar on the left lists items — searchable, and grouped into collapsible sections you expand by clicking the header — while the right side shows the details of whatever is selected. Use the **Add** button in the toolbar to create a new item (in the Rules Library, it's a menu since there are three kinds of item); hover a row and click the trash icon to delete it.

        Spells, conditions, and actions/activities can also be imported in bulk from Archive of Nethys, via **File → Import Data from Archive of Nethys…**. That item is only available once — once any of those three libraries has AoN-imported content, it's blocked, to avoid hammering Archive of Nethys with repeat requests. Wipe the relevant library from **Wipe Data** first if you want a fresh import. The **File** menu also has Export/Import Data for full backups, and a **Wipe Data** submenu for clearing out a section entirely.
        """
        case .encounters: return """
        Encounters live in the Combat Tracker, organized into numbered **Sessions** in the sidebar. Sessions are collapsible — click a session header to expand it.

        To create one, click **+** in the toolbar. Give it a name, session number, and optional tags, then click **Add to encounter** to load entities from your Entities Library. PCs and bosses can only be added to an encounter once each; other roles (like a squad of goblins) can be added as many times as you like.

        Once entities are loaded:

        • Click an entity to expand it and edit its live stats — HP, wounds, conditions, spent spell slots.
        • **Roll Initiative** rolls for that entity, or you can type a value in directly.
        • The **Play** button in the Initiative panel advances to the next entity's turn; once every entity has a rolled initiative, later rounds advance automatically.
        • Apply conditions from the **+** in an entity's Conditions section. Conditions with a numeric value (like Frightened) or persistent damage (like Persistent Bleed) can be edited right on their tag; click a tag to see its full description.
        • **Reset** clears initiative and the round counter; **Remove this entity** takes an entity out of the encounter. Once combat has started, both ask for confirmation first, since neither can be undone.

        Mark an encounter **Encounter done** when you're finished with it — completed encounters are shown struck-through in the sidebar and are skipped by Sync to Encounters (see Combat Entities).
        """
        case .entities: return """
        The Entities Library holds reusable templates — PCs, NPCs, bosses, and hazards — that you load into encounters. Templates are grouped by role in the sidebar.

        To create one, click **Add a new entity**, then fill in:

        • Name, Level, and Role (role controls how it's grouped, and how many copies you can add to a single encounter).
        • Defenses: AC, DC, Fortitude/Reflex/Will saves, Perception.
        • HP, Speed (e.g. "30, 45 swimming"), Size, and Tags.
        • **Actions** — attacks or abilities with a name, action cost, target (an AC or a save), to-hit bonus, damage, and description.
        • **Spells** — click **Enable Spellcasting** to track focus points, spell slots per rank, and known/focus spells. Add known spells with the **+** next to each rank; a cantrip has its own row separate from its numeric rank, no matter what rank it's actually cast at.

        If you edit a template after it's already been loaded into one or more encounters, click **Sync to Encounters** to push those changes into any encounters that are still in progress — so a rules correction doesn't require re-adding the entity everywhere it's used.
        """
        case .spells: return """
        The Spells library is both your spell reference and the catalog Combat Entities pick known spells from.

        To create one, click **Add a new spell**, then fill in Name, Level (a spell's real rank — cantrips keep their real rank too, e.g. a 7th-rank cantrip stays rank 7), the Focus Spell toggle, casting Speed, Range/Area/Target (all optional), Traditions, Tags, and a Description.

        Whether a spell counts as a cantrip is decided entirely by tagging it **Cantrip** — add that tag and it's treated as a cantrip everywhere in the app (its own section at the top of the library, its own row in an entity's spellcasting section), regardless of its rank number. There's no separate cantrip toggle.

        You can set an Archive of Nethys ID to link back to a spell's page there, or import the whole spell list at once from **File → Import Data from Archive of Nethys…**.

        Spells are only editable from this library. Everywhere else — an entity's spellcasting section, the spell picker, tags shown in an encounter — shows them read-only; click a spell tag anywhere to see its full details.
        """
        case .conditions: return """
        The Rules and Conditions library has three collapsible sections in its sidebar: Conditions, Actions, and Activities.

        **Conditions** (Frightened, Prone, Persistent Damage, etc.) are what entities' applied conditions draw from. Use the **Add** menu in the toolbar and choose Condition, then set its Name and Description. Toggle **Persistent Damage** for damage-over-time conditions like Persistent Bleed — those get a damage tag (e.g. "1d6 Fire") instead of a numeric value, and unlike ordinary conditions, multiple instances can stack on the same entity.

        **Actions and Activities** are single-action, reaction, and free-action rules text (Stride, Seek, Grab an Edge, …) and longer activities (Avoid Notice, downtime activities, …). Choose Action or Activity from the **Add** menu, then set its Name, Cost (or None for activities with no fixed cost), Tags, and Description. Whether something is an Action or an Activity is just a Kind setting — change it any time.

        All three kinds are bulk-imported together from **File → Import Data from Archive of Nethys…**.

        Like spells, everything in this library is only editable from here — an entity's applied condition tag shows the description on click, but can't rename or redefine the underlying condition.
        """
        case .licenses: return """
        **Open RPG Creative (ORC) License**

        PathCombat includes game rules content made available by Paizo Inc. under the Open RPG Creative (ORC) License.

        The ORC-licensed content used by PathCombat consists of rules-related material such as spells, actions, conditions, traits, and other game rules content made available under the ORC License.

        The use of this content is subject to the terms of the Open RPG Creative (ORC) License.

        For more information about the ORC License, please visit:

        [https://paizo.com/orclicense](https://paizo.com/orclicense)

        **Archives of Nethys**

        PathCombat uses Archives of Nethys as a source for importing ORC-licensed game rules content.

        Archives of Nethys is an independent, community-maintained reference for tabletop roleplaying game rules. Imported content is retrieved from publicly available Archives of Nethys data and stored locally by PathCombat for use within the application.

        Archives of Nethys:
        [https://2e.aonprd.com/](https://2e.aonprd.com/)

        **Attribution**

        Some game rules content displayed or stored by PathCombat is derived from material originally published by Paizo Inc. and made available under the ORC License.

        PathCombat is not published, endorsed, or specifically approved by Paizo Inc. or Archives of Nethys.

        PathCombat does not include Paizo artwork, logos, or other visual assets.

        All trademarks and copyrights remain the property of their respective owners.

        **About PathCombat**

        PathCombat is an independent tool designed to assist Game Masters during tabletop roleplaying sessions. It is not affiliated with or endorsed by Paizo Inc. or Archives of Nethys.
        """
        }
    }
}

struct HelpView: View {
    @State private var selectedSection: HelpSection? = .overview

    var body: some View {
        NavigationSplitView {
            List(HelpSection.allCases, selection: $selectedSection) { section in
                Label(section.rawValue, systemImage: section.systemImage)
                    .tag(section)
            }
            .navigationSplitViewColumnWidth(min: 160, ideal: 180)
        } detail: {
            let section = selectedSection ?? .overview
            ScrollView {
                Text(LocalizedStringKey(section.content))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            }
            .navigationTitle(section.rawValue)
        }
        .frame(minWidth: 680, minHeight: 500)
    }
}

#Preview {
    HelpView()
}
