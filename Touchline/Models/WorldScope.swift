//
//  WorldScope.swift
//  Touchline
//
//  Which countries' club football is in the game. Club leagues are European
//  plus North America; Australia, Asia, Africa and South America have no
//  club leagues, though their national teams still play in international
//  tournaments (their squads are stored with the national teams, not drawn
//  from club squads).
//

import Foundation

extension LeagueCountry {
    /// Whether this country's club leagues are part of the world.
    public var hasClubLeagues: Bool {
        switch self {
        case .argentina, .brazil, .australia, .japan, .southKorea, .saudiArabia:
            return false
        default:
            return true
        }
    }
}

extension GameState {

    /// Takes the leagues of countries no longer in the game (Australia,
    /// Asia, Africa and South America) out of an older save, between
    /// seasons. A league is left alone if the user's own club is in it.
    /// Players on loan at the departing clubs go back to their own clubs.
    func pruneLeaguesOutsideTheGame() {
        let removedTiers = Set(leagues.map(\.tier).filter { !$0.country.hasClubLeagues })
            .filter { tier in userClub?.leagueTier != tier }
        guard !removedTiers.isEmpty else { return }
        let removedClubIds = Set(clubs.filter { removedTiers.contains($0.leagueTier) }.map(\.id))

        // Loanees go home first.
        var returning: [(parentIdx: Int, player: Player)] = []
        for club in clubs where removedClubIds.contains(club.id) {
            for player in club.players {
                guard let loan = player.loan, !removedClubIds.contains(loan.parentClubId),
                      let parentIdx = clubs.firstIndex(where: { $0.id == loan.parentClubId }) else { continue }
                var back = player
                back.loan = nil
                returning.append((parentIdx, back))
            }
        }
        for item in returning { clubs[item.parentIdx].addPlayer(item.player) }

        clubs.removeAll { removedClubIds.contains($0.id) }
        leagues.removeAll { removedTiers.contains($0.tier) }
        rivalries.removeAll { removedClubIds.contains($0.clubA) || removedClubIds.contains($0.clubB) }
        pendingTransferOffers.removeAll { removedClubIds.contains($0.fromClubId) || removedClubIds.contains($0.toClubId) }
        jobOffers.removeAll { offer in offer.clubId.map { removedClubIds.contains($0) } ?? false }
        transferInstallments.removeAll { removedClubIds.contains($0.payerClubId) || removedClubIds.contains($0.payeeClubId) }
        for idx in clubs.indices {
            clubs[idx].ensureTacticalIntegrity()
            clubs[idx].finances.currentWageBill = clubs[idx].totalWeeklyWageBill
        }
    }
}
