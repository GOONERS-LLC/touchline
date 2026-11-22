//
//  Loans.swift
//  Touchline
//
//  Season-long loans: young or fringe players gain first-team football at
//  smaller clubs, while the borrowing club strengthens cheaply. Loans run
//  until the end of the season and the parent club can recall a player
//  while a transfer window is open.
//

import Foundation

/// Purchase terms attached to a loan.
public enum LoanTerms: String, CaseIterable, Identifiable {
    case plain = "Loan only"
    case option = "Option to buy"
    case obligation = "Obligation to buy"
    public var id: String { rawValue }
}

/// The outcome of asking another club to lend the user a player.
public enum LoanRequestResult: Equatable {
    case agreed(wageShare: Int, fee: Int)
    case refused(String)
}

extension GameState {

    // MARK: - Eligibility

    /// Whether a club would be willing to let this player go out on loan:
    /// young players not yet established, or squad players out of the side.
    public func isLoanable(_ player: Player, at club: Club) -> Bool {
        guard !player.isOnLoan, player.injury == nil || (player.injury?.weeksRemaining ?? 0) <= 2 else { return false }
        let xi = club.startingXIAverageOverall
        let starter = club.tactics.startingXI.contains(player.id)
        if player.age <= 21 && !starter { return true }
        return !starter && Double(player.overall) <= xi - 3 && player.age <= 29
    }

    /// Whether the player would walk into the club's side: fewer fit players
    /// in his area of the pitch are better than him than the formation has
    /// places for.
    public func wouldStart(_ player: Player, at club: Club) -> Bool {
        let category = player.primaryPosition.category
        let slots = club.tactics.formation.defaultPositions.filter { $0.category == category }.count
        let better = club.players.filter {
            $0.id != player.id && $0.primaryPosition.category == category
                && $0.overall > player.overall && $0.injury == nil
        }.count
        return better < max(1, slots)
    }

    /// The minimum share of a loanee's wage the parent club insists on.
    private func minimumWageShare(for player: Player) -> Int {
        player.age <= 21 ? 50 : 75
    }

    /// A small fee is charged for established players; young players are
    /// lent for free because the parent club wants them playing.
    public func loanFee(for player: Player) -> Int {
        guard player.age > 21 else { return 0 }
        return max(0, player.value / 20 / 10_000 * 10_000)
    }

    // MARK: - User loans out

    /// Lists clubs that would take the user's player on loan, best match
    /// first. A good destination plays at a level where he will start.
    public func loanDestinations(forPlayerId playerId: UUID, limit: Int = 5) -> [Club] {
        guard let userIdx = clubs.firstIndex(where: { $0.isUserClub }),
              let player = clubs[userIdx].player(withId: playerId), !player.isOnLoan else { return [] }
        let home = clubs[userIdx]
        let candidates = clubs.filter { club in
            guard !club.isUserClub,
                  club.leagueTier.country == home.leagueTier.country,
                  club.leagueTier.level >= home.leagueTier.level,
                  club.players.count < 28,
                  rivalry(between: club.id, and: home.id) == nil else { return false }
            let share = affordableShare(for: player, at: club)
            return share >= minimumWageShare(for: player) && wouldStart(player, at: club)
        }
        return candidates.sorted { lhs, rhs in
            // Prefer the strongest club where he would still start.
            if lhs.leagueTier.level != rhs.leagueTier.level {
                return lhs.leagueTier.level < rhs.leagueTier.level
            }
            return lhs.reputation > rhs.reputation
        }
        .prefix(limit)
        .map { $0 }
    }

    /// The largest share of the player's wage the club can fit under its
    /// wage budget, rounded down to 25% steps and capped at 100%.
    private func affordableShare(for player: Player, at club: Club) -> Int {
        guard player.wage > 0 else { return 100 }
        let room = club.finances.wageBudget - club.totalWeeklyWageBill
        guard room > 0 else { return 0 }
        let share = min(100, room * 100 / player.wage)
        return share / 25 * 25
    }

    /// Sends one of the user's players on a season-long loan.
    @discardableResult
    public func loanOutPlayer(playerId: UUID, to destinationId: UUID) -> Bool {
        guard isTransferWindowOpen,
              let userIdx = clubs.firstIndex(where: { $0.isUserClub }),
              let destIdx = clubs.firstIndex(where: { $0.id == destinationId }),
              let player = clubs[userIdx].player(withId: playerId),
              !player.isOnLoan,
              clubs[userIdx].players.count > 16,
              loanDestinations(forPlayerId: playerId, limit: 50).contains(where: { $0.id == destinationId }) else { return false }
        let share = min(100, affordableShare(for: player, at: clubs[destIdx]))
        guard moveOnLoan(playerId: playerId, fromIdx: userIdx, toIdx: destIdx, wageShare: share, fee: 0) else { return false }
        let destination = clubs[destIdx].name
        addNews(
            headline: "\(player.fullName) Joins \(destination) on Loan",
            body: "\(player.fullName) will spend the rest of the season at \(destination), who cover \(share)% of his wages. You can recall him while a transfer window is open.",
            category: .transfer,
            sender: "Director of Football"
        )
        return true
    }

    /// Brings a player the user lent out back early. Only while a window is
    /// open, as in real football.
    @discardableResult
    public func recallLoanedPlayer(playerId: UUID) -> Bool {
        guard isTransferWindowOpen,
              let userId = userClubId,
              let parentIdx = clubs.firstIndex(where: { $0.id == userId }),
              let hostIdx = clubs.firstIndex(where: { $0.player(withId: playerId)?.loan?.parentClubId == userId }),
              var player = clubs[hostIdx].removePlayer(withId: playerId) else { return false }
        player.loan = nil
        clubs[parentIdx].addPlayer(player)
        clubs[hostIdx].ensureTacticalIntegrity()
        addNews(
            headline: "\(player.fullName) Recalled",
            body: "\(player.fullName) has been recalled from his loan at \(clubs[hostIdx].name) after \(player.seasonStats.appearances) appearances.",
            category: .transfer,
            sender: "Director of Football"
        )
        return true
    }

    /// The user's players currently out on loan, with the club they are at.
    public var userPlayersOutOnLoan: [(player: Player, club: Club)] {
        guard let userId = userClubId else { return [] }
        var out: [(Player, Club)] = []
        for club in clubs where !club.isUserClub {
            for player in club.players where player.loan?.parentClubId == userId {
                out.append((player, club))
            }
        }
        return out.sorted { $0.0.overall > $1.0.overall }
    }

    // MARK: - User loans in

    /// Asks the player's club to lend him to the user for the season.
    /// The fee written into a loan's purchase clause.
    public func loanPurchaseFee(for player: Player, terms: LoanTerms) -> Int? {
        switch terms {
        case .plain: return nil
        case .option: return Int(Double(player.value) * 1.1) / 10_000 * 10_000
        case .obligation: return player.value / 10_000 * 10_000
        }
    }

    public func requestLoan(playerId: UUID, wageShare: Int, terms: LoanTerms = .plain) -> LoanRequestResult {
        guard isTransferWindowOpen else { return .refused("Loans can only be agreed while a transfer window is open.") }
        guard let userIdx = clubs.firstIndex(where: { $0.isUserClub }),
              let parentIdx = clubs.firstIndex(where: { !$0.isUserClub && $0.player(withId: playerId) != nil }),
              let player = clubs[parentIdx].player(withId: playerId) else {
            return .refused("That player is not available.")
        }
        let parent = clubs[parentIdx]
        let borrower = clubs[userIdx]
        if player.isOnLoan { return .refused("\(player.fullName) is already out on loan.") }
        if let derby = rivalry(between: parent.id, and: borrower.id) {
            return .refused("\(parent.name) will not lend a player to their \(derby.name) rivals.")
        }
        guard parent.players.count > 20 else {
            return .refused("\(parent.name) cannot spare anyone; their squad is too thin.")
        }
        guard isLoanable(player, at: parent) else {
            return .refused("\(parent.name) see \(player.fullName) as part of their first team and will not lend him.")
        }
        // The parent club wants him playing regularly.
        if Double(player.overall) < borrower.startingXIAverageOverall - 4 {
            return .refused("\(parent.name) want \(player.fullName) to play every week and doubt he would start for you.")
        }
        let share = max(0, min(100, wageShare))
        guard share >= minimumWageShare(for: player) else {
            return .refused("\(parent.name) insist you cover at least \(minimumWageShare(for: player))% of his wages.")
        }
        let fee = loanFee(for: player)
        guard fee <= borrower.finances.transferBudget else {
            return .refused("The \(Player.formatCurrency(fee)) loan fee is beyond your transfer budget.")
        }
        let weekly = player.wage * share / 100
        guard borrower.totalWeeklyWageBill + weekly <= wageCeiling(for: borrower) else {
            return .refused("Covering \(share)% of his wages (\(Player.formatCurrency(weekly))/w) would take the wage bill far beyond the board's recommendation.")
        }
        let purchaseFee = loanPurchaseFee(for: player, terms: terms)
        if terms == .obligation, let purchaseFee, purchaseFee > borrower.finances.balance + borrower.finances.transferBudget {
            return .refused("You could not afford the \(Player.formatCurrency(purchaseFee)) obligation to buy him.")
        }
        guard moveOnLoan(playerId: playerId, fromIdx: parentIdx, toIdx: userIdx, wageShare: share, fee: fee,
                         buyOption: terms == .option ? purchaseFee : nil,
                         obligation: terms == .obligation ? purchaseFee : nil) else {
            return .refused("The deal fell through.")
        }
        addNews(
            headline: "\(player.fullName) Arrives on Loan",
            body: "\(player.fullName) joins from \(parent.name) on a season-long loan. You pay \(share)% of his wages\(fee > 0 ? " and a \(Player.formatCurrency(fee)) loan fee" : "")." + (terms == .option ? " You can sign him permanently for \(Player.formatCurrency(purchaseFee ?? 0)) at any time." : terms == .obligation ? " He joins permanently for \(Player.formatCurrency(purchaseFee ?? 0)) when the loan ends." : " He returns to \(parent.name) in the summer."),
            category: .transfer,
            sender: "Director of Football"
        )
        return .agreed(wageShare: share, fee: fee)
    }

    /// Signs a borrowed player permanently under his loan's purchase clause.
    @discardableResult
    public func exerciseLoanOption(playerId: UUID) -> String {
        guard let userIdx = clubs.firstIndex(where: { $0.isUserClub }),
              let loan = clubs[userIdx].player(withId: playerId)?.loan,
              let fee = loan.buyOptionFee ?? loan.obligationFee else { return "There is no purchase clause in this loan." }
        guard clubs[userIdx].finances.balance >= fee else {
            return "The club cannot afford the \(Player.formatCurrency(fee)) fee."
        }
        guard makeLoanPermanent(playerId: playerId, at: userIdx, fee: fee) else { return "The deal fell through." }
        return "Deal done: he is now your player permanently."
    }

    /// Converts a loan into a permanent transfer at the agreed fee.
    private func makeLoanPermanent(playerId: UUID, at hostIdx: Int, fee: Int) -> Bool {
        guard let pIdx = clubs[hostIdx].players.firstIndex(where: { $0.id == playerId }),
              let loan = clubs[hostIdx].players[pIdx].loan else { return false }
        var player = clubs[hostIdx].players[pIdx]
        player.loan = nil
        // He now takes his full wage from the new club.
        clubs[hostIdx].players[pIdx] = player
        clubs[hostIdx].finances.balance -= fee
        clubs[hostIdx].finances.transferBudget = max(0, clubs[hostIdx].finances.transferBudget - fee)
        if clubs[hostIdx].isUserClub { seasonLedger?.transfers += fee }
        if let parentIdx = clubs.firstIndex(where: { $0.id == loan.parentClubId }) {
            clubs[parentIdx].finances.balance += fee
            clubs[parentIdx].finances.transferBudget += fee
            if clubs[parentIdx].isUserClub { seasonLedger?.playerSales += fee }
        }
        clubs[hostIdx].finances.currentWageBill = clubs[hostIdx].totalWeeklyWageBill
        transferHistory.append(TransferRecord(playerId: player.id, playerName: player.fullName,
                                              fromClubId: loan.parentClubId, fromClubName: loan.parentClubName,
                                              toClubId: clubs[hostIdx].id, toClubName: clubs[hostIdx].name,
                                              fee: fee, date: season.currentDate))
        if clubs[hostIdx].isUserClub || loan.parentClubId == userClubId {
            addNews(headline: "\(player.fullName) Signs Permanently",
                    body: "\(clubs[hostIdx].name) have made \(player.fullName)'s loan from \(loan.parentClubName) permanent for \(Player.formatCurrency(fee)).",
                    category: .transfer, sender: "Director of Football")
        }
        return true
    }

    /// Sends a player the user borrowed back to his parent club early.
    @discardableResult
    public func endLoanEarly(playerId: UUID) -> Bool {
        guard isTransferWindowOpen,
              let userIdx = clubs.firstIndex(where: { $0.isUserClub }),
              let loan = clubs[userIdx].player(withId: playerId)?.loan,
              clubs[userIdx].players.count > 16,
              var player = clubs[userIdx].removePlayer(withId: playerId) else { return false }
        player.loan = nil
        if let parentIdx = clubs.firstIndex(where: { $0.id == loan.parentClubId }) {
            clubs[parentIdx].addPlayer(player)
        } else {
            player.contract = nil
            freeAgents.append(player)
        }
        clubs[userIdx].ensureTacticalIntegrity()
        addNews(
            headline: "\(player.fullName) Returns to \(loan.parentClubName)",
            body: "\(player.fullName)'s loan has been cut short and he has gone back to \(loan.parentClubName).",
            category: .transfer,
            sender: "Director of Football"
        )
        return true
    }

    // MARK: - Mechanics

    /// Moves a player between clubs on loan, settling the fee.
    private func moveOnLoan(playerId: UUID, fromIdx: Int, toIdx: Int, wageShare: Int, fee: Int,
                            buyOption: Int? = nil, obligation: Int? = nil) -> Bool {
        guard fromIdx != toIdx, var player = clubs[fromIdx].removePlayer(withId: playerId) else { return false }
        player.transferStatus = nil
        player.loan = LoanSpell(
            parentClubId: clubs[fromIdx].id,
            parentClubName: clubs[fromIdx].name,
            startDate: season.currentDate,
            wageSharePercent: wageShare,
            loanFee: fee,
            buyOptionFee: buyOption,
            obligationFee: obligation
        )
        if fee > 0 {
            clubs[toIdx].finances.balance -= fee
            clubs[toIdx].finances.transferBudget -= fee
            clubs[fromIdx].finances.balance += fee
            clubs[fromIdx].finances.transferBudget += fee
            if clubs[toIdx].isUserClub { seasonLedger?.transfers += fee }
            if clubs[fromIdx].isUserClub { seasonLedger?.playerSales += fee }
        }
        clubs[toIdx].addPlayer(player)
        clubs[fromIdx].ensureTacticalIntegrity()
        clubs[fromIdx].finances.currentWageBill = clubs[fromIdx].totalWeeklyWageBill
        transferHistory.append(
            TransferRecord(
                playerId: player.id,
                playerName: player.fullName,
                fromClubId: clubs[fromIdx].id,
                fromClubName: clubs[fromIdx].name,
                toClubId: clubs[toIdx].id,
                toClubName: clubs[toIdx].name,
                fee: fee,
                isLoan: true,
                date: season.currentDate
            )
        )
        return true
    }

    /// Completes a loan the user agreed to from an inbox request.
    func completeAgreedLoan(playerId: UUID, fromIdx: Int, toIdx: Int, wageShare: Int) -> Bool {
        guard isTransferWindowOpen, clubs[fromIdx].players.count > 16,
              let player = clubs[fromIdx].player(withId: playerId), !player.isOnLoan,
              clubs[toIdx].totalWeeklyWageBill + player.wage * wageShare / 100 <= clubs[toIdx].finances.wageBudget,
              moveOnLoan(playerId: playerId, fromIdx: fromIdx, toIdx: toIdx, wageShare: wageShare, fee: 0) else { return false }
        addNews(
            headline: "\(player.fullName) Joins \(clubs[toIdx].name) on Loan",
            body: "\(player.fullName) will play for \(clubs[toIdx].name) for the rest of the season. You can recall him while a window is open.",
            category: .transfer,
            sender: "Head of Loans"
        )
        return true
    }

    /// Other clubs ask to borrow the manager's young players who are not
    /// getting games; the request arrives in the inbox.
    private func requestUserLoansFromAI() {
        let hasLoanListed = clubs.first(where: { $0.isUserClub })?.players.contains { $0.transferStatus == .loanListed } ?? false
        guard gameMode == .manageClub, Double.random(in: 0..<1) < (hasLoanListed ? 0.6 : 0.25),
              let userIdx = clubs.firstIndex(where: { $0.isUserClub }),
              clubs[userIdx].players.count > 20 else { return }
        let home = clubs[userIdx]
        let xi = Set(home.tactics.startingXI + home.tactics.substitutes)
        guard let prospect = home.players
            .filter({ !$0.isOnLoan && $0.injury == nil && $0.transferStatus != .notForSale
                && ($0.transferStatus == .loanListed || ($0.age <= 21 && !xi.contains($0.id))) })
            .filter({ p in !pendingTransferOffers.contains { $0.playerId == p.id && $0.isLive } })
            .max(by: { ($0.transferStatus == .loanListed ? 1000 : 0) + $0.potential < ($1.transferStatus == .loanListed ? 1000 : 0) + $1.potential }),
              let host = loanDestinations(forPlayerId: prospect.id, limit: 4).randomElement() else { return }
        let share = min(100, affordableShare(for: prospect, at: host))
        let offer = TransferOffer(
            playerId: prospect.id,
            fromClubId: home.id,
            toClubId: host.id,
            fee: 0,
            isLoan: true,
            status: .pending,
            offeredWage: prospect.wage * share / 100,
            contractYears: 1,
            isIncoming: true,
            createdDate: season.currentDate,
            weeksUntilResponse: 2
        )
        pendingTransferOffers.append(offer)
        addNews(
            headline: "\(host.name) Ask to Borrow \(prospect.fullName)",
            body: "\(host.name) (\(host.leagueTier.displayName)) want \(prospect.fullName) on a season-long loan and would cover \(share)% of his wages. He has not been in your matchday squad, and they would play him regularly.",
            category: .transfer,
            sender: host.name,
            transferOfferId: offer.id
        )
    }

    /// Weekly AI loan market: big clubs farm out young players who are not
    /// getting games to clubs where they will start.
    func processAILoans() {
        guard isTransferWindowOpen else { return }
        requestUserLoansFromAI()
        guard Double.random(in: 0..<1) < 0.5 else { return }
        let userManages = gameMode == .manageClub
        var deals = 0
        for parentIdx in clubs.indices.shuffled() where deals < 3 {
            let parent = clubs[parentIdx]
            if parent.isUserClub && userManages { continue }
            guard parent.players.count > 23 else { continue }
            let xi = parent.startingXIAverageOverall
            guard let prospect = parent.players
                .filter({ $0.age <= 22 && !$0.isOnLoan && $0.injury == nil
                    && Double($0.overall) <= xi - 6 && !parent.tactics.startingXI.contains($0.id) })
                .max(by: { $0.potential < $1.potential }) else { continue }
            let hosts = clubs.indices.filter { idx in
                let host = clubs[idx]
                guard idx != parentIdx, !(host.isUserClub && userManages),
                      host.leagueTier.country == parent.leagueTier.country,
                      host.leagueTier.level > parent.leagueTier.level,
                      host.players.count < 25,
                      wouldStart(prospect, at: host) else { return false }
                return affordableShare(for: prospect, at: host) >= 50
                    && rivalry(between: host.id, and: parent.id) == nil
            }
            guard let hostIdx = hosts.min(by: { clubs[$0].leagueTier.level < clubs[$1].leagueTier.level }) else { continue }
            let share = min(100, affordableShare(for: prospect, at: clubs[hostIdx]))
            // About a third of loans carry an option to buy.
            let option = Double.random(in: 0..<1) < 0.3 ? loanPurchaseFee(for: prospect, terms: .option) : nil
            if moveOnLoan(playerId: prospect.id, fromIdx: parentIdx, toIdx: hostIdx, wageShare: share, fee: 0, buyOption: option) {
                deals += 1
                if clubs[parentIdx].isUserClub || clubs[hostIdx].isUserClub {
                    addNews(
                        headline: "\(prospect.fullName) Moves on Loan",
                        body: "\(clubs[hostIdx].name) have taken \(prospect.fullName) on a season-long loan from \(clubs[parentIdx].name) to give him regular football.",
                        category: .transfer,
                        sender: clubs[hostIdx].isUserClub ? clubs[hostIdx].manager : "Club News Desk"
                    )
                }
            }
        }
    }

    /// Summer: every loanee returns to his parent club. A young player who
    /// played regularly comes back a little better for the experience.
    func returnLoanedPlayers() {
        var userReports: [String] = []
        let userId = userClubId
        for hostIdx in clubs.indices {
            // Obligations to buy are honoured, and AI clubs take up options on
            // young loanees who played regularly.
            for loanee in clubs[hostIdx].players where loanee.loan?.obligationFee != nil
                || (loanee.loan?.buyOptionFee != nil && !clubs[hostIdx].isUserClub
                    && loanee.seasonStats.appearances >= 20 && Double.random(in: 0..<1) < 0.5) {
                if let fee = loanee.loan?.obligationFee ?? loanee.loan?.buyOptionFee {
                    _ = makeLoanPermanent(playerId: loanee.id, at: hostIdx, fee: fee)
                }
            }
            let loanees = clubs[hostIdx].players.filter { $0.isOnLoan }
            for loanee in loanees {
                guard var player = clubs[hostIdx].removePlayer(withId: loanee.id),
                      let loan = player.loan else { continue }
                player.loan = nil
                let apps = player.seasonStats.appearances
                if player.age <= 23 && apps >= 20 && player.overall < player.potential {
                    player.overall += 1
                }
                if let parentIdx = clubs.firstIndex(where: { $0.id == loan.parentClubId }) {
                    clubs[parentIdx].addPlayer(player)
                    if loan.parentClubId == userId {
                        userReports.append("\(player.fullName) (\(clubs[hostIdx].name): \(apps) apps, \(player.seasonStats.goals) goals)")
                    }
                } else {
                    // The parent club no longer exists: the move becomes permanent.
                    clubs[hostIdx].addPlayer(player)
                }
            }
            clubs[hostIdx].ensureTacticalIntegrity()
            clubs[hostIdx].finances.currentWageBill = clubs[hostIdx].totalWeeklyWageBill
        }
        if !userReports.isEmpty {
            addNews(
                headline: "Loan Players Return",
                body: "Back from their loans: " + userReports.prefix(6).joined(separator: "; ") + ".",
                category: .transfer,
                sender: "Head of Loans"
            )
        }
    }
}
