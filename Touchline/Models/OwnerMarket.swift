//
//  OwnerMarket.swift
//  Touchline
//
//  The owner's dealings with the outside world: sponsors that approach the
//  club (rather than being signed on demand), takeover bids at the start of
//  a season, and buying another club with the proceeds of a sale.
//

import Foundation

// MARK: - Sponsor offers

/// A sponsor's proposal, waiting for the owner's answer.
public struct SponsorOffer: Codable, Hashable, Identifiable {
    public var id: UUID
    public var sponsorName: String
    public var tier: SponsorshipTier
    public var annualValue: Int
    public var years: Int
    /// The matchweek after which the sponsor walks away.
    public var expiresWeek: Int

    public init(id: UUID = UUID(), sponsorName: String, tier: SponsorshipTier, annualValue: Int, years: Int, expiresWeek: Int) {
        self.id = id
        self.sponsorName = sponsorName
        self.tier = tier
        self.annualValue = annualValue
        self.years = years
        self.expiresWeek = expiresWeek
    }
}

extension SponsorshipTier {
    /// Whether a partner of this size would talk to a club at this level.
    /// A fourth-tier club does not get a global brand on its shirt.
    public func isAvailable(level: Int, reputation: Int) -> Bool {
        switch self {
        case .local: return true
        case .regional: return level <= 3 || reputation >= 30
        case .national: return level == 1 || (level == 2 && reputation >= 45)
        case .global: return level == 1 && reputation >= 72
        }
    }

    /// Share of the division's typical shirt deal.
    var marketShare: Double {
        switch self {
        case .local: return 0.12
        case .regional: return 0.35
        case .national: return 1.0
        case .global: return 2.6
        }
    }

    var brands: [String] {
        switch self {
        case .local: return ["Town Motors", "Riverside Bakery", "Hillside Builders", "Parkway Dental", "Corner Print Co.",
                             "Station Garage", "Market Street Cafe", "Oakfield Plumbing", "Bridge Carpets", "Fairway Taxis"]
        case .regional: return ["County Energy", "Northern Rail Tours", "Valley Brewery", "Shire Insurance", "Coastline Homes",
                                "Midland Logistics", "Highland Water", "Westway Cars"]
        case .national: return ["Sterling Bank", "Apex Energy", "Halcyon Telecom", "Crown Logistics", "Vantage Motors",
                                "Bluewater Holidays", "Atlas Insurance"]
        case .global: return ["Meridian Airways", "Pioneer Electronics", "Orbit Payments", "Nimbus Cloud", "Zenith Sportswear"]
        }
    }
}

public enum SponsorMarket {
    /// A typical main shirt deal per year, by division level.
    public static func divisionScale(level: Int) -> Int {
        switch level {
        case 1: return 12_000_000
        case 2: return 2_500_000
        case 3: return 900_000
        case 4: return 400_000
        default: return 150_000
        }
    }

    public static func value(tier: SponsorshipTier, level: Int, reputation: Int) -> Int {
        let reputationFactor = 0.6 + Double(max(0, min(100, reputation))) / 125.0
        let raw = Double(divisionScale(level: level)) * tier.marketShare * reputationFactor * Double.random(in: 0.85...1.15)
        return max(5_000, Int(raw / 5_000) * 5_000)
    }

    /// What the agency charges to go looking for a partner.
    public static func agencyFee(level: Int) -> Int {
        max(5_000, divisionScale(level: level) / 50)
    }
}

// MARK: - Buying a club

/// A club the owner could buy, and what it would cost.
public struct ClubForSale: Identifiable, Hashable {
    public var id: UUID { clubId }
    public let clubId: UUID
    public let name: String
    public let division: String
    public let reputation: Int
    public let price: Int
}

extension GameState {

    // MARK: Sponsors

    /// The tiers of partner currently willing to talk to the owner's club.
    public var availableSponsorTiers: [SponsorshipTier] {
        guard let club = userClub else { return [] }
        return SponsorshipTier.allCases.filter { $0.isAvailable(level: club.leagueTier.level, reputation: club.reputation) }
    }

    public var sponsorSlotsFree: Int { max(0, 3 - owner.sponsorshipDeals.count) }

    /// Builds one offer pitched at the club's level. Smaller partners are far
    /// more common than big ones.
    func makeSponsorOffer() -> SponsorOffer? {
        guard let club = userClub else { return nil }
        let tiers = availableSponsorTiers
        guard !tiers.isEmpty else { return nil }
        let weights: [SponsorshipTier: Double] = [.local: 6, .regional: 3, .national: 1.5, .global: 0.6]
        let total = tiers.reduce(0.0) { $0 + (weights[$1] ?? 1) }
        var roll = Double.random(in: 0..<total)
        var tier = tiers[0]
        for candidate in tiers {
            roll -= weights[candidate] ?? 1
            if roll < 0 { tier = candidate; break }
        }
        let taken = Set(owner.sponsorshipDeals.map { $0.sponsorName } + pendingSponsorOffers.map { $0.sponsorName })
        let name = tier.brands.filter { !taken.contains($0) }.randomElement() ?? tier.brands[0]
        let value = SponsorMarket.value(tier: tier, level: club.leagueTier.level, reputation: club.reputation)
        return SponsorOffer(sponsorName: name, tier: tier, annualValue: value,
                            years: Int.random(in: 1...3), expiresWeek: season.currentWeek + 4)
    }

    /// Adds an offer to the table and tells the owner about it.
    func receiveSponsorOffer() {
        guard sponsorSlotsFree > 0, pendingSponsorOffers.count < 2, let offer = makeSponsorOffer() else { return }
        pendingSponsorOffers.append(offer)
        addNews(headline: "Sponsorship Offer: \(offer.sponsorName)",
                body: "\(offer.sponsorName) (\(offer.tier.rawValue.lowercased())) would pay \(Player.formatCurrency(offer.annualValue)) a year for \(offer.years) season\(offer.years == 1 ? "" : "s"). The offer stands for four weeks. Answer it under Commercial.",
                category: .board, sender: "Commercial Director")
    }

    /// Weekly: offers lapse, and now and then a new partner calls.
    func processSponsorMarketWeek() {
        guard gameMode == .createClub, let club = userClub else { return }
        let lapsed = pendingSponsorOffers.filter { $0.expiresWeek < season.currentWeek }
        pendingSponsorOffers.removeAll { $0.expiresWeek < season.currentWeek }
        for offer in lapsed {
            addNews(headline: "\(offer.sponsorName) Walks Away",
                    body: "With no answer from the club, \(offer.sponsorName) has taken its money elsewhere.",
                    category: .board, sender: "Commercial Director")
        }
        if sponsorAgencyCooldown > 0 { sponsorAgencyCooldown -= 1 }
        let chance = 0.04 + Double(club.reputation) / 1_500.0
        if Double.random(in: 0..<1) < chance { receiveSponsorOffer() }
    }

    @discardableResult
    public func acceptSponsorOffer(_ id: UUID) -> String {
        guard let idx = pendingSponsorOffers.firstIndex(where: { $0.id == id }),
              let clubIdx = clubs.firstIndex(where: { $0.isUserClub }) else { return "That offer is no longer available." }
        guard sponsorSlotsFree > 0 else { return "You already have three commercial partners." }
        let offer = pendingSponsorOffers.remove(at: idx)
        let deal = SponsorshipDeal(sponsorName: offer.sponsorName, tier: offer.tier, annualValue: offer.annualValue,
                                   yearsRemaining: offer.years, performanceBonus: offer.annualValue / 10)
        owner.sponsorshipDeals.append(deal)
        clubs[clubIdx].finances.sponsorshipIncome += offer.annualValue
        addNews(headline: "New Commercial Partner",
                body: "\(offer.sponsorName) has signed a \(Player.formatCurrency(offer.annualValue)) a year deal for \(offer.years) season\(offer.years == 1 ? "" : "s").",
                category: .board, sender: "Commercial Director")
        try? SaveManager.shared.autoSave(gameState: self)
        return "\(offer.sponsorName) is now a partner of the club."
    }

    public func declineSponsorOffer(_ id: UUID) {
        pendingSponsorOffers.removeAll { $0.id == id }
    }

    /// Pays an agency to find a partner. They do not always find one.
    public func hireSponsorAgency() -> String {
        guard gameMode == .createClub, let clubIdx = clubs.firstIndex(where: { $0.isUserClub }) else { return "" }
        guard sponsorAgencyCooldown == 0 else {
            return "The agency is still working on your last brief. Try again in \(sponsorAgencyCooldown) week\(sponsorAgencyCooldown == 1 ? "" : "s")."
        }
        guard sponsorSlotsFree > 0 else { return "You already have three commercial partners." }
        let fee = SponsorMarket.agencyFee(level: clubs[clubIdx].leagueTier.level)
        guard clubs[clubIdx].finances.balance >= fee else { return "The agency wants \(Player.formatCurrency(fee)) up front." }
        clubs[clubIdx].finances.balance -= fee
        sponsorAgencyCooldown = 4
        let chance = 0.45 + Double(clubs[clubIdx].reputation) / 250.0
        let before = pendingSponsorOffers.count
        if Double.random(in: 0..<1) < chance { receiveSponsorOffer() }
        try? SaveManager.shared.autoSave(gameState: self)
        return pendingSponsorOffers.count > before
            ? "The agency found an interested partner. Their offer is waiting."
            : "The agency could not find anyone interested this month."
    }

    // MARK: Season start

    /// Owner business at the start of a season: sponsors call, and a buyer
    /// may bid for the club.
    func ownerSeasonStartMarket() {
        guard gameMode == .createClub, userClub != nil else { return }
        pendingSponsorOffers.removeAll()
        sponsorAgencyCooldown = 0
        let calls = sponsorSlotsFree > 0 ? Int.random(in: 0...2) : 0
        for _ in 0..<calls { receiveSponsorOffer() }

        guard pendingTakeover == nil, !owner.isInAdministration else { return }
        let start = owner.valuationAtTakeover ?? clubValuation
        let grown = clubValuation > start
        guard Double.random(in: 0..<1) < (grown ? 0.6 : 0.3) else { return }
        let bidders = ["a Gulf investment fund", "an American sports group", "a local consortium",
                       "a private equity firm", "a former player's consortium", "a Far East holding company"]
        let amount = Int(Double(clubValuation) * Double.random(in: 0.95...1.3))
        pendingTakeover = TakeoverOffer(bidder: bidders.randomElement() ?? "a consortium", amount: amount)
        addNews(headline: "Takeover Bid Received",
                body: "\(pendingTakeover?.bidder.capitalized ?? "A consortium") has offered \(Player.formatCurrency(amount)) for the club. If you sell, you can use the money to buy another club. Answer it in the Boardroom.",
                category: .board, sender: "Owner's Office")
    }

    // MARK: Selling and buying

    /// Sells the club. The owner keeps playing: they choose a new club to buy.
    public func sellClubAndShop() {
        guard let offer = pendingTakeover, let club = userClub else { return }
        pendingTakeover = nil
        owner.personalWealth += offer.amount
        awaitingClubPurchase = true
        addNews(headline: "\(club.name) Sold",
                body: "You sold \(club.name) to \(offer.bidder) for \(Player.formatCurrency(offer.amount)). You now have \(Player.formatCurrency(owner.personalWealth)) to buy your next club.",
                category: .board, sender: "Owner's Office")
        try? SaveManager.shared.autoSave(gameState: self)
    }

    /// Clubs the owner can afford, dearest first.
    public var clubsForSale: [ClubForSale] {
        let wealth = owner.personalWealth
        return clubs.compactMap { club -> ClubForSale? in
            guard club.id != userClubId else { return nil }
            let price = OwnerBusiness.valuation(of: club, debt: 0)
            guard price <= wealth else { return nil }
            return ClubForSale(clubId: club.id, name: club.name, division: club.leagueTier.displayName,
                               reputation: club.reputation, price: price)
        }
        .sorted { $0.price > $1.price }
    }

    /// Buys a club. What is left of the owner's money becomes its cash.
    @discardableResult
    public func buyClub(_ clubId: UUID) -> Bool {
        guard let sale = clubsForSale.first(where: { $0.clubId == clubId }),
              let newIdx = clubs.firstIndex(where: { $0.id == clubId }) else { return false }
        let remaining = owner.personalWealth - sale.price
        if let oldIdx = clubs.firstIndex(where: { $0.isUserClub }) {
            clubs[oldIdx].isUserClub = false
            if clubs[oldIdx].manager == "Interim Manager" { clubs[oldIdx].manager = "Caretaker Manager" }
        }
        clubs[newIdx].isUserClub = true
        userClubId = clubId
        clubs[newIdx].finances.balance = remaining
        let transferShare = Double(owner.budgetAllocation.transferBudgetPercent) / 100.0
        clubs[newIdx].finances.transferBudget = max(0, Int(Double(remaining) * transferShare * 0.5))

        owner.personalWealth = 0
        owner.loans = []
        owner.stadiumProject = nil
        owner.namingRightsValue = nil
        owner.sponsorshipDeals = []
        owner.weeksInDebt = 0
        owner.isInAdministration = false
        owner.supporterConfidence = 60
        owner.managerSatisfaction = 60
        owner.fanMoodLog = []
        owner.valuationAtTakeover = sale.price
        owner.managerRating = max(40, min(90, clubs[newIdx].reputation))
        let names = clubs[newIdx].manager.split(separator: " ")
        let personality = ManagerPersonality.allCases.randomElement() ?? .levelHeaded
        owner.managerContract = ManagerContract(
            managerName: names.isEmpty ? "Interim Manager" : clubs[newIdx].manager,
            weeklyWage: max(1_500, Int(pow(1.07, Double(clubs[newIdx].reputation - 40)) * 2_500)),
            yearsRemaining: Int.random(in: 1...3), age: Int.random(in: 38...62),
            personality: personality, style: "Inherited from the previous owner")

        pendingManagerRequest = nil
        pendingOwnerDecision = nil
        pendingWinBonusRequest = false
        pendingSponsorOffers = []
        activeMatchFixtureId = nil
        liveMatch = nil
        seasonLedger = FinanceLedger(startingBalance: remaining)
        awaitingClubPurchase = false
        addNews(headline: "\(owner.name) Buys \(clubs[newIdx].name)",
                body: "The takeover is complete. \(clubs[newIdx].name) of the \(clubs[newIdx].leagueTier.displayName) start life under new ownership with \(Player.formatCurrency(remaining)) in the bank.",
                category: .board, sender: "Owner's Office")
        try? SaveManager.shared.autoSave(gameState: self)
        return true
    }

    // MARK: Match days for the owner

    /// The user's fixture being played today, if any.
    public var todaysUserFixture: Fixture? {
        guard let fixture = nextUserFixture, fixture.date == season.currentDate else { return nil }
        return fixture
    }

    /// Makes today's fixture the active match. Returns false when there is
    /// no match today.
    @discardableResult
    public func selectTodaysUserFixture() -> Bool {
        guard let fixture = todaysUserFixture else { return false }
        season.currentWeek = fixture.matchWeek
        activeMatchFixtureId = fixture.id
        if let session = liveMatch, session.fixtureId != fixture.id { liveMatch = nil }
        return true
    }

    /// After the full-time report: forget the finished match so the next
    /// match day can never reopen it.
    public func closeFinishedMatch() {
        if let fixture = activeMatchFixture, fixture.isPlayed { activeMatchFixtureId = nil }
        if let session = liveMatch,
           season.fixtures.first(where: { $0.id == session.fixtureId })?.isPlayed ?? true {
            liveMatch = nil
        }
    }

    /// "Continue" for either career: moves the calendar to the next match
    /// day (simulating everyone else's games on the way) and stops there,
    /// so the inbox can be read before kick-off.
    public func continueToMatchDay() {
        if gameMode == .createClub { checkWinBonusRequest() }
        _ = advanceCalendar()
        if gameMode == .createClub { checkOwnerWeeklyMilestones() }
        try? SaveManager.shared.autoSave(gameState: self)
    }
}
