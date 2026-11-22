//
//  TransferTalks.swift
//  Touchline
//
//  Instant, two-stage transfer negotiations, as in a modern career mode:
//
//    1. The fee, with the selling club: how much, paid in how many yearly
//       installments, any sell-on clause, and any add-on.
//    2. Personal terms, with the player: weekly wage, contract length and a
//       signing-on bonus.
//
//  Both sides answer straight away: accept, counter with a figure, refuse,
//  or (after too many rounds or an insulting offer) walk away. Contract
//  renewals with the manager's own players work the same way.
//

import Foundation

extension GameState {

    // MARK: - Dates and payments

    /// "YYYY-MM-DD" moved on by whole years.
    static func dateAdding(years: Int, to date: String) -> String {
        let parts = date.split(separator: "-")
        guard parts.count == 3, let year = Int(parts[0]) else { return date }
        return "\(year + years)-\(parts[1])-\(parts[2])"
    }

    /// Pays every installment and add-on that has fallen due. An add-on is
    /// only owed if the player is still at the club that bought him.
    func payDueInstallments() {
        guard !transferInstallments.isEmpty else { return }
        let today = season.currentDate
        var remaining: [TransferInstallment] = []
        for due in transferInstallments {
            guard due.dueDate <= today else { remaining.append(due); continue }
            guard let payer = clubs.firstIndex(where: { $0.id == due.payerClubId }),
                  let payee = clubs.firstIndex(where: { $0.id == due.payeeClubId }) else { continue }
            if due.isConditionalAddOn && clubs[payer].player(withId: due.playerId) == nil { continue }
            clubs[payer].finances.balance -= due.amount
            clubs[payer].finances.transferBudget -= due.amount
            clubs[payee].finances.balance += due.amount
            clubs[payee].finances.transferBudget += due.amount
            let kind = due.isConditionalAddOn ? "add-on" : "installment"
            if clubs[payer].isUserClub {
                seasonLedger?.transfers += due.amount
                addNews(
                    headline: "Transfer \(kind.capitalized) Paid",
                    body: "We have paid \(clubs[payee].name) \(Player.formatCurrency(due.amount)), the \(kind) due for \(due.playerName).",
                    category: .transfer,
                    sender: "Finance Director"
                )
            }
            if clubs[payee].isUserClub {
                seasonLedger?.playerSales += due.amount
                addNews(
                    headline: "Transfer \(kind.capitalized) Received",
                    body: "\(clubs[payer].name) have paid us \(Player.formatCurrency(due.amount)), the \(kind) due for \(due.playerName).",
                    category: .transfer,
                    sender: "Finance Director"
                )
            }
        }
        transferInstallments = remaining
    }

    /// Payments the user's club still owes (or is owed) for transfers.
    public var userInstallmentsOwed: Int {
        guard let uid = userClubId else { return 0 }
        return transferInstallments.filter { $0.payerClubId == uid && !$0.isConditionalAddOn }.reduce(0) { $0 + $1.amount }
    }

    // MARK: - Stage 1: the fee

    /// What a bid is worth to the selling club. Money later is worth a bit
    /// less than money now; a sell-on is worth more on a young player who
    /// may be sold on for a big fee; an add-on might never be paid.
    func bidValue(fee: Int, installments: Int, sellOnPercent: Int, addOn: Int, player: Player) -> Double {
        let deferral: Double
        switch max(1, min(4, installments)) {
        case 1: deferral = 1.0
        case 2: deferral = 0.96
        case 3: deferral = 0.93
        default: deferral = 0.90
        }
        let resale: Double = player.age <= 21 ? 0.9 : player.age <= 24 ? 0.6 : player.age <= 28 ? 0.3 : 0.1
        return Double(fee) * (deferral + Double(sellOnPercent) / 100.0 * resale) + Double(addOn) * 0.5
    }

    /// The live talks between the user and a selling club or player.
    func liveTalksIndex(for playerId: UUID) -> Int? {
        pendingTransferOffers.firstIndex { $0.playerId == playerId && !$0.isIncoming && $0.isLive && !$0.isLoan }
    }

    /// True for a few weeks after the club or the player walked out of talks
    /// (the dead offer is kept until it is pruned three weeks later).
    func talksRecentlyCollapsed(for playerId: UUID) -> Bool {
        pendingTransferOffers.contains {
            $0.playerId == playerId && !$0.isIncoming && !$0.isLoan && !$0.isLive
                && $0.status != .completed && $0.negotiationRound > 4
        }
    }

    /// A round figure for a fee.
    static func roundedFee(_ value: Int) -> Int {
        let step = value < 1_000_000 ? 10_000 : value < 10_000_000 ? 50_000 : 250_000
        return max(step, (value + step - 1) / step * step)
    }

    /// A round figure for a weekly wage.
    static func roundedWage(_ value: Int) -> Int {
        let step = value < 10_000 ? 100 : value < 100_000 ? 500 : 1_000
        return max(step, (value + step - 1) / step * step)
    }

    /// Bids for a player at another club. The club answers at once: it
    /// accepts (personal terms with the player come next), counters with
    /// the fee it would take on the same structure, or refuses. It gives a
    /// little ground the longer talks go on, but loses patience with lowballs.
    @discardableResult
    public func negotiateTransferFee(playerId: UUID, fee: Int, installments: Int = 1,
                                     sellOnPercent: Int = 0, addOn: Int = 0) -> NegotiationReply {
        guard let uid = userClubId, let buyerIdx = clubs.firstIndex(where: { $0.id == uid }) else {
            return NegotiationReply(.walkedAway, "You do not control a club.")
        }
        guard let sellerIdx = clubs.firstIndex(where: { $0.id != uid && $0.player(withId: playerId) != nil }),
              let player = clubs[sellerIdx].player(withId: playerId) else {
            return NegotiationReply(.walkedAway, "That player is not at another club.")
        }
        let seller = clubs[sellerIdx]
        if player.isOnLoan {
            return NegotiationReply(.walkedAway, "\(player.fullName) is on loan and cannot be sold until it ends.")
        }
        guard isTransferWindowOpen else {
            return NegotiationReply(.walkedAway, "The transfer window is closed. \(transferWindowStatus).")
        }
        if let derby = rivalry(between: uid, and: seller.id) {
            return NegotiationReply(.walkedAway, "\(seller.name) will not sell \(player.fullName) to their \(derby.name) rivals at any price.")
        }
        if liveTalksIndex(for: playerId) == nil && talksRecentlyCollapsed(for: playerId) {
            return NegotiationReply(.walkedAway, "Talks for \(player.fullName) broke down recently. \(seller.name) will not reopen them for a few weeks.")
        }

        let parts = max(1, min(4, installments))
        let sellOn = max(0, min(40, sellOnPercent))
        let fee = max(0, fee)
        let addOn = max(0, addOn)
        let upfront = parts == 1 ? fee : fee - (fee / parts) * (parts - 1)
        let budget = clubs[buyerIdx].finances.transferBudget
        guard upfront <= budget else {
            return NegotiationReply(.rejected, "The first payment of \(Player.formatCurrency(upfront)) is more than your transfer budget of \(Player.formatCurrency(budget)). Lower the fee or spread it over more installments.")
        }

        let idx: Int
        if let existing = liveTalksIndex(for: playerId) {
            idx = existing
        } else {
            pendingTransferOffers.append(TransferOffer(
                playerId: playerId,
                fromClubId: seller.id,
                toClubId: uid,
                fee: fee,
                status: .pending,
                askingPrice: sellingValuation(for: player, at: seller, buyerReputation: clubs[buyerIdx].reputation),
                isIncoming: false,
                createdDate: season.currentDate,
                weeksUntilResponse: 3
            ))
            idx = pendingTransferOffers.count - 1
        }
        var offer = pendingTransferOffers[idx]
        if offer.status == .personalTerms {
            return NegotiationReply(.feeAgreed, "The fee is already agreed. Now agree personal terms with \(player.fullName).")
        }
        offer.fee = fee
        offer.installments = parts
        offer.sellOnPercent = sellOn
        offer.addOnAmount = addOn
        offer.negotiationRound += 1
        offer.weeksUntilResponse = 3

        let asking = Double(max(1, offer.askingPrice))
        let value = bidValue(fee: fee, installments: parts, sellOnPercent: sellOn, addOn: addOn, player: player)
        // A club comes down a little as talks go on, to 6% under its price.
        let target = asking * (1.0 - 0.02 * Double(min(max(0, offer.negotiationRound - 1), 3)))
        let structure = Self.dealStructureText(fee: fee, installments: parts, sellOnPercent: sellOn, addOn: addOn)

        if value >= target {
            offer.status = .personalTerms
            offer.counterFee = nil
            offer.demandedWage = nil
            offer.baseWageDemand = nil
            // Personal terms are a fresh negotiation with the player.
            offer.negotiationRound = 0
            pendingTransferOffers[idx] = offer
            return NegotiationReply(.feeAgreed, "\(seller.name) accept \(structure). Now agree personal terms with \(player.fullName).")
        }

        // Insulting bids use up their patience twice as fast.
        let insulting = value < asking * 0.6
        if insulting { offer.negotiationRound += 1 }
        if offer.negotiationRound > 5 {
            offer.status = .rejected
            offer.weeksUntilResponse = 0
            pendingTransferOffers[idx] = offer
            return NegotiationReply(.walkedAway, "\(seller.name) have had enough and ended talks for \(player.fullName).")
        }

        // Their counter: the fee that meets their price on your structure.
        let perPound = bidValue(fee: 1_000_000, installments: parts, sellOnPercent: sellOn, addOn: 0, player: player) / 1_000_000
        let needed = (target - Double(addOn) * 0.5) / max(0.5, perPound)
        let counter = max(fee + 1, Self.roundedFee(Int(needed.rounded(.up))))
        offer.counterFee = counter
        offer.status = .counterOffer
        pendingTransferOffers[idx] = offer
        let counterStructure = Self.dealStructureText(fee: counter, installments: parts, sellOnPercent: sellOn, addOn: addOn)
        if insulting {
            return NegotiationReply(.rejected, "\(seller.name) find that offer insulting. They would want \(counterStructure).", counter: counter)
        }
        return NegotiationReply(.countered, "\(seller.name) turn down \(structure). They would accept \(counterStructure).", counter: counter)
    }

    /// "£20M in three yearly installments, with a 15% sell-on and a £2M add-on".
    static func dealStructureText(fee: Int, installments: Int, sellOnPercent: Int, addOn: Int) -> String {
        var text = Player.formatCurrency(fee)
        if installments > 1 { text += " in \(installments) yearly installments" }
        var extras: [String] = []
        if sellOnPercent > 0 { extras.append("a \(sellOnPercent)% sell-on clause") }
        if addOn > 0 { extras.append("a \(Player.formatCurrency(addOn)) add-on") }
        if !extras.isEmpty { text += ", with " + extras.joined(separator: " and ") }
        return text
    }

    // MARK: - Stage 2: personal terms

    /// How far below his asking wage a player will go to join. Joining a
    /// bigger club, being without one, or a long deal for a veteran all make
    /// him more flexible; dropping down a level makes him less so.
    func termsFlexibility(player: Player, buyer: Club, seller: Club?, years: Int) -> Double {
        var flex = 0.9
        if let seller {
            let stature = buyer.reputation - seller.reputation
            if stature >= 10 { flex -= 0.06 } else if stature >= 3 { flex -= 0.03 } else if stature <= -10 { flex += 0.05 }
        } else {
            flex -= 0.05
        }
        if player.age >= 30 && years >= 3 { flex -= 0.04 }
        if player.age <= 23 && years >= 5 { flex += 0.02 }
        return max(0.75, min(1.0, flex))
    }

    /// Offers a player personal terms. For a player at another club the fee
    /// must be agreed first; a free agent talks terms straight away. He
    /// accepts, counters with a wage (coming down a little each round), or
    /// walks away after too many rounds. A signing-on bonus counts towards
    /// what he gets, spread over the contract.
    @discardableResult
    public func negotiatePersonalTerms(playerId: UUID, wage: Int, years: Int, signingBonus: Int = 0) -> NegotiationReply {
        guard let uid = userClubId, let buyerIdx = clubs.firstIndex(where: { $0.id == uid }) else {
            return NegotiationReply(.walkedAway, "You do not control a club.")
        }
        guard let lookup = player(withId: playerId) else {
            return NegotiationReply(.walkedAway, "That player is no longer available.")
        }
        let player = lookup.player
        let sellerIdx = lookup.club.flatMap { c in clubs.firstIndex(where: { $0.id == c.id }) }
        if sellerIdx == buyerIdx {
            return NegotiationReply(.walkedAway, "\(player.fullName) already plays for you.")
        }

        var talks = liveTalksIndex(for: playerId)
        if talks == nil && talksRecentlyCollapsed(for: playerId) {
            return NegotiationReply(.walkedAway, "Talks with \(player.fullName) broke down recently. His agent will not reopen them for a few weeks.")
        }
        if let sellerIdx {
            guard let i = talks, pendingTransferOffers[i].status == .personalTerms else {
                return NegotiationReply(.rejected, "Agree a fee with \(clubs[sellerIdx].name) first.")
            }
        } else if talks == nil {
            pendingTransferOffers.append(TransferOffer(
                playerId: playerId,
                fromClubId: UUID(),
                toClubId: uid,
                fee: 0,
                status: .personalTerms,
                askingPrice: 0,
                isIncoming: false,
                createdDate: season.currentDate,
                weeksUntilResponse: 3
            ))
            talks = pendingTransferOffers.count - 1
        }
        guard let i = talks else { return NegotiationReply(.walkedAway, "Talks could not be opened.") }

        var offer = pendingTransferOffers[i]
        offer.status = .personalTerms
        let years = max(1, min(5, years))
        let wage = max(0, wage)
        let bonus = max(0, signingBonus)
        let seller = sellerIdx.map { clubs[$0] }
        let demand = offer.baseWageDemand ?? Self.roundedWage(wageDemand(for: player, buyer: clubs[buyerIdx], seller: seller))
        offer.baseWageDemand = demand
        offer.offeredWage = wage
        offer.contractYears = years
        offer.negotiationRound += 1
        offer.weeksUntilResponse = 3

        let floor = Double(demand) * termsFlexibility(player: player, buyer: clubs[buyerIdx], seller: seller, years: years)
        let effective = Double(wage) + Double(bonus) / Double(52 * years) * 0.85

        if effective >= floor {
            guard completeSigning(player: player, buyerIdx: buyerIdx, sellerIdx: sellerIdx, fee: offer.fee, wage: wage,
                                  years: years, installments: offer.installments, sellOnPercent: offer.sellOnPercent,
                                  addOn: offer.addOnAmount, signingBonus: bonus) else {
                pendingTransferOffers[i] = offer
                return NegotiationReply(.rejected, "\(player.fullName) would sign, but the board will not sanction it: the payment due now or the wage bill is more than the club can afford.")
            }
            offer.status = .completed
            offer.demandedWage = nil
            offer.weeksUntilResponse = 0
            pendingTransferOffers[i] = offer
            clubs[buyerIdx].ensureTacticalIntegrity()
            let fromText = seller.map { " from \($0.name)" } ?? " on a free transfer"
            let feeText = seller == nil ? "" : " The fee: " + Self.dealStructureText(fee: offer.fee, installments: offer.installments, sellOnPercent: offer.sellOnPercent, addOn: offer.addOnAmount) + "."
            let bonusText = bonus > 0 ? " plus a \(Player.formatCurrency(bonus)) signing-on bonus" : ""
            let message = "\(player.fullName) joins\(fromText) on a \(years)-year contract worth \(Player.formatCurrency(wage))/w\(bonusText).\(feeText)"
            addNews(headline: "\(player.fullName) Signs for \(clubs[buyerIdx].name)!", body: message,
                    category: .transfer, sender: "Director of Football")
            return NegotiationReply(.completed, "Deal done! " + message)
        }

        if effective < floor * 0.7 { offer.negotiationRound += 1 }
        if offer.negotiationRound > 4 {
            offer.status = .withdrawn
            offer.weeksUntilResponse = 0
            pendingTransferOffers[i] = offer
            return NegotiationReply(.walkedAway, "\(player.fullName) has walked away from talks. He felt the offers were not serious.")
        }
        // He comes down from his first figure toward his limit as talks go on.
        let progress = min(1.0, Double(offer.negotiationRound) / 4.0)
        let ask = Double(demand) - (Double(demand) - floor) * progress
        let counter = max(wage + 1, Self.roundedWage(Int(ask.rounded(.up))))
        offer.demandedWage = counter
        pendingTransferOffers[i] = offer
        return NegotiationReply(.countered, "\(player.fullName)'s agent says \(Player.formatCurrency(wage))/w is not enough. He would sign a \(years)-year deal for \(Player.formatCurrency(counter))/w.", counter: counter)
    }

    /// Ends talks for a player the user was negotiating for.
    public func abandonTalks(playerId: UUID) {
        guard let i = liveTalksIndex(for: playerId) else { return }
        pendingTransferOffers[i].status = .withdrawn
        pendingTransferOffers[i].weeksUntilResponse = 0
    }

    // MARK: - Contract renewals

    /// How far below his asking wage one of the user's players will go to
    /// stay. Happy players, squad players and veterans offered security take
    /// less; stars and unhappy players hold out; a player in the last year
    /// of his deal has the upper hand.
    func renewalFlexibility(player: Player, club: Club, years: Int) -> Double {
        var flex = 0.92
        switch player.morale {
        case .delighted: flex -= 0.08
        case .happy: flex -= 0.05
        case .content: flex -= 0.02
        case .unhappy: flex += 0.03
        case .furious: flex += 0.08
        }
        switch squadRole(of: player, at: club) {
        case .keyPlayer: flex += 0.03
        case .firstTeam: break
        case .rotation: flex -= 0.03
        case .youngster: flex -= 0.04
        case .backup, .notNeeded: flex -= 0.07
        }
        if player.age >= 31 && years >= 2 { flex -= 0.04 }
        if player.age >= 33 { flex -= 0.04 }
        if (player.contract?.yearsRemaining ?? 1) <= 1 { flex += 0.03 }
        return max(0.7, min(1.0, flex))
    }

    /// The lowest weekly wage he will accept on these terms (for the
    /// renewal screen's hint; the exact figure stays hidden).
    func renewalFloor(for player: Player, years: Int) -> Int {
        guard let club = userClub else { return contractRenewalWage(for: player) }
        return Int(Double(contractRenewalWage(for: player)) * renewalFlexibility(player: player, club: club, years: years))
    }
}
