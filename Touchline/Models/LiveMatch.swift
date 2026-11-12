//
//  LiveMatch.swift
//  Touchline
//
//  A match being played live, stopped at half-time so the manager can make
//  substitutions and change tactics before the second half.
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

    /// The first half: score, events and stats.
    public var firstHalf: MatchResult { paused.snapshot }
}
