//
//  EuropeanCompetitionBuilder.swift
//  Touchline
//
//  Loads European competition participants (real seeds from the bundled JSON) and
//  builds the league-phase schedules. Participants are matched to in-game clubs by
//  name; where a competition is short of its full field the strongest remaining
//  top-flight clubs are added so every competition is complete.
//

import Foundation

public struct EuropeanParticipantData: Codable {
    public let key: String
    public let name: String
    public let shortName: String
    public let clubNames: [String]
}

public struct EuropeanDataFile: Codable {
    public let competitions: [EuropeanParticipantData]
}

public enum EuropeanCompetitionBuilder {

    /// Loads the bundled participant seed file.
    public static func loadParticipantData() -> EuropeanDataFile? {
        guard let url = Bundle.main.url(forResource: "european_competitions", withExtension: "json"),
              let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(EuropeanDataFile.self, from: data)
    }

    /// Builds all three European competitions from the loaded clubs, seeding real
    /// participants first and padding with the strongest eligible top-flight clubs.
    ///
    /// `qualifiers`, when given, replaces the bundled 2025-26 entry list with
    /// the clubs that earned their places last season.
    public static func build(
        from clubs: [Club],
        qualifiers: [EuropeanCompetition: [UUID]]? = nil
    ) -> [EuropeanCompetitionState] {
        let dataFile = qualifiers == nil ? loadParticipantData() : nil
        var results: [EuropeanCompetitionState] = []
        var alreadyEntered = Set<UUID>()

        for competition in EuropeanCompetition.allCases {
            let seedNames = dataFile?.competitions.first(where: { $0.key == competition.rawValue })?.clubNames ?? []
            var participants: [UUID] = []
            var usedNames = Set<String>()

            // 1a. Clubs that qualified on merit last season.
            let target = competition.leaguePhaseCount
            for id in qualifiers?[competition] ?? [] where participants.count < target {
                guard let club = clubs.first(where: { $0.id == id }),
                      !usedNames.contains(club.name), !alreadyEntered.contains(id) else { continue }
                participants.append(id)
                usedNames.insert(club.name)
            }

            // 1b. Real seeds, matched to loaded clubs by normalised name. A club
            //    already entered in a stronger competition cannot be seeded twice.
            for name in seedNames {
                let available: (Club) -> Bool = { !usedNames.contains($0.name) && !alreadyEntered.contains($0.id) }
                // Exact (normalised) names first; loose matching only among top
                // flights, so "Rangers" can never resolve to Queens Park Rangers.
                let exact = clubs.first { normalise($0.name) == normalise(name) && available($0) }
                let loose = clubs.first { $0.leagueTier.isTopFlight && matches($0, name: name) && available($0) }
                if let club = exact ?? loose {
                    participants.append(club.id)
                    usedNames.insert(club.name)
                }
            }

            // 2. Pad with the strongest remaining clubs from top flights, ignoring any
            //    already entered in a stronger competition.
            if participants.count < target {
                // Pad with the strongest remaining top-flight clubs, spreading
                // places across countries: a country already well represented
                // waits behind one that is not, so the big leagues cannot take
                // every spare place.
                var perCountry: [LeagueCountry: Int] = [:]
                for club in clubs where alreadyEntered.contains(club.id) || participants.contains(club.id) {
                    perCountry[club.leagueTier.country, default: 0] += 1
                }
                var eligible = clubs.filter {
                    $0.leagueTier.isTopFlight && $0.leagueTier.country.competesInEurope
                        && !usedNames.contains($0.name) && !alreadyEntered.contains($0.id)
                }
                while participants.count < target, !eligible.isEmpty {
                    let pickIndex = eligible.indices.min { lhs, rhs in
                        let lc = perCountry[eligible[lhs].leagueTier.country, default: 0]
                        let rc = perCountry[eligible[rhs].leagueTier.country, default: 0]
                        if lc != rc { return lc < rc }
                        return eligible[lhs].reputation > eligible[rhs].reputation
                    } ?? eligible.startIndex
                    let club = eligible.remove(at: pickIndex)
                    participants.append(club.id)
                    usedNames.insert(club.name)
                    perCountry[club.leagueTier.country, default: 0] += 1
                }
            }

            // A league phase needs an even number of clubs. Trim a spare seed
            // rather than leaving one participant without a single fixture.
            if participants.count % 2 != 0 {
                participants.removeLast()
            }
            guard participants.count >= 4 else { continue }

            for id in participants { alreadyEntered.insert(id) }

            var state = EuropeanCompetitionState(competition: competition, participantClubIds: participants)
            state.fixtures = generateLeaguePhase(for: competition, participantClubIds: participants)
            results.append(state)
        }

        return results
    }

    /// Loose name matching between the dataset name and an in-game club name.
    private static func matches(_ club: Club, name: String) -> Bool {
        let a = normalise(club.name)
        let b = normalise(name)
        if a == b { return true }
        // Match on a distinctive leading token, e.g. "Real Madrid" vs "Real Madrid CF".
        if a.count >= 4 && (b.contains(a) || a.contains(b)) { return true }
        return false
    }

    private static func normalise(_ s: String) -> String {
        let lowered = s.lowercased()
        let stripped = lowered.replacingOccurrences(of: "fc", with: "")
            .replacingOccurrences(of: "cf", with: "")
            .replacingOccurrences(of: "afc", with: "")
            .replacingOccurrences(of: "sc", with: "")
            .replacingOccurrences(of: ".", with: "")
            .replacingOccurrences(of: "-", with: " ")
            .replacingOccurrences(of: " ", with: "")
        return stripped
    }

    /// Builds an 8-match (or 6 for UECL) Swiss-style league phase. Uses a single
    /// round-robin (circle method) and takes the first `matches` rounds, so every
    /// club faces a distinct set of opponents with alternating venues.
    private static func generateLeaguePhase(
        for competition: EuropeanCompetition,
        participantClubIds: [UUID]
    ) -> [EuropeanFixture] {
        var pool = participantClubIds
        guard pool.count >= 4 else { return [] }
        if pool.count % 2 != 0 { pool.removeLast() }

        let n = pool.count
        let half = n / 2
        let totalRounds = n - 1
        let rounds = min(competition.leaguePhaseMatches, totalRounds)

        var rotation = Array(pool.dropFirst())   // clubs[1...]
        let fixed = pool[0]

        var fixtures: [EuropeanFixture] = []

        for round in 0..<rounds {
            var roundFixtures: [EuropeanFixture] = []

            // Fixed club plays the first rotating club.
            let firstOpponent = rotation[0]
            let fixedHome = round % 2 == 0
            roundFixtures.append(EuropeanFixture(
                homeClubId: fixedHome ? fixed : firstOpponent,
                awayClubId: fixedHome ? firstOpponent : fixed,
                matchweek: round + 1,
                stage: "League Phase",
                leg: 0
            ))

            // Pair the remaining rotating clubs symmetrically.
            for i in 1..<half {
                let a = rotation[i]
                let b = rotation[rotation.count - i]
                let aHome = (round + i) % 2 == 0
                roundFixtures.append(EuropeanFixture(
                    homeClubId: aHome ? a : b,
                    awayClubId: aHome ? b : a,
                    matchweek: round + 1,
                    stage: "League Phase",
                    leg: 0
                ))
            }

            fixtures.append(contentsOf: roundFixtures)
            if let last = rotation.popLast() { rotation.insert(last, at: 0) }
        }

        return fixtures
    }
}
