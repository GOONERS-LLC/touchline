//
//  Commentary.swift
//  Touchline
//
//  Created for Touchline - iOS Football Manager Game.
//  Dynamic, context-aware match commentary text engine. Generates rich narrative descriptions,
//  crowd reactions, goal buildups, close calls, and atmospheric color.
//

import Foundation

public struct Commentary {
    
    // MARK: - Goal Commentary
    
    public enum GoalType: CaseIterable {
        case tapIn
        case toweringHeader
        case longRangeScreamer
        case clinicalPenalty
        case curlingFreeKick
        case soloRun
        case reboundAfterSpill
        case glancingCornerHeader
        case cheekyChip
        case thunderousVolley
        case deflectedStrike
        case counterAttackBreakaway
        case divingHeader
        case sideFootCurler
        case oneOnOneFinish
        case bicycleKick
        case cutback
        case nearPostFinish
        case nutmegKeeper
        case firstTimeFinish
        case goalmouthScramble
        case pressingTurnover
        case backheelFlick
        case overlapCross
        case lobFromDistance
        case tikiTakaMove
        case driveIntoBox
    }

    /// Generates short header and rich expanded narrative for a goal. The
    /// finish suits the scorer (a centre-back heads it, a winger dribbles,
    /// a deep midfielder shoots from range) and every part of the text is
    /// drawn from its own pool, so the same goal rarely reads twice.
    public static func goal(
        scorer: Player,
        assister: Player?,
        club: Club,
        opponent: Club,
        minute: Int,
        homeGoals: Int,
        awayGoals: Int,
        isHome: Bool,
        goalType: GoalType? = nil
    ) -> (short: String, detail: String) {
        let type = goalType ?? pickGoalType(scorer: scorer, hasAssist: assister != nil)
        let shortText = "GOAL! \(scorer.displayName) (\(club.name)) \(minute)' [\(homeGoals)-\(awayGoals)]"
        let keeper = opponent.startingXIPlayers.first { $0.primaryPosition == .GK }?.lastName ?? "the keeper"
        var body = GoalLines.body(type: type, scorer: scorer, assister: assister, keeper: keeper,
                                  club: club, opponent: opponent, minute: minute)
        // Free kicks and penalties draw on bigger pools of their own.
        if type == .curlingFreeKick && Double.random(in: 0..<1) < 0.7 {
            body = CommentaryLines.freeKickGoal(taker: scorer, keeper: keeper).randomElement()!
        } else if type == .clinicalPenalty && Double.random(in: 0..<1) < 0.7 {
            body = CommentaryLines.penaltyGoal(taker: scorer, keeper: keeper).randomElement()!
        }
        let teamGoals = isHome ? homeGoals : awayGoals
        let oppGoals = isHome ? awayGoals : homeGoals
        let situation = GoalLines.situation(club: club, opponent: opponent, minute: minute,
                                            teamGoals: teamGoals, oppGoals: oppGoals, scorer: scorer)
        let crowd = crowdReactionText(isHome: isHome, club: club, minute: minute,
                                      isLateWinner: minute > 82 && teamGoals == oppGoals + 1)
        // A little extra, now and then: credit for the provider, the keeper's
        // reaction, the celebration.
        var extras: [String] = []
        if let assister, Double.random(in: 0..<1) < 0.5 {
            extras.append(CommentaryLines.assistPraise(assister: assister, scorer: scorer).randomElement()!)
        }
        if type != .clinicalPenalty && Double.random(in: 0..<1) < 0.3 {
            extras.append(CommentaryLines.keeperReaction(keeper: keeper).randomElement()!)
        }
        if Double.random(in: 0..<1) < 0.6 {
            extras.append(CommentaryLines.celebration(scorer: scorer, club: club).randomElement()!)
        }
        let extra = extras.isEmpty ? "" : " " + extras.joined(separator: " ")
        return (shortText, "\(body) \(situation)\(extra)\n\n\(crowd)")
    }

    /// A finish that suits the scorer's position and strengths.
    static func pickGoalType(scorer: Player, hasAssist: Bool) -> GoalType {
        let a = scorer.attributes
        let category = scorer.primaryPosition.category
        func w(_ v: Int) -> Double { max(0.2, Double(v - 40) / 20) }
        var weights: [(GoalType, Double)] = []
        switch category {
        case .defender, .goalkeeper:
            weights = [(.toweringHeader, 3 * w(a.heading)), (.goalmouthScramble, 2.5), (.reboundAfterSpill, 1.5),
                       (.thunderousVolley, 1), (.longRangeScreamer, 0.6 * w(a.longShots)), (.divingHeader, 1),
                       (.deflectedStrike, 1), (.overlapCross, 0.8), (.driveIntoBox, 0.6)]
        case .midfielder:
            weights = [(.longRangeScreamer, 2 * w(a.longShots)), (.sideFootCurler, 1.6 * w(a.shooting)),
                       (.driveIntoBox, 1.4 * w(a.dribbling)), (.cutback, 1.6), (.firstTimeFinish, 1.4),
                       (.tikiTakaMove, 1.2 * w(a.passing)), (.pressingTurnover, 1), (.deflectedStrike, 1),
                       (.reboundAfterSpill, 1), (.soloRun, 0.8 * w(a.dribbling)), (.thunderousVolley, 0.9),
                       (.toweringHeader, 0.5 * w(a.heading)), (.lobFromDistance, 0.3 * w(a.longShots)),
                       (.counterAttackBreakaway, 0.8 * w(a.pace)), (.backheelFlick, 0.25)]
        case .forward:
            weights = [(.tapIn, 2), (.oneOnOneFinish, 1.6 * w(a.composure)), (.toweringHeader, 1.3 * w(a.heading)),
                       (.cutback, 1.5), (.nearPostFinish, 1.4), (.firstTimeFinish, 1.4), (.reboundAfterSpill, 1.1),
                       (.soloRun, 1.2 * w(a.dribbling)), (.counterAttackBreakaway, 1.2 * w(a.pace)),
                       (.cheekyChip, 0.8 * w(a.composure)), (.nutmegKeeper, 0.7), (.sideFootCurler, 1 * w(a.shooting)),
                       (.longRangeScreamer, 0.6 * w(a.longShots)), (.divingHeader, 0.6), (.goalmouthScramble, 0.8),
                       (.pressingTurnover, 0.9), (.thunderousVolley, 0.8), (.backheelFlick, 0.35),
                       (.overlapCross, 0.9), (.driveIntoBox, 0.9 * w(a.dribbling)), (.deflectedStrike, 0.6),
                       (.bicycleKick, a.agility >= 70 ? 0.15 : 0.03)]
        }
        if !hasAssist {
            // Unassisted goals come from individual efforts and loose balls.
            let solo: Set<GoalType> = [.longRangeScreamer, .soloRun, .reboundAfterSpill, .deflectedStrike,
                                       .goalmouthScramble, .pressingTurnover, .driveIntoBox, .lobFromDistance,
                                       .sideFootCurler, .nutmegKeeper]
            weights = weights.filter { solo.contains($0.0) }
            if weights.isEmpty { weights = [(.soloRun, 1), (.reboundAfterSpill, 1), (.longRangeScreamer, 1)] }
        }
        let total = weights.reduce(0) { $0 + $1.1 }
        var roll = Double.random(in: 0..<total)
        for (type, weight) in weights {
            roll -= weight
            if roll < 0 { return type }
        }
        return weights.last?.0 ?? .tapIn
    }

    // MARK: - Chances & Shots

    public static func chance(
        shooter: Player,
        assister: Player?,
        club: Club,
        minute: Int,
        isHome: Bool
    ) -> (short: String, detail: String) {
        let shortText = "CHANCE! \(shooter.displayName) (\(club.name)) \(minute)'"
        return (shortText, CommentaryLines.chance(shooter: shooter, assister: assister, club: club).randomElement()!)
    }

    // MARK: - Saves

    public static func save(
        keeper: Player,
        shooter: Player,
        keeperClub: Club,
        minute: Int,
        isHome: Bool
    ) -> (short: String, detail: String) {
        let shortText = "SENSATIONAL SAVE! \(keeper.displayName) \(minute)'"
        return (shortText, CommentaryLines.bigSave(keeper: keeper, shooter: shooter, keeperClub: keeperClub).randomElement()!)
    }

    // MARK: - Misses & Woodwork

    public static func miss(
        shooter: Player,
        club: Club,
        minute: Int,
        isWoodwork: Bool = false
    ) -> (short: String, detail: String) {
        if isWoodwork {
            return ("OFF THE WOODWORK! \(shooter.displayName) \(minute)'",
                    CommentaryLines.woodwork(shooter: shooter).randomElement()!)
        }
        return ("CHANCE MISSED! \(shooter.displayName) \(minute)'",
                CommentaryLines.bigMiss(shooter: shooter, club: club).randomElement()!)
    }

    // MARK: - Fouls & Disciplinary Cards

    /// A foul that brings nothing more than a free kick.
    public static func foul(player: Player, victim: Player?, club: Club, minute: Int) -> (short: String, detail: String) {
        let against = victim.map { " on \($0.displayName)" } ?? ""
        return ("Foul: \(player.displayName) (\(club.name))\(against) \(minute)'",
                CommentaryLines.foul(player: player, victim: victim, club: club).randomElement()!)
    }

    public static func card(
        player: Player,
        club: Club,
        isRed: Bool,
        isSecondYellow: Bool = false,
        minute: Int,
        victim: Player? = nil
    ) -> (short: String, detail: String) {
        let minuteStr = "\(minute)'"
        if isSecondYellow {
            return ("RED CARD (SECOND YELLOW)! \(player.displayName) \(minuteStr)",
                    CommentaryLines.secondYellow(player: player, victim: victim, club: club).randomElement()!)
        }
        if isRed {
            return ("STRAIGHT RED CARD! \(player.displayName) \(minuteStr)",
                    CommentaryLines.straightRed(player: player, victim: victim, club: club).randomElement()!)
        }
        return ("YELLOW CARD — \(player.displayName) (\(club.name)) \(minuteStr)",
                CommentaryLines.yellow(player: player, victim: victim, club: club).randomElement()!)
    }

    // MARK: - Injuries & Substitutions

    public static func injury(
        player: Player,
        club: Club,
        minute: Int,
        injuryType: InjuryType
    ) -> (short: String, detail: String) {
        let shortText = "INJURY — \(player.displayName) (\(club.name)) \(minute)'"
        return (shortText, CommentaryLines.injuryOff(player: player, club: club, injury: injuryType.commentaryPhrase).randomElement()!)
    }

    public static func substitution(
        playerIn: Player,
        playerOut: Player,
        club: Club,
        minute: Int
    ) -> (short: String, detail: String) {
        substitution(playerIn: playerIn, playerOut: playerOut, club: club, minute: minute, reason: .manager)
    }

    // MARK: - Atmospheric & Tactical Color
    
    public static func atmosphere(
        homeClub: Club,
        awayClub: Club,
        minute: Int,
        homeGoals: Int,
        awayGoals: Int
    ) -> (short: String, detail: String) {
        let diff = homeGoals - awayGoals
        let isLate = minute >= 75
        let isEarly = minute <= 20
        
        let templates: [String]
        if isEarly {
            templates = [
                "Both teams feeling each other out in the opening exchanges. The tempo is brisk as they battle for dominance in the midfield.",
                "\(homeClub.name) look to establish an early rhythm with sharp, short passing along the back line.",
                "Loud and vocal support from both sets of fans as the teams settle into their tactical formations.",
                "High pressing from \(homeClub.name) early on, forcing \(awayClub.name) into rushed clearances."
            ]
        } else if isLate {
            if diff == 0 {
                templates = [
                    "You can cut the tension with a knife! Every tackle, every pass is celebrated like a goal. Who will find the decisive moment?",
                    "Nail-biting final minutes here at \(homeClub.stadium). Neither manager dares to blink as both teams push for the winner.",
                    "Fingernails being chewed to the bone in the stands! A single mistake now will decide the contest."
                ]
            } else if diff == 1 || diff == -1 {
                let leadingClub = diff > 0 ? homeClub.name : awayClub.name
                let trailingClub = diff > 0 ? awayClub.name : homeClub.name
                templates = [
                    "Desperation setting in for \(trailingClub)! Long balls being launched forward as \(leadingClub) throw bodies in front of every shot.",
                    "The home crowd are roaring their team over the line! Resolute defensive blocks keeping the lead intact.",
                    "End-to-end chaos in the dying stages! Tired legs creating acres of space on the counter."
                ]
            } else {
                templates = [
                    "Ole chants ring out from the stands as the clock winds down toward a comfortable result.",
                    "The outcome is all but sealed, but both sides continue to battle hard for every loose ball.",
                    "The stadium begins to celebrate early as the referee checks his watch."
                ]
            }
        } else {
            templates = [
                "Intense midfield duel right now. Neither team giving an inch in the tackle.",
                "Tactical chess match unfolding on the pitch. Both managers shouting instructions constantly from their technical areas.",
                "\(homeClub.name) are enjoying a dominant spell of possession, probing for openings in the defensive structure.",
                "\(awayClub.name) look dangerous on the break, threatening with direct diagonal balls into the channels."
            ]
        }
        
        let pool = templates + CommentaryLines.atmosphereExtra(home: homeClub, away: awayClub, minute: minute,
                                                               homeGoals: homeGoals, awayGoals: awayGoals)
        let chosen = pool.randomElement()!
        return (chosen, chosen)
    }
    
    // MARK: - Crowd Reactions
    
    public static func crowdReactionText(
        isHome: Bool,
        club: Club,
        minute: Int,
        isLateWinner: Bool
    ) -> String {
        if isLateWinner {
            return isHome ? "PANDEMONIUM! The ground is SHAKING as the home fans erupt in unbridled ecstasy!" : "Stunned silence in the home terraces as the away end goes completely ballistic!"
        }
        if isHome {
            let reactions = [
                "The home fans go wild! Scarves twirling, chants echoing around the arena!",
                "An explosion of noise around \(club.stadium)! The atmosphere is electric!",
                "The home terrace roars in celebration as the players pile on by the corner flag!",
                "\(club.stadium) is rocking. You can feel the stands bouncing.",
                "The scorer cups an ear to the home end and they roar right back at him.",
                "Flags, flares and noise: the home support has found its voice.",
                "The players sprint to the dugout to celebrate with the bench.",
                "A knee-slide towards the home fans, and the whole team piles on top."
            ]
            return reactions.randomElement()!
        } else {
            let reactions = [
                "Wild celebrations in the away section! The travelling faithful are in dreamland!",
                "Silence falls over the home end as the away fans make all the noise!",
                "The away supporters are bouncing in unison, outsinging the entire stadium!",
                "The scorer runs the length of the touchline to the away end. They will remember this trip.",
                "A finger to the lips towards the home crowd. Not everyone in the stands appreciates that.",
                "In the corner of the ground, a small pocket of \(club.name) fans goes absolutely berserk.",
                "Home fans head for their pies early. The away end can't stop singing."
            ]
            return reactions.randomElement()!
        }
    }
    
    // MARK: - Half-Time & Full-Time Summaries

    public static func halfTimeSummary(
        home: Club,
        away: Club,
        homeGoals: Int,
        awayGoals: Int
    ) -> (short: String, detail: String) {
        let shortText = "Half-Time: \(home.name) \(homeGoals) - \(awayGoals) \(away.name)"
        return (shortText, CommentaryLines.halfTime(home: home, away: away, homeGoals: homeGoals, awayGoals: awayGoals).randomElement()!)
    }

    public static func fullTimeSummary(
        home: Club,
        away: Club,
        homeGoals: Int,
        awayGoals: Int,
        motm: Player?
    ) -> (short: String, detail: String) {
        let shortText = "FULL-TIME: \(home.name) \(homeGoals) - \(awayGoals) \(away.name)"
        let motmText = motm.map { "\n\nMan of the Match: \($0.fullName) (\($0.primaryPosition.abbreviation))" } ?? ""
        let line = CommentaryLines.fullTime(home: home, away: away, homeGoals: homeGoals, awayGoals: awayGoals).randomElement()!
        return (shortText, line + motmText)
    }
}