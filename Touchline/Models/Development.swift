//
//  Development.swift
//  Touchline
//
//  Players develop during the season as well as over the summer: each month
//  on the training ground can add (or, for an out-of-form veteran, cost) a
//  point, and better facilities make the difference. A manager can ask the
//  board to invest in the training ground, the academy and the medical
//  department.
//

import Foundation

public enum FacilityKind: String, CaseIterable, Identifiable {
    case training, youth, medical

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .training: return "Training Ground"
        case .youth: return "Youth Academy"
        case .medical: return "Medical Department"
        }
    }

    public var effect: String {
        switch self {
        case .training: return "Players improve faster during the season and over the summer."
        case .youth: return "Better academy prospects with higher ceilings."
        case .medical: return "Injured players recover faster and pick up fewer training injuries."
        }
    }
}

extension GameState {

    // MARK: - Monthly training

    /// A month on every club's training ground. The user's club gets a
    /// report of who has moved.
    func applyMonthlyTraining() {
        var improved: [String] = []
        var declined: [String] = []
        for c in clubs.indices {
            let level = clubs[c].trainingFacilityLevel
            let isUsers = clubs[c].isUserClub
            for p in clubs[c].players.indices {
                let change = clubs[c].players[p].applyMonthlyTraining(trainingLevel: level)
                guard isUsers, change != 0 else { continue }
                let player = clubs[c].players[p]
                if change > 0 { improved.append("\(player.fullName) (\(player.overall))") }
                else { declined.append("\(player.fullName) (\(player.overall))") }
            }
        }
        guard !improved.isEmpty || !declined.isEmpty else { return }
        var lines: [String] = []
        if !improved.isEmpty { lines.append("Improved: " + improved.joined(separator: ", ") + ".") }
        if !declined.isEmpty { lines.append("Gone backwards: " + declined.joined(separator: ", ") + ".") }
        addNews(
            headline: "Monthly Training Report",
            body: lines.joined(separator: " ") + " Good form and better facilities speed up development.",
            category: .general,
            sender: "First-Team Coach"
        )
    }

    // MARK: - Facilities

    public func facilityLevel(_ kind: FacilityKind) -> Int {
        guard let club = userClub else { return 0 }
        switch kind {
        case .training: return club.trainingFacilityLevel
        case .youth: return club.youthAcademyLevel
        case .medical: return club.medicalFacilityLevel
        }
    }

    public func facilityUpgradeCost(_ kind: FacilityKind) -> Int {
        guard let club = userClub else { return 0 }
        switch kind {
        case .training: return club.trainingUpgradeCost
        case .youth: return club.academyUpgradeCost
        case .medical: return club.medicalUpgradeCost
        }
    }

    /// The manager asks the board to invest in a facility. They agree if
    /// the money is there (from the transfer budget for the training ground
    /// and academy, the bank for the medical department).
    @discardableResult
    public func requestFacilityUpgrade(_ kind: FacilityKind) -> String {
        guard let idx = clubs.firstIndex(where: { $0.isUserClub }) else { return "You do not have a club." }
        let level = facilityLevel(kind)
        guard level < 5 else { return "The \(kind.title.lowercased()) is already the best there is." }
        let cost = facilityUpgradeCost(kind)
        let done: Bool
        switch kind {
        case .training: done = clubs[idx].upgradeTrainingGround()
        case .youth: done = clubs[idx].upgradeYouthAcademy()
        case .medical: done = clubs[idx].upgradeMedicalFacilities()
        }
        guard done else {
            let source = kind == .medical ? "bank balance" : "transfer budget"
            return "The board can't fund it: the \(Player.formatCurrency(cost)) upgrade is more than the \(source) allows."
        }
        seasonLedger?.transfers += cost
        addNews(
            headline: "\(kind.title) Upgraded",
            body: "The board have approved \(Player.formatCurrency(cost)) to take the \(kind.title.lowercased()) to level \(level + 1). \(kind.effect)",
            category: .board,
            sender: "The Board"
        )
        return "Approved. The \(kind.title.lowercased()) is now level \(level + 1)."
    }
}
