//
//  EntitiesLibraryView.swift
//  PathCombat
//
//  Created by Federico Brandani on 23/09/2026.
//

import SwiftUI

struct EntitiesLibraryView: View {
    var body: some View {
        ContentUnavailableView(
            "Entities Library",
            systemImage: AppSection.entitiesLibrary.systemImage,
            description: Text("Coming soon.")
        )
    }
}

#Preview {
    EntitiesLibraryView()
}
