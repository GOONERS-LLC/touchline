//
//  WinBonus.swift
//  Touchline
//
//  Owner career: early each season the players ask for a bonus for every
//  win, a share of their weekly wages. Agreeing lifts morale and pleases
//  the manager; every win then costs money.
//

import Foundation

extension GameState {

    /// Raises the players' request once a season, a couple of weeks in.
    func checkWinBonusRequest() {
        guard gameMode == .createClub, userClub != nil,
              winBonusAskedSeason != season.year, season.currentWeek >= 2 else { return }
        winBonusAskedSeason = season.year
        pendingWinBonusRequest = true
    }

    /// What one win costs at a given bonus.
    public func winBonusCost(percent: Int) -> Int {
        guard let club = userClub else { return 0 }
        return club.totalPlayerWageBill * percent / 100
    }

    /// The owner's answer: 0, 10 or 20 percent of weekly wages per win.
    @discardableResult
    public func answerWinBonus(percent: Int) -> String {
        pendingWinBonusRequest = false
        winBonusPercent = percent
        guard let idx = clubs.firstIndex(where: { $0.isUserClub }) else { return "" }
        if percent == 0 {
            for p in clubs[idx].players.indices where Double.random(in: 0..<1) < 0.35 {
                clubs[idx].players[p].morale = clubs[idx].players[p].morale.lowered
            }
            owner.managerSatisfaction = max(0, owner.managerSatisfaction - 3)
            return "No bonus this season. Some of the squad are disappointed."
        }
        for p in clubs[idx].players.indices where Double.random(in: 0..<1) < (percent >= 20 ? 0.8 : 0.5) {
            clubs[idx].players[p].morale = clubs[idx].players[p].morale.raised
        }
        owner.managerSatisfaction = min(100, owner.managerSatisfaction + (percent >= 20 ? 6 : 3))
        return "Agreed: a \(percent)% win bonus, about \(Player.formatCurrency(winBonusCost(percent: percent))) for every win. The dressing room is delighted."
    }

    /// Pays the bonus after a win in any competition.
    func payWinBonusIfDue(_ fixture: Fixture) {
        guard gameMode == .createClub, winBonusPercent > 0, let uid = userClubId,
              let result = fixture.result, result.outcomeLetter(for: uid) == "W",
              let idx = clubs.firstIndex(where: { $0.id == uid }) else { return }
        let cost = winBonusCost(percent: winBonusPercent)
        clubs[idx].finances.balance -= cost
        seasonLedger?.wages += cost
    }
}

extension Morale {
    var raised: Morale {
        switch self {
        case .furious: return .unhappy
        case .unhappy: return .content
        case .content: return .happy
        case .happy, .delighted: return .delighted
        }
    }
    var lowered: Morale {
        switch self {
        case .delighted: return .happy
        case .happy: return .content
        case .content: return .unhappy
        case .unhappy, .furious: return .furious
        }
    }
}
