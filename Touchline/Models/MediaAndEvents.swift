//
//  MediaAndEvents.swift
//  Touchline
//
//  The manager's post-match press conference, and owner decisions forced by
//  events (supporters turning on the manager).
//

import Foundation

/// How the manager answers the press.
public enum PressTone: String, CaseIterable, Identifiable {
    case praise = "Praise the players"
    case demand = "Demand more"
    case deflect = "Keep it calm"
    public var id: String { rawValue }

    public var icon: String {
        switch self {
        case .praise: return "hands.clap.fill"
        case .demand: return "flame.fill"
        case .deflect: return "face.smiling"
        }
    }
}

/// A choice the owner must make about the manager when the fans turn.
public struct OwnerDecision: Codable, Hashable {
    public var headline: String
    public var detail: String
    public var createdDate: String
}

public enum OwnerDecisionChoice: String, CaseIterable, Identifiable {
    case backPublicly = "Back him publicly"
    case ultimatum = "Issue an ultimatum"
    case stayQuiet = "Say nothing"
    public var id: String { rawValue }

    public var summary: String {
        switch self {
        case .backPublicly: return "He will be grateful. The fans will not, unless results turn."
        case .ultimatum: return "The fans hear you; the manager feels the pressure."
        case .stayQuiet: return "No one is satisfied, but nothing is risked."
        }
    }
}

extension GameState {

    // MARK: - Press conference

    /// The question the press asks after the user's match, if it has not
    /// been answered yet.
    public func pressQuestion(for fixture: Fixture) -> String? {
        guard gameMode == .manageClub, fixture.isPlayed, let uid = userClubId,
              fixture.involves(clubId: uid), !answeredPressFixtureIds.contains(fixture.id),
              let result = fixture.result,
              let opponentId = fixture.opponentId(for: uid) else { return nil }
        let opponent = clubName(for: opponentId)
        let outcome = result.outcomeLetter(for: uid)
        let derby = rivalry(between: uid, and: opponentId)?.name
        switch outcome {
        case "W":
            if let derby { return "The \(derby) is yours. What does this win mean to the supporters?" }
            return "A fine win over \(opponent). Is this the standard from now on?"
        case "L":
            if let derby { return "Losing the \(derby) hurts. What do you say to the fans?" }
            return "A defeat to \(opponent). Where did it go wrong today?"
        default:
            return "A draw with \(opponent). Two points dropped or one gained?"
        }
    }

    /// Answers the press. Praise lifts the players (and helps after a win);
    /// demanding more stings the squad but reassures the board after a bad
    /// result; a calm answer changes little.
    public func answerPressConference(fixtureId: UUID, tone: PressTone) -> String {
        guard let fixture = season.fixtures.first(where: { $0.id == fixtureId }),
              let uid = userClubId, let result = fixture.result,
              let idx = clubs.firstIndex(where: { $0.isUserClub }),
              !answeredPressFixtureIds.contains(fixtureId) else { return "" }
        answeredPressFixtureIds.append(fixtureId)
        if answeredPressFixtureIds.count > 12 { answeredPressFixtureIds.removeFirst(answeredPressFixtureIds.count - 12) }
        let outcome = result.outcomeLetter(for: uid)
        let starters = Set(fixture.result?.playerRatings.keys.map { $0 } ?? [])
        switch tone {
        case .praise:
            for p in clubs[idx].players.indices where starters.contains(clubs[idx].players[p].id) {
                clubs[idx].players[p].boostMorale()
            }
            if outcome == "L" {
                jobSecurity.boardConfidence = max(0, jobSecurity.boardConfidence - 2)
                return "The squad appreciates the backing, but the board wonder whether you are being too soft."
            }
            return "The dressing room lifts. The players who featured are in high spirits."
        case .demand:
            for p in clubs[idx].players.indices where starters.contains(clubs[idx].players[p].id)
                && (result.playerRatings[clubs[idx].players[p].id] ?? 7) < 6.5 {
                clubs[idx].players[p].dampenMorale()
            }
            if outcome != "W" {
                jobSecurity.boardConfidence = min(100, jobSecurity.boardConfidence + 3)
                return "The board approve of your demanding standards. The poorest performers are stung."
            }
            return "Even after a win you want more. A few quieter performers feel the heat."
        case .deflect:
            return "A measured answer. The headlines move on."
        }
    }

    // MARK: - Fans turn on the manager (owner mode)

    /// After three defeats in four league games, supporters start chanting
    /// against the manager and the owner must respond.
    func reviewFanPressureOnManager() {
        guard gameMode == .createClub, pendingOwnerDecision == nil,
              let club = userClub, club.manager != "Interim Manager", let uid = userClubId else { return }
        let recent = season.completedFixtures(forClub: uid).filter { !$0.isEuropean }.suffix(4)
        guard recent.count == 4 else { return }
        let defeats = recent.compactMap { $0.result?.outcomeLetter(for: uid) }.filter { $0 == "L" }.count
        guard defeats >= 3, owner.supporterConfidence < 70 else { return }
        pendingOwnerDecision = OwnerDecision(
            headline: "Fans Turn on \(club.manager)",
            detail: "After \(defeats) defeats in four, chants against \(club.manager) rang around \(club.stadium). The press want to know where you stand.",
            createdDate: season.currentDate
        )
        addNews(headline: "Fans Turn on \(club.manager)",
                body: "Supporters are calling for change. Respond in the Boardroom.",
                category: .board, sender: "Supporters' Trust")
    }

    /// The owner's response to the supporters.
    @discardableResult
    public func respondToFans(_ choice: OwnerDecisionChoice) -> String {
        guard pendingOwnerDecision != nil, let club = userClub else { return "" }
        pendingOwnerDecision = nil
        switch choice {
        case .backPublicly:
            owner.managerSatisfaction = min(100, owner.managerSatisfaction + 15)
            adjustFans(-4, reason: "Owner backed the manager")
            return "\(club.manager) thanks you for your support. Some fans are unimpressed."
        case .ultimatum:
            owner.managerSatisfaction = max(0, owner.managerSatisfaction - managerMoodChange(12))
            adjustFans(6, reason: "Owner demanded results")
            return "The fans welcome your stance. \(club.manager) knows the next few games are crucial."
        case .stayQuiet:
            adjustFans(-2, reason: "Owner silent on the manager")
            return "Your silence is noted. The pressure has not gone away."
        }
    }
}

// MARK: - Owner insight

/// A facility compared with the rest of the division.
public struct FacilityComparison: Identifiable {
    public var id: String { name }
    public let name: String
    public let level: String
    public let rank: Int
    public let of: Int
}

/// A typical week's money in and out, and where the season is heading.
public struct WeeklyCashFlow {
    public let broadcasting: Int
    public let commercial: Int
    public let matchday: Int
    public let wages: Int
    public let running: Int
    public let loanRepayments: Int
    public var income: Int { broadcasting + commercial + matchday }
    public var costs: Int { wages + running + loanRepayments }
    public var net: Int { income - costs }
    public let weeksLeft: Int
    public let projectedBalance: Int
    public let advice: String
}

extension GameState {

    /// How the user's facilities rank among the clubs in their division.
    public var facilityComparison: [FacilityComparison] {
        guard let club = userClub,
              let league = leagues.first(where: { $0.clubIds.contains(club.id) }) else { return [] }
        let rivals = league.clubIds.compactMap { self.club(withId: $0) }
        func rank(_ value: (Club) -> Int) -> Int {
            1 + rivals.filter { value($0) > value(club) }.count
        }
        return [
            FacilityComparison(name: "Training ground", level: "Level \(club.trainingFacilityLevel)", rank: rank { $0.trainingFacilityLevel }, of: rivals.count),
            FacilityComparison(name: "Youth academy", level: "Level \(club.youthAcademyLevel)", rank: rank { $0.youthAcademyLevel }, of: rivals.count),
            FacilityComparison(name: "Medical department", level: "Level \(club.medicalFacilityLevel)", rank: rank { $0.medicalFacilityLevel }, of: rivals.count),
            FacilityComparison(name: "Stadium", level: "\(club.stadiumCapacity.formatted()) seats", rank: rank { $0.stadiumCapacity }, of: rivals.count),
            FacilityComparison(name: "Wage bill", level: "\(Player.formatCurrency(club.totalWeeklyWageBill))/w", rank: rank { $0.totalWeeklyWageBill }, of: rivals.count)
        ]
    }

    /// A typical week of the club's finances with a season forecast.
    public var weeklyCashFlow: WeeklyCashFlow? {
        guard let club = userClub else { return nil }
        let f = club.finances
        let homeGamesPerWeek = 0.5
        let matchday = Int(Double(f.matchdayIncome) * homeGamesPerWeek
                           * (gameMode == .createClub ? owner.ticketPricing.revenueMultiplier : 1))
        let repayments = gameMode == .createClub ? owner.loans.reduce(0) { $0 + min($1.remaining, $1.weeklyRepayment) } : 0
        let remaining = max(0, season.totalMatchWeeks - season.currentWeek + 1)
        let flow = WeeklyCashFlow(
            broadcasting: f.weeklyTvShare,
            commercial: f.weeklySponsorshipShare + f.weeklyMerchandiseShare,
            matchday: matchday,
            wages: f.currentWageBill,
            running: f.weeklyOperatingCosts,
            loanRepayments: repayments,
            weeksLeft: remaining,
            projectedBalance: 0,
            advice: ""
        )
        let projected = f.balance + flow.net * remaining
        let wageShare = Double(f.currentWageBill) / Double(max(1, flow.income))
        let advice: String
        if flow.net < 0 && projected < 0 {
            advice = "You are losing \(Player.formatCurrency(-flow.net)) a week and will run out of cash this season. Cut the wage bill, sell a player or raise funds now."
        } else if flow.net < 0 {
            advice = "You are losing \(Player.formatCurrency(-flow.net)) a week. The bank balance covers it this season, but it cannot continue."
        } else if wageShare > 0.7 {
            advice = "Wages take \(Int(wageShare * 100))% of income. Profitable for now, but there is little room for new signings."
        } else {
            advice = "The club makes \(Player.formatCurrency(flow.net)) a week. There is room to invest in the squad or facilities."
        }
        return WeeklyCashFlow(broadcasting: flow.broadcasting, commercial: flow.commercial, matchday: flow.matchday,
                              wages: flow.wages, running: flow.running, loanRepayments: flow.loanRepayments,
                              weeksLeft: remaining, projectedBalance: projected, advice: advice)
    }

    /// Renames the stadium (not while a sponsor holds the naming rights).
    @discardableResult
    public func renameStadium(_ name: String) -> Bool {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed.count <= 40, owner.namingRightsValue == nil,
              let idx = clubs.firstIndex(where: { $0.isUserClub }) else { return false }
        clubs[idx].stadium = trimmed
        return true
    }

    /// Changes the club's colours.
    public func setClubColours(primary: String, secondary: String) {
        guard let idx = clubs.firstIndex(where: { $0.isUserClub }) else { return }
        clubs[idx].primaryColor = primary
        clubs[idx].secondaryColor = secondary
    }
}

// MARK: - Getting started

/// A short tip for new players, shown one at a time until dismissed.
public struct GameTip: Identifiable, Hashable {
    public let id: String
    public let title: String
    public let body: String
    public let icon: String

    static let manager: [GameTip] = [
        GameTip(id: "m_continue", title: "Moving through the season", body: "Continue runs the calendar day by day to your next match. It stops when important mail arrives, such as a bid or a board message.", icon: "calendar"),
        GameTip(id: "m_squad", title: "Picking your side", body: "In the Squad tab, tap a player and then another to swap them. Starters can swap positions, and anyone on the bench or in the reserves can come in.", icon: "person.3.fill"),
        GameTip(id: "m_matchday", title: "Match day", body: "Check the scouting report and odds, change the lineup for this match only if you need to, then play it live or take an instant result.", icon: "sportscourt.fill"),
        GameTip(id: "m_transfers", title: "Transfers and loans", body: "Search the market from the Transfers tab. Bid, borrow players with an option to buy, star players to shortlist them, and list your own players for sale or loan.", icon: "arrow.left.arrow.right"),
        GameTip(id: "m_board", title: "Keeping the board happy", body: "Your board target is on the dashboard. Meet it to earn bigger budgets; fall well short and your job is at risk.", icon: "building.columns.fill")
    ]

    static let owner: [GameTip] = [
        GameTip(id: "o_week", title: "Running the club", body: "Advance One Week moves the club forward. Your manager picks the team; you decide money, people and facilities.", icon: "calendar.badge.clock"),
        GameTip(id: "o_manager", title: "Hiring a manager", body: "Appoint a manager from the People tab on a contract of one to four years. Personality matters: ambitious managers attract offers from bigger clubs.", icon: "person.badge.key.fill"),
        GameTip(id: "o_money", title: "Watching the money", body: "The Business tab shows a typical week's income and costs and where the season is heading. Ten weeks overdrawn means administration.", icon: "banknote.fill"),
        GameTip(id: "o_fans", title: "The supporters", body: "The Boardroom shows the fans' mood and why. Ticket prices, results, selling stars and backing the manager all move it.", icon: "megaphone.fill"),
        GameTip(id: "o_facilities", title: "Building for the future", body: "Facilities are ranked against your division. A better training ground develops young players; a better academy produces more of them.", icon: "hammer.fill")
    ]
}

extension GameState {
    /// The next tip the player has not dismissed, for the current mode.
    public var nextTip: GameTip? {
        let tips = gameMode == .createClub ? GameTip.owner : GameTip.manager
        return tips.first { !dismissedTips.contains($0.id) }
    }

    public func dismissTip(_ id: String) {
        if !dismissedTips.contains(id) { dismissedTips.append(id) }
    }

    public func dismissAllTips() {
        dismissedTips = (GameTip.manager + GameTip.owner).map { $0.id }
    }
}
