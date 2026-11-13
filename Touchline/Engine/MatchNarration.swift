//
//  MatchNarration.swift
//  Touchline
//
//  Commentary for the finer grain of a match: saves and misses pitched to
//  how good the chance was (not every save is "sensational", not every miss
//  a "sitter"), blocks, knocks, players hobbling on, and substitutions that
//  say why they were made.
//

import Foundation

extension Commentary {

    // MARK: - Shots by quality

    /// A save, described according to the chance (xG) it stopped.
    public static func save(keeper: Player, shooter: Player, keeperClub: Club, minute: Int, isHome: Bool, quality: Double)
        -> (short: String, detail: String) {
        if quality >= 0.3 {
            return save(keeper: keeper, shooter: shooter, keeperClub: keeperClub, minute: minute, isHome: isHome)
        }
        let k = keeper.fullName, s = shooter.fullName
        if quality >= 0.12 {
            let lines = [
                "\(s) gets a clean strike away from inside the box, but \(k) is down well to push it round the post.",
                "Good save from \(k), standing firm to block \(s)'s shot from close range.",
                "\(s) drives it low towards the far corner; \(k) gets across and turns it away.",
                "\(k) reads \(s)'s near-post effort and smothers it at the second attempt."
            ]
            return ("Saved: \(keeper.displayName) denies \(shooter.displayName) \(minute)'", lines.randomElement()!)
        }
        let lines = [
            "\(s) tries his luck from distance. Straight at \(k), who gathers comfortably.",
            "A tame effort from \(s) rolls through to \(k).",
            "\(s) hits it first time from the edge of the area; \(k) holds on without fuss.",
            "Half-chance for \(s), but the shot lacks power and \(k) collects."
        ]
        return ("Shot: \(shooter.displayName), held by \(keeper.displayName) \(minute)'", lines.randomElement()!)
    }

    /// A miss, described according to the chance (xG) it wasted.
    public static func miss(shooter: Player, club: Club, minute: Int, isWoodwork: Bool, quality: Double)
        -> (short: String, detail: String) {
        if isWoodwork || quality >= 0.3 {
            return miss(shooter: shooter, club: club, minute: minute, isWoodwork: isWoodwork)
        }
        let s = shooter.fullName
        if quality >= 0.1 {
            let lines = [
                "\(s) finds a yard of space in the box but drags his shot wide of the far post.",
                "Decent opening for \(club.name): \(s) meets the cross but his header goes over.",
                "\(s) gets on the end of a cut-back and side-foots it the wrong side of the post.",
                "\(s) shoots across goal from an angle. Wide."
            ]
            return ("Wide: \(shooter.displayName) \(minute)'", lines.randomElement()!)
        }
        let lines = [
            "\(s) has a go from 30 yards. It sails well over.",
            "Ambitious from \(s), whose long-range effort never troubles the target.",
            "\(s) snatches at a half-chance and slices it into the stand.",
            "Speculative from \(s). Off target."
        ]
        return ("Off target: \(shooter.displayName) \(minute)'", lines.randomElement()!)
    }

    public static func blockedShot(shooter: Player, club: Club, defending: Club, minute: Int) -> (short: String, detail: String) {
        let lines = [
            "\(shooter.fullName) shapes to shoot from inside the area, but a \(defending.name) defender throws himself in the way.",
            "Big block! \(shooter.fullName)'s goal-bound effort cannons off a body in the six-yard box.",
            "\(club.name) work it to \(shooter.fullName), whose shot is charged down at the last moment.",
            "Brave defending from \(defending.name): \(shooter.fullName)'s strike is blocked on the line."
        ]
        return ("Blocked: \(shooter.displayName) \(minute)'", lines.randomElement()!)
    }

    public static func freeKickSaved(taker: Player, club: Club, minute: Int) -> (short: String, detail: String) {
        let lines = [
            "\(taker.fullName) curls the free kick over the wall, but the keeper is equal to it.",
            "\(taker.fullName) goes for goal from the set piece. Saved, low to the keeper's left.",
            "Free kick in a dangerous spot. \(taker.fullName) hits it well, but straight at the keeper."
        ]
        return ("Free kick: \(taker.displayName), saved \(minute)'", lines.randomElement()!)
    }

    // MARK: - Discipline

    public static func timeWastingBooking(player: Player, club: Club, minute: Int) -> (short: String, detail: String) {
        let lines = [
            "\(player.fullName) takes an age over the restart and the referee has seen enough. Booked for time-wasting.",
            "\(club.name) are running the clock down and \(player.fullName) pays for it with a yellow card.",
            "The referee books \(player.fullName) for delaying the restart. The home crowd make their feelings known."
        ]
        return ("YELLOW CARD — \(player.displayName) (\(club.name)) \(minute)'", lines.randomElement()!)
    }

    // MARK: - Injuries

    public static func knock(player: Player, club: Club, minute: Int) -> (short: String, detail: String) {
        let lines = [
            "\(player.fullName) needs treatment after a heavy challenge, but he is back on his feet and carries on.",
            "\(player.fullName) goes down holding his ankle. The physio has a look; he will try to run it off.",
            "A knock for \(player.fullName), who limps for a few moments before carrying on. \(club.name)'s bench will be watching him.",
            "Play is held up while \(player.fullName) is treated for a dead leg. He continues, gingerly."
        ]
        return ("Knock: \(player.displayName) (\(club.name)) \(minute)'", lines.randomElement()!)
    }

    public static func playingThroughInjury(player: Player, club: Club, minute: Int) -> (short: String, detail: String) {
        let lines = [
            "\(player.fullName) pulls up and grabs the back of his thigh. He insists he can carry on, but he is clearly not right.",
            "\(player.fullName) is hobbling. He waves away the physio for now, but \(club.name) may need to make a change.",
            "Something has gone for \(player.fullName). He is still out there, but he is a passenger at the moment."
        ]
        return ("Hurt: \(player.displayName) (\(club.name)) is struggling \(minute)'", lines.randomElement()!)
    }

    // MARK: - Substitutions

    static func substitution(playerIn: Player, playerOut: Player, club: Club, minute: Int, reason: MatchEngine.SubReason)
        -> (short: String, detail: String) {
        let short = "SUB — \(club.name): \(playerIn.displayName) ON, \(playerOut.displayName) OFF \(minute)'"
        let i = playerIn.fullName, o = playerOut.fullName
        let detail: String
        switch reason {
        case .injury:
            detail = "\(o) cannot continue and is helped off. \(i) comes on in his place."
        case .fatigue:
            detail = [
                "\(o) has run himself into the ground and makes way for fresh legs: \(i) is on.",
                "Tired legs for \(o), who is replaced by \(i).",
                "\(club.name) freshen things up: \(i) on for the weary \(o)."
            ].randomElement()!
        case .chasing:
            detail = "\(club.name) need a goal. \(o) is sacrificed for another attacker, \(i)."
        case .protecting:
            detail = "\(club.name) look to shut up shop: \(i) comes on to shore things up, \(o) makes way."
        case .booked:
            detail = "\(o), on a yellow card and living dangerously, is taken off before he gets a second. \(i) replaces him."
        case .poorForm:
            detail = "It hasn't been \(o)'s day, and the manager has seen enough. \(i) is on."
        case .tactical:
            detail = "A tactical change for \(club.name): \(i) on, \(o) off."
        case .manager:
            detail = "The manager makes his move: \(i) comes on for \(o) with instructions from the touchline."
        }
        return (short, detail)
    }
}
