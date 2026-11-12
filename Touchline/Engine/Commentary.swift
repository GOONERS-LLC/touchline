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
        let shortText = "GOAL! \(scorer.displayName) (\(club.shortName)) \(minute)' [\(homeGoals)-\(awayGoals)]"
        let keeper = opponent.startingXIPlayers.first { $0.primaryPosition == .GK }?.lastName ?? "the keeper"
        let body = GoalLines.body(type: type, scorer: scorer, assister: assister, keeper: keeper,
                                  club: club, opponent: opponent, minute: minute)
        let teamGoals = isHome ? homeGoals : awayGoals
        let oppGoals = isHome ? awayGoals : homeGoals
        let situation = GoalLines.situation(club: club, opponent: opponent, minute: minute,
                                            teamGoals: teamGoals, oppGoals: oppGoals, scorer: scorer)
        let crowd = crowdReactionText(isHome: isHome, club: club, minute: minute,
                                      isLateWinner: minute > 82 && teamGoals == oppGoals + 1)
        return (shortText, "\(body) \(situation)\n\n\(crowd)")
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
        let shortText = "CHANCE! \(shooter.displayName) (\(club.shortName)) \(minute)'"
        
        let templates = [
            "\(shooter.fullName) carves out a yard of space just outside the box and lets fly with a ferocious drive that whistles inches over the crossbar!",
            "Great vision from \(assister?.fullName ?? "the midfield") to thread a ball behind the backline. \(shooter.fullName) takes it in his stride, but his snapshot flashes agonizingly wide of the upright.",
            "A scramble in the six-yard box! The ball ricochets around like a pinball before \(shooter.fullName) stabs a shot toward goal, only for a desperate defensive block to deflect it behind for a corner.",
            "\(shooter.fullName) cuts inside onto his stronger foot and curls a wicked effort toward the far top corner—it looks in all the way, but just shaves the outside of the post!",
            "Fast build-up play from \(club.name)! \(shooter.fullName) connects first-time with a cross from the byline, but can't quite direct his header on target under heavy defensive pressure.",
            "Thunderous strike from 25 yards out by \(shooter.fullName)! It skims across the slick turf and forces the keeper to scramble across his goal line.",
            "\(shooter.fullName) finds himself unmarked at the back post from a deep cross! He cushions a volley down into the ground, but it bounces up and over the crossbar.",
            "A sweeping team move across the pitch finishes with \(shooter.fullName) receiving the ball in the D. He pulls the trigger quickly, sending the ball skimming just past the post.",
            "Clever flick around the corner sets \(shooter.fullName) into the area! He fires across the face of goal, but there's nobody at the back stick to turn it in.",
            "\(shooter.fullName) twists and turns his marker inside out before firing toward the near post, hitting the side netting! Half the stadium thought that was in!"
        ]
        
        let detailText = templates.randomElement()!
        return (shortText, detailText)
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
        
        let templates = [
            "WHAT A REFLEX STOP! \(shooter.fullName) looked certain to score with a bullet header from point-blank range, but \(keeper.fullName) flung out a strong hand to tip it over the bar!",
            "\(keeper.fullName) comes to \(keeperClub.name)'s rescue! \(shooter.fullName) went through clean on goal, but the keeper stood tall and smothered the one-on-one attempt brilliantly.",
            "Incredible agility from \(keeper.fullName)! Dipping and swerving from 30 yards, the shot looked destined for the top corner before the goalkeeper made a full-stretch fingertip save.",
            "Double save from \(keeper.fullName)! First parrying the stinging drive from distance, then reacting with superhuman speed to block the rebound with his legs!",
            "A flying save! \(shooter.fullName) unleashed a venomous curler, but \(keeper.fullName) launched himself across the goalmouth to push the ball wide of the post.",
            "Pure bravery! \(keeper.fullName) dives right at the feet of \(shooter.fullName) to snatch the ball away just as the striker was about to pull the trigger.",
            "Strong wrists from \(keeper.fullName)! The striker struck it with immense power from 12 yards, but the goalkeeper parried it firmly away from danger.",
            "A crucial intervention by \(keeper.fullName)! Sticking out an outstretched boot, he deflects what looked like a guaranteed goal behind for a corner."
        ]
        
        return (shortText, templates.randomElement()!)
    }
    
    // MARK: - Misses & Woodwork
    
    public static func miss(
        shooter: Player,
        club: Club,
        minute: Int,
        isWoodwork: Bool = false
    ) -> (short: String, detail: String) {
        if isWoodwork {
            let shortText = "OFF THE WOODWORK! \(shooter.displayName) \(minute)'"
            let woodworkTemplates = [
                "OFF THE BAR! \(shooter.fullName) crashes a thunderbolt against the crossbar! The goalframe is still rattling as the defense scrambles the ball away.",
                "OFF THE POST! Beautiful curling strike from \(shooter.fullName), beat the goalkeeper all ends up, but smacks against the inside of the far post and bounces clear!",
                "HOW HAS THAT STAYED OUT?! \(shooter.fullName)'s header loops over the keeper, cannons against the crossbar, bounces on the goal line, and is hooked clear!",
                "WOODWORK AGAIN! \(shooter.fullName) drills a low drive that rebounds off the base of the upright with the goalkeeper beaten."
            ]
            return (shortText, woodworkTemplates.randomElement()!)
        }
        
        let shortText = "CHANCE MISSED! \(shooter.displayName) \(minute)'"
        let missTemplates = [
            "HOW DID HE MISS THAT?! Sitter of the season! The ball was served on a silver platter inside the six-yard box, but \(shooter.fullName) somehow skewed his finish wide!",
            "A wasted opportunity for \(club.name). \(shooter.fullName) had time and space to pick his spot, but rushed his effort and blasted it high into the stands.",
            "Groans around the ground as \(shooter.fullName) drags his left-footed effort wide of the target when passing to a teammate was the better option.",
            "\(shooter.fullName) can only hold his head in his hands. He created the opening with fantastic footwork, but snatched at the final shot, slicing it harmlessly into the crowd.",
            "A great counter-attack comes to nothing. \(shooter.fullName) was in on goal with runners either side, but his chipped attempt drifted harmlessly over the bar.",
            "Frustration boils over as \(shooter.fullName) scuffs a tame shot straight into the turf from a prime scoring position.",
            "\(shooter.fullName) blazes over! With the defense retreating, the striker opted for power over placement and cleared the crossbar by ten yards.",
            "A glorious delivery went begging as \(shooter.fullName) completely mistimed his jump, brushing the ball with his shoulder instead of making solid contact."
        ]
        return (shortText, missTemplates.randomElement()!)
    }
    
    // MARK: - Disciplinary Cards
    
    public static func card(
        player: Player,
        club: Club,
        isRed: Bool,
        isSecondYellow: Bool = false,
        minute: Int
    ) -> (short: String, detail: String) {
        let minuteStr = "\(minute)'"
        if isRed || isSecondYellow {
            let shortText = isSecondYellow ? "RED CARD (SECOND YELLOW)! \(player.displayName) \(minuteStr)" : "STRAIGHT RED CARD! \(player.displayName) \(minuteStr)"
            
            let redTemplates = [
                "HE'S OFF! A reckless, two-footed lunge with studs showing leaves the referee with absolutely no choice. The referee reaches straight into his back pocket and produces a red card for \(player.fullName)! \(club.name) are down to 10 men!",
                "DISASTER FOR \(club.shortName)! A professional foul as the last defender! \(player.fullName) tugged back the advancing attacker who was clean through on goal. Clear denial of an obvious goalscoring opportunity. Off he goes!",
                "DRAMA! Tempers boil over off the ball! An altercation breaks out and the referee spots \(player.fullName) raising his hands aggressively. The red card is brandished immediately amidst furious protests!",
                "SECOND YELLOW! \(player.fullName) mistimes a cynical trip to halt a promising counter-attack. The referee blows his whistle, issues a second caution, followed immediately by the red! Walking down the tunnel in disbelief."
            ]
            return (shortText, redTemplates.randomElement()!)
        }
        
        let shortText = "YELLOW CARD — \(player.displayName) (\(club.shortName)) \(minuteStr)"
        let yellowTemplates = [
            "Late challenge by \(player.fullName). He arrived a fraction of a second after the ball was released and wiped out his opponent. A deserved caution.",
            "Tactical foul. \(player.fullName) deliberately pulls back the attacker's shirt to break up a dangerous break. The referee reaches into his pocket without hesitation.",
            "Dissent from \(player.fullName). After disputing a throw-in decision aggressively in the referee's face, he talks himself into the referee's notebook.",
            "Persistent infringement. After several warnings for niggling fouls, \(player.fullName) commits one foul too many and receives a yellow card.",
            "A heavy sliding tackle on the wet pitch. \(player.fullName) got a piece of the ball, but followed through with too much force. The referee brandishes yellow.",
            "Time wasting caution. The referee penalizes \(player.fullName) for delaying the restart of play by kicking the ball away."
        ]
        return (shortText, yellowTemplates.randomElement()!)
    }
    
    // MARK: - Injuries & Substitutions
    
    public static func injury(
        player: Player,
        club: Club,
        minute: Int,
        injuryType: InjuryType
    ) -> (short: String, detail: String) {
        let shortText = "INJURY — \(player.displayName) (\(club.shortName)) \(minute)'"
        let detailText = "Play stops as \(player.fullName) goes down clutching his leg in obvious pain. The physios rush onto the pitch with the medical kit. After a brief assessment, he is signaled off the pitch with what looks like a \(injuryType.displayName.lowercased())."
        return (shortText, detailText)
    }
    
    public static func substitution(
        playerIn: Player,
        playerOut: Player,
        club: Club,
        minute: Int
    ) -> (short: String, detail: String) {
        let shortText = "SUB — \(club.shortName): \(playerIn.displayName) ON, \(playerOut.displayName) OFF \(minute)'"
        let detailText = "Tactical change for \(club.name). \(playerOut.fullName) makes way after a tireless shift, receiving applause from the traveling supporters as \(playerIn.fullName) trots on with fresh instructions from the touchline."
        return (shortText, detailText)
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
                "High pressing from \(homeClub.name) early on, forcing \(awayClub.shortName) into rushed clearances."
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
        
        let chosen = templates.randomElement()!
        return ("● \(chosen)", chosen)
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
                "In the corner of the ground, a small pocket of \(club.shortName) fans goes absolutely berserk.",
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
        let shortText = "Half-Time: \(home.shortName) \(homeGoals) - \(awayGoals) \(away.shortName)"
        let detailText: String
        
        if homeGoals == awayGoals && homeGoals == 0 {
            detailText = "The referee blows the whistle for half-time. A cagey, tactical 45 minutes with limited clear-cut openings. Both managers will be demanding more creative spark after the break."
        } else if homeGoals == awayGoals {
            detailText = "An entertaining first half comes to a close with the sides deadlocked at \(homeGoals)-\(awayGoals). Plenty of attacking intent on display; this one is poised on a knife-edge for the second half."
        } else if homeGoals > awayGoals {
            detailText = "Half-time at \(home.stadium). \(home.name) head into the tunnel with a deserved \(homeGoals)-\(awayGoals) lead having controlled the tempo. \(away.name) need a tactical response."
        } else {
            detailText = "The whistle sounds for the interval. An impressive away display so far as \(away.name) take a \(awayGoals)-\(homeGoals) lead into the dressing rooms."
        }
        
        return (shortText, detailText)
    }
    
    public static func fullTimeSummary(
        home: Club,
        away: Club,
        homeGoals: Int,
        awayGoals: Int,
        motm: Player?
    ) -> (short: String, detail: String) {
        let shortText = "FULL-TIME: \(home.shortName) \(homeGoals) - \(awayGoals) \(away.shortName)"
        let motmText = motm != nil ? "\n\nMan of the Match: \(motm!.fullName) (\(motm!.primaryPosition.abbreviation))" : ""
        let detailText: String
        
        if homeGoals == awayGoals {
            detailText = "The final whistle blows! Points shared after 90 hard-fought minutes. Both teams gave everything, and a draw is probably a fair reflection of a fiercely contested match.\(motmText)"
        } else if homeGoals > awayGoals {
            detailText = "FULL TIME! A resounding victory for \(home.name) in front of their home supporters, claiming all three points with a \(homeGoals)-\(awayGoals) triumph.\(motmText)"
        } else {
            detailText = "FULL TIME! An outstanding away performance from \(away.name), silencing the home crowd to take the spoils with a \(awayGoals)-\(homeGoals) win.\(motmText)"
        }
        
        return (shortText, detailText)
    }
}
