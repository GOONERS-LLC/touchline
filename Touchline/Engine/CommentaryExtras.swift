//
//  CommentaryExtras.swift
//  Touchline
//
//  More of the match in words: VAR reviews, offsides, free-kick and
//  penalty goals, saved and missed penalties, and corners that come to
//  nothing.
//

import Foundation

extension CommentaryLines {

    // MARK: - VAR

    static func varGoalDisallowed(scorer: Player, club: Club) -> [String] {
        let s = scorer.fullName, c = club.name
        return [
            "The celebrations stop. VAR has spotted \(s) a toe offside in the build-up, and the goal is ruled out.",
            "\(s) thinks he has scored, but the referee is sent to the monitor. A foul in the build-up: no goal.",
            "Agony for \(c)! VAR checks the handball, the lines are drawn, and \(s)'s goal is chalked off.",
            "It's in, then it's out. The VAR review finds \(s) offside by a shoulder. The away end can't believe it.",
            "\(s) wheels away, but the referee holds a finger to his ear. A long check... and the goal is disallowed.",
            "The referee goes to the screen and sees the push on the defender before \(s) scored. No goal.",
            "Offside! The flag stays down, but VAR draws the lines and \(s) was beyond the last man. Disallowed.",
            "Heartbreak for \(c). The ball brushed \(s)'s arm on its way in, and VAR rules it out.",
            "Four minutes of waiting, a screen full of lines, and the verdict: \(s) was offside. The goal does not stand.",
            "The referee watches it three times at the monitor and reverses his decision. \(c) will not have that goal.",
            "A tight one, but VAR says the ball had gone out of play before the cross. \(s)'s goal is cancelled.",
            "The noise dies as the big screen shows NO GOAL. \(s) was fractionally offside."
        ]
    }

    static func varGoalStands(scorer: Player) -> [String] {
        let s = scorer.fullName
        return [
            "VAR checks the goal for offside... and it stands. \(s) was level.",
            "A quick look from VAR at a possible handball in the build-up. Nothing doing: the goal stands.",
            "The referee waits for the check to finish, then points to the centre circle. It's a goal.",
            "VAR draws its lines and \(s) was onside by a whisker. Goal confirmed.",
            "A nervous wait while VAR checks for a foul, but the goal is given.",
            "Checked and confirmed: \(s)'s goal stands."
        ]
    }

    static func varPenaltyOverturned(victim: Player?, club: Club) -> [String] {
        let v = victim?.fullName ?? "the attacker"
        return [
            "The referee points to the spot, then is called to the monitor. Replays show \(v) went down too easily. No penalty.",
            "VAR to the rescue for \(club.name): the contact was outside the box. The penalty is overturned, a free kick instead.",
            "Penalty given... and taken away. The VAR review shows the defender got the ball first.",
            "The referee watches it again on the screen and changes his mind. No penalty, and \(v) is lucky not to be booked for diving.",
            "After a long VAR check, the spot kick is cancelled: \(v) was offside before he was fouled.",
            "The penalty decision is reversed at the monitor. \(club.name)'s players are mobbing the referee in relief."
        ]
    }

    static func varPenaltyConfirmed(victim: Player?) -> [String] {
        let v = victim?.fullName ?? "the attacker"
        return [
            "VAR checks the penalty decision and backs the referee: \(v) was clipped inside the box.",
            "The referee is sent to the screen... and points to the spot! Penalty, after VAR review.",
            "A long VAR check, but the replays are clear: the defender took \(v)'s standing leg. Penalty.",
            "Penalty confirmed by VAR. The defenders surround the referee, but the decision stands.",
            "No doubt in the end: VAR confirms the foul on \(v) was inside the area."
        ]
    }

    static func varRedConfirmed(player: Player) -> [String] {
        let p = player.fullName
        return [
            "VAR looks at it again and confirms the red card for \(p). The studs were up.",
            "The red card is checked by VAR and stands. \(p) has to go.",
            "VAR review complete: serious foul play. \(p)'s red card is confirmed."
        ]
    }

    // MARK: - Offside

    static func offside(attacker: Player, club: Club) -> [String] {
        let a = attacker.fullName, l = attacker.lastName
        return [
            "\(a) times his run a fraction too early. The flag goes up for offside.",
            "Offside. \(a) was a yard beyond the last defender when the ball was played.",
            "\(club.name) spring the trap... almost. \(l) is flagged offside.",
            "The through ball finds \(a), but the assistant's flag is already up.",
            "\(a) races clear and finishes, but the whistle has gone. Offside.",
            "A well-drilled line catches \(a) offside again.",
            "\(l) drifts offside, and the move breaks down.",
            "Tight call: \(a) is flagged offside, and the replay suggests it was the right one.",
            "\(a) complains, but he was clearly offside.",
            "The ball over the top is perfect, but \(l) has gone too soon."
        ]
    }

    // MARK: - Set pieces

    static func freeKickGoal(taker: Player, keeper: String) -> [String] {
        let t = taker.fullName, l = taker.lastName, k = keeper
        return [
            "Breathtaking technique from \(t)! From 25 yards he whips it up and over the wall, and it dips into the top corner.",
            "\(t) curls the free kick around the wall and inside the post. \(k) is rooted to the spot.",
            "Power over placement: \(t) drives the free kick through a gap in the wall and into the net.",
            "\(t) rolls it under the jumping wall! Cheeky, clever, and in the bottom corner.",
            "A knuckleball from \(t)! It wobbles, swerves, and \(k) can only push it into his own net.",
            "\(l) catches everyone out from a tight angle, going for goal and squeezing it in at the near post.",
            "Standing over it, \(t) takes a breath, takes four steps, and bends it into the top corner. Perfection.",
            "The wall jumps, \(k) dives, and \(t)'s free kick kisses the underside of the bar on its way in!",
            "From 30 yards, \(t) hits a rocket of a free kick that \(k) gets a glove to, but can't keep out.",
            "\(t) whips the free kick to the far post and it beats everybody, bouncing in off the post.",
            "Dead-ball genius: \(t) lifts it over the wall and dips it under the bar.",
            "\(t) fakes to shoot, a team-mate runs over the ball, and then \(l) curls it into the corner. Rehearsed and perfect.",
            "\(k) sets his wall, and \(t) puts it exactly where the keeper is not.",
            "A free kick on the edge of the box, and \(t) makes no mistake: low, hard, and through the wall.",
            "\(t) sends the free kick over the wall and in off \(k)'s fingertips."
        ]
    }

    static func penaltyGoal(taker: Player, keeper: String) -> [String] {
        let t = taker.fullName, l = taker.lastName, k = keeper
        return [
            "\(t) steps up, waits for \(k) to move, and rolls it into the other corner.",
            "Smashed! \(t) hits the penalty high into the roof of the net. \(k) had no chance.",
            "\(k) goes the right way, but \(t)'s penalty is too well placed.",
            "A stuttering run-up from \(l), and the keeper is sent the wrong way.",
            "\(t) chips it down the middle! A Panenka, with \(k) diving to his left.",
            "Ice cold from \(t): bottom corner, keeper beaten.",
            "\(t) side-foots the penalty into the corner. Composure itself.",
            "\(k) gets a hand to it, but \(t) has struck it too hard. In off the post!",
            "\(t) puts the ball on the spot, ignores the noise, and scores.",
            "A long wait for \(t) while VAR checked the decision, but he doesn't flinch. Goal."
        ]
    }

    static func penaltySaved(taker: Player, keeper: Player) -> [String] {
        let t = taker.fullName, k = keeper.fullName, kl = keeper.lastName
        return [
            "\(t) goes to the bottom corner, but \(k) guesses right and keeps it out!",
            "SAVED! \(k) dives full length to his right and pushes \(t)'s penalty round the post.",
            "\(kl) stands tall, waits, and saves with his legs as \(t) goes down the middle.",
            "What a save! \(k) gets a strong hand to a well-struck penalty.",
            "\(t)'s penalty is too close to \(k), who blocks it and then smothers the rebound.",
            "\(k) has done his homework. He goes the right way and saves from \(t).",
            "\(k) the hero! He reads \(t)'s run-up and saves the spot kick."
        ]
    }

    static func penaltyMissed(taker: Player, club: Club) -> [String] {
        let t = taker.fullName
        return [
            "\(t) leans back and blazes the penalty over the bar.",
            "Off the post! \(t)'s penalty hits the upright and bounces clear.",
            "\(t) drags the spot kick wide. A huge let-off.",
            "\(t) goes for the top corner and misses the target altogether.",
            "Off the crossbar! \(t) hit that hard, but not hard enough in the right place.",
            "\(t) slips as he strikes it and the penalty sails high and wide. \(club.name) can't believe it."
        ]
    }

    static func cornerCleared(taker: Player, defending: Club) -> [String] {
        let t = taker.fullName
        return [
            "\(t)'s corner is headed away at the near post.",
            "The corner from \(t) is too close to the keeper, who claims it.",
            "\(t) swings the corner in, and \(defending.name) clear their lines.",
            "A short corner routine from \(t) comes to nothing.",
            "\(t)'s inswinger is punched clear by the keeper.",
            "The corner is overhit and goes out for a goal kick.",
            "\(defending.name) defend the corner well, and \(t)'s delivery is cleared.",
            "Bodies everywhere from \(t)'s corner, but the ball is hacked away."
        ]
    }
}
