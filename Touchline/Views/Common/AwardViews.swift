//
//  AwardViews.swift
//  Touchline
//
//  Full-screen moments: the end-of-season review (shown when the manager
//  starts the next season) and the awards nights (the Ballon d'Or in
//  October, the Team of the Year in January).
//

import SwiftUI

// MARK: - A ranked list

/// "1. Name (Club) — detail", with the user's own players highlighted.
struct AwardList: View {
    let title: String
    let icon: String
    let entries: [AwardEntry]
    var numbered = true
    /// The player whose profile is open (to buy or shortlist him).
    @State private var profileId: UUID?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            GFSectionHeader(title: title, icon: icon) { EmptyView() }
            ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                HStack(alignment: .top, spacing: 10) {
                    Text(numbered ? "\(index + 1)" : entry.position)
                        .font(.gfLabel(14).monospacedDigit())
                        .frame(width: 34, alignment: .leading)
                        .foregroundStyle(index == 0 && numbered ? Color.goldAccent : .secondary)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(entry.name)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(entry.isUsersPlayer ? Color.gfMint : .primary)
                        Text("\(entry.clubName) · \(entry.detail)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 0)
                }
                .contentShape(Rectangle())
                .onTapGesture { profileId = entry.id }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(numbered ? "\(index + 1). " : "\(entry.position), ")\(entry.name), \(entry.clubName)\(entry.isUsersPlayer ? ", your player" : ""). \(entry.detail)")
                .accessibilityAddTraits(.isButton)
                .accessibilityHint("Opens his profile, to bid for him or shortlist him")
                .accessibilityAction { profileId = entry.id }
            }
        }
        .gfCard()
        .awardProfileSheet($profileId)
    }
}

/// An eleven laid out by line: forwards at the top, the keeper at the bottom.
struct ElevenView: View {
    let title: String
    let players: [AwardEntry]
    @State private var profileId: UUID?

    private func line(_ positions: Set<String>) -> [AwardEntry] {
        players.filter { positions.contains($0.position) }
    }

    var body: some View {
        let forwards = line(["ST", "CF", "LW", "RW"])
        let keepers = line(["GK"])
        let defenders = line(["CB", "LB", "RB", "LWB", "RWB"])
        let midfielders = players.filter { p in !(forwards + keepers + defenders).contains { $0.id == p.id } }
        return VStack(spacing: 14) {
            GFSectionHeader(title: title, icon: "person.3.sequence.fill") { EmptyView() }
            ForEach([forwards, midfielders, defenders, keepers].filter { !$0.isEmpty }, id: \.first?.id) { row in
                HStack(spacing: 6) {
                    ForEach(row) { player in
                        VStack(spacing: 3) {
                            Text(player.position)
                                .font(.gfLabel(11))
                                .foregroundStyle(Color.gfNight)
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .background(Capsule().fill(Color.white))
                            Text(player.name.split(separator: " ").last.map(String.init) ?? player.name)
                                .font(.caption.weight(.bold))
                                .foregroundStyle(player.isUsersPlayer ? Color.gfMint : .primary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                            Text(player.clubName)
                                .font(.system(size: 9))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                        .onTapGesture { profileId = player.id }
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("\(player.position), \(player.name), \(player.clubName)\(player.isUsersPlayer ? ", your player" : ""). \(player.detail)")
                        .accessibilityAddTraits(.isButton)
                        .accessibilityHint("Opens his profile, to bid for him or shortlist him")
                        .accessibilityAction { profileId = player.id }
                    }
                }
            }
        }
        .padding(.vertical, 6)
        .gfCard()
        .awardProfileSheet($profileId)
    }
}

extension View {
    /// A player's profile over an awards list, where he can be bid for or
    /// shortlisted.
    func awardProfileSheet(_ id: Binding<UUID?>) -> some View {
        sheet(isPresented: Binding(get: { id.wrappedValue != nil }, set: { if !$0 { id.wrappedValue = nil } })) {
            if let playerId = id.wrappedValue {
                NavigationStack { PlayerDetailView(playerId: playerId) }
            }
        }
    }
}

// MARK: - Season review

/// The whole season on one screen, shown when the manager presses Start New
/// Season; the button at the bottom starts it.
struct SeasonReviewScreen: View {
    @Environment(GameState.self) private var gameState
    let review: SeasonReview
    let onStart: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    SeasonReviewCard(review: review)
                    if let clubs = review.topClubs, !clubs.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            GFSectionHeader(title: "\(review.leagueName): Top Three", icon: "trophy.fill") { EmptyView() }
                            ForEach(clubs, id: \.self) { line in
                                Text(line).font(.subheadline)
                            }
                        }
                        .gfCard()
                    }
                    if let best = review.bestPlayers, !best.isEmpty {
                        AwardList(title: "Best Players", icon: "star.fill", entries: best)
                    }
                    if let scorers = review.topScorers, !scorers.isEmpty {
                        AwardList(title: "Top Scorers", icon: "soccerball", entries: scorers)
                    }
                    if let providers = review.topAssists, !providers.isEmpty {
                        AwardList(title: "Most Assists", icon: "shoe.fill", entries: providers)
                    }
                    if let team = review.teamOfTheSeason, !team.isEmpty {
                        ElevenView(title: "\(review.leagueName) Team of the Season", players: team)
                    }
                    if let others = review.otherDivisions, !others.isEmpty {
                        otherDivisions(others)
                    }
                }
                .padding()
                .padding(.bottom, 80)
            }
            .stadiumBackground()
            .navigationTitle("Season \(review.season)")
            .navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .bottom) {
                Button(action: onStart) {
                    Text("Start Season \(nextSeasonLabel)")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.gfPrimary)
                .padding(.horizontal, 24)
                .padding(.vertical, 8)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { gameState.showingSeasonReview = false }
                }
            }
        }
    }

    @State private var divisionName: String?

    /// Every other division in the world, one at a time.
    @ViewBuilder
    private func otherDivisions(_ divisions: [DivisionHonours]) -> some View {
        let selected = divisions.first { $0.leagueName == divisionName } ?? divisions[0]
        VStack(alignment: .leading, spacing: 10) {
            GFSectionHeader(title: "Around the World", icon: "globe.europe.africa.fill") { EmptyView() }
            Menu {
                ForEach(divisions) { division in
                    Button("\(division.country): \(division.leagueName)") { divisionName = division.leagueName }
                }
            } label: {
                Label("\(selected.country): \(selected.leagueName)", systemImage: "chevron.up.chevron.down")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .accessibilityLabel("Division")
            .accessibilityValue("\(selected.country), \(selected.leagueName)")
            .accessibilityHint("Choose another division's season to view")
            ForEach(selected.topClubs, id: \.self) { line in
                Text(line).font(.subheadline)
            }
        }
        .gfCard()
        if !selected.bestPlayers.isEmpty {
            AwardList(title: "\(selected.leagueName): Best Players", icon: "star.fill", entries: selected.bestPlayers)
        }
        if !selected.topScorers.isEmpty {
            AwardList(title: "\(selected.leagueName): Top Scorers", icon: "soccerball", entries: selected.topScorers)
        }
        if !selected.topAssists.isEmpty {
            AwardList(title: "\(selected.leagueName): Most Assists", icon: "shoe.fill", entries: selected.topAssists)
        }
        if !selected.teamOfTheSeason.isEmpty {
            ElevenView(title: "\(selected.leagueName) Team of the Season", players: selected.teamOfTheSeason)
        }
    }

    /// "2027-28" after "2026-27".
    private var nextSeasonLabel: String {
        let parts = review.season.split(separator: "-")
        guard parts.count == 2, let start = Int(parts[0]), let end = Int(parts[1]) else { return "" }
        return String(format: "%d-%02d", start + 1, (end + 1) % 100)
    }
}

// MARK: - Awards night

/// The Ballon d'Or or the Team of the Year, on its own screen.
struct AwardCeremonyView: View {
    @Environment(GameState.self) private var gameState
    let ceremony: AwardCeremony
    @State private var winnerProfileId: UUID?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    Text(ceremony.title.uppercased())
                        .font(.gfDisplay(24))
                        .multilineTextAlignment(.center)
                    switch ceremony.kind {
                    case .ballonDor: ballonDor
                    case .teamOfTheYear: teamOfTheYear
                    }
                }
                .padding()
                .padding(.bottom, 80)
            }
            .stadiumBackground()
            .navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .bottom) {
                Button {
                    gameState.ceremonyToShow = nil
                    try? SaveManager.shared.autoSave(gameState: gameState)
                } label: {
                    Text("Continue").font(.headline).frame(maxWidth: .infinity)
                }
                .buttonStyle(.gfPrimary)
                .padding(.horizontal, 24)
                .padding(.vertical, 8)
            }
        }
    }

    @ViewBuilder
    private var ballonDor: some View {
        if let winner = ceremony.ranking.first {
            VStack(spacing: 10) {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 54))
                    .foregroundStyle(Color.goldAccent)
                    .accessibilityHidden(true)
                if let player = gameState.player(withId: winner.id)?.player {
                    FaceView(player: player, size: 110, style: .full)
                        .frame(width: 170, height: 190)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .accessibilityHidden(true)
                }
                Text(winner.name.uppercased())
                    .font(.gfDisplay(26))
                    .foregroundStyle(winner.isUsersPlayer ? Color.gfMint : .primary)
                    .multilineTextAlignment(.center)
                Text(winner.clubName).font(.headline)
                Text(winner.detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .gfCard()
            .accessibilityElement(children: .ignore)
            .contentShape(Rectangle())
            .onTapGesture { winnerProfileId = winner.id }
            .accessibilityLabel("The Ballon d'Or goes to \(winner.name) of \(winner.clubName)\(winner.isUsersPlayer ? ", your player" : ""). \(winner.detail)")
            .accessibilityAddTraits(.isButton)
            .accessibilityAction { winnerProfileId = winner.id }
            .awardProfileSheet($winnerProfileId)
        }
        if ceremony.ranking.count > 1 {
            AwardList(title: "The Rest of the Top Ten", icon: "list.number",
                      entries: Array(ceremony.ranking.dropFirst()))
        }
        if let young = ceremony.youngPlayer {
            AwardList(title: "Kopa Trophy: Best Young Player", icon: "sparkles", entries: [young], numbered: false)
        }
        if let keeper = ceremony.goalkeeper {
            AwardList(title: "Yashin Trophy: Best Goalkeeper", icon: "hand.raised.fill", entries: [keeper], numbered: false)
        }
    }

    @ViewBuilder
    private var teamOfTheYear: some View {
        Text("The best eleven from Europe's top five leagues.")
            .font(.subheadline)
            .foregroundStyle(.secondary)
        ElevenView(title: "Team of the Year", players: ceremony.ranking)
        AwardList(title: "The Eleven", icon: "person.3.fill", entries: ceremony.ranking, numbered: false)
    }
}
