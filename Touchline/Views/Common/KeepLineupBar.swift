//
//  KeepLineupBar.swift
//  Touchline
//
//  Lineup changes made for a match last for that match only. This bar
//  explains that and lets the manager keep the new lineup as his usual one,
//  or go back to the usual one.
//

import SwiftUI

struct KeepLineupBar: View {
    @Environment(GameState.self) private var gameState
    /// Shows the "Use my usual lineup" button (not during a live match,
    /// where players already substituted can't come back on).
    var allowRevert: Bool = true
    @State private var keptMessage = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Changes here are for this match only. Your usual lineup comes back afterwards unless you keep this one.")
                .font(.caption)
                .foregroundStyle(.secondary)
            if gameState.matchLineupDiffersFromUsual {
                HStack(spacing: 10) {
                    Button("Keep as my lineup") {
                        gameState.keepMatchLineup()
                        keptMessage = true
                        UIAccessibility.post(notification: .announcement, argument: "Kept as your usual lineup")
                    }
                    .buttonStyle(.gfPrimary)
                    if allowRevert {
                        Button("Use my usual lineup") {
                            gameState.restoreUsualLineup()
                            gameState.beginMatchOnlyLineup()
                            UIAccessibility.post(notification: .announcement, argument: "Back to your usual lineup")
                        }
                        .buttonStyle(.gfOutline)
                    }
                }
            } else if keptMessage {
                Text("Kept as your usual lineup.")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.green)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
