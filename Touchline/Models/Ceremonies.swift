//
//  Ceremonies.swift
//  Touchline
//
//  The awards nights. The season's individual honours are decided when it
//  ends, but, as in real football, they are handed out later: the Ballon
//  d'Or at the end of October, the Team of the Year in January. Each is
//  shown on its own screen when the night comes round.
//
//  Also builds the ranked lists for the end-of-season review: the top three
//  clubs, players, scorers and providers in the user's division, and its
//  team of the season.
//

import Foundation

/// One name on an awards list.
public struct AwardEntry: Codable, Hashable, Identifiable {
    /// The player's id.
    public var id: UUID
    public var name: String
    public var clubName: String
    /// Position abbreviation, e.g. "CB".
    public var position: String
    /// "24 goals, 9 assists, 7.62 average".
    public var detail: String
    public var isUsersPlayer: Bool
}

/// One division's season, for the review.
public struct DivisionHonours: Codable, Hashable, Identifiable {
    public var id: String { leagueName }
    public var leagueName: String
    public var level: Int
    public var country: String
    public var topClubs: [String]
    public var bestPlayers: [AwardEntry]
    public var topScorers: [AwardEntry]
    public var topAssists: [AwardEntry]
    public var teamOfTheSeason: [AwardEntry]
}

/// An awards night still to come, or just held.
public struct AwardCeremony: Codable, Hashable, Identifiable {
    public enum Kind: String, Codable, Hashable {
        case ballonDor
        case teamOfTheYear
    }

    public var id: UUID
    public var kind: Kind
    /// The season being honoured, e.g. "2026-27".
    public var season: String
    /// "YYYY-MM-DD": held on the first week on or after this date.
    public var date: String
    /// Ballon d'Or: the top ten, winner first. Team of the Year: the eleven.
    public var ranking: [AwardEntry]
    /// Other prizes on the night: the best young player and the best keeper.
    public var youngPlayer: AwardEntry?
    public var goalkeeper: AwardEntry?

    public var title: String {
        switch kind {
        case .ballonDor: return "Ballon d'Or \(season)"
        case .teamOfTheYear: return "Team of the Year \(season)"
        }
    }
}

extension GameState {

    // MARK: - Picking players

    typealias Candidate = (player: Player, club: Club)

    /// How good a season a player had: his ratings above all, with goals,
    /// assists and clean sheets, his quality, and a bonus for winning things.
    /// With `weighLeague`, for the world awards, the strength of the club
    /// and league counts too, so a great season in a small league does not
    /// outrank one at the top of the game.
    func seasonScore(_ entry: Candidate, champions: Set<UUID>, weighLeague: Bool = false) -> Double {
        let s = entry.player.seasonStats
        var score = s.averageRating * 10 + Double(s.goals) * 0.6 + Double(s.assists) * 0.35
            + Double(entry.player.overall) * 0.2
        if entry.player.primaryPosition == .GK { score += Double(s.cleanSheets) * 0.35 }
        if champions.contains(entry.club.id) { score += 4 }
        if weighLeague {
            // The world awards lean on quality as well as the season: the
            // best players in the world, not just the best statistics.
            score += Double(entry.player.overall) * 0.6 + Double(entry.club.reputation) * 0.12
                - Double(entry.club.leagueTier.level - 1) * 3
        }
        return score
    }

    func awardEntry(_ entry: Candidate, detail: String? = nil) -> AwardEntry {
        let s = entry.player.seasonStats
        let line: String
        if let detail {
            line = detail
        } else if entry.player.primaryPosition == .GK {
            line = "\(s.appearances) games, \(s.cleanSheets) clean sheets, \(String(format: "%.2f", s.averageRating)) average"
        } else {
            line = "\(s.appearances) games, \(s.goals) goals, \(s.assists) assists, \(String(format: "%.2f", s.averageRating)) average"
        }
        return AwardEntry(id: entry.player.id, name: entry.player.fullName, clubName: entry.club.name,
                          position: entry.player.primaryPosition.abbreviation, detail: line,
                          isUsersPlayer: entry.club.isUserClub)
    }

    /// The best eleven in a 4-3-3: a keeper, four defenders, three
    /// midfielders and three forwards.
    func bestEleven(from pool: [Candidate], champions: Set<UUID>, weighLeague: Bool = false) -> [Candidate] {
        func best(_ category: PositionCategory, _ count: Int) -> [Candidate] {
            Array(pool.filter { $0.player.primaryPosition.category == category }
                .sorted { seasonScore($0, champions: champions, weighLeague: weighLeague)
                    > seasonScore($1, champions: champions, weighLeague: weighLeague) }
                .prefix(count))
        }
        return best(.goalkeeper, 1) + best(.defender, 4) + best(.midfielder, 3) + best(.forward, 3)
    }

    // MARK: - Deciding the awards (end of season)

    /// Decides the Ballon d'Or (with the best young player and the best
    /// keeper) and the Team of the Year from every league in the world, to
    /// be presented in October and January.
    func scheduleAwardCeremonies(pool: [Candidate], champions: Set<UUID>) {
        guard !pool.isEmpty else { return }
        let endYear = Int(season.currentDate.prefix(4)) ?? 2027
        func score(_ c: Candidate) -> Double { seasonScore(c, champions: champions, weighLeague: true) }
        let ranked = pool.sorted { score($0) > score($1) }
        let young = pool.filter { $0.player.age <= 21 }.max { score($0) < score($1) }
        let keeper = pool.filter { $0.player.primaryPosition == .GK }.max { score($0) < score($1) }
        pendingCeremonies.append(AwardCeremony(
            id: UUID(),
            kind: .ballonDor,
            season: season.year,
            date: "\(endYear)-10-28",
            ranking: ranked.prefix(10).map { awardEntry($0) },
            youngPlayer: young.map { awardEntry($0) },
            goalkeeper: keeper.map { awardEntry($0) }
        ))
        pendingCeremonies.append(AwardCeremony(
            id: UUID(),
            kind: .teamOfTheYear,
            season: season.year,
            date: "\(endYear + 1)-01-15",
            ranking: bestEleven(from: pool, champions: champions, weighLeague: true).map { awardEntry($0) },
            youngPlayer: nil,
            goalkeeper: nil
        ))
    }
    // MARK: - Holding them (in season)

    /// Holds any awards night whose date has come: the winners go into the
    /// record books and the news, and the ceremony is shown on screen.
    func holdDueCeremonies() {
        guard !pendingCeremonies.isEmpty else { return }
        let today = season.currentDate
        var remaining: [AwardCeremony] = []
        for ceremony in pendingCeremonies {
            guard ceremony.date <= today else { remaining.append(ceremony); continue }
            switch ceremony.kind {
            case .ballonDor:
                if let winner = ceremony.ranking.first {
                    record("Ballon d'Or", winner, season: ceremony.season)
                    let podium = ceremony.ranking.dropFirst().prefix(2).map { "\($0.name) (\($0.clubName))" }.joined(separator: " and ")
                    addNews(
                        headline: "\(winner.name) Wins the Ballon d'Or",
                        body: "\(winner.name) of \(winner.clubName) is crowned the world's best player for \(ceremony.season): \(winner.detail).\(podium.isEmpty ? "" : " \(podium) complete the podium.")",
                        category: .award,
                        sender: winner.isUsersPlayer ? "Awards Committee" : "World Football Awards"
                    )
                }
                if let young = ceremony.youngPlayer { record("Kopa Trophy (best young player)", young, season: ceremony.season) }
                if let keeper = ceremony.goalkeeper { record("Yashin Trophy (best goalkeeper)", keeper, season: ceremony.season) }
            case .teamOfTheYear:
                let ours = ceremony.ranking.filter { $0.isUsersPlayer }.map(\.name)
                addNews(
                    headline: "Team of the Year \(ceremony.season)",
                    body: ceremony.ranking.map { "\($0.position) \($0.name)" }.joined(separator: ", ") + "."
                        + (ours.isEmpty ? "" : " Our \(ours.count == 1 ? "player" : "players") \(ours.joined(separator: " and ")) made the side."),
                    category: .award,
                    sender: ours.isEmpty ? "World Football Awards" : "Awards Committee"
                )
            }
            ceremonyToShow = ceremony
        }
        pendingCeremonies = remaining
    }

    private func record(_ award: String, _ entry: AwardEntry, season year: String) {
        history.awards.append(AwardRecord(season: year, award: award, playerId: entry.id, playerName: entry.name,
                                          clubName: entry.clubName, detail: entry.detail))
    }

    // MARK: - The division's season, for the review

    /// One division's season: its top three clubs, best players, top
    /// scorers and providers, and its team of the season.
    func divisionHonours(league: League, table: [LeagueStanding]) -> DivisionHonours {
        let members = table.compactMap { club(withId: $0.clubId) }
        let pool: [Candidate] = members.flatMap { c in c.players.map { (player: $0, club: c) } }
        let regulars = pool.filter { $0.player.seasonStats.appearances >= 15 }
        let eligible = regulars.count >= 11 ? regulars : pool.filter { $0.player.seasonStats.appearances >= 5 }
        let champion: Set<UUID> = Set(table.prefix(1).map(\.clubId))
        return DivisionHonours(
            leagueName: league.name,
            level: league.tier.level,
            country: league.tier.country.displayName,
            topClubs: table.prefix(3).enumerated().map { index, row in
                "\(index + 1). \(clubName(for: row.clubId)) — \(row.points) pts"
            },
            bestPlayers: eligible
                .sorted { $0.player.seasonStats.averageRating > $1.player.seasonStats.averageRating }
                .prefix(3).map { awardEntry($0) },
            topScorers: pool.filter { $0.player.seasonStats.goals > 0 }
                .sorted { ($0.player.seasonStats.goals, -$0.player.seasonStats.appearances) > ($1.player.seasonStats.goals, -$1.player.seasonStats.appearances) }
                .prefix(3).map { awardEntry($0, detail: "\($0.player.seasonStats.goals) goals in \($0.player.seasonStats.appearances) games") },
            topAssists: pool.filter { $0.player.seasonStats.assists > 0 }
                .sorted { ($0.player.seasonStats.assists, -$0.player.seasonStats.appearances) > ($1.player.seasonStats.assists, -$1.player.seasonStats.appearances) }
                .prefix(3).map { awardEntry($0, detail: "\($0.player.seasonStats.assists) assists in \($0.player.seasonStats.appearances) games") },
            teamOfTheSeason: bestEleven(from: eligible, champions: champion).map { awardEntry($0) }
        )
    }

    /// Fills the review's ranked lists: the user's own division in full, and
    /// every other division in the world to browse.
    func addDivisionHonours(to review: inout SeasonReview, table: [LeagueStanding], finalTables: [LeagueTier: [LeagueStanding]]) {
        var all: [DivisionHonours] = []
        for league in leagues {
            guard let leagueTable = finalTables[league.tier], !leagueTable.isEmpty else { continue }
            all.append(divisionHonours(league: league, table: leagueTable))
        }
        if let own = all.first(where: { $0.leagueName == review.leagueName }) {
            review.topClubs = own.topClubs
            review.bestPlayers = own.bestPlayers
            review.topScorers = own.topScorers
            review.topAssists = own.topAssists
            review.teamOfTheSeason = own.teamOfTheSeason
        }
        review.otherDivisions = all
            .filter { $0.leagueName != review.leagueName }
            .sorted { ($0.country, $0.level) < ($1.country, $1.level) }
    }
    /// How the user's club got on in its other competitions: the league cup,
    /// any other domestic trophy, and Europe.
    func otherCompetitionRuns(for clubId: UUID, country: LeagueCountry) -> (leagueCup: String?, europe: [String]) {
        var leagueCup: String?
        for cup in domesticCups where cup.country == country && cup.kind != .national && cup.kind != .superCup {
            let ties = season.fixtures.filter { $0.competition == cup.name && $0.involves(clubId: clubId) }
            guard !ties.isEmpty || cup.championClubId == clubId else { continue }
            let line: String
            if cup.championClubId == clubId {
                line = "\(cup.name) winners"
            } else if let last = ties.last, let round = last.cupRound {
                line = round == "Final" ? "\(cup.name): runners-up" : "\(cup.name): out in the \(round.lowercased())"
            } else {
                continue
            }
            leagueCup = leagueCup.map { "\($0) · \(line)" } ?? line
        }

        var europe: [String] = []
        for competition in europeanCompetitions {
            let ties = competition.fixtures.filter { $0.homeClubId == clubId || $0.awayClubId == clubId }
            guard !ties.isEmpty else { continue }
            let name = competition.competition.displayName
            if competition.championClubId == clubId {
                europe.append("\(name) winners")
            } else if let last = ties.filter({ $0.isPlayed }).last {
                if last.stage == "League Phase" {
                    let rank = (competition.table().firstIndex { $0.clubId == clubId } ?? 0) + 1
                    europe.append("\(name): out in the league phase (\(rank)\(rank == 1 ? "st" : rank == 2 ? "nd" : rank == 3 ? "rd" : "th"))")
                } else if last.stage == "Final" {
                    europe.append("\(name): runners-up")
                } else {
                    europe.append("\(name): out in the \(last.stage.lowercased())")
                }
            } else {
                europe.append("\(name): entered")
            }
        }
        return (leagueCup, europe)
    }
}
