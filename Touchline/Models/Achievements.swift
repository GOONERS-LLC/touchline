//
//  Achievements.swift
//  Touchline
//
//  Career achievements for both modes, unlocked by results, trophies,
//  transfers and longevity. Each records the date it was earned.
//

import Foundation

public struct Achievement: Identifiable, Hashable {
    public let id: String
    public let title: String
    public let detail: String
    public let icon: String
    /// Owner-only, manager-only, or either career.
    public let mode: GameMode?

    public static let catalog: [Achievement] = [
        Achievement(id: "first_win", title: "Off the Mark", detail: "Win your first match.", icon: "1.circle.fill", mode: nil),
        Achievement(id: "big_win", title: "Thrashing", detail: "Win a match by five goals or more.", icon: "flame.fill", mode: nil),
        Achievement(id: "derby_win", title: "Derby Day", detail: "Win a derby.", icon: "bolt.shield.fill", mode: nil),
        Achievement(id: "giant_killing", title: "Giant Killers", detail: "Beat a side whose XI is rated six or more points higher.", icon: "figure.fall", mode: nil),
        Achievement(id: "unbeaten_10", title: "Unbeatable", detail: "Go ten matches without defeat.", icon: "shield.lefthalf.filled", mode: nil),
        Achievement(id: "win_streak_6", title: "On Fire", detail: "Win six matches in a row.", icon: "flame.circle.fill", mode: nil),
        Achievement(id: "promotion", title: "Going Up", detail: "Win promotion.", icon: "arrow.up.circle.fill", mode: nil),
        Achievement(id: "league_title", title: "Champions", detail: "Win a league title.", icon: "trophy.fill", mode: nil),
        Achievement(id: "top_flight_title", title: "Top of the Pile", detail: "Win a top-flight league title.", icon: "crown.fill", mode: nil),
        Achievement(id: "cup_win", title: "Cup Glory", detail: "Win a domestic cup.", icon: "trophy", mode: nil),
        Achievement(id: "double", title: "The Double", detail: "Win the league and the domestic cup in the same season.", icon: "2.circle.fill", mode: nil),
        Achievement(id: "europe_win", title: "Kings of Europe", detail: "Win a European competition.", icon: "star.circle.fill", mode: nil),
        Achievement(id: "treble", title: "The Treble", detail: "League, cup and Europe in one season.", icon: "3.circle.fill", mode: nil),
        Achievement(id: "invincibles", title: "Invincibles", detail: "Go a whole league season unbeaten.", icon: "checkmark.shield.fill", mode: nil),
        Achievement(id: "centurions", title: "Centurions", detail: "Reach 100 league points in a season.", icon: "100.circle", mode: nil),
        Achievement(id: "big_signing", title: "Statement Signing", detail: "Sign a player for £50M or more.", icon: "signature", mode: nil),
        Achievement(id: "big_sale", title: "Cashing In", detail: "Sell a player for £50M or more.", icon: "banknote.fill", mode: nil),
        Achievement(id: "world_player", title: "Best in the World", detail: "Have the World Player of the Year in your squad.", icon: "globe.europe.africa.fill", mode: nil),
        Achievement(id: "young_player", title: "Wonderkid", detail: "Have the Young Player of the Year in your squad.", icon: "sparkles", mode: nil),
        Achievement(id: "club_legend", title: "Club Legend", detail: "A player reaches 200 appearances for your club.", icon: "person.crop.circle.badge.checkmark", mode: nil),
        Achievement(id: "five_seasons", title: "Long Haul", detail: "Complete five seasons.", icon: "calendar", mode: nil),
        Achievement(id: "ten_seasons", title: "A Decade at the Top", detail: "Complete ten seasons.", icon: "calendar.badge.clock", mode: nil),
        Achievement(id: "loan_star", title: "Finishing School", detail: "A player you loaned out returns after 20+ appearances.", icon: "graduationcap.fill", mode: .manageClub),
        Achievement(id: "sacked_survived", title: "Back from the Brink", detail: "Win the next match with board confidence below 25%.", icon: "heart.fill", mode: .manageClub),
        Achievement(id: "billion", title: "Billion-Pound Club", detail: "Grow the club's valuation to £1 billion.", icon: "building.columns.fill", mode: .createClub),
        Achievement(id: "adored", title: "Adored", detail: "Reach 95% supporter confidence.", icon: "heart.circle.fill", mode: .createClub),
        Achievement(id: "debt_free", title: "In the Black", detail: "Finish a season with no bank loans and £20M in the bank.", icon: "checkmark.circle.fill", mode: .createClub)
    ]
}

extension GameState {

    /// Achievements for the current career mode, with unlock dates.
    public var achievementList: [(achievement: Achievement, unlockedOn: String?)] {
        Achievement.catalog
            .filter { $0.mode == nil || $0.mode == gameMode }
            .map { ($0, achievements[$0.id]) }
    }

    func unlock(_ id: String) {
        guard achievements[id] == nil,
              let achievement = Achievement.catalog.first(where: { $0.id == id }),
              achievement.mode == nil || achievement.mode == gameMode else { return }
        achievements[id] = season.currentDate
        addNews(headline: "Achievement Unlocked: \(achievement.title)",
                body: achievement.detail,
                category: .award, sender: "Achievements")
    }

    /// Checked after each of the user's matches.
    func checkMatchAchievements(_ fixture: Fixture) {
        guard let uid = userClubId, let result = fixture.result, fixture.involves(clubId: uid),
              let opponentId = fixture.opponentId(for: uid) else { return }
        let outcome = result.outcomeLetter(for: uid)
        let isHome = fixture.homeClubId == uid
        let margin = isHome ? result.homeGoals - result.awayGoals : result.awayGoals - result.homeGoals
        if outcome == "W" {
            unlock("first_win")
            if margin >= 5 { unlock("big_win") }
            if rivalry(between: uid, and: opponentId) != nil { unlock("derby_win") }
            if let me = userClub, let them = club(withId: opponentId),
               them.startingXIAverageOverall - me.startingXIAverageOverall >= 6 { unlock("giant_killing") }
            if gameMode == .manageClub && jobSecurity.boardConfidence < 25 { unlock("sacked_survived") }
        }
        let recent = season.completedFixtures(forClub: uid).compactMap { $0.result?.outcomeLetter(for: uid) }
        if recent.count >= 10 && !recent.suffix(10).contains("L") { unlock("unbeaten_10") }
        if recent.count >= 6 && recent.suffix(6).allSatisfy({ $0 == "W" }) { unlock("win_streak_6") }
    }

    /// Checked when the user's club buys or sells.
    func checkTransferAchievements(fee: Int, userBought: Bool) {
        guard fee >= 50_000_000 else { return }
        unlock(userBought ? "big_signing" : "big_sale")
    }

    /// Checked at the end of each season, after the record books are written.
    func checkSeasonAchievements(finalTables: [LeagueTier: [LeagueStanding]], promoted: Bool) {
        guard let club = userClub else { return }
        let year = season.year
        let won = history.honours.filter { $0.clubId == club.id && $0.season == year }
        let league = won.contains { $0.kind == .league }
        let cup = won.contains { $0.kind == .cup }
        let europe = won.contains { $0.kind == .europe }
        if promoted { unlock("promotion") }
        if league { unlock("league_title") }
        // Judge the division the season was played in, not the one the club
        // has just been promoted to.
        let playedTier = finalTables.first { $0.value.contains { $0.clubId == club.id } }?.key
        if league && playedTier?.level == 1 { unlock("top_flight_title") }
        if cup { unlock("cup_win") }
        if europe { unlock("europe_win") }
        if league && cup { unlock("double") }
        if league && cup && europe { unlock("treble") }
        if let tier = playedTier, let table = finalTables[tier], let row = table.first(where: { $0.clubId == club.id }) {
            if row.lost == 0 && row.played >= 20 { unlock("invincibles") }
            if row.points >= 100 { unlock("centurions") }
        }
        let squadIds = Set(club.players.map { $0.id })
        for award in history.awards where award.season == year && squadIds.contains(award.playerId) {
            if award.award == "World Player of the Year" { unlock("world_player") }
            if award.award == "Young Player of the Year" { unlock("young_player") }
        }
        if history.legends(for: club.id).contains(where: { $0.appearances >= 200 }) { unlock("club_legend") }
        let seasonsDone = Set(history.honours.map { $0.season }).count
        if seasonsDone >= 5 { unlock("five_seasons") }
        if seasonsDone >= 10 { unlock("ten_seasons") }
        if gameMode == .manageClub && userPlayersOutOnLoan.contains(where: { $0.player.seasonStats.appearances >= 20 }) {
            unlock("loan_star")
        }
        if gameMode == .createClub {
            if OwnerBusiness.valuation(of: club, debt: owner.totalDebt) >= 1_000_000_000 { unlock("billion") }
            if owner.loans.isEmpty && club.finances.balance >= 20_000_000 { unlock("debt_free") }
        }
    }

    /// Checked weekly in owner mode.
    func checkOwnerWeeklyAchievements() {
        guard gameMode == .createClub else { return }
        if owner.supporterConfidence >= 95 { unlock("adored") }
    }
}
