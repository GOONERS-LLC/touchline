//
//  IncomingNegotiation.swift
//  Touchline
//
//  Haggling over a bid for one of the user's players. The buyer has a price
//  it will go to (decided from the player's value and how keen it is) and
//  answers each request at once: it pays, meets you part of the way, or
//  walks away after being pushed too often.
//

import Foundation

public enum IncomingCounterResult: Equatable {
    /// The buyer agreed and the player has gone.
    case agreed(fee: Int)
    /// The buyer raised its offer but not to the full request.
    case raised(fee: Int)
    /// The buyer has had enough and withdrawn.
    case walkedAway
    /// The offer could not be found or is no longer live.
    case unavailable
}

extension GameState {

    /// The most the buying club would pay for this offer's player. Fixed per
    /// offer, so asking twice doesn't change its mind.
    public func buyerCeiling(for offer: TransferOffer) -> Int {
        guard let player = player(withId: offer.playerId)?.player,
              let buyer = club(withId: offer.toClubId) else { return offer.fee }
        var hash: UInt64 = 1469598103934665603
        for b in offer.id.uuidString.utf8 { hash = (hash ^ UInt64(b)) &* 1099511628211 }
        let keenness = 1.05 + Double(hash % 45) / 100          // 1.05 ... 1.49
        // Fixed from the player's value, so raising the bid doesn't move it.
        let wanted = Int(Double(player.value) * keenness)
        // A sale only completes within the buyer's transfer budget.
        return max(offer.fee, min(wanted, buyer.finances.transferBudget))
    }

    /// Asks the buyer for `fee`. Agreeing completes the sale immediately.
    @discardableResult
    public func counterIncomingOffer(offerId: UUID, askingFee: Int) -> IncomingCounterResult {
        guard let idx = pendingTransferOffers.firstIndex(where: { $0.id == offerId }),
              pendingTransferOffers[idx].isIncoming, pendingTransferOffers[idx].isLive,
              !pendingTransferOffers[idx].isLoan else { return .unavailable }
        let offer = pendingTransferOffers[idx]
        let ceiling = buyerCeiling(for: offer)
        let buyerName = club(withId: offer.toClubId)?.name ?? "The buyer"
        let name = playerName(for: offer.playerId)

        if askingFee <= ceiling {
            let agreed = max(askingFee, offer.fee)
            pendingTransferOffers[idx].fee = agreed
            acceptIncomingOffer(offerId: offerId)
            if pendingTransferOffers.first(where: { $0.id == offerId })?.status == .completed {
                return .agreed(fee: agreed)
            }
            return .unavailable
        }

        pendingTransferOffers[idx].negotiationRound += 1
        if pendingTransferOffers[idx].negotiationRound >= 3 || askingFee > ceiling * 2 {
            pendingTransferOffers[idx].status = .withdrawn
            pendingTransferOffers[idx].weeksUntilResponse = 0
            for n in news.indices where news[n].transferOfferId == offerId { news[n].isRead = true }
            addNews(
                headline: "\(buyerName) Walk Away",
                body: "\(buyerName) have withdrawn their offer for \(name). They felt your demands were unrealistic.",
                category: .transfer,
                sender: "Director of Football"
            )
            return .walkedAway
        }
        // Meet in the middle of where they were and the most they'll pay.
        let raised = offer.fee + (ceiling - offer.fee) / 2
        let rounded = (raised / 10_000) * 10_000
        pendingTransferOffers[idx].fee = min(ceiling, rounded > offer.fee ? rounded : raised)
        return .raised(fee: pendingTransferOffers[idx].fee)
    }
}
