import SwiftUI

struct LicensesView: View {
    private let content = """
    **ORC License**

    PathCombat uses game rules content made available by Paizo Inc. under the Open RPG Creative (ORC) License.

    The ORC-licensed content used by PathCombat includes rules-related material such as spells, actions, conditions, traits, and other game rules content.

    [Open RPG Creative (ORC) License](https://paizo.com/orclicense)

    **Archives of Nethys**

    PathCombat uses Archives of Nethys as a source for importing ORC-licensed game rules content.

    [Archives of Nethys](https://2e.aonprd.com/)

    PathCombat is an independent application and is not affiliated with, endorsed by, or specifically approved by Paizo Inc. or Archives of Nethys.

    PathCombat does not include Paizo artwork, logos, or other visual assets.

    All trademarks and copyrights remain the property of their respective owners.
    """

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Licenses")
                    .font(.title2)
                    .fontWeight(.bold)
                Text(LocalizedStringKey(content))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
        .frame(minWidth: 460, minHeight: 400)
    }
}

#Preview {
    LicensesView()
}
