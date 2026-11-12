//
//  Haptics.swift
//  Touchline
//
//  Vibrations for goals, cards, saves and the woodwork during live matches.
//  Turned on or off in Settings (Haptics).
//

import UIKit

@MainActor
public enum Haptics {
    nonisolated public static let enabledKey = "tlHapticsEnabled"

    private static let medium = UIImpactFeedbackGenerator(style: .medium)
    private static let heavy = UIImpactFeedbackGenerator(style: .heavy)
    private static let rigid = UIImpactFeedbackGenerator(style: .rigid)
    private static let notifier = UINotificationFeedbackGenerator()

    private static var on: Bool {
        UserDefaults.standard.object(forKey: enabledKey) as? Bool ?? true
    }

    /// A goal: a triple thump for your side, an error buzz against.
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

    public static func matchEvent(_ type: MatchEventType) {
        guard on else { return }
        switch type {
        case .woodwork: rigid.impactOccurred(intensity: 1.0)
        case .shotOnTarget: medium.impactOccurred(intensity: 0.7)
        case .yellowCard: notifier.notificationOccurred(.warning)
        case .redCard, .secondYellow: notifier.notificationOccurred(.error)
        case .halfTime, .fullTime, .kickOff: rigid.impactOccurred(intensity: 0.6)
        default: break
        }
    }
}
