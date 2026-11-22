//
//  MatchNarration.swift
//  Touchline
//
//  Commentary for the finer grain of a match: saves and misses pitched to
//  how good the chance was (not every save is "sensational", not every miss
//  a "sitter"), blocks, knocks, players hobbling on, and substitutions that
//  say why they were made. The lines themselves live in CommentaryLines.
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
        if quality >= 0.12 {
            return ("Saved: \(keeper.displayName) denies \(shooter.displayName) \(minute)'",
                    CommentaryLines.goodSave(keeper: keeper, shooter: shooter).randomElement()!)
        }
        return ("Shot: \(shooter.displayName), held by \(keeper.displayName) \(minute)'",
                CommentaryLines.routineSave(keeper: keeper, shooter: shooter).randomElement()!)
    }

    /// A miss, described according to the chance (xG) it wasted.
    public static func miss(shooter: Player, club: Club, minute: Int, isWoodwork: Bool, quality: Double)
        -> (short: String, detail: String) {
        if isWoodwork || quality >= 0.3 {
            return miss(shooter: shooter, club: club, minute: minute, isWoodwork: isWoodwork)
        }
        if quality >= 0.1 {
            return ("Wide: \(shooter.displayName) \(minute)'",
                    CommentaryLines.decentMiss(shooter: shooter, club: club).randomElement()!)
        }
        return ("Off target: \(shooter.displayName) \(minute)'",
                CommentaryLines.poorMiss(shooter: shooter, club: club).randomElement()!)
    }

    public static func blockedShot(shooter: Player, club: Club, defending: Club, minute: Int) -> (short: String, detail: String) {
        ("Blocked: \(shooter.displayName) \(minute)'",
         CommentaryLines.blocked(shooter: shooter, club: club, defending: defending).randomElement()!)
    }

    public static func freeKickSaved(taker: Player, club: Club, minute: Int) -> (short: String, detail: String) {
        ("Free kick: \(taker.displayName), saved \(minute)'",
         CommentaryLines.freeKickSaved(taker: taker).randomElement()!)
    }

    // MARK: - Discipline

    public static func timeWastingBooking(player: Player, club: Club, minute: Int) -> (short: String, detail: String) {
        ("YELLOW CARD — \(player.displayName) (\(club.name)) \(minute)'",
         CommentaryLines.timeWasting(player: player, club: club).randomElement()!)
    }

    // MARK: - Injuries

    public static func knock(player: Player, club: Club, minute: Int) -> (short: String, detail: String) {
        ("Knock: \(player.displayName) (\(club.name)) \(minute)'",
         CommentaryLines.knock(player: player, club: club).randomElement()!)
    }

    public static func playingThroughInjury(player: Player, club: Club, minute: Int) -> (short: String, detail: String) {
        ("Hurt: \(player.displayName) (\(club.name)) is struggling \(minute)'",
         CommentaryLines.playingThroughInjury(player: player, club: club).randomElement()!)
    }

    /// The sentence added to an injury once his replacement comes on.
    static func injuryReplacement(incoming: Player, injured: Player) -> String {
        CommentaryLines.injuryReplacement(incoming: incoming, injured: injured).randomElement()!
    }

    // MARK: - Substitutions

    static func substitution(playerIn: Player, playerOut: Player, club: Club, minute: Int, reason: MatchEngine.SubReason)
        -> (short: String, detail: String) {
        let short = reason == .injury
            ? "SUB — \(club.name): \(playerIn.displayName) ON for the injured \(playerOut.displayName) \(minute)'"
            : "SUB — \(club.name): \(playerIn.displayName) ON, \(playerOut.displayName) OFF \(minute)'"
        return (short, CommentaryLines.substitution(incoming: playerIn, outgoing: playerOut, club: club, reason: reason).randomElement()!)
    }
}
