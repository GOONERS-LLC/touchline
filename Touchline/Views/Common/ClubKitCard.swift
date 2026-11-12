//
//  ClubKitCard.swift
//  Touchline
//
//  The user's kit and shirt sponsor, with a way into the Kit Designer.
//  Shown in the owner's Club Identity screen and on the manager's Kit page.
//

import SwiftUI

struct ClubKitCard: View {
    @Environment(GameState.self) private var gameState
    @State private var designing = false

    var body: some View {
        if let club = gameState.userClub {
            HStack(spacing: 16) {
                KitView(kit: club.effectiveKit, sponsor: gameState.shirtSponsorName, monogram: club.shortName, height: 150)
                VStack(alignment: .leading, spacing: 8) {
                    Text(club.kit == nil ? "Traditional home kit" : "Custom home kit")
                        .font(.headline)
                    Text(gameState.shirtSponsorName.map { "Shirt sponsor: \($0)" } ?? "No shirt sponsor yet")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Button {
                        Haptics.tap()
                        designing = true
                    } label: {
                        Label("Design Kit", systemImage: "paintbrush.fill")
                    }
                    .buttonStyle(.gfPrimary)
                }
            }
            .padding(.vertical, 6)
            .sheet(isPresented: $designing) {
                KitDesignerView(club: club).environment(gameState)
            }
        }
    }
}

/// A page holding the kit card, for the manager's home grid.
struct ClubKitPage: View {
    var body: some View {
        ScrollView {
            ClubKitCard()
                .gfCard()
                .padding()
        }
        .stadiumBackground()
        .navigationTitle("Club Kit")
        .navigationBarTitleDisplayMode(.inline)
    }
}
