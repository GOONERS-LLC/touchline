//
//  InternationalTournamentBuilder.swift
//  Touchline
//
//  Seeds one edition of an international tournament from the loaded national
//  teams: takes the top ranked nations eligible for it, draws them into groups
//  serpentine-style, and dates a round-robin group stage (three matchdays,
//  back to back, with a set number of games a day). Knockout rounds are dated
//  as they are drawn.
//

import Foundation

public enum InternationalTournamentBuilder {

    /// Builds one dated edition of a tournament.
    public static func build(kind: InternationalTournament.Kind, edition: Int, startDate: String,
                             from teams: [NationalTeam]) -> InternationalTournament.State? {
        // Eligible nations: matching confederations (or all for the World Cup), ranked.
        let eligible: [NationalTeam]
        if kind.confederations.isEmpty {
            eligible = teams
        } else {
            eligible = teams.filter { kind.confederations.contains($0.confederation) }
        }

        let ranked = eligible.sorted { lhs, rhs in
            switch (lhs.fifaRanking, rhs.fifaRanking) {
            case let (l?, r?): return l < r
            case (.some, .none): return true
            case (.none, .some): return false
            default: return lhs.strength > rhs.strength
            }
        }

        let field = Array(ranked.prefix(kind.teamCount))
        // A four-nation field is the smallest bracket that can produce a final
        // (two semi-finals), so smaller confederations simply have no tournament.
        guard field.count >= 4 else { return nil }

        // Draw into groups serpentine-style for balanced pools. Cap the group
        // count by the available field so every group has at least two nations.
        let groupCount = min(kind.groupCount, max(2, field.count / 2))
        var groups: [[NationalTeam]] = Array(repeating: [], count: groupCount)
        for (i, team) in field.enumerated() {
            let round = i / groupCount
            let slot = (round % 2 == 0) ? (i % groupCount) : (groupCount - 1 - (i % groupCount))
            groups[slot].append(team)
        }

        var assignments: [String: [String]] = [:]
        // Matchday -> that day's games across every group.
        var matchdays: [[InternationalTournament.Fixture]] = []

        for (gIdx, group) in groups.enumerated() {
            let groupName = "Group \(String(UnicodeScalar(65 + gIdx)!))"
            let ids = group.map { $0.id }
            assignments[groupName] = ids
            for (md, pairs) in rounds(ids).enumerated() {
                while matchdays.count <= md { matchdays.append([]) }
                for (home, away) in pairs {
                    matchdays[md].append(InternationalTournament.Fixture(homeTeamId: home, awayTeamId: away, stage: groupName))
                }
            }
        }

        // Date the group stage: each matchday fills consecutive days, a fixed
        // number of games a day, and the next matchday starts the day after.
        var fixtures: [InternationalTournament.Fixture] = []
        var day = startDate
        let perDay = max(1, kind.groupGamesPerDay)
        for games in matchdays {
            for (i, var game) in games.enumerated() {
                if i > 0 && i % perDay == 0 { day = TournamentDates.add(day, days: 1) }
                game.date = day
                fixtures.append(game)
            }
            day = TournamentDates.add(day, days: 1)
        }

        return InternationalTournament.State(
            kind: kind,
            stage: .groupStage,
            participantIds: field.map { $0.id },
            groupAssignments: assignments,
            fixtures: fixtures,
            edition: edition,
            startDate: startDate
        )
    }

    /// A round-robin split into matchdays (the circle method). Each team plays
    /// once a matchday; a group of odd size gives one side a rest day.
    private static func rounds(_ ids: [String]) -> [[(String, String)]] {
        var teams: [String?] = ids
        if teams.count % 2 == 1 { teams.append(nil) }
        let n = teams.count
        var result: [[(String, String)]] = []
        for round in 0..<(n - 1) {
            var pairs: [(String, String)] = []
            for i in 0..<(n / 2) {
                guard let a = teams[i], let b = teams[n - 1 - i] else { continue }
                // Alternate who is nominally at home so it is not always the top seed.
                pairs.append(round % 2 == 0 ? (a, b) : (b, a))
            }
            result.append(pairs)
            teams.insert(teams.removeLast(), at: 1)
        }
        return result
    }
}
