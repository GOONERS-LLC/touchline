//
//  DomesticCup.swift
//  Touchline
//
//  National knockout cups (FA Cup, Copa del Rey, DFB-Pokal...). Every club in
//  a country enters; lower-division clubs start in the first round while the
//  strongest receive byes, and each round is drawn once the previous one has
//  finished. Ties are single matches with extra time and penalties.
//

import Foundation

public struct DomesticCupState: Codable, Hashable, Identifiable {
    public var id: String { name }
    public let country: LeagueCountry
    public let name: String
    /// Round names in order, e.g. ["First Round", ..., "Final"].
    public let rounds: [String]
    /// Calendar matchweek in which each round is played.
    public let roundWeeks: [Int]
    /// Index into `rounds` of the round currently being played.
    public var currentRoundIndex: Int
    /// Clubs that skip the first round.
    public var byeClubIds: [UUID]
    public var championClubId: UUID?

    public init(country: LeagueCountry, name: String, rounds: [String], roundWeeks: [Int], byeClubIds: [UUID]) {
        self.country = country
        self.name = name
        self.rounds = rounds
        self.roundWeeks = roundWeeks
        self.currentRoundIndex = 0
        self.byeClubIds = byeClubIds
        self.championClubId = nil
    }

    public var currentRoundName: String {
        rounds.indices.contains(currentRoundIndex) ? rounds[currentRoundIndex] : ""
    }

    public var isFinished: Bool { championClubId != nil }
}

public enum DomesticCups {
    /// Calendar weeks reserved for cup rounds. League rounds skip these weeks,
    /// so no club ever has a league match and a cup tie in the same week.
    public static let cupWeeks: [Int] = [6, 12, 18, 24, 30, 36, 42]

    /// Smallest number of clubs for which a country runs a cup.
    public static let minimumEntrants = 8

    public static func cupName(for country: LeagueCountry) -> String {
        switch country {
        case .england: return "FA Cup"
        case .spain: return "Copa del Rey"
        case .italy: return "Coppa Italia"
        case .germany: return "DFB-Pokal"
        case .france: return "Coupe de France"
        case .portugal: return "Taça de Portugal"
        case .netherlands: return "KNVB Cup"
        case .turkey: return "Turkish Cup"
        case .scotland: return "Scottish Cup"
        case .belgium: return "Belgian Cup"
        case .argentina: return "Copa Argentina"
        case .australia: return "Australia Cup"
        case .austria: return "ÖFB-Cup"
        case .brazil: return "Copa do Brasil"
        case .japan: return "Emperor's Cup"
        case .southKorea: return "Korea Cup"
        case .mexico: return "Copa MX"
        case .unitedStates: return "U.S. Open Cup"
        default: return "\(country.displayName) Cup"
        }
    }

    /// Round names for a bracket with `count` rounds, ending in the final.
    public static func roundNames(count: Int) -> [String] {
        let named = ["Final", "Semi-Final", "Quarter-Final", "Round of 16"]
        let ordinals = ["First Round", "Second Round", "Third Round", "Fourth Round", "Fifth Round", "Sixth Round"]
        var names: [String] = []
        for index in 0..<count {
            let fromEnd = count - 1 - index
            if fromEnd < named.count {
                names.append(named[fromEnd])
            } else {
                names.append(index < ordinals.count ? ordinals[index] : "Round \(index + 1)")
            }
        }
        return names
    }

    /// Smallest power of two that is at least `n`.
    public static func bracketSize(for n: Int) -> Int {
        var size = 1
        while size < n { size *= 2 }
        return size
    }
}
