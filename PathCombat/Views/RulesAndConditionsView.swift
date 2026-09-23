//
//  RulesAndConditionsView.swift
//  PathCombat
//
//  Created by Federico Brandani on 23/09/2026.
//

import SwiftUI

struct RulesAndConditionsView: View {
    var body: some View {
        ContentUnavailableView(
            "Rules and Conditions",
            systemImage: AppSection.rulesAndConditions.systemImage,
            description: Text("Coming soon.")
        )
    }
}

#Preview {
    RulesAndConditionsView()
}
