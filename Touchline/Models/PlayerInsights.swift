//
//  PlayerInsights.swift
//  Touchline
//
//  What a player's profile says about him beyond the raw numbers: how well
//  he would play in each position, his role in the squad, whether he is
//  playing as much as he expects, and what he thinks about it all.
//

import Foundation

public struct PlayerThought: Hashable {
    public enum Tone { case good, neutral, bad }
    public let text: String
    public let tone: Tone
}

extension Player {
    /// How good he would be in a position: his rating in a natural role,
    /// a little less elsewhere in the same line, and far less out of it.
    public func roleRating(at position: Position) -> Int {
        if positions.contains(position) { return overall }
        if primaryPosition == .GK || position == .GK {
            return max(1, overall / 12)
        }
        let a = attributes
        let mine = primaryPosition.category
        if position.category == mine { return max(1, overall - 5) }
        // An adjacent line: defenders and forwards can fill in at midfield.
        let base: Int
        switch position.category {
        case .defender: base = (a.tackling + a.marking + a.positioning + a.strength) / 4
        case .midfielder: base = (a.passing + a.vision + a.firstTouch + a.stamina) / 4
        case .forward: base = (a.shooting + a.offTheBall + a.dribbling + a.pace) / 4
        case .goalkeeper: base = 5
        }
        return max(1, min(overall - 8, base - 6))
    }
}

extension GameState {

    /// His standing at his club, from where he sits in the squad's pecking order.
    public func squadRole(of player: Player, at club: Club) -> SquadRole {
        let xi = club.startingXIAverageOverall
        let o = Double(player.overall)
        if player.age <= 20 && o < xi - 5 { return .youngster }
        if o >= xi + 3 { return .keyPlayer }
        if o >= xi - 2 { return .firstTeam }
        if o >= xi - 6 { return .rotation }
        if o >= xi - 11 { return .backup }
        return .notNeeded
    }

    /// The share of minutes he expects, given his role.
    public func expectedMinutesShare(of player: Player, at club: Club) -> Double {
        switch squadRole(of: player, at: club) {
        case .keyPlayer: return 0.75
        case .firstTeam: return 0.6
        case .rotation: return 0.3
        case .backup: return 0.1
        case .youngster, .notNeeded: return 0.05
        }
    }

    /// The share of the club's minutes he has actually played this season.
    public func minutesShare(of player: Player, at club: Club) -> Double {
        let played = season.completedFixtures(forClub: club.id).count
        guard played > 0 else { return 0 }
        return min(1, Double(player.seasonStats.minutesPlayed) / Double(played * 90))
    }

    /// A few sentences on how he feels: pay, playing time, form, contract.
    public func thoughts(of player: Player, at club: Club) -> [PlayerThought] {
        var out: [PlayerThought] = []
        let fair = Player.calculateWage(overall: player.overall, age: player.age, tier: club.leagueTier)
        if player.wage >= Int(Double(fair) * 0.9) {
            out.append(PlayerThought(text: "He is happy with his salary.", tone: .good))
        } else if player.wage >= Int(Double(fair) * 0.6) {
            out.append(PlayerThought(text: "He thinks he deserves a slightly better salary.", tone: .neutral))
        } else {
            out.append(PlayerThought(text: "He feels badly underpaid.", tone: .bad))
        }
        let played = season.completedFixtures(forClub: club.id).count
        if played >= 3 {
            let share = minutesShare(of: player, at: club)
            let expected = expectedMinutesShare(of: player, at: club)
            if share >= expected + 0.15 {
                out.append(PlayerThought(text: "He plays more than he expected.", tone: .good))
            } else if share >= expected - 0.15 {
                out.append(PlayerThought(text: "He is content with his playing time.", tone: .neutral))
            } else {
                out.append(PlayerThought(text: "He wants to play more often.", tone: .bad))
            }
        }
        if let years = player.contract?.yearsRemaining, years <= 1, !player.isOnLoan {
            out.append(PlayerThought(text: "His contract is running down and he wants to know his future.", tone: .bad))
        }
        switch player.transferStatus {
        case .transferListed?: out.append(PlayerThought(text: "He knows the club is ready to sell him.", tone: .bad))
        case .notForSale?: out.append(PlayerThought(text: "He feels valued: the club has blocked all offers.", tone: .good))
        default: break
        }
        let recent = player.form.suffix(3)
        if recent.count == 3 {
            let avg = recent.reduce(0, +) / 3
            if avg >= 7.3 { out.append(PlayerThought(text: "He is full of confidence after his recent performances.", tone: .good)) }
            else if avg < 6.0 { out.append(PlayerThought(text: "He is low on confidence after some poor games.", tone: .bad)) }
        }
        if player.isOnLoan {
            out.append(PlayerThought(text: "He is here on loan and wants to make an impression.", tone: .neutral))
        }
        return out
    }
}
