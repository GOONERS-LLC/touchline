//
//  Ownership.swift
//  Touchline
//
//  The owner career is intentionally separate from the manager career. Owners
//  make long-term football and business decisions; managers run the matches.
//

import Foundation

public enum ClubVision: String, Codable, CaseIterable, Identifiable, Hashable {
    case sustainable = "Sustainable Builder"
    case youthFirst = "Youth First"
    case ambitious = "Ambitious Challenger"

    public var id: String { rawValue }

    public var summary: String {
        switch self {
        case .sustainable: return "Protect the club's future with sensible wages and steady growth."
        case .youthFirst: return "Build a pathway from academy to first team."
        case .ambitious: return "Back the manager and chase rapid promotion."
        }
    }
}

public struct OwnerMilestone: Codable, Hashable, Identifiable {
    public let id: String
    public let title: String
    public let detail: String
    public let bonusPoints: Int
    public var isUnlocked: Bool

    public init(id: String, title: String, detail: String, bonusPoints: Int, isUnlocked: Bool = false) {
        self.id = id
        self.title = title
        self.detail = detail
        self.bonusPoints = bonusPoints
        self.isUnlocked = isUnlocked
    }

    public static let standard: [OwnerMilestone] = [
        OwnerMilestone(id: "first_win", title: "First Victory", detail: "Win your first competitive match under your ownership", bonusPoints: 4),
        OwnerMilestone(id: "clean_sheet", title: "Clean Sheet", detail: "Record a shutout in any league fixture", bonusPoints: 3),
        OwnerMilestone(id: "commercial_partner", title: "Commercial Partner", detail: "Sign your first official club sponsorship deal", bonusPoints: 5),
        OwnerMilestone(id: "reserves", title: "Solid Reserves", detail: "Build club cash reserves to over £2,500,000", bonusPoints: 6),
        OwnerMilestone(id: "five_unbeaten", title: "5 Unbeaten", detail: "Go five consecutive league matches without defeat", bonusPoints: 8),
        OwnerMilestone(id: "promotion", title: "Ascent", detail: "Earn promotion to a higher tier of English football", bonusPoints: 15),
        OwnerMilestone(id: "cup_winner", title: "Silverware", detail: "Win the FA Cup", bonusPoints: 20)
    ]
}

public struct OwnerProfile: Codable, Hashable {
    public var name: String
    public var vision: ClubVision
    /// 0–100 supporter confidence. It reacts to appointments and investment.
    public var supporterConfidence: Int
    public var legacyPoints: Int
    public var budgetAllocation: BudgetAllocation
    public var sponsorshipDeals: [SponsorshipDeal]
    public var milestones: [OwnerMilestone]
    /// Coaching quality of the appointed first-team manager (an interim is
    /// weaker). It nudges match performance and the quality of signings.
    public var managerRating: Int
    /// Matchday pricing policy: revenue against goodwill.
    public var ticketPricing: TicketPricing
    /// The owner's own fortune, which can be invested in the club.
    public var personalWealth: Int
    /// Total the owner has put into the club.
    public var totalInvested: Int
    public var loans: [ClubLoan]
    public var stadiumProject: StadiumProject?
    /// Annual value of a stadium naming-rights deal, once signed.
    public var namingRightsValue: Int?
    /// 0-100: how happy the manager is with the owner's backing.
    public var managerSatisfaction: Int
    /// Share of the transfer budget the manager may spend on one signing
    /// without asking the owner.
    public var delegatedSpendPercent: Int
    /// The kind of player the owner wants the manager to recruit.
    public var recruitmentPolicy: RecruitmentPolicy
    /// The appointed manager's contract (nil for an interim manager).
    public var managerContract: ManagerContract?
    /// Recent reasons the supporters' mood moved, newest last.
    public var fanMoodLog: [FanMoodEntry]
    /// Consecutive weeks the club has been overdrawn.
    public var weeksInDebt: Int
    public var isInAdministration: Bool
    /// Club valuation when the owner took over.
    public var valuationAtTakeover: Int?
    /// One record per completed season of the owner's tenure.
    public var seasonHistory: [ManagerSeasonRecord]
    /// What the owner expects of the manager this season; judged at the final whistle.
    public var seasonObjective: SeasonObjective
    /// Total taken out of the club as dividends.
    public var dividendsTaken: Int

    public var totalDebt: Int { loans.reduce(0) { $0 + $1.remaining } }

    public init(
        name: String = "Club Owner",
        vision: ClubVision = .sustainable,
        supporterConfidence: Int = 62,
        legacyPoints: Int = 0,
        budgetAllocation: BudgetAllocation = BudgetAllocation(),
        sponsorshipDeals: [SponsorshipDeal] = [],
        milestones: [OwnerMilestone] = OwnerMilestone.standard,
        managerRating: Int = 45,
        ticketPricing: TicketPricing = .standard,
        personalWealth: Int? = nil
    ) {
        self.name = name
        self.vision = vision
        self.supporterConfidence = max(0, min(100, supporterConfidence))
        self.legacyPoints = max(0, legacyPoints)
        self.budgetAllocation = budgetAllocation
        self.sponsorshipDeals = sponsorshipDeals
        self.milestones = milestones.isEmpty ? OwnerMilestone.standard : milestones
        self.managerRating = max(30, min(95, managerRating))
        self.ticketPricing = ticketPricing
        self.personalWealth = personalWealth ?? OwnerBusiness.startingWealth(for: vision)
        self.totalInvested = 0
        self.loans = []
        self.stadiumProject = nil
        self.namingRightsValue = nil
        self.managerSatisfaction = 60
        self.delegatedSpendPercent = 25
        self.recruitmentPolicy = .balanced
        self.managerContract = nil
        self.fanMoodLog = []
        self.weeksInDebt = 0
        self.isInAdministration = false
        self.valuationAtTakeover = nil
        self.seasonHistory = []
        self.seasonObjective = .topHalf
        self.dividendsTaken = 0
    }

    private enum CodingKeys: String, CodingKey {
        case name, vision, supporterConfidence, legacyPoints, budgetAllocation, sponsorshipDeals, milestones
        case managerRating, ticketPricing
        case personalWealth, totalInvested, loans, stadiumProject, namingRightsValue
        case managerSatisfaction, delegatedSpendPercent, recruitmentPolicy, managerContract, fanMoodLog, weeksInDebt, isInAdministration, valuationAtTakeover
        case seasonHistory, seasonObjective, dividendsTaken
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.name = try container.decodeIfPresent(String.self, forKey: .name) ?? "Club Owner"
        self.vision = try container.decodeIfPresent(ClubVision.self, forKey: .vision) ?? .sustainable
        self.supporterConfidence = try container.decodeIfPresent(Int.self, forKey: .supporterConfidence) ?? 62
        self.legacyPoints = try container.decodeIfPresent(Int.self, forKey: .legacyPoints) ?? 0
        self.budgetAllocation = try container.decodeIfPresent(BudgetAllocation.self, forKey: .budgetAllocation) ?? BudgetAllocation()
        self.sponsorshipDeals = try container.decodeIfPresent([SponsorshipDeal].self, forKey: .sponsorshipDeals) ?? []
        self.milestones = try container.decodeIfPresent([OwnerMilestone].self, forKey: .milestones) ?? OwnerMilestone.standard
        self.managerRating = try container.decodeIfPresent(Int.self, forKey: .managerRating) ?? 55
        self.ticketPricing = try container.decodeIfPresent(TicketPricing.self, forKey: .ticketPricing) ?? .standard
        self.personalWealth = try container.decodeIfPresent(Int.self, forKey: .personalWealth) ?? OwnerBusiness.startingWealth(for: vision)
        self.totalInvested = try container.decodeIfPresent(Int.self, forKey: .totalInvested) ?? 0
        self.loans = try container.decodeIfPresent([ClubLoan].self, forKey: .loans) ?? []
        self.stadiumProject = try container.decodeIfPresent(StadiumProject.self, forKey: .stadiumProject)
        self.namingRightsValue = try container.decodeIfPresent(Int.self, forKey: .namingRightsValue)
        self.managerSatisfaction = try container.decodeIfPresent(Int.self, forKey: .managerSatisfaction) ?? 60
        self.delegatedSpendPercent = try container.decodeIfPresent(Int.self, forKey: .delegatedSpendPercent) ?? 25
        self.recruitmentPolicy = try container.decodeIfPresent(RecruitmentPolicy.self, forKey: .recruitmentPolicy) ?? .balanced
        self.managerContract = try container.decodeIfPresent(ManagerContract.self, forKey: .managerContract)
        self.fanMoodLog = try container.decodeIfPresent([FanMoodEntry].self, forKey: .fanMoodLog) ?? []
        self.weeksInDebt = try container.decodeIfPresent(Int.self, forKey: .weeksInDebt) ?? 0
        self.isInAdministration = try container.decodeIfPresent(Bool.self, forKey: .isInAdministration) ?? false
        self.valuationAtTakeover = try container.decodeIfPresent(Int.self, forKey: .valuationAtTakeover)
        self.seasonHistory = try container.decodeIfPresent([ManagerSeasonRecord].self, forKey: .seasonHistory) ?? []
        self.seasonObjective = try container.decodeIfPresent(SeasonObjective.self, forKey: .seasonObjective) ?? .topHalf
        self.dividendsTaken = try container.decodeIfPresent(Int.self, forKey: .dividendsTaken) ?? 0
    }
}

/// Matchday ticket pricing set by the owner.
/// The owner's brief to the manager on who to sign.
public enum RecruitmentPolicy: String, Codable, CaseIterable, Identifiable, Hashable {
    case winNow = "Win Now"
    case balanced = "Balanced"
    case youth = "Youth"

    public var id: String { rawValue }

    /// The oldest player the manager will sign.
    public var maximumAge: Int {
        switch self {
        case .winNow: return 32
        case .balanced: return 29
        case .youth: return 23
        }
    }

    /// How much better than the current starter a signing must be.
    public var requiredUpgrade: Int {
        switch self {
        case .winNow: return 2
        case .balanced: return 3
        case .youth: return 0
        }
    }

    public var summary: String {
        switch self {
        case .winNow: return "Proven players for immediate impact. Costly, and their value falls with age."
        case .balanced: return "Players in their prime who improve the side now and hold their value."
        case .youth: return "Young players with high potential: cheaper wages, rising value, slower results."
        }
    }
}

public enum TicketPricing: String, Codable, CaseIterable, Identifiable, Hashable {
    case affordable = "Affordable"
    case standard = "Standard"
    case premium = "Premium"

    public var id: String { rawValue }

    /// Multiplier on gate receipts.
    public var revenueMultiplier: Double {
        switch self {
        case .affordable: return 0.8
        case .standard: return 1.0
        case .premium: return 1.25
        }
    }

    /// Supporter confidence change after each home match.
    public var confidenceDrift: Int {
        switch self {
        case .affordable: return 1
        case .standard: return 0
        case .premium: return -1
        }
    }

    public var summary: String {
        switch self {
        case .affordable: return "Lower gate income, but supporters warm to the club."
        case .standard: return "Market-rate prices with no effect on goodwill."
        case .premium: return "Higher gate income, but supporters grow restless."
        }
    }
}

/// One-off board interventions funded by legacy points. They give an owner a
/// concrete way to steer the club without taking over the manager's role.
public enum OwnerInvestment: String, CaseIterable, Identifiable, Hashable {
    case recruitment
    case facilities
    case community

    public var id: String { rawValue }
    public var title: String {
        switch self {
        case .recruitment: return "Recruitment Injection"
        case .facilities: return "Infrastructure Grant"
        case .community: return "Supporter Initiative"
        }
    }
    public var cost: Int {
        switch self {
        case .recruitment: return 8
        case .facilities: return 6
        case .community: return 4
        }
    }
    public var detail: String {
        switch self {
        case .recruitment: return "Adds £650K to the transfer allocation for your manager."
        case .facilities: return "Adds £450K club cash for medical or stadium projects."
        case .community: return "Builds supporter confidence and raises the club profile."
        }
    }
}

public enum TrainingFocus: String, CaseIterable, Identifiable, Hashable {
    case balanced
    case fitness
    case sharpness
    case morale

    public var id: String { rawValue }
    public var title: String { rawValue.capitalized }
    public var icon: String {
        switch self {
        case .balanced: return "equal.circle.fill"
        case .fitness: return "figure.run"
        case .sharpness: return "scope"
        case .morale: return "person.2.fill"
        }
    }
    public var detail: String {
        switch self {
        case .balanced: return "A small fitness and sharpness lift across the squad."
        case .fitness: return "Prioritise recovery for a fresher matchday squad."
        case .sharpness: return "Sharpen execution, with a small fitness trade-off."
        case .morale: return "Build belief and cohesion across the healthy squad."
        }
    }
}

/// How a manager behaves in the job.
public enum ManagerPersonality: String, Codable, CaseIterable, Hashable {
    case ambitious = "Ambitious"
    case loyal = "Loyal"
    case demanding = "Demanding"
    case levelHeaded = "Level-headed"

    /// Multiplier on the chance a bigger club poaches him after a good season.
    public var poachingRisk: Double {
        switch self {
        case .ambitious: return 1.7
        case .loyal: return 0.35
        case .demanding: return 1.0
        case .levelHeaded: return 0.8
        }
    }

    /// The satisfaction level at which he walks out.
    public var resignationThreshold: Int {
        switch self {
        case .loyal: return 8
        case .demanding: return 22
        default: return 15
        }
    }

    /// Multiplier on how much the owner's decisions move his satisfaction.
    public var sensitivity: Double {
        switch self {
        case .demanding: return 1.5
        case .levelHeaded: return 0.7
        default: return 1.0
        }
    }

    public var summary: String {
        switch self {
        case .ambitious: return "Wants to reach the top. Bigger clubs will come calling after a good season."
        case .loyal: return "Rarely tempted away and patient with the board."
        case .demanding: return "Expects backing; refusals hit his mood hard."
        case .levelHeaded: return "Steady, whatever happens."
        }
    }
}

/// One change in the supporters' mood and why it happened.
public struct FanMoodEntry: Codable, Hashable, Identifiable {
    public var id = UUID()
    public var date: String
    public var reason: String
    public var change: Int
}

/// The appointed manager's contract.
public struct ManagerContract: Codable, Hashable {
    public var managerName: String
    public var weeklyWage: Int
    public var yearsRemaining: Int
    public var age: Int
    public var personality: ManagerPersonality
    public var style: String

    /// Paid when the owner sacks him: half the wages left on the deal.
    public var severance: Int { max(100_000, weeklyWage * 52 * max(1, yearsRemaining) / 2) }
    /// Paid by a club that poaches him: his remaining wages in full.
    public var releaseFee: Int { max(200_000, weeklyWage * 52 * max(1, yearsRemaining)) }
}

public struct ManagerCandidate: Identifiable, Hashable {
    public var id: String { name }
    public let name: String
    public let style: String
    public let reputation: Int
    public let wage: Int
    public let compensation: Int
    public let age: Int
    public let personality: ManagerPersonality

    public init(name: String, style: String, reputation: Int, wage: Int, compensation: Int,
                age: Int = 48, personality: ManagerPersonality = .levelHeaded) {
        self.name = name
        self.style = style
        self.reputation = reputation
        self.wage = wage
        self.compensation = compensation
        self.age = age
        self.personality = personality
    }

    /// A shortlist pitched at the club's level, refreshed every season.
    /// Deterministic per club and season, so it does not reshuffle on screen.
    public static func shortlist(clubReputation: Int, country: LeagueCountry, seed: UInt64) -> [ManagerCandidate] {
        var rng = SeededGenerator(seed: seed)
        let styles = ["Possession & youth development", "High press & man management", "Defensive structure & set pieces",
                      "Attacking football & recruitment", "Counter-attacking & discipline", "Data-led & tactical flexibility"]
        return (0..<4).map { index in
            let pool = index == 0 ? NamePools.pool(for: country)
                : [NamePools.england, NamePools.spain, NamePools.italy, NamePools.germany, NamePools.france, NamePools.portugal][Int(rng.next() % 6)]
            let first = pool.firstNames[Int(rng.next() % UInt64(pool.firstNames.count))]
            let last = pool.lastNames[Int(rng.next() % UInt64(pool.lastNames.count))]
            // Spread from a cheap gamble to an ambitious, expensive name.
            let reputation = max(35, min(92, clubReputation - 8 + index * 7 + Int(rng.next() % 5)))
            let wage = max(2_000, Int(pow(1.07, Double(reputation - 40)) * 2_500))
            let style = styles[Int(rng.next() % UInt64(styles.count))]
            let age = 36 + Int(rng.next() % 28)
            let personality = ManagerPersonality.allCases[Int(rng.next() % UInt64(ManagerPersonality.allCases.count))]
            return ManagerCandidate(
                name: "\(first) \(last)",
                style: style,
                reputation: reputation,
                wage: wage,
                compensation: wage * 100,
                age: age,
                personality: personality
            )
        }
        .sorted { $0.reputation < $1.reputation }
    }

    public static let shortlist: [ManagerCandidate] = [
        ManagerCandidate(name: "Maya Brooks", style: "Possession & youth development", reputation: 58, wage: 7_500, compensation: 850_000),
        ManagerCandidate(name: "Daniel Okafor", style: "High press & man management", reputation: 64, wage: 9_500, compensation: 1_200_000),
        ManagerCandidate(name: "Elena Rossi", style: "Defensive structure & set pieces", reputation: 61, wage: 8_500, compensation: 1_000_000),
        ManagerCandidate(name: "Tomás Silva", style: "Attacking football & recruitment", reputation: 69, wage: 12_000, compensation: 1_800_000)
    ]
}

/// Small deterministic random generator (SplitMix64) for stable shortlists.
public struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64
    public init(seed: UInt64) { state = seed &+ 0x9E3779B97F4A7C15 }
    public mutating func next() -> UInt64 {
        state = state &+ 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}

/// The finish an owner expects from the manager this season.
public enum SeasonObjective: String, Codable, CaseIterable, Identifiable, Hashable {
    case avoidRelegation = "Avoid relegation"
    case midTable = "Mid-table"
    case topHalf = "Top half"
    case promotionOrTopSix = "Promotion / top six"
    case title = "Win the league"

    public var id: String { rawValue }

    /// The lowest league position that meets the target in a division of `teams` clubs.
    public func lowestAcceptablePosition(teams: Int) -> Int {
        switch self {
        case .avoidRelegation: return max(1, teams - 3)
        case .midTable: return max(1, Int((Double(teams) * 0.65).rounded()))
        case .topHalf: return max(1, teams / 2)
        case .promotionOrTopSix: return 6
        case .title: return 1
        }
    }

    public var summary: String {
        switch self {
        case .avoidRelegation: return "Survival is enough. Little pressure, little reward."
        case .midTable: return "A comfortable, forgettable season is fine."
        case .topHalf: return "Finish in the top half of the table."
        case .promotionOrTopSix: return "Go up, or at least reach the top six."
        case .title: return "Nothing but the league title will do. The manager feels the heat."
        }
    }

    /// How hard missing the target is felt (and how well meeting it is rewarded).
    public var stakes: Double {
        switch self {
        case .avoidRelegation: return 0.6
        case .midTable: return 0.8
        case .topHalf: return 1.0
        case .promotionOrTopSix: return 1.3
        case .title: return 1.6
        }
    }
}
