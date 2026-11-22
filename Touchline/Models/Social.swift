//
//  Social.swift
//  Touchline
//
//  "The Terrace": a social feed of posts by players and clubs, written from
//  the season's real results, transfers and awards. Posts are rebuilt from
//  the world on demand, so they cost nothing in the save file.
//

import Foundation

public struct SocialPost: Identifiable, Hashable {
    public enum Kind: String, CaseIterable, Identifiable {
        case general = "General"
        case transfer = "Transfers"
        case myTeam = "My Team"
        case award = "Awards"
        public var id: String { rawValue }
    }

    public var id: String
    public var kind: Kind
    public var handle: String
    /// A player's face, or nil for a club account.
    public var faceSeed: UInt64?
    public var clubId: UUID?
    public var text: String
    public var hashtag: String?
    public var date: String
    public var likes: Int
    public var reposts: Int
    public var involvesUser: Bool
}

extension GameState {

    /// Up to `limit` posts, newest first.
    public func socialFeed(limit: Int = 60) -> [SocialPost] {
        var posts: [SocialPost] = []
        posts += resultPosts()
        posts += transferPosts()
        posts += awardPosts()
        return Array(posts.sorted { ($0.date, $0.likes) > ($1.date, $1.likes) }.prefix(limit))
    }

    // MARK: - Sources

    private func resultPosts() -> [SocialPost] {
        let played = season.fixtures.filter { $0.isPlayed && $0.result != nil }
        guard !played.isEmpty else { return [] }
        // The two most recent matchdays, plus every game the user played.
        let recentDates = Set(played.map(\.date).sorted(by: >).prefix(4))
        let userId = userClubId
        let chosen = played.filter { f in
            let involvesUser = f.homeClubId == userId || f.awayClubId == userId
            guard recentDates.contains(f.date) || involvesUser else { return false }
            if involvesUser { return true }
            // Elsewhere, only the bigger games make the feed.
            let rep = max(club(withId: f.homeClubId)?.reputation ?? 0, club(withId: f.awayClubId)?.reputation ?? 0)
            return rep >= 78
        }
        .suffix(40)

        return chosen.compactMap { fixture -> SocialPost? in
            guard let result = fixture.result,
                  let home = club(withId: fixture.homeClubId),
                  let away = club(withId: fixture.awayClubId) else { return nil }
            var rng = SocialRandom(seed: fixture.id)
            // Speaker: man of the match, else a scorer, else a starter.
            let speakerId = result.manOfTheMatch
                ?? result.goalEvents.first?.playerId
                ?? home.startingXIPlayers.first?.id
            guard let speakerId, let found = player(withId: speakerId) else { return nil }
            let speaker = found.player
            // Skip anyone who has changed clubs since the match.
            guard let speakerClub = found.club, speakerClub.id == home.id || speakerClub.id == away.id else { return nil }
            let speakerIsHome = speakerClub.id == home.id
            let scored = speakerIsHome ? result.homeGoals : result.awayGoals
            let conceded = speakerIsHome ? result.awayGoals : result.homeGoals
            let goals = result.goalEvents.filter { $0.playerId == speaker.id }.count
            let lines: [String]
            if goals >= 2 {
                lines = ["Match ball's coming home with me.", "Two goals, three points, one happy dressing room.",
                         "Strikers live for days like this."]
            } else if scored > conceded {
                lines = ["Days like this make the bad ones worth it.", "Three points. On to the next one.",
                         "Proud of this group. Big performance today.", "Hard work pays. Thanks for the noise today!"]
            } else if scored == conceded {
                lines = ["A point is a point. We go again.", "Not the result we wanted, but we keep building.",
                         "Draws are like pizza without toppings. Still edible."]
            } else {
                lines = ["Not good enough today. We'll respond.", "Heads up. Back to work on Monday.",
                         "Tough one. Sorry to everyone who travelled."]
            }
            let text = lines[rng.next(lines.count)]
            let fame = Double(speakerClub.reputation) * 0.6 + Double(speaker.overall) * 0.8
            let likes = Int(pow(fame / 40, 4) * Double(18_000 + rng.next(14_000)))
            let tag = "#\(Self.tagName(home.name))_\(result.homeGoals)-\(result.awayGoals)_\(Self.tagName(away.name))"
            let isUser = home.id == userClubId || away.id == userClubId
            return SocialPost(id: "r-\(fixture.id)", kind: isUser ? .myTeam : .general,
                              handle: "@" + Self.tagName(speaker.fullName), faceSeed: speaker.faceSeed,
                              clubId: speakerClub.id, text: text, hashtag: tag, date: fixture.date,
                              likes: likes, reposts: likes / (3 + rng.next(3)), involvesUser: isUser)
        }
    }

    private func transferPosts() -> [SocialPost] {
        let seasonStart = season.fixtures.map(\.date).min() ?? ""
        let recent = transferHistory.filter { $0.date >= String(seasonStart.prefix(4)) }.suffix(30)
        return recent.compactMap { record -> SocialPost? in
            guard let buyer = club(withId: record.toClubId) else { return nil }
            var rng = SocialRandom(seed: record.id)
            let lines = record.isLoan
                ? ["\(record.playerName) joins on loan from \(record.fromClubName). Welcome!",
                   "On loan and ready to go: welcome, \(record.playerName)."]
                : ["Pleased to confirm \(record.playerName) as our new player.",
                   "Welcome to the project, \(record.playerName). Ready to go to work.",
                   "Deal done. \(record.playerName) joins the family.",
                   "Smart pickup for the squad. Welcome, \(record.playerName)."]
            let likes = Int(pow(Double(buyer.reputation) / 45, 4) * Double(25_000 + rng.next(20_000)))
            let isUser = record.toClubId == userClubId || record.fromClubId == userClubId
            return SocialPost(id: "t-\(record.id)", kind: .transfer, handle: "@" + Self.tagName(buyer.name),
                              faceSeed: nil, clubId: buyer.id, text: lines[rng.next(lines.count)],
                              hashtag: record.fee > 0 && !record.isLoan ? "#\(Self.tagName(record.playerName))" : nil,
                              date: record.date, likes: likes, reposts: likes / 4, involvesUser: isUser)
        }
    }

    private func awardPosts() -> [SocialPost] {
        history.awards.suffix(8).compactMap { award -> SocialPost? in
            var rng = SocialRandom(seed: award.id)
            let clubMatch = clubs.first { $0.name == award.clubName }
            let lines = ["Congratulations \(award.playerName), the \(award.award)!",
                         "History made. \(award.playerName) wins the \(award.award)."]
            let likes = 900_000 + rng.next(1_800_000)
            return SocialPost(id: "a-\(award.id)", kind: .award, handle: "@" + Self.tagName(award.clubName),
                              faceSeed: nil, clubId: clubMatch?.id, text: lines[rng.next(lines.count)],
                              hashtag: "#\(Self.tagName(award.award))", date: "\(award.season)-06-30",
                              likes: likes, reposts: likes / 3, involvesUser: clubMatch?.id == userClubId)
        }
    }

    /// "Manchester United" → "Manchester_United".
    static func tagName(_ s: String) -> String {
        s.split(whereSeparator: { !$0.isLetter && !$0.isNumber }).joined(separator: "_")
    }
}

/// A tiny deterministic generator seeded from an id, so a post always reads
/// the same however often the feed is rebuilt.
private struct SocialRandom {
    private var state: UInt64
    init(seed: UUID) {
        var h: UInt64 = 0xcbf29ce484222325
        for b in seed.uuidString.utf8 { h = (h ^ UInt64(b)) &* 0x100000001b3 }
        state = h
    }
    mutating func next(_ bound: Int) -> Int {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return bound > 0 ? Int((state >> 33) % UInt64(bound)) : 0
    }
}
