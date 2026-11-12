//
//  CommentaryExtras.swift
//  Touchline
//
//  Additional commentary for the moments between the big ones: fouls that do
//  not earn a card, corners, offsides and blocked shots, plus extra variety
//  for saves, misses, woodwork, bookings, chances and injuries. Every line is
//  written to be read aloud, so names are spelled out in full and no symbols
//  or abbreviations carry meaning.
//

import Foundation

extension Commentary {

    // MARK: - Fouls (no card)

    public static func foul(
        fouler: Player,
        victim: Player?,
        club: Club,
        victimClub: Club,
        minute: Int
    ) -> (short: String, detail: String) {
        let shortText = "Foul by \(fouler.displayName) (\(club.name)) \(minute)'"
        let v = victim?.fullName ?? "his opponent"
        let f = fouler.fullName
        let templates = [
            "\(f) clips the heels of \(v) as he tries to turn. The referee blows straight away and \(victimClub.name) have a free kick.",
            "A clumsy challenge from \(f), who arrives a touch late on \(v). Just a free kick, and a quiet word from the referee.",
            "\(f) leans into \(v) at a throw-in and the referee spots the push. Free kick to \(victimClub.name).",
            "Shirt pull! \(f) grabs a handful of \(v)'s shirt to stop him getting away. The whistle goes, but the referee keeps his cards in his pocket.",
            "\(v) goes down under a challenge from \(f). The home crowd want more, but it is only a free kick.",
            "Mistimed! \(f) slides in and catches \(v) on the ankle instead of the ball. \(v) needs a moment before getting back to his feet.",
            "\(f) climbs all over \(v) as they compete for a high ball. The referee sees it and gives the foul.",
            "A tactical nudge from \(f) to stop a \(victimClub.name) break in its tracks. Free kick in midfield.",
            "\(f) and \(v) tangle near the touchline. The referee decides \(f) was the one who held, and awards the free kick.",
            "That was cynical from \(f), body-checking \(v) as he tried to run past. \(club.name) get away with just the free kick this time.",
            "\(f) goes through the back of \(v). The referee plays a brief advantage, then brings it back for the foul.",
            "Handball! The ball strikes the arm of \(f) as he tries to block. Free kick to \(victimClub.name) in a promising position.",
        ]
        return (shortText, templates.randomElement()!)
    }

    // MARK: - Corners

    public static func corner(taker: Player, club: Club, minute: Int) -> (short: String, detail: String) {
        let shortText = "Corner to \(club.name) \(minute)'"
        let t = taker.fullName
        let templates = [
            "A defender heads behind under pressure and \(club.name) win a corner. \(t) jogs over to take it as the big men make their way forward.",
            "Corner kick. \(t) places the ball by the flag, raises an arm to signal the routine, and the penalty area fills with bodies.",
            "The goalkeeper tips it around the post for a corner. \(t) will deliver it, and the crowd rises in anticipation.",
            "A low cross is turned behind by a stretching defender. Corner to \(club.name), and \(t) is over to take it.",
            "\(club.name) have been building pressure, and they earn another corner. \(t) whips it in towards the near post.",
        ]
        return (shortText, templates.randomElement()!)
    }

    // MARK: - Offsides

    public static func offside(player: Player, club: Club, minute: Int) -> (short: String, detail: String) {
        let shortText = "Offside, \(player.displayName) (\(club.name)) \(minute)'"
        let p = player.fullName
        let templates = [
            "The flag goes up. \(p) timed his run a fraction too early and was caught offside as the through ball was played.",
            "\(p) puts the ball in the net, but the assistant referee has his flag raised. Offside, and the celebrations stop before they start.",
            "A clever ball over the top, but \(p) had strayed beyond the last defender. The defence stepped up perfectly to catch him offside.",
            "Offside again. \(p) is getting frustrated, holding his arms out at the linesman, but replays suggest it was the right call.",
            "\(p) races clear and the crowd roars, but the whistle has already gone. He was a yard offside.",
        ]
        return (shortText, templates.randomElement()!)
    }

    // MARK: - Blocked Shots

    public static func blocked(shooter: Player, blocker: Player?, club: Club, minute: Int) -> (short: String, detail: String) {
        let shortText = "Shot blocked, \(shooter.displayName) (\(club.name)) \(minute)'"
        let s = shooter.fullName
        let b = blocker?.fullName ?? "a defender"
        let templates = [
            "\(s) winds up a shot from the edge of the area, but \(b) throws himself in the way and the ball cannons off his body.",
            "Brave defending! \(b) slides across to block \(s)'s goal-bound effort with the goalkeeper beaten.",
            "\(s) shapes to shoot and \(b) reads it perfectly, sticking out a leg to deflect the ball behind.",
            "A crowded penalty area, and \(s)'s strike smashes straight into \(b). The danger is cleared.",
            "\(s) tries to curl one into the far corner, but \(b) gets his head to it and blocks the shot.",
        ]
        return (shortText, templates.randomElement()!)
    }

    // MARK: - More Variety For Existing Moments

    static func saveHeadline(keeper: Player, minute: Int) -> String {
        let options = ["Save! \(keeper.displayName) \(minute)'",
                       "Great save, \(keeper.displayName) \(minute)'",
                       "Saved by \(keeper.displayName) \(minute)'",
                       "Shot on target, saved by \(keeper.displayName) \(minute)'"]
        return options.randomElement()!
    }

    static func moreSaves(keeper: Player, shooter: Player, keeperClub: Club) -> [String] {
        let k = keeper.fullName, s = shooter.fullName
        return [
            "\(s) drives it low towards the near post, but \(k) gets down quickly and gathers it at the second attempt.",
            "A comfortable save in the end. \(s) hit it with power but straight at \(k), who holds on to it against his chest.",
            "\(k) is equal to it! \(s)'s volley was dipping under the crossbar, and the goalkeeper backpedals to palm it over.",
            "\(s) tries to catch \(k) off his line from distance, but the goalkeeper scrambles back and claws it away.",
            "Point-blank range! \(s) looked certain to score but \(k) spreads himself and the ball hits his knee and loops away.",
            "\(k) punches clear under pressure after \(s) flicks a header goalwards. \(keeperClub.name) breathe again.",
        ]
    }

    static func moreMisses(shooter: Player, club: Club) -> [String] {
        let s = shooter.fullName
        return [
            "\(s) gets his body over the ball and hits it sweetly, but it fizzes a yard wide of the far post.",
            "Too much on it from \(s). The shot sails over the crossbar and into the crowd behind the goal.",
            "\(s) tries a first-time finish across goal and pulls it wide. A chance \(club.name) will feel they should have taken.",
            "Wide! \(s) tried to pick out the bottom corner but dragged it past the post.",
            "A tame effort from \(s), rolling wide of the target with the goalkeeper watching it all the way.",
            "\(s) leans back as he shoots and the ball balloons high over the bar. He looks at the turf in disbelief.",
        ]
    }

    static func moreWoodwork(shooter: Player) -> [String] {
        let s = shooter.fullName
        return [
            "The crowd were already celebrating! \(s)'s shot beat the goalkeeper but cracked against the outside of the post.",
            "Crossbar! \(s) looped a header over the goalkeeper and it bounced down off the bar and out.",
            "Agonising for \(s). A curling free kick clips the top of the crossbar and goes behind.",
            "\(s) side-foots it towards the corner, it kisses the inside of the post, runs along the goal line, and somehow stays out.",
        ]
    }

    static func moreYellows(player: Player) -> [String] {
        let p = player.fullName
        return [
            "\(p) goes in high with his studs showing. It could have been worse for him, but it is a yellow card.",
            "\(p) slides in from behind and takes the man before the ball. Into the book he goes.",
            "Simulation! \(p) goes down far too easily in the penalty area, and the referee books him for diving.",
            "\(p) kicks the ball away after the whistle and the referee has had enough. Yellow card.",
            "A deliberate handball from \(p) to stop a quick break. The referee shows the yellow card without hesitation.",
            "\(p) leaves an elbow in during an aerial challenge. The referee calls him over and shows a yellow card.",
        ]
    }

    static func moreChances(shooter: Player, club: Club) -> [String] {
        let s = shooter.fullName
        return [
            "\(club.name) work it neatly down the left and cut it back for \(s), whose shot is deflected just wide.",
            "\(s) wriggles free in the area and fires at goal, but a defender recovers to make a vital challenge.",
            "A loose ball drops to \(s) on the penalty spot. He snatches at it and the chance is gone.",
            "\(s) meets a cross on the run but cannot keep his header down. The ball drifts over the bar.",
        ]
    }

    static func injuryDetail(player: Player, club: Club, injuryName: String) -> String {
        let p = player.fullName
        let options = [
            "Play stops as \(p) goes down clutching his leg. The physios rush on. After a brief assessment he is helped off with what looks like a \(injuryName).",
            "\(p) pulls up sharply chasing a long ball and immediately signals to the bench. It looks like a \(injuryName). \(club.name) will need to reshuffle.",
            "A heavy collision, and \(p) is down. The stretcher is called for. Early signs point to a \(injuryName). Warm applause from all four sides of the ground.",
            "\(p) lands awkwardly after an aerial challenge and cannot continue. The medical staff suspect a \(injuryName).",
        ]
        return options.randomElement()!
    }
}
