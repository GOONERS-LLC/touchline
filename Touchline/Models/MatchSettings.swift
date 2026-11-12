//
//  MatchSettings.swift
//  Touchline
//
//  User preferences controlling how live matches are played back and how the
//  team is automatically managed during a match.
//

import Foundation

public struct MatchSettings: Codable, Hashable {

    /// Playback speed of the live match replay.
    public enum Speed: String, Codable, CaseIterable, Identifiable, Hashable {
        case slow = "Slow"
        case normal = "Normal"
        case fast = "Fast"
        case veryFast = "Very Fast"

        public var id: String { rawValue }

        /// Seconds between displayed minutes during replay.
        public var tickInterval: Double {
            switch self {
            case .slow: return 0.7
            case .normal: return 0.35
            case .fast: return 0.18
            case .veryFast: return 0.08
            }
        }

        public var displayName: String { rawValue }
    }

    /// When automatic substitutions should occur.
    public enum AutoSubTiming: String, Codable, CaseIterable, Identifiable, Hashable {
        case off = "Off"
        case halfTime = "At Half-Time"
        case secondHalf = "In the Second Half"
        case throughout = "Throughout"

        public var id: String { rawValue }
        public var displayName: String { rawValue }
    }

    /// How aggressively the assistant manager rotates players.
    public enum AutoSubAggression: String, Codable, CaseIterable, Identifiable, Hashable {
        case conservative = "Conservative"
        case balanced = "Balanced"
        case aggressive = "Aggressive"

        public var id: String { rawValue }
        public var displayName: String { rawValue }

        /// Fatigue percentage above which a tired player is replaced.
        public var fatigueThreshold: Double {
            switch self {
            case .conservative: return 78
            case .balanced: return 68
            case .aggressive: return 58
            }
        }

        /// Maximum substitutions the assistant will make.
        public var maxSubs: Int {
            switch self {
            case .conservative: return 3
            case .balanced: return 5
            case .aggressive: return 5
            }
        }
    }

    /// Playback speed for replaying a live match.
    public var speed: Speed
    /// Pause the replay at half-time to let the manager make changes.
    public var stopAtHalfTime: Bool
    /// When the assistant manager makes automatic substitutions.
    public var autoSubTiming: AutoSubTiming
    /// How aggressively the assistant rotates players.
    public var autoSubAggression: AutoSubAggression
    /// Before each match the assistant rests tired starters for fresh squad
    /// players of similar quality (manager mode).
    public var assistantRotatesTiredPlayers: Bool
    /// Continue shows the days ticking by on an animated calendar rather than
    /// jumping straight to the next match day.
    public var animateCalendar: Bool
    /// The animated calendar stops to show important new mail.
    public var pauseCalendarForMail: Bool

    public init(
        speed: Speed = .normal,
        stopAtHalfTime: Bool = true,
        autoSubTiming: AutoSubTiming = .secondHalf,
        autoSubAggression: AutoSubAggression = .balanced,
        assistantRotatesTiredPlayers: Bool = false,
        animateCalendar: Bool = true,
        pauseCalendarForMail: Bool = true
    ) {
        self.speed = speed
        self.stopAtHalfTime = stopAtHalfTime
        self.autoSubTiming = autoSubTiming
        self.autoSubAggression = autoSubAggression
        self.assistantRotatesTiredPlayers = assistantRotatesTiredPlayers
        self.animateCalendar = animateCalendar
        self.pauseCalendarForMail = pauseCalendarForMail
    }

    private enum CodingKeys: String, CodingKey {
        case speed, stopAtHalfTime, autoSubTiming, autoSubAggression, assistantRotatesTiredPlayers, animateCalendar, pauseCalendarForMail
    }

    /// Tolerant decoding so settings saved by older versions still load.
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        speed = try c.decodeIfPresent(Speed.self, forKey: .speed) ?? .normal
        stopAtHalfTime = try c.decodeIfPresent(Bool.self, forKey: .stopAtHalfTime) ?? true
        autoSubTiming = try c.decodeIfPresent(AutoSubTiming.self, forKey: .autoSubTiming) ?? .secondHalf
        autoSubAggression = try c.decodeIfPresent(AutoSubAggression.self, forKey: .autoSubAggression) ?? .balanced
        assistantRotatesTiredPlayers = try c.decodeIfPresent(Bool.self, forKey: .assistantRotatesTiredPlayers) ?? false
        animateCalendar = try c.decodeIfPresent(Bool.self, forKey: .animateCalendar) ?? true
        pauseCalendarForMail = try c.decodeIfPresent(Bool.self, forKey: .pauseCalendarForMail) ?? true
    }
}
