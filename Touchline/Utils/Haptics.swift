//
//  Haptics.swift
//  Touchline
//
//  Device-wide feedback preferences (stored per device, not per save) and a
//  small haptics vocabulary used across the app and during live matches.
//

import UIKit
import SwiftUI

/// Keys for device-level preferences shown under Settings, Accessibility and Feedback.
public enum PrefKey {
    public static let haptics = "pref.hapticsEnabled"
    public static let crowd = "pref.crowdEnabled"
    public static let crowdVolume = "pref.crowdVolume"
    public static let commentaryDetail = "pref.commentaryDetail"
    public static let waitForVoiceOver = "pref.waitForVoiceOver"
    public static let announceScore = "pref.announceScoreAfterGoals"
    public static let minuteUpdates = "pref.minuteUpdates"
}

/// How much of the live commentary is read aloud and listed.
public enum CommentaryDetail: String, CaseIterable, Identifiable {
    case everything = "Everything"
    case highlights = "Shots, cards and goals"
    case keyMoments = "Key moments only"

    public var id: String { rawValue }

    public var description: String {
        switch self {
        case .everything: return "Every foul, corner, offside, shot, save and booking is described."
        case .highlights: return "Shots, saves, woodwork, cards, injuries and goals."
        case .keyMoments: return "Goals, red cards, injuries, half-time and full-time only."
        }
    }

    /// Whether an event of this type is spoken and listed at this detail level.
    public func includes(_ type: MatchEventType) -> Bool {
        switch self {
        case .everything:
            return true
        case .highlights:
            switch type {
            case .foul, .corner, .offside, .freeKick: return false
            default: return true
            }
        case .keyMoments:
            return type.isMajorEvent
        }
    }
}

public enum Preferences {
    private static let defaults = UserDefaults.standard

    public static func registerDefaults() {
        defaults.register(defaults: [
            PrefKey.haptics: true,
            PrefKey.crowd: true,
            PrefKey.crowdVolume: 0.7,
            PrefKey.commentaryDetail: CommentaryDetail.everything.rawValue,
            PrefKey.waitForVoiceOver: true,
            PrefKey.announceScore: true,
            PrefKey.minuteUpdates: true,
        ])
    }

    public static var hapticsEnabled: Bool { defaults.bool(forKey: PrefKey.haptics) }
    public static var crowdEnabled: Bool { defaults.bool(forKey: PrefKey.crowd) }
    public static var crowdVolume: Float { Float(defaults.double(forKey: PrefKey.crowdVolume)) }
    public static var waitForVoiceOver: Bool { defaults.bool(forKey: PrefKey.waitForVoiceOver) }
    public static var announceScore: Bool { defaults.bool(forKey: PrefKey.announceScore) }
    public static var minuteUpdates: Bool { defaults.bool(forKey: PrefKey.minuteUpdates) }
    public static var commentaryDetail: CommentaryDetail {
        CommentaryDetail(rawValue: defaults.string(forKey: PrefKey.commentaryDetail) ?? "") ?? .everything
    }
}

@MainActor
public enum Haptics {
    private static let light = UIImpactFeedbackGenerator(style: .light)
    private static let medium = UIImpactFeedbackGenerator(style: .medium)
    private static let heavy = UIImpactFeedbackGenerator(style: .heavy)
    private static let rigid = UIImpactFeedbackGenerator(style: .rigid)
    private static let notifier = UINotificationFeedbackGenerator()
    private static let selector = UISelectionFeedbackGenerator()

    private static var on: Bool { Preferences.hapticsEnabled }

    /// Buttons and taps.
    public static func tap() { guard on else { return }; light.impactOccurred() }
    public static func selection() { guard on else { return }; selector.selectionChanged() }
    public static func success() { guard on else { return }; notifier.notificationOccurred(.success) }
    public static func warning() { guard on else { return }; notifier.notificationOccurred(.warning) }
    public static func error() { guard on else { return }; notifier.notificationOccurred(.error) }

    /// A goal: a rising triple thump.
    public static func goal(forUser: Bool) {
        guard on else { return }
        if forUser {
            heavy.impactOccurred(intensity: 1.0)
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 120_000_000)
                heavy.impactOccurred(intensity: 0.8)
                try? await Task.sleep(nanoseconds: 120_000_000)
                notifier.notificationOccurred(.success)
            }
        } else {
            notifier.notificationOccurred(.error)
        }
    }

    /// Feedback for the smaller moments of a live match.
    public static func matchEvent(_ type: MatchEventType) {
        guard on else { return }
        switch type {
        case .woodwork: rigid.impactOccurred(intensity: 1.0)
        case .shotOnTarget, .shotBlocked: medium.impactOccurred(intensity: 0.7)
        case .chanceMissed, .chance: light.impactOccurred(intensity: 0.6)
        case .yellowCard: notifier.notificationOccurred(.warning)
        case .redCard, .secondYellow: notifier.notificationOccurred(.error)
        case .injury: medium.impactOccurred(intensity: 0.5)
        case .halfTime, .fullTime, .kickOff: rigid.impactOccurred(intensity: 0.6)
        case .foul: light.impactOccurred(intensity: 0.4)
        default: break
        }
    }
}
