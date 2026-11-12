//
//  ClubRecords.swift
//  Touchline
//
//  Records set since the user took charge: the biggest crowd, the biggest
//  win and the heaviest defeat. Breaking one makes the news, and in the
//  owner career it lands on the chairman's desk as a card.
//

import Foundation

public struct ClubRecords: Codable, Hashable {
    public var clubId: UUID?
    public var matchesTracked: Int = 0
    public var recordCrowd: Int = 0
    public var biggestWin: Int = 0
    public var biggestWinText: String = ""
    public var heaviestDefeat: Int = 0
    public var heaviestDefeatText: String = ""

    public init() {}

    private enum CodingKeys: String, CodingKey {
        case clubId, matchesTracked, recordCrowd, biggestWin, biggestWinText, heaviestDefeat, heaviestDefeatText
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        clubId = try c.decodeIfPresent(UUID.self, forKey: .clubId)
        matchesTracked = try c.decodeIfPresent(Int.self, forKey: .matchesTracked) ?? 0
        recordCrowd = try c.decodeIfPresent(Int.self, forKey: .recordCrowd) ?? 0
        biggestWin = try c.decodeIfPresent(Int.self, forKey: .biggestWin) ?? 0
        biggestWinText = try c.decodeIfPresent(String.self, forKey: .biggestWinText) ?? ""
        heaviestDefeat = try c.decodeIfPresent(Int.self, forKey: .heaviestDefeat) ?? 0
        heaviestDefeatText = try c.decodeIfPresent(String.self, forKey: .heaviestDefeatText) ?? ""
    }
}

/// A record just broken, waiting to be shown as a card.
public struct ClubRecordMoment: Codable, Hashable {
    public var title: String
    public var detail: String
    public var icon: String
}

extension GameState {

    /// Checks the user's latest match against the club records.
    func checkClubRecords(_ fixture: Fixture) {
        guard let uid = userClubId, let result = fixture.result, fixture.involves(clubId: uid),
              let me = userClub, let opponentId = fixture.opponentId(for: uid),
              let opponent = club(withId: opponentId) else { return }
        // Records restart when the user moves to another club.
        if clubRecords.clubId != uid {
            clubRecords = ClubRecords()
            clubRecords.clubId = uid
        }
        clubRecords.matchesTracked += 1
        let announce = clubRecords.matchesTracked > 3
        let since = gameMode == .createClub ? "since you took over as chairman" : "since you took charge"
        let isHome = fixture.homeClubId == uid
        let scored = isHome ? result.homeGoals : result.awayGoals
        let conceded = isHome ? result.awayGoals : result.homeGoals
        let score = "\(me.name) \(scored)-\(conceded) \(opponent.name)"
        var moments: [ClubRecordMoment] = []

        if isHome && result.attendance > clubRecords.recordCrowd {
            if announce && clubRecords.recordCrowd > 0 {
                moments.append(ClubRecordMoment(
                    title: "New Record Crowd",
                    detail: "The attendance of \(result.attendance.formatted()) for \(me.name)'s match against \(opponent.name) at \(me.stadium) was the highest \(since).",
                    icon: "person.3.fill"))
            }
            clubRecords.recordCrowd = result.attendance
        }
        let margin = scored - conceded
        if margin > clubRecords.biggestWin {
            if announce && clubRecords.biggestWin > 0 {
                moments.append(ClubRecordMoment(
                    title: "New Record: Biggest Win",
                    detail: "\(score) is the biggest win \(since). The previous best was \(clubRecords.biggestWinText).",
                    icon: "flame.fill"))
            }
            clubRecords.biggestWin = margin
            clubRecords.biggestWinText = score
        }
        if -margin > clubRecords.heaviestDefeat {
            if announce && clubRecords.heaviestDefeat > 0 {
                moments.append(ClubRecordMoment(
                    title: "New Record: Heaviest Defeat",
                    detail: "\(me.name)'s \(conceded)-\(scored) defeat to \(opponent.name) is the heaviest \(since).",
                    icon: "cloud.rain.fill"))
            }
            clubRecords.heaviestDefeat = -margin
            clubRecords.heaviestDefeatText = score
        }
        for moment in moments {
            addNews(headline: moment.title, body: moment.detail, category: .general, sender: "Club Historian")
        }
        if gameMode == .createClub, let first = moments.first {
            pendingRecordMoment = first
        }
    }
}
