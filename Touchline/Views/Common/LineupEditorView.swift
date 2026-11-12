//
//  LineupEditorView.swift
//  Touchline
//
//  Tap a player, then tap another to swap them: two starters swap
//  positions, a starter and a substitute or reserve swap places, and a
//  reserve can be added to the bench. Used on the Squad tab and, for
//  one-off changes, before a match.
//

import SwiftUI

struct LineupEditorView: View {
    @Environment(GameState.self) private var gameState
    /// Opens a player's profile; nil hides the Profile action.
    var onProfile: ((UUID) -> Void)? = nil

    @State private var selectedId: UUID?
    @State private var message: String?
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOver

    var body: some View {
        if let club = gameState.userClub {
            VStack(alignment: .leading, spacing: 16) {
                FormationPitchView(
                    formation: club.tactics.formation,
                    players: club.startingXIPlayers,
                    selectedPlayerId: selectedId,
                    onSelect: { tap($0.id) }
                )

                if voiceOver {
                    // VoiceOver: no floating selection bar; actions are on each card.
                    EmptyView()
                } else if let selectedId, let player = club.player(withId: selectedId) {
                    selectionBar(player: player, club: club)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                } else {
                    Label("Tap a player, then another to swap them. Starters can swap positions too.",
                          systemImage: "hand.tap")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if let message {
                    Label(message, systemImage: "exclamationmark.circle")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.lossRed)
                }

                cardRow(title: "Bench", subtitle: "\(club.substitutePlayers.count)/7",
                        players: club.substitutePlayers, club: club)
                cardRow(title: "Reserves", subtitle: "\(club.reservePlayers.count)",
                        players: club.reservePlayers.sorted { $0.overall > $1.overall }, club: club)
            }
            .animation(voiceOver ? nil : .snappy, value: selectedId)
        }
    }

    // MARK: - Interaction

    private func tap(_ id: UUID) {
        message = nil
        let name = { (pid: UUID) in gameState.userClub?.player(withId: pid)?.fullName ?? "Player" }
        if selectedId == id {
            selectedId = nil
            announce("Selection cancelled.")
            return
        }
        guard let first = selectedId else {
            selectedId = id
            announce("\(name(id)) selected. Choose a player to swap with.")
            return
        }
        message = gameState.swapLineup(first, id)
        selectedId = nil
        if let message {
            announce(message)
        } else {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            announce("Swapped \(name(first)) and \(name(id)).")
        }
    }

    private func announce(_ text: String) {
        guard voiceOver else { return }
        // Let the list update first so the announcement isn't cut off.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            AccessibilityNotification.Announcement(text).post()
        }
    }

    /// VoiceOver: bench and reserves as plain rows with rotor actions.
    @ViewBuilder
    private func accessibleRows(title: String, players: [Player], club: Club) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.headline).accessibilityAddTraits(.isHeader)
            if players.isEmpty {
                Text("None.").font(.subheadline).foregroundStyle(.secondary)
            }
            ForEach(players) { player in
                AccessibleLineupRow(player: player, isSelected: player.id == selectedId,
                                    hint: selectedId == nil ? "Double tap to select." : "Double tap to swap with the selected player.") {
                    tap(player.id)
                }
                .accessibilityActions {
                    if let onProfile {
                        Button("View profile") { onProfile(player.id) }
                    }
                    if case .reserve = gameState.lineupSlot(of: player.id), club.tactics.substitutes.count < 7 {
                        Button("Add to bench") {
                            message = gameState.addToBench(player.id)
                            announce(message ?? "\(player.fullName) added to the bench.")
                        }
                    }
                    if case .bench = gameState.lineupSlot(of: player.id) {
                        Button("Drop to reserves") {
                            gameState.removeFromBench(player.id)
                            announce("\(player.fullName) dropped to the reserves.")
                        }
                    }
                }
            }
        }
    }

    private func selectionBar(player: Player, club: Club) -> some View {
        let slot = gameState.lineupSlot(of: player.id)
        return HStack(spacing: 10) {
            FaceView(player: player, size: 34)
            VStack(alignment: .leading, spacing: 1) {
                Text(player.fullName).font(.subheadline.weight(.bold)).lineLimit(1)
                Text("Tap another player to swap").font(.caption2).foregroundStyle(.secondary)
            }
            Spacer(minLength: 4)
            if case .reserve = slot, club.tactics.substitutes.count < 7 {
                Button {
                    message = gameState.addToBench(player.id)
                    selectedId = nil
                } label: { Image(systemName: "arrow.up.circle.fill").font(.title2) }
                .accessibilityLabel("Add to bench")
            }
            if case .bench = slot {
                Button {
                    gameState.removeFromBench(player.id)
                    selectedId = nil
                } label: { Image(systemName: "arrow.down.circle.fill").font(.title2) }
                .accessibilityLabel("Drop to reserves")
            }
            if let onProfile {
                Button {
                    onProfile(player.id)
                } label: { Image(systemName: "person.text.rectangle").font(.title2) }
                .accessibilityLabel("View profile")
            }
            Button {
                selectedId = nil
            } label: { Image(systemName: "xmark.circle.fill").font(.title2).foregroundStyle(.secondary) }
            .accessibilityLabel("Cancel selection")
        }
        .padding(10)
        .background(Color.accentColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func cardRow(title: String, subtitle: String, players: [Player], club: Club) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title).font(.headline)
                Text(subtitle).font(.subheadline).foregroundStyle(.secondary)
                Spacer()
            }
            if players.isEmpty {
                Text(title == "Bench" ? "No substitutes. Select a reserve and choose Add to Bench." : "Everyone is in the matchday squad.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                // Not lazy: every card exists up front, so VoiceOver can
                // swipe through the whole row without losing its place.
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(players) { player in
                            SquadPlayerCard(player: player, isSelected: player.id == selectedId)
                                .onTapGesture { tap(player.id) }
                                .accessibilityAddTraits(player.id == selectedId ? [.isButton, .isSelected] : .isButton)
                                .accessibilityHint(selectedId == nil ? "Double tap to select" : "Double tap to swap with the selected player")
                                .accessibilityAction { tap(player.id) }
                                .accessibilityActions {
                                    if let onProfile {
                                        Button("View profile") { onProfile(player.id) }
                                    }
                                    if title == "Reserves", club.tactics.substitutes.count < 7 {
                                        Button("Add to bench") {
                                            message = gameState.addToBench(player.id)
                                            announce(message ?? "\(player.fullName) added to the bench.")
                                        }
                                    }
                                    if title == "Bench" {
                                        Button("Drop to reserves") {
                                            gameState.removeFromBench(player.id)
                                            announce("\(player.fullName) dropped to the reserves.")
                                        }
                                    }
                                }
                        }
                    }
                    .padding(10)
                }
                .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color.gfNight.opacity(0.75)))
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color.gfStroke))
                .accessibilityElement(children: .contain)
                .accessibilityLabel(title)
            }
        }
    }
}

/// A compact vertical player card for horizontal rows.
struct SquadPlayerCard: View {
    let player: Player
    var isSelected: Bool = false

    var body: some View {
        PlayerPitchCard(player: player, isSelected: isSelected, width: 84)
            .frame(width: 84)
    }
}
