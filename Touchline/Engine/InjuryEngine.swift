//
//  InjuryEngine.swift
//  Touchline
//
//  Injury risk, severity and recovery.
//
//  Modelled on the shape of elite football's injury data: most match
//  incidents are knocks a player runs off, a few keep him out for days, a
//  smaller share for weeks, and the odd one for months. Tired legs, a lack of
//  match fitness, age, the press and a player's own body all raise the risk;
//  a player who comes back too soon is the likeliest to break down again.
//  Recovery runs day by day and is quicker with good medical facilities and
//  a good physio.
//

import Foundation

public struct InjuryEngine {

    /// What happens to a player who gets hurt during a match.
    public enum MatchInjuryOutcome {
        /// Treated on the pitch, carries on; no time lost.
        case knock
        /// Hurt and playing through it; he will miss time afterwards.
        case playsOn(Injury)
        /// Cannot carry on.
        case forcedOff(Injury)
    }

    // MARK: - Player Traits

    /// Some bodies break down more than others. A hidden, fixed trait from
    /// 0.7 (rarely injured) to 1.5 (always in the treatment room).
    public static func proneness(of player: Player) -> Double {
        let seed = abs(player.id.uuidString.hashValueStable % 1000)
        var value = 0.7 + Double(seed % 61) / 100.0
        // A small share are genuinely injury-prone.
        if seed % 13 == 0 { value += 0.2 }
        return value
    }

    // MARK: - In-Match

    /// Relative risk (1.0 = a fit, rested, mid-career player) of something
    /// going wrong this minute.
    public static func matchInjuryRisk(
        player: Player,
        fatigue: Double,
        minute: Int,
        pressing: PressingIntensity,
        carryingKnock: Bool
    ) -> Double {
        var risk = proneness(of: player)
        // Short of match fitness: the classic soft-tissue injury.
        let fitness = player.matchFitness
        if fitness < 55 { risk *= 2.6 } else if fitness < 70 { risk *= 1.8 } else if fitness < 85 { risk *= 1.25 }
        // Tired legs in the closing stages.
        risk *= 1.0 + fatigue / 60.0
        if minute > 75 { risk *= 1.2 }
        // Older bodies.
        if player.age >= 33 { risk *= 1.6 } else if player.age >= 30 { risk *= 1.25 } else if player.age <= 19 { risk *= 1.1 }
        // Conditioning.
        risk *= 1.25 - Double(player.attributes.stamina + player.attributes.strength) / 400.0
        switch pressing {
        case .high: risk *= 1.2
        case .medium: break
        case .low: risk *= 0.9
        }
        if carryingKnock { risk *= 1.8 }
        // The factors overlap (an old, unfit, tired player is one risk, not
        // five stacked ones); uncapped, a tired squad broke down in clusters.
        return min(risk, 3.5)
    }

    /// How bad it is. About two in five are knocks he runs off.
    public static func matchInjury(player: Player, contact: Bool) -> MatchInjuryOutcome {
        let roll = Double.random(in: 0..<1)
        if roll < (contact ? 0.55 : 0.40) { return .knock }
        let injury = severity(contact: contact, player: player)
        // A minor strain or dead leg can be played through for a while.
        if injury.daysRemaining <= 7 && Double.random(in: 0..<1) < 0.45 {
            return .playsOn(injury)
        }
        return .forcedOff(injury)
    }

    /// A time-loss injury, roughly in elite football's proportions: about a
    /// third out for under a week, most of the rest one to six weeks, about
    /// one in eight two months or more, and a few season-threatening.
    /// Contact brings sprains, ligament damage and fractures; non-contact
    /// injuries are mostly muscular.
    static func severity(contact: Bool, player: Player) -> Injury {
        let roll = Double.random(in: 0..<100)
        let type: InjuryType
        if contact {
            switch roll {
            case ..<32: type = .minorKnock                   // bruising, dead leg: days
            case ..<56: type = .ankleSprain
            case ..<70: type = .muscleStrain
            case ..<78: type = .calfStrain
            case ..<88: type = .ankleLigament
            case ..<94: type = .brokenBone
            case ..<98.5: type = .kneeInjury
            default: type = .aclTear
            }
        } else {
            switch roll {
            case ..<28: type = .minorKnock                   // tightness, cramp: days
            case ..<50: type = .muscleStrain
            case ..<62: type = .calfStrain
            case ..<84: type = .hamstring
            case ..<90: type = .ankleSprain
            case ..<96: type = .kneeInjury
            case ..<98.8: type = .ankleLigament
            default: type = .aclTear
            }
        }
        let range = type.recoveryDaysRange
        var days = Int.random(in: range.lowerBound...range.upperBound)
        // Older players heal more slowly.
        if player.age >= 31 { days = Int(Double(days) * 1.15) }
        return Injury(type: type, days: days)
    }

    // MARK: - Training

    /// A training-ground injury for a fit player. Over a season a typical
    /// squad loses a handful of players this way; tired, unfit and
    /// injury-prone players most of all. Better medical facilities help.
    public static func trainingInjury(player: Player, medicalLevel: Int, days: Int = 7) -> Injury? {
        guard player.injury == nil else { return nil }
        var chance = 0.003 * Double(days) / 7.0
        chance *= proneness(of: player)
        if player.matchFitness < 60 { chance *= 1.6 }
        if player.age >= 32 { chance *= 1.4 }
        chance *= 1.2 - Double(max(1, min(5, medicalLevel))) * 0.08
        guard Double.random(in: 0..<1) < chance else { return nil }
        let roll = Double.random(in: 0..<1)
        let type: InjuryType = roll < 0.45 ? .minorKnock
            : roll < 0.7 ? .muscleStrain
            : roll < 0.82 ? .calfStrain
            : roll < 0.94 ? .hamstring
            : roll < 0.98 ? .ankleSprain
            : .ankleLigament
        let range = type.recoveryDaysRange
        return Injury(type: type, days: Int.random(in: range.lowerBound...range.upperBound))
    }

    // MARK: - Pre-Match Injury Risk Calculator

    /// Percentage risk (1-95) for squad management display.
    public static func calculateInjuryRisk(player: Player, pressing: PressingIntensity) -> Double {
        var risk = 3.0 * proneness(of: player)
        if player.matchFitness < 60 { risk += 25.0 } else if player.matchFitness < 75 { risk += 14.0 } else if player.matchFitness < 90 { risk += 5.0 }
        if player.age > 32 { risk += Double(player.age - 32) * 3.0 }
        if player.attributes.stamina < 60 { risk += Double(60 - player.attributes.stamina) * 0.3 }
        switch pressing {
        case .high: risk *= 1.35
        case .medium: break
        case .low: risk *= 0.80
        }
        return min(95.0, max(1.0, risk))
    }

    // MARK: - Recovery

    /// How fast injuries heal at a club: medical facilities (1-5) and the
    /// best physio's quality (0 = none, 1-5).
    public static func recoveryRate(medicalLevel: Int, physioQuality: Int) -> Double {
        let facilities = 1.0 + Double(max(1, min(5, medicalLevel)) - 3) * 0.05
        let physio = physioQuality == 0 ? 0.92 : 1.0 + Double(max(1, min(5, physioQuality)) - 3) * 0.05
        return facilities * physio
    }

    /// Advances an injured player's recovery by some days. On return he is
    /// short of match fitness and sharpness: the longer the lay-off, the more
    /// he needs games (and the more likely he is to break down if rushed).
    public static func recover(_ player: inout Player, days: Int, rate: Double) {
        guard var injury = player.injury else { return }
        let healed = Double(days) * rate + injury.carry
        let whole = Int(healed)
        injury.carry = healed - Double(whole)
        injury.daysRemaining -= whole
        if injury.daysRemaining <= 0 {
            let layOff = injury.totalDays
            player.injury = nil
            player.matchFitness = layOff >= 60 ? 55 : layOff >= 21 ? 65 : layOff >= 8 ? 78 : 88
            player.sharpness = min(player.sharpness, layOff >= 60 ? 35 : layOff >= 21 ? 50 : 70)
        } else {
            player.injury = injury
        }
    }
}
