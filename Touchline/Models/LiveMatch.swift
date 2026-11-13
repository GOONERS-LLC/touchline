//
//  LiveMatch.swift
//  Touchline
//
//  A match being played live, a minute at a time, so the manager can stop
//  it whenever he likes to make substitutions and change tactics.
//

import Foundation

public struct LiveMatchSession {
    public let fixtureId: UUID
    public var paused: MatchEngine.PausedMatch
    var home: Club
    var away: Club
    var homeSuspensions: [UUID: Int]
    var awaySuspensions: [UUID: Int]
    var config: MatchEngine.SimulationConfig
    /// Set when the final whistle has gone; written to the world by
    /// `simulateFixture(id:)`.
    var finished: Finished? = nil

    struct Finished {
        var result: MatchResult
        var home: Club
        var away: Club
    }

    /// The match so far: score, events and stats.
    public var firstHalf: MatchResult { finished?.result ?? paused.snapshot }
    /// The match so far.
    public var soFar: MatchResult { finished?.result ?? paused.snapshot }
    /// The last minute played.
    public var minutePlayed: Int { finished == nil ? paused.minutePlayed : max(90, paused.maxMinute) }
    public var isFinished: Bool { finished != nil }
}
