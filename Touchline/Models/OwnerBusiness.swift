//
//  OwnerBusiness.swift
//  Touchline
//
//  The business side of owning a club: the season's profit-and-loss ledger,
//  bank loans, the owner's personal wealth, stadium projects, manager
//  requests and the club's market valuation.
//

import Foundation

/// Season-to-date money in and out of the user's club. Anything not recorded
/// in a named line (staff hires, facility upgrades, compensation...) is shown
/// as "other", derived from the change in the bank balance, so the ledger
/// always reconciles with the real balance.
public struct FinanceLedger: Codable, Hashable {
    public var startingBalance: Int
    public var broadcasting = 0
    public var commercial = 0
    public var merchandise = 0
    public var matchday = 0
    public var prizeMoney = 0
    public var playerSales = 0
    public var ownerInvestment = 0
    public var loansReceived = 0
    public var wages = 0
    public var transfers = 0
    public var loanRepayments = 0

    public init(startingBalance: Int) {
        self.startingBalance = startingBalance
    }

    public var recordedIncome: Int {
        broadcasting + commercial + merchandise + matchday + prizeMoney + playerSales + ownerInvestment + loansReceived
    }

    public var recordedExpenses: Int {
        wages + transfers + loanRepayments
    }

    /// Everything else, so that income − expenses always equals the real
    /// change in the bank balance.
    public func other(currentBalance: Int) -> Int {
        (currentBalance - startingBalance) - (recordedIncome - recordedExpenses)
    }

    /// Operating profit: football income against wages, excluding the owner's
    /// money, loans and player trading.
    public var operatingProfit: Int {
        broadcasting + commercial + merchandise + matchday + prizeMoney - wages
    }
}

/// A bank loan taken by the owner on the club's behalf.
public struct ClubLoan: Codable, Hashable, Identifiable {
    public let id: UUID
    public let principal: Int
    public var remaining: Int
    public let weeklyRepayment: Int
    /// Annual interest rate, e.g. 0.08.
    public let rate: Double

    public init(id: UUID = UUID(), principal: Int, rate: Double, termWeeks: Int) {
        self.id = id
        self.principal = principal
        self.rate = rate
        // Simple interest over the term, repaid in equal instalments.
        let total = Int(Double(principal) * (1.0 + rate * Double(termWeeks) / 52.0))
        self.remaining = total
        self.weeklyRepayment = max(1, total / max(1, termWeeks))
    }
}

/// A new-stadium build that takes a year to complete.
public struct StadiumProject: Codable, Hashable {
    public var newCapacity: Int
    public var cost: Int
    public var weeksRemaining: Int
    public let totalWeeks: Int

    public init(newCapacity: Int, cost: Int, weeks: Int) {
        self.newCapacity = newCapacity
        self.cost = cost
        self.weeksRemaining = weeks
        self.totalWeeks = weeks
    }

    public var progress: Double {
        guard totalWeeks > 0 else { return 1 }
        return Double(totalWeeks - weeksRemaining) / Double(totalWeeks)
    }
}

/// The manager asking the owner to fund a signing above his delegated limit.
public struct ManagerRequest: Codable, Hashable {
    public let playerId: UUID
    public let playerName: String
    public let position: String
    public let rating: Int
    public let sellerClubId: UUID
    public let sellerName: String
    public let fee: Int
    public let wage: Int
    /// The request lapses when the transfer window closes.
    public let createdDate: String
}

/// A consortium's offer to buy the club.
public struct TakeoverOffer: Codable, Hashable {
    public let bidder: String
    public let amount: Int
}

public enum OwnerBusiness {
    /// Personal fortune an owner starts with, by vision.
    public static func startingWealth(for vision: ClubVision) -> Int {
        switch vision {
        case .sustainable: return 25_000_000
        case .youthFirst: return 18_000_000
        case .ambitious: return 80_000_000
        }
    }

    public static let namingRightsBrands = ["Northgate", "Apex Energy", "Sterling Bank", "Meridian", "Halcyon Telecom",
                                           "Crown Logistics", "Vantage Motors", "Bluewater", "Atlas Insurance", "Pioneer"]

    /// Annual value of a stadium naming-rights deal.
    public static func namingRightsValue(capacity: Int, reputation: Int) -> Int {
        max(150_000, Int(Double(capacity) * Double(max(20, reputation)) * 1.5))
    }

    /// Approximate annual turnover of a club, from its revenue lines.
    public static func annualRevenue(_ finances: ClubFinances) -> Int {
        finances.tvIncome + finances.sponsorshipIncome + finances.merchandiseIncome + finances.matchdayIncome * 19
    }

    /// Market valuation: a revenue multiple by division, plus squad and
    /// stadium value and net cash, less debt.
    public static func valuation(of club: Club, debt: Int) -> Int {
        let multiple: Double
        switch club.leagueTier.level {
        case 1: multiple = 2.5
        case 2: multiple = 1.6
        default: multiple = 1.2
        }
        let revenue = Double(annualRevenue(club.finances)) * multiple
        let squad = Double(club.players.reduce(0) { $0 + $1.value }) * 0.35
        let stadium = Double(club.stadiumCapacity) * 1_200
        let value = revenue + squad + stadium + Double(club.finances.balance) - Double(debt)
        return max(1_000_000, Int(value))
    }
}
