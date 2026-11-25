//
//  EuropeanTableAround.swift
//  Touchline
//
//  The five clubs around yours in a European league-phase table, as after
//  a league match: after your European match, and on the Europe screen.
//

import SwiftUI

extension GameState {
    /// A competition's league-phase table, optionally counting a result of
    /// the user's that the competition has not recorded yet (it records the
    /// whole matchweek at once, after everyone has played).
    func europeanTable(_ state: EuropeanCompetitionState, including fixture: Fixture? = nil) -> [EuropeanRow] {
        var rows = state.table()
        if let fixture, let result = fixture.result,
           let h = rows.firstIndex(where: { $0.clubId == fixture.homeClubId }),
           let a = rows.firstIndex(where: { $0.clubId == fixture.awayClubId }) {
            rows[h].record(goalsFor: result.homeGoals, goalsAgainst: result.awayGoals)
            rows[a].record(goalsFor: result.awayGoals, goalsAgainst: result.homeGoals)
            rows.sort(by: EuropeanRow.sort)
        }
        return rows
    }
}

struct EuropeanTableAround: View {
    @Environment(GameState.self) private var gameState
    let title: String
    let rows: [EuropeanRow]
    let userClubId: UUID
    var note: String? = nil

    var body: some View {
        if let mine = rows.firstIndex(where: { $0.clubId == userClubId }) {
            let lower = max(0, min(mine - 2, rows.count - 5))
            let upper = min(rows.count, lower + 5)
            VStack(spacing: 8) {
                HStack {
                    Text("STANDINGS").font(.gfDisplay(18))
                    Spacer()
                    Text(title).font(.caption).foregroundStyle(.secondary)
                }
                HStack {
                    Text("#").frame(width: 26, alignment: .leading)
                    Text("TEAM").frame(maxWidth: .infinity, alignment: .leading)
                    Text("P").frame(width: 28)
                    Text("GD").frame(width: 34)
                    Text("PTS").frame(width: 34)
                }
                .font(.gfLabel(12))
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
                ForEach(lower..<upper, id: \.self) { i in
                    let row = rows[i]
                    let club = gameState.club(withId: row.clubId)
                    HStack {
                        Text("\(i + 1)").frame(width: 26, alignment: .leading)
                        HStack(spacing: 6) {
                            if let club { CrestView(club: club, size: 18) }
                            Text(club?.name ?? "–").lineLimit(1)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        Text("\(row.played)").frame(width: 28)
                        Text(row.goalDifference > 0 ? "+\(row.goalDifference)" : "\(row.goalDifference)").frame(width: 34)
                        Text("\(row.points)").frame(width: 34).fontWeight(.heavy)
                    }
                    .font(.subheadline.monospacedDigit())
                    .fontWeight(row.clubId == userClubId ? .heavy : .regular)
                    .padding(.vertical, 4)
                    .padding(.horizontal, 6)
                    .background(RoundedRectangle(cornerRadius: 8).fill(row.clubId == userClubId ? Color.white.opacity(0.14) : Color.clear))
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(i + 1). \(club?.name ?? ""), played \(row.played), goal difference \(row.goalDifference), \(row.points) points")
                }
                if let note {
                    Text(note).font(.caption2).foregroundStyle(.secondary)
                }
            }
            .gfCard()
        }
    }
}
