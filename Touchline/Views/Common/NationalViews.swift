//
//  NationalViews.swift
//  Touchline
//
//  The national-team screens: picking the eleven and the approach, and the
//  report of a match the user managed.
//

import SwiftUI

// MARK: - Squad selection

struct NationalSquadView: View {
    @Environment(GameState.self) private var gameState
    @State private var starters: [UUID] = []
    @State private var formation: FormationPreset = .f433
    @State private var mentality: Mentality = .balanced

    var body: some View {
        Group {
            if let team = gameState.managedNationalTeam {
                List {
                    Section(footer: Text("Pick eleven starters, including a goalkeeper. The rest of the squad sits on the bench.")) {
                        Picker("Formation", selection: $formation) {
                            ForEach(FormationPreset.allCases) { Text($0.rawValue).tag($0) }
                        }
                        Picker("Approach", selection: $mentality) {
                            ForEach(Mentality.allCases) { Text($0.displayName).tag($0) }
                        }
                        Button("Pick the Best Eleven") { pickBest(team) }
                    }
                    Section(header: Text("Starters \(starters.count) of 11")) {
                        ForEach(sorted(team.players)) { player in
                            row(player)
                        }
                    }
                }
                .navigationTitle("\(team.name) Squad")
                .navigationBarTitleDisplayMode(.inline)
                .onAppear { load() }
                .onDisappear { save() }
            } else {
                ContentUnavailableView("No National Team", systemImage: "flag.slash")
            }
        }
    }

    private func sorted(_ players: [Player]) -> [Player] {
        players.sorted { ($0.primaryPosition.sortIndex, -$0.overall) < ($1.primaryPosition.sortIndex, -$1.overall) }
    }

    private func row(_ player: Player) -> some View {
        let picked = starters.contains(player.id)
        return Button {
            if picked {
                starters.removeAll { $0 == player.id }
            } else if starters.count < 11 {
                starters.append(player.id)
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: picked ? "checkmark.circle.fill" : "circle").accessibilityHidden(true)
                    .foregroundStyle(picked ? Color.gfMint : .secondary)
                Text(player.primaryPosition.abbreviation)
                    .font(.caption.weight(.bold))
                    .frame(width: 36, alignment: .leading)
                Text(player.fullName)
                    .foregroundStyle(.primary)
                Spacer()
                Text("\(player.overall)")
                    .font(.subheadline.weight(.bold).monospacedDigit())
                    .foregroundStyle(.primary)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(player.primaryPosition.displayName), \(player.fullName), rated \(player.overall)")
        .accessibilityValue(picked ? "Starting" : "Not starting")
        .accessibilityHint(picked ? "Drop him from the eleven" : (starters.count < 11 ? "Put him in the eleven" : "The eleven is full"))
    }

    private func load() {
        let selection = gameState.nationalSelection
        starters = selection.startingXI
        formation = selection.formation
        mentality = selection.mentality
    }

    private func pickBest(_ team: NationalTeam) {
        var side = gameState.matchSide(for: team, tactics: nil)
        side.tactics.formation = formation
        side.autoPickStartingXI()
        starters = side.tactics.startingXI
    }

    private func save() {
        var tactics = gameState.nationalSelection
        tactics.formation = formation
        tactics.mentality = mentality
        if starters.count == 11 {
            tactics.startingXI = starters
            tactics.substitutes = []
        }
        gameState.nationalTactics = tactics
        try? SaveManager.shared.autoSave(gameState: gameState)
    }
}

// MARK: - Match report

struct InternationalMatchReportView: View {
    let report: InternationalReport

    var body: some View {
        List {
            Section {
                VStack(spacing: 6) {
                    Text("\(report.tournament) · \(report.stage)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(report.scoreLine)
                        .font(.gfDisplay(22))
                        .multilineTextAlignment(.center)
                    Text(report.isDraw ? "Draw" : (report.userWon ? "Victory" : "Defeat"))
                        .font(.headline)
                        .foregroundStyle(report.isDraw ? Color.secondary : (report.userWon ? Color.winGreen : Color.lossRed))
                }
                .frame(maxWidth: .infinity)
                .accessibilityElement(children: .combine)
            }
            Section(header: Text("Commentary")) {
                ForEach(report.events.filter { $0.type != .kickOff }) { event in
                    VStack(alignment: .leading, spacing: 3) {
                        Text("\(event.minute)' · \(event.shortText)")
                            .font(.subheadline.weight(event.type.isMajorEvent ? .bold : .regular))
                        Text(event.detailText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityElement(children: .combine)
                }
            }
        }
        .navigationTitle("Match Report")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - The nation's matches, for the International screen

struct NationalMatchSection: View {
    @Environment(GameState.self) private var gameState
    @State private var report: InternationalReport?

    var body: some View {
        Section(header: Text("Your Nation's Matches")) {
            if let due = gameState.dueInternationalMatch, let teamId = gameState.managedNationalTeamId {
                let opponentId = due.fixture.homeTeamId == teamId ? due.fixture.awayTeamId : due.fixture.homeTeamId
                let opponent = gameState.nationalTeam(withId: opponentId)?.name ?? opponentId
                VStack(alignment: .leading, spacing: 4) {
                    Text("Match day: v \(opponent)").font(.headline)
                    Text("\(due.tournament.title) · \(due.fixture.stage)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .accessibilityElement(children: .combine)
                NavigationLink("Pick the Squad") { NationalSquadView() }
                Button {
                    report = gameState.playInternationalMatch()
                    try? SaveManager.shared.autoSave(gameState: gameState)
                } label: {
                    Label("Play the Match", systemImage: "sportscourt.fill")
                }
            } else if let next = gameState.nextInternationalFixture, let teamId = gameState.managedNationalTeamId {
                let opponentId = next.fixture.homeTeamId == teamId ? next.fixture.awayTeamId : next.fixture.homeTeamId
                let opponent = gameState.nationalTeam(withId: opponentId)?.name ?? opponentId
                Text("Next: v \(opponent), \(next.tournament.title) \(next.fixture.stage)\(next.fixture.date.map { " on \(GameState.longDateText($0))" } ?? "")")
                    .font(.subheadline)
                NavigationLink("Pick the Squad") { NationalSquadView() }
            } else {
                Text("No international matches scheduled yet.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                NavigationLink("Pick the Squad") { NationalSquadView() }
            }
            if let last = gameState.lastInternationalReport {
                NavigationLink {
                    InternationalMatchReportView(report: last)
                } label: {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Last match: \(last.scoreLine)").font(.subheadline)
                        Text("\(last.tournament) · \(last.stage)").font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
        }
        .sheet(item: $report) { report in
            NavigationStack {
                InternationalMatchReportView(report: report)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") { self.report = nil }
                        }
                    }
            }
        }
    }
}
