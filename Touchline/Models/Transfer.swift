//
//  Transfer.swift
//  Touchline
//
//  Created for Touchline - iOS Football Manager Game.
//  Transfer negotiation offers, personal terms agreements, and completed transaction records.
//

import Foundation

// MARK: - Transfer Offer

public struct TransferOffer: Codable, Identifiable, Hashable {
    public let id: UUID
    public var playerId: UUID
    public var fromClubId: UUID       // The club currently holding the player's contract
    public var toClubId: UUID         // The bidding club
    public var fee: Int               // Transfer fee in GBP
    public var isLoan: Bool
    public var loanWeeks: Int?        // Duration if loan
    public var status: TransferOfferStatus
    public var offeredWage: Int?      // Weekly wage offer for personal terms
    public var contractYears: Int?    // Contract length in years

// MARK: Negotiation state
    /// The selling club's valuation captured when the bid was made, used for counters.
    public var askingPrice: Int
    /// Fee the selling club is willing to accept (their latest counter). nil = none.
    public var counterFee: Int?
    /// Wage the player is demanding (their latest counter). nil = accepts offer.
    public var demandedWage: Int?
    /// Which way the offer flows: true when the user is bidding, false when an AI club bids.
    public var isIncoming: Bool
    /// Number of back-and-forth rounds already exchanged.
    public var negotiationRound: Int
    /// In-game date the offer was made.
    public var createdDate: String
    /// Weeks until the counterparty responds (0 = ready to resolve this week).
    public var weeksUntilResponse: Int
    /// Realistic deal structure: pay a portion now, remainder in installments.
    public var installments: Int        // e.g. 1 = full, 2 = 50/50, 3 = thirds
    /// Years of sell-on percentage (0 if none).
    public var sellOnPercent: Int
    /// Years of sell-on obligation (0 if none).
    public var sellOnYears: Int
    /// Bonus if add-ons triggered (e.g. appearances).
    public var addOnAmount: Int
    /// The weekly wage the player first asked for in personal-terms talks;
    /// his counters come down from it. `demandedWage` is his latest figure.
    public var baseWageDemand: Int? = nil

    public init(
        id: UUID = UUID(),
        playerId: UUID,
        fromClubId: UUID,
        toClubId: UUID,
        fee: Int,
        isLoan: Bool = false,
        loanWeeks: Int? = nil,
        status: TransferOfferStatus = .pending,
        offeredWage: Int? = nil,
        contractYears: Int? = nil,
        askingPrice: Int = 0,
        counterFee: Int? = nil,
        demandedWage: Int? = nil,
        isIncoming: Bool = false,
        negotiationRound: Int = 0,
        createdDate: String = "",
        weeksUntilResponse: Int = 1,
        installments: Int = 1,
        sellOnPercent: Int = 0,
        sellOnYears: Int = 0,
        addOnAmount: Int = 0
    ) {
        self.id = id
        self.playerId = playerId
        self.fromClubId = fromClubId
        self.toClubId = toClubId
        self.fee = fee
        self.isLoan = isLoan
        self.loanWeeks = loanWeeks
        self.status = status
        self.offeredWage = offeredWage
        self.contractYears = contractYears
        self.askingPrice = askingPrice
        self.counterFee = counterFee
        self.demandedWage = demandedWage
        self.isIncoming = isIncoming
        self.negotiationRound = negotiationRound
        self.createdDate = createdDate
        self.weeksUntilResponse = weeksUntilResponse
        self.installments = max(1, installments)
        self.sellOnPercent = max(0, min(50, sellOnPercent))
        self.sellOnYears = max(0, sellOnYears)
        self.addOnAmount = max(0, addOnAmount)
    }

    /// True while the offer is waiting on a response (fee negotiation or the
    /// player's personal terms) and can still be resolved or countered.
    public var isLive: Bool {
        switch status {
        case .pending, .counterOffer, .personalTerms, .accepted: return true
        case .rejected, .completed, .withdrawn: return false
        }
    }

    public var formattedFee: String {
        return Player.formatCurrency(fee)
    }

    public var formattedOfferedWage: String {
        guard let wage = offeredWage else { return "N/A" }
        return "\(Player.formatCurrency(wage))/w"
    }

    // MARK: - Codable (tolerant of saves predating the richer negotiation model)

    private enum CodingKeys: String, CodingKey {
        case id, playerId, fromClubId, toClubId, fee, isLoan, loanWeeks, status
        case offeredWage, contractYears, askingPrice, counterFee, demandedWage
        case isIncoming, negotiationRound, createdDate, weeksUntilResponse
        case installments, sellOnPercent, sellOnYears, addOnAmount, baseWageDemand
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        playerId = try c.decode(UUID.self, forKey: .playerId)
        fromClubId = try c.decode(UUID.self, forKey: .fromClubId)
        toClubId = try c.decode(UUID.self, forKey: .toClubId)
        fee = try c.decode(Int.self, forKey: .fee)
        isLoan = try c.decodeIfPresent(Bool.self, forKey: .isLoan) ?? false
        loanWeeks = try c.decodeIfPresent(Int.self, forKey: .loanWeeks)
        status = try c.decodeIfPresent(TransferOfferStatus.self, forKey: .status) ?? .pending
        offeredWage = try c.decodeIfPresent(Int.self, forKey: .offeredWage)
        contractYears = try c.decodeIfPresent(Int.self, forKey: .contractYears)
        askingPrice = try c.decodeIfPresent(Int.self, forKey: .askingPrice) ?? fee
        counterFee = try c.decodeIfPresent(Int.self, forKey: .counterFee)
        demandedWage = try c.decodeIfPresent(Int.self, forKey: .demandedWage)
        isIncoming = try c.decodeIfPresent(Bool.self, forKey: .isIncoming) ?? false
        negotiationRound = try c.decodeIfPresent(Int.self, forKey: .negotiationRound) ?? 0
        createdDate = try c.decodeIfPresent(String.self, forKey: .createdDate) ?? ""
        weeksUntilResponse = try c.decodeIfPresent(Int.self, forKey: .weeksUntilResponse) ?? 0
        installments = max(1, try c.decodeIfPresent(Int.self, forKey: .installments) ?? 1)
        sellOnPercent = max(0, min(50, try c.decodeIfPresent(Int.self, forKey: .sellOnPercent) ?? 0))
        sellOnYears = max(0, try c.decodeIfPresent(Int.self, forKey: .sellOnYears) ?? 0)
        addOnAmount = max(0, try c.decodeIfPresent(Int.self, forKey: .addOnAmount) ?? 0)
        baseWageDemand = try c.decodeIfPresent(Int.self, forKey: .baseWageDemand)
    }
}

// MARK: - Transfer Installment

/// A transfer payment still to be made: a later installment of the fee, or
/// an add-on that is paid only if the player is still at the buying club when
/// it falls due.
public struct TransferInstallment: Codable, Identifiable, Hashable {
    public var id: UUID
    public var playerId: UUID
    public var playerName: String
    public var payerClubId: UUID
    public var payeeClubId: UUID
    public var amount: Int
    /// "YYYY-MM-DD": paid on the first week on or after this date.
    public var dueDate: String
    /// An add-on: paid only if the player is still at the payer club.
    public var isConditionalAddOn: Bool

    public init(id: UUID = UUID(), playerId: UUID, playerName: String, payerClubId: UUID, payeeClubId: UUID,
                amount: Int, dueDate: String, isConditionalAddOn: Bool = false) {
        self.id = id
        self.playerId = playerId
        self.playerName = playerName
        self.payerClubId = payerClubId
        self.payeeClubId = payeeClubId
        self.amount = amount
        self.dueDate = dueDate
        self.isConditionalAddOn = isConditionalAddOn
    }
}

/// How the other side answered in an instant negotiation.
public struct NegotiationReply: Equatable {
    public enum Kind: Equatable {
        /// The selling club accepts the fee: personal terms are next.
        case feeAgreed
        /// The other side names a price you can accept or beat.
        case countered
        /// This offer is refused, but talks go on.
        case rejected
        /// Talks are over.
        case walkedAway
        /// The deal is done.
        case completed
    }
    public var kind: Kind
    public var message: String
    /// The counter figure (fee or weekly wage), when countered.
    public var counter: Int?

    public init(_ kind: Kind, _ message: String, counter: Int? = nil) {
        self.kind = kind
        self.message = message
        self.counter = counter
    }
}

// MARK: - Transfer Record

public struct TransferRecord: Codable, Identifiable, Hashable {
    public let id: UUID
    public var playerId: UUID
    public var playerName: String
    public var fromClubId: UUID
    public var fromClubName: String
    public var toClubId: UUID
    public var toClubName: String
    public var fee: Int
    public var isLoan: Bool
    public var date: String           // Date completed "YYYY-MM-DD"
    
    public init(
        id: UUID = UUID(),
        playerId: UUID,
        playerName: String,
        fromClubId: UUID,
        fromClubName: String,
        toClubId: UUID,
        toClubName: String,
        fee: Int,
        isLoan: Bool = false,
        date: String
    ) {
        self.id = id
        self.playerId = playerId
        self.playerName = playerName
        self.fromClubId = fromClubId
        self.fromClubName = fromClubName
        self.toClubId = toClubId
        self.toClubName = toClubName
        self.fee = fee
        self.isLoan = isLoan
        self.date = date
    }
    
    public var formattedFee: String {
        if isLoan {
            return "Loan"
        }
        if fee == 0 {
            return "Free Transfer"
        }
        return Player.formatCurrency(fee)
    }
}
