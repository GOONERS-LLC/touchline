//
//  SeasonCalendar.swift
//  Touchline
//
//  The shape of a season. Every competition shares one numbered list of
//  "slots" (the matchWeek on a fixture): a Saturday for each week, and a
//  Wednesday cup night after most of them.
//
//    Saturday 1           super cups (champions v cup winners)
//    Saturdays 2 onward   league rounds
//    Wednesdays           national cups, league cups and trophies, plus the
//                         extra league rounds of 24-club divisions
//
//  Leagues play their real number of rounds (38 in the Scottish Premiership,
//  34 in MLS, 36 in the HNL) and every season still finishes in May.
//

import Foundation

public enum SeasonCalendar {
    /// Wednesdays follow these Saturdays (0 = the opening Saturday).
    private static let midweekAfterSaturday = Array(1...38)
    private static let saturdays = 60

    private struct Slot { let dayOffset: Int; let midweek: Bool; let index: Int }

    /// slot number (1-based) -> day offset from the opening Saturday.
    private static let table: [Slot] = {
        var slots: [Slot] = []
        var midweekIndex = 0
        for week in 0..<saturdays {
            slots.append(Slot(dayOffset: week * 7, midweek: false, index: week + 1))
            if midweekAfterSaturday.contains(week) {
                midweekIndex += 1
                slots.append(Slot(dayOffset: week * 7 + 4, midweek: true, index: midweekIndex))
            }
        }
        return slots
    }()

    /// Days after the opening Saturday that a slot is played.
    public static func dayOffset(forSlot slot: Int) -> Int {
        guard slot >= 1 else { return 0 }
        if slot <= table.count { return table[slot - 1].dayOffset }
        return table.last!.dayOffset + (slot - table.count) * 7
    }

    public static func isMidweek(_ slot: Int) -> Bool {
        slot >= 1 && slot <= table.count && table[slot - 1].midweek
    }

    /// The slot of the nth Saturday (1-based).
    public static func saturday(_ n: Int) -> Int {
        table.firstIndex { !$0.midweek && $0.index == n }.map { $0 + 1 } ?? n
    }

    /// The slot of the nth Wednesday (1-based).
    public static func wednesday(_ n: Int) -> Int {
        table.firstIndex { $0.midweek && $0.index == n }.map { $0 + 1 } ?? saturday(n)
    }

    // MARK: - Who plays when

    /// Wednesdays for each kind of cup, earliest round first. Cups with fewer
    /// rounds use the last ones, so every final lands on the same night.
    public static func cupNights(for kind: CupKind) -> [Int] {
        switch kind {
        case .national: return [6, 11, 16, 21, 26, 31, 35].map(wednesday)
        case .league: return [2, 4, 8, 13, 18, 23, 28].map(wednesday)
        case .trophy: return [3, 9, 14, 19, 24, 29].map(wednesday)
        case .superCup: return [saturday(1)]
        }
    }

    /// Wednesdays free of cups, used for midweek league rounds.
    private static let leagueMidweeks: [Int] = {
        let cupWeds: Set<Int> = Set([6, 11, 16, 21, 26, 31, 35, 2, 4, 8, 13, 18, 23, 28, 3, 9, 14, 19, 24, 29])
        return (1...midweekAfterSaturday.count).filter { !cupWeds.contains($0) }.map(wednesday)
    }()

    /// Slots for a league's rounds: Saturdays 2 to 39, then free Wednesdays.
    public static func leagueSlots(rounds: Int) -> [Int] {
        let weekend = (2...39).map(saturday)
        if rounds <= weekend.count { return Array(weekend.prefix(rounds)) }
        let extra = Array(leagueMidweeks.prefix(rounds - weekend.count))
        var slots = (weekend + extra).sorted()
        // More rounds than Saturdays and free Wednesdays: carry on into June.
        var next = 40
        while slots.count < rounds { slots.append(saturday(next)); next += 1 }
        return slots
    }
}

// MARK: - Real season lengths

extension LeagueTier {
    /// Matches each club plays in a season, as in the real competition.
    /// Leagues not listed play every opponent home and away.
    public func seasonRounds(clubCount: Int) -> Int {
        let doubleRoundRobin = 2 * (clubCount - 1)
        switch rawValue {
        case 91: return 38                 // Scottish Premiership: 33 rounds plus the split
        case 92: return 36                 // Scottish Championship: four rounds of ten
        case 111: return 32                // Liga Profesional: Apertura and Clausura group stages
        case 121: return 26                // A-League Men
        case 131: return 32                // Austrian Bundesliga: 22 plus the split
        case 151: return 36                // SuperSport HNL: four rounds of ten
        case 161: return 35                // Chance Liga: 30 plus the split
        case 171: return 32                // Danish Superliga: 22 plus the split
        case 181: return 32                // Greek Super League: 26 plus the play-offs
        case 201: return 38                // K League 1: 33 plus the split
        case 241: return 40                // Romanian SuperLiga: 30 plus the play-offs
        case 271: return 37                // Serbian SuperLiga: 30 plus the split
        case 291: return 38                // Swiss Super League: 33 plus the split
        case 292: return 40                // Swiss Challenge League: nine clubs, one rests each round
        case 311: return 34                // Major League Soccer
        case 312: return 31                // USL Championship: 25 clubs, one rests each round
        case 101: return 40                // Belgian Pro League: 30 plus the play-offs
        default: return doubleRoundRobin
        }
    }
}
