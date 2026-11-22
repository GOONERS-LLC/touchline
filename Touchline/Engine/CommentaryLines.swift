//
//  CommentaryLines.swift
//  Touchline
//
//  The big book of match commentary: many ways of telling every kind of
//  moment (chances, saves, misses, fouls, cards, knocks, injuries,
//  substitutions, celebrations and the mood of the ground) so a season of
//  matches rarely repeats itself.
//

import Foundation

extension InjuryType {
    /// "a sprained ankle", "ankle ligament damage": for commentary.
    var commentaryPhrase: String {
        switch self {
        case .minorKnock: return "a knock"
        case .muscleStrain: return "a thigh strain"
        case .hamstring: return "a hamstring injury"
        case .ankleLigament: return "ankle ligament damage"
        case .kneeInjury: return "a knee injury"
        case .aclTear: return "a cruciate ligament injury"
        case .brokenBone: return "a fracture"
        case .ankleSprain: return "a sprained ankle"
        case .calfStrain: return "a calf strain"
        }
    }
}

enum CommentaryLines {

    // MARK: - Chances

    static func chance(shooter: Player, assister: Player?, club: Club) -> [String] {
        let s = shooter.fullName, l = shooter.lastName, c = club.name
        let a = assister?.fullName ?? "a team-mate"
        return [
            "\(s) carves out a yard of space just outside the box and lets fly with a ferocious drive that whistles inches over the crossbar!",
            "Great vision from \(a) to thread a ball behind the back line. \(s) takes it in his stride, but his snapshot flashes agonisingly wide.",
            "A scramble in the six-yard box! The ball ricochets around like a pinball before \(s) stabs at it, only for a desperate block to send it behind.",
            "\(s) cuts inside onto his stronger foot and curls one towards the far top corner. It looks in all the way, but shaves the outside of the post!",
            "Quick build-up from \(c)! \(s) meets a cross from the byline first time, but can't direct the header on target under pressure.",
            "Thunderous strike from 25 yards by \(s)! It skims across the turf and forces the keeper to scramble across his line.",
            "\(s) is unmarked at the back post! He cushions a volley into the ground, but it bounces up and over the bar.",
            "A sweeping move ends with \(s) receiving it in the D. He pulls the trigger quickly and sends it skimming past the post.",
            "A clever flick around the corner sets \(s) into the area! He fires across the face of goal, but there's nobody at the back stick.",
            "\(s) twists his marker inside out and hits the side netting from a tight angle! Half the stadium thought that was in.",
            "\(a) whips in a dangerous delivery and \(s) gets a glancing touch, but it flies a yard wide of the far post.",
            "\(l) bursts onto a loose ball and hits it on the half-volley. It clears the bar by the width of a coat of paint.",
            "\(c) win it high up the pitch and \(s) is in! He shoots early, too early, and it drifts wide.",
            "Lovely one-two between \(a) and \(s) on the edge of the box, but the final shot is dragged just past the upright.",
            "\(s) chests it down, swivels and shoots in one movement. Inches wide! What a goal that would have been.",
            "\(s) attacks the near post and flicks it goalwards. The keeper reacts late, but it's the wrong side of the post.",
            "A long diagonal finds \(s) in space. He takes a touch, steadies himself, and curls it just over.",
            "\(s) wins a header at the far post and nods it back across goal, but nobody in a \(c) shirt gambles on it.",
            "Corner to \(c), it's flicked on, and \(s) is a fraction too late to turn it in at the back post.",
            "\(s) goes for the spectacular, an acrobatic volley from twelve yards. It flies over, but the crowd applaud the effort.",
            "\(a) skips past two and squares for \(s), whose first-time shot is deflected inches wide.",
            "\(s) drives through the middle and unleashes a low shot that whistles past the post with the keeper beaten.",
            "\(l) tries to bend one into the far corner from the left side of the box. It's not far away at all.",
            "\(c) break three against two. \(a) finds \(s), who scuffs his shot at the crucial moment.",
            "A loose pass in midfield and \(s) is away, but he shoots from distance when a run into the box was on.",
            "\(s) dances along the edge of the area before cracking a shot that the defender just gets a toe to.",
            "Low cross, \(s) slides in, and it's agonisingly out of reach. The ball rolls across the six-yard box and out.",
            "\(s) meets \(a)'s free kick with a diving header that skims the top of the crossbar.",
            "The ball sits up nicely for \(s) on the edge of the box and he hits it sweetly, but straight into a defender's chest.",
            "\(s) gets in behind on the overlap and drills it across goal. It needs a touch, and doesn't get one."
        ]
    }

    // MARK: - Saves

    static func bigSave(keeper: Player, shooter: Player, keeperClub: Club) -> [String] {
        let k = keeper.fullName, kl = keeper.lastName, s = shooter.fullName
        return [
            "WHAT A REFLEX STOP! \(s) looked certain to score from point-blank range, but \(k) flung out a strong hand to tip it over!",
            "\(k) comes to \(keeperClub.name)'s rescue! \(s) was clean through, but the keeper stood tall and smothered the one-on-one.",
            "Incredible agility from \(k)! The shot was dipping into the top corner before a full-stretch fingertip save.",
            "Double save from \(k)! He parries the first effort, then reacts superbly to block the rebound with his legs!",
            "A flying save! \(s) unleashed a venomous curler, but \(k) launched himself across goal to push it round the post.",
            "Pure bravery! \(k) dives at the feet of \(s) to snatch the ball away just as he was about to shoot.",
            "Strong wrists from \(k)! \(s) struck it with immense power from twelve yards, but the keeper parried it firmly away.",
            "A crucial intervention by \(k)! An outstretched boot deflects what looked a certain goal behind for a corner.",
            "HOW HAS HE SAVED THAT?! \(s)'s header is going in until \(kl) somehow claws it off the line.",
            "\(k) makes himself enormous. \(s) tries to go round him, then past him, and \(kl) blocks both.",
            "\(s) volleys from eight yards and \(k) beats it away with both fists. Outstanding goalkeeping.",
            "Save of the season contender! \(k) changes direction mid-dive to keep out \(s)'s deflected shot.",
            "\(s) picks his spot, low to the left, and \(k) gets down like a cat to turn it past the post.",
            "\(k) is off his line in a flash to close down \(s), who has to shoot early. Saved!",
            "Point-blank! \(s) can't believe it. \(kl) didn't even see it, he just stuck out a hand and it hit him.",
            "\(s) catches it perfectly from the edge of the area and \(k) flies to his right to tip it onto the bar and over!",
            "\(k) spreads himself brilliantly to deny \(s), who had the whole goal to aim at.",
            "A one-handed save from \(k), back-pedalling to keep out \(s)'s looping header.",
            "\(s) goes for the far corner, \(k) goes with it, and the keeper's fingertips win the battle.",
            "\(keeperClub.name)'s fans are chanting \(kl)'s name after that stop from \(s)'s close-range effort.",
            "Brilliant from \(k)! \(s)'s shot took a deflection and the keeper still adjusted to palm it away.",
            "\(k) makes it look easy, but that was a superb save, low and strong to keep out \(s).",
            "The rebound falls to \(s), who smashes it goalward, and \(k) is up off the floor to save that too!",
            "\(s) slips through and dinks it, but \(k) reads it and claws the ball out from under the bar."
        ]
    }

    static func goodSave(keeper: Player, shooter: Player) -> [String] {
        let k = keeper.fullName, s = shooter.fullName
        return [
            "\(s) gets a clean strike away from inside the box, but \(k) is down well to push it round the post.",
            "Good save from \(k), standing firm to block \(s)'s shot from close range.",
            "\(s) drives it low towards the far corner; \(k) gets across and turns it away.",
            "\(k) reads \(s)'s near-post effort and smothers it at the second attempt.",
            "\(s) shoots on the turn and \(k) has to be alert to beat it away.",
            "\(k) gets two strong hands to \(s)'s header and holds on under pressure.",
            "A firm shot from \(s), but \(k) is well positioned and pushes it to safety.",
            "\(s) tries to squeeze it in at the near post; \(k) is having none of it.",
            "\(k) makes a smart save down to his left from \(s)'s curling effort.",
            "\(s)'s angled drive is tipped wide by the alert \(k).",
            "\(k) tips \(s)'s dipping effort over the crossbar. Corner.",
            "\(s) gets his shot away quickly, but \(k) gets his body behind it."
        ]
    }

    static func routineSave(keeper: Player, shooter: Player) -> [String] {
        let k = keeper.fullName, s = shooter.fullName
        return [
            "\(s) tries his luck from distance. Straight at \(k), who gathers comfortably.",
            "A tame effort from \(s) rolls through to \(k).",
            "\(s) hits it first time from the edge of the area; \(k) holds on without fuss.",
            "Half-chance for \(s), but the shot lacks power and \(k) collects.",
            "\(s) shoots from a narrow angle. \(k) covers his near post and gathers.",
            "A looping header from \(s) drops into \(k)'s arms.",
            "\(s) has a go on the swivel, but it's a comfortable catch for \(k).",
            "\(k) watches \(s)'s bobbling shot all the way into his gloves.",
            "Speculative from \(s), and \(k) barely has to move.",
            "\(s) drags his shot towards the near post; \(k) falls on it.",
            "\(k) claims \(s)'s scuffed effort at the second attempt.",
            "A routine stop for \(k) from \(s)'s low drive."
        ]
    }

    // MARK: - Misses

    static func bigMiss(shooter: Player, club: Club) -> [String] {
        let s = shooter.fullName, l = shooter.lastName, c = club.name
        return [
            "HOW DID HE MISS THAT?! The ball was served on a plate inside the six-yard box, but \(s) somehow skewed it wide!",
            "A wasted opportunity for \(c). \(s) had time and space to pick his spot, but rushed it and blasted it into the stands.",
            "Groans around the ground as \(s) drags his effort wide when passing to a team-mate was the better option.",
            "\(s) holds his head in his hands. He created the opening with fantastic footwork, but snatched at the finish.",
            "A great counter-attack comes to nothing. \(s) was in on goal with runners either side, but his chip drifted over.",
            "Frustration as \(s) scuffs a tame shot into the turf from a prime scoring position.",
            "\(s) blazes over! With the defence retreating, he opted for power over placement and cleared the bar by ten yards.",
            "A glorious delivery went begging as \(s) mistimed his jump, brushing the ball with his shoulder.",
            "Open goal! And \(s) has put it wide! He'll be seeing that one in his sleep tonight.",
            "\(l) only had the keeper to beat, and he passed it straight to him.",
            "\(s) was on his own six yards out and headed it over. The \(c) bench can't believe it.",
            "One-on-one, and \(s) tries to round the keeper but takes it too wide. The chance is gone.",
            "\(s) slides in at the back post and somehow gets it all wrong. The ball goes behind off his shin.",
            "That should be a goal! \(s) has two bites at it from a yard out and misses both.",
            "\(s) gets under it completely and it balloons over. A huge let-off.",
            "\(l) goes for the corner when he could have walked it in. Wide.",
            "\(c) cut the defence open, and \(s) shoots straight at the only defender on the line.",
            "The ball falls kindly for \(s) in the box, and he side-foots it the wrong side of the post. Big chance.",
            "\(s) tries to place it and gets no power on it at all. It rolls harmlessly wide.",
            "\(s) leans back and lifts it over from the penalty spot. He knows he should have scored.",
            "The keeper is stranded and \(s) hits the side netting from eight yards. What a chance!"
        ]
    }

    static func woodwork(shooter: Player) -> [String] {
        let s = shooter.fullName, l = shooter.lastName
        return [
            "OFF THE BAR! \(s) crashes a thunderbolt against the crossbar! The frame is still shaking as it's scrambled clear.",
            "OFF THE POST! A beautiful curling strike from \(s) beats the keeper, but smacks the inside of the far post and bounces out!",
            "HOW HAS THAT STAYED OUT?! \(s)'s header loops over the keeper, hits the bar, bounces on the line and is hooked clear!",
            "WOODWORK AGAIN! \(s) drills a low drive that comes back off the base of the post with the keeper beaten.",
            "\(s) hits the bar from 30 yards! The ball comes down and is booted to safety.",
            "Unlucky \(l)! His deflected shot loops onto the top of the crossbar.",
            "The post saves the keeper! \(s)'s shot was going in all the way.",
            "\(s)'s header thuds against the upright. Inches from a goal.",
            "Off the inside of the post and along the line! \(s) cannot believe it hasn't gone in.",
            "\(s) volleys against the underside of the bar. It comes down, and the referee says it hasn't crossed the line.",
            "The crossbar is still vibrating after \(s)'s free kick crashed against it.",
            "\(s) rattles the post with a low shot. The rebound is cleared before anyone can react.",
            "Agonising for \(l)! He beats the keeper with a lovely chip that hits the bar and bounces away."
        ]
    }

    static func decentMiss(shooter: Player, club: Club) -> [String] {
        let s = shooter.fullName
        return [
            "\(s) finds a yard of space in the box but drags his shot wide of the far post.",
            "Decent opening for \(club.name): \(s) meets the cross but his header goes over.",
            "\(s) gets on the end of a cut-back and side-foots it the wrong side of the post.",
            "\(s) shoots across goal from an angle. Wide.",
            "\(s) catches it on the volley, but it flies a couple of yards over.",
            "\(s) gets a header in from the corner, but it lacks direction.",
            "\(s) turns sharply in the area and shoots, but it curls wide.",
            "A clever run from \(s), but his finish isn't as good. Over the bar.",
            "\(s) hits it with the outside of his foot and it bends away from the target.",
            "\(s) can't keep his shot down from twelve yards.",
            "\(s) tries to tuck it inside the near post and misses by a foot."
        ]
    }

    static func poorMiss(shooter: Player, club: Club) -> [String] {
        let s = shooter.fullName
        return [
            "\(s) has a go from 30 yards. It sails well over.",
            "Ambitious from \(s), whose long-range effort never troubles the target.",
            "\(s) snatches at a half-chance and slices it into the stand.",
            "Speculative from \(s). Off target.",
            "\(s) shoots from distance and the ball ends up nearer the corner flag.",
            "\(club.name) work it to \(s), whose effort from range is high and wide.",
            "\(s) tries the spectacular and gets it badly wrong.",
            "A hopeful strike from \(s) that the keeper watches sail past.",
            "\(s) leans back on it and the ball disappears into the crowd.",
            "Wild from \(s). That one is still going.",
            "\(s) has a pop from an angle. It goes for a goal kick."
        ]
    }

    static func blocked(shooter: Player, club: Club, defending: Club) -> [String] {
        let s = shooter.fullName, d = defending.name
        return [
            "\(s) shapes to shoot from inside the area, but a \(d) defender throws himself in the way.",
            "Big block! \(s)'s goal-bound effort cannons off a body in the six-yard box.",
            "\(club.name) work it to \(s), whose shot is charged down at the last moment.",
            "Brave defending from \(d): \(s)'s strike is blocked on the line.",
            "\(s) winds up for the shot and a sliding defender gets there first.",
            "\(d) put bodies on the line! \(s)'s shot hits a defender and loops away.",
            "\(s)'s shot is blocked, the rebound is blocked again. \(d) are defending for their lives.",
            "Superb last-ditch block from \(d) to deny \(s).",
            "\(s) gets the shot away, but it smacks into the defender's back.",
            "Charged down! \(s) never got a clean sight of goal.",
            "A crowded box, and \(s)'s shot hits a wall of \(d) shirts.",
            "\(s) drops the shoulder and shoots, but it's blocked behind for a corner."
        ]
    }

    static func freeKickSaved(taker: Player) -> [String] {
        let t = taker.fullName
        return [
            "\(t) curls the free kick over the wall, but the keeper is equal to it.",
            "\(t) goes for goal from the set piece. Saved, low to the keeper's left.",
            "Free kick in a dangerous spot. \(t) hits it well, but straight at the keeper.",
            "\(t) whips it over the wall and the keeper tips it over the bar.",
            "\(t) tries to beat the keeper at his near post. He's ready for it.",
            "A powerful free kick from \(t) is beaten away by the keeper.",
            "\(t) dips it over the wall and the keeper has to stretch to push it out.",
            "\(t) goes low under the jumping wall, but the keeper has it covered.",
            "Lovely technique from \(t), and a lovely save to match it.",
            "\(t)'s free kick takes a nick off the wall and the keeper adjusts to hold it."
        ]
    }

    // MARK: - Fouls

    static func foul(player: Player, victim: Player?, club: Club) -> [String] {
        let p = player.fullName, l = player.lastName, c = club.name
        let v = victim?.fullName ?? "his opponent"
        let vl = victim?.lastName ?? "the attacker"
        return [
            "\(p) clips the heels of \(v) and the referee blows for a free kick.",
            "Free kick. \(p) leans into \(v) and sends him sprawling.",
            "\(p) goes through the back of \(v). The referee has a word.",
            "\(v) is too quick for \(p), who brings him down with a cynical little trip.",
            "A shirt pull from \(p) on \(v). Free kick, and a stern look from the referee.",
            "\(p) mistimes his challenge on \(v) and the whistle goes.",
            "\(v) shields the ball well and \(p) can only stop him by fouling him.",
            "Clumsy from \(l). He catches \(vl) on the ankle as he tries to nick the ball.",
            "\(p) and \(v) tangle on the halfway line. Free kick given against \(l).",
            "\(v) goes down under a challenge from \(p). The referee gives it.",
            "\(p) leaves a bit on \(v). Nothing more than a free kick, the referee decides.",
            "Hand on the back from \(p), and \(v) hits the deck. Foul.",
            "\(p) blocks off \(v)'s run. The referee spots it and penalises \(c).",
            "\(v) skips past one challenge but \(p) takes his legs from under him.",
            "\(p) wins the ball but goes through \(v) to get it. Free kick.",
            "A frustrated \(p) bundles into \(v). The referee waves play on, then pulls it back for the foul.",
            "\(v) is held back by \(p) as he tries to spin away. The referee isn't fooled.",
            "\(p) slides in late on \(v). That one stung, and \(c)'s defender knows it.",
            "Aerial challenge between \(p) and \(v), and \(l) used his arm. Free kick.",
            "\(p) stands on \(v)'s foot as they jostle for the ball. Free kick.",
            "\(v) gets his body between man and ball, and \(p) climbs all over him.",
            "\(p) dives in, \(v) has already gone, and the foul is given.",
            "Petty from \(l), a little kick at \(vl)'s heels after the ball has gone.",
            "\(p) catches \(v) with a trailing leg. Accidental, but a foul all the same.",
            "\(v) is bundled over by \(p) on the edge of the area. The referee points to the spot of the foul, just outside.",
            "\(p) gets nothing but man as he lunges at \(v). The crowd howl for a card, but the referee shows restraint.",
            "\(v) tries to turn \(p), who simply pulls him back. Free kick.",
            "\(p) slides in and takes \(v) out near the touchline. \(c) are breaking up the play.",
            "Obstruction by \(p) on \(v). Indirect free kick, the referee signals.",
            "\(p) gives \(v) a shove in the back as they chase a long ball. Foul.",
            "\(v) holds off \(p) and draws the foul. Clever play.",
            "\(p) is penalised for a high boot as he challenges \(v) for a bouncing ball.",
            "\(v) goes down a little easily under \(p)'s challenge, but the referee gives the free kick.",
            "\(p) tugs at \(v)'s arm. The referee is close by and blows straight away.",
            "A crunching tackle from \(p) sends \(v) flying. The referee decides it was a foul but no more.",
            "\(p) arrives a fraction late on \(v). The referee plays advantage, then goes back for the foul."
        ]
    }

    // MARK: - Cards

    static func yellow(player: Player, victim: Player?, club: Club) -> [String] {
        let p = player.fullName, l = player.lastName, c = club.name
        let v = victim?.fullName ?? "his opponent"
        return [
            "Late challenge by \(p) on \(v). He arrived a fraction after the ball had gone and wiped him out. A deserved caution.",
            "Tactical foul. \(p) pulls back \(v)'s shirt to stop a dangerous break. The referee reaches into his pocket without hesitation.",
            "Dissent from \(p). After disputing a decision in the referee's face, he talks himself into the book.",
            "Persistent fouling. After several warnings, \(p) brings down \(v) once too often and is booked.",
            "A heavy sliding tackle. \(p) got a piece of the ball, but followed through on \(v). Yellow card.",
            "\(p) scythes down \(v) on the counter. A textbook booking.",
            "\(p) goes in high on \(v) and the referee has no hesitation. Yellow.",
            "\(v) was away until \(p) dragged him down. Booked, and he knows it.",
            "\(p) clatters into \(v) from behind. The referee books him and has a long word.",
            "\(l) is booked for a reckless lunge on \(v). He can't have any complaints.",
            "\(p) kicks the ball away after the whistle. Silly, and it earns him a yellow card.",
            "\(p) is shown a yellow for an elbow as he challenges \(v) in the air.",
            "\(p) chops down \(v) as he breaks through midfield. \(c) take one for the team, and \(l) is booked.",
            "\(p) protests too much about the free kick and the referee books him for dissent.",
            "\(p) leaves his foot in on \(v). The referee shows him the yellow card.",
            "A cynical trip on \(v) by \(p) halts the break. It's a booking.",
            "\(p) wraps an arm around \(v)'s neck at a corner. The referee spots it: yellow card.",
            "\(p) is cautioned for simulation, the referee deciding he went down far too easily.",
            "\(p) and \(v) square up after a challenge. The referee books \(l) as the instigator.",
            "\(p) races in and takes out \(v) near the corner flag. A clear yellow.",
            "Into the book goes \(p), for a rugby tackle on the marauding \(v).",
            "\(p) handles deliberately to stop \(v)'s pass. Yellow card.",
            "\(p) dives in, misses the ball by a mile and catches \(v). Booked.",
            "\(p) leaves the wall before the free kick is taken and is booked for encroachment.",
            "\(p)'s challenge on \(v) has the crowd on their feet. The referee settles for yellow.",
            "\(v) skins \(p) for pace, and \(l) is booked for the shirt-pull that follows.",
            "\(p) goes to ground and takes man and ball. The referee thinks it's more man: yellow.",
            "That's a booking for \(p). \(v) needs treatment after the challenge."
        ]
    }

    static func straightRed(player: Player, victim: Player?, club: Club) -> [String] {
        let p = player.fullName, c = club.name
        let v = victim?.fullName ?? "his opponent"
        return [
            "HE'S OFF! A reckless, two-footed lunge on \(v) leaves the referee no choice. Straight red for \(p)! \(c) are down to ten!",
            "DISASTER FOR \(c.uppercased())! \(p) hauls back \(v), who was clean through on goal. Denial of a goalscoring opportunity. Off he goes!",
            "DRAMA! Tempers boil over, and the referee sees \(p) raise his hands to \(v). The red card comes out amid furious protests!",
            "Red card! \(p) goes in over the ball on \(v), studs up. That's a horror challenge and he's gone.",
            "\(p) is sent off! He lashes out at \(v) off the ball and the assistant has seen everything.",
            "STRAIGHT RED! \(p) went through \(v) like he wasn't there. A dangerous, dangerous tackle.",
            "\(p) is the last man and brings down \(v) on the edge of the box. The referee reaches for red.",
            "An elbow from \(p) into \(v)'s face. Violent conduct. Off!",
            "\(p) dives in with both feet and catches \(v) high on the shin. The referee doesn't hesitate: red card.",
            "\(c) are down to ten men! \(p) handles on the line to deny \(v) and is dismissed.",
            "A moment of madness from \(p), who stamps on \(v). The red card is shown immediately.",
            "\(p) is shown a straight red for a wild challenge on \(v). He trudges off without looking back.",
            "The referee consults the monitor and upgrades it: \(p)'s tackle on \(v) is a red card!",
            "Off he goes! \(p) loses his head and headbutts \(v). Unforgivable."
        ]
    }

    static func secondYellow(player: Player, victim: Player?, club: Club) -> [String] {
        let p = player.fullName, l = player.lastName, c = club.name
        let v = victim?.fullName ?? "his opponent"
        return [
            "SECOND YELLOW! \(p) mistimes a trip on \(v) to stop a counter. A second caution, then the red. He walks off in disbelief.",
            "\(p) was walking a tightrope and he's fallen off. A second booking for the foul on \(v), and \(c) are down to ten.",
            "That's two yellows for \(p)! He couldn't resist going in on \(v), and now he's off.",
            "Silly, silly. \(p), already booked, pulls back \(v) and gets his marching orders.",
            "\(l) dives in on \(v) when he didn't need to. Second yellow, red card, and an early bath.",
            "The referee had warned him. \(p) brings down \(v) again and sees a second yellow.",
            "\(p) argues with the referee, already on a yellow. Big mistake: a second card, and he's off.",
            "Off goes \(p)! A second booking for kicking the ball away. His manager is furious.",
            "\(p) goes to ground on \(v), already on a booking. Off!",
            "Red card for \(p) after a second bookable offence, a late one on \(v).",
            "\(c)'s manager wanted him off before this happened. \(p) takes down \(v) and gets a second yellow.",
            "And that's that for \(p). A tug on \(v)'s shirt brings a second yellow and a red."
        ]
    }

    static func timeWasting(player: Player, club: Club) -> [String] {
        let p = player.fullName, c = club.name
        return [
            "\(p) takes an age over the restart and the referee has seen enough. Booked for time-wasting.",
            "\(c) are running the clock down and \(p) pays for it with a yellow card.",
            "The referee books \(p) for delaying the restart. The crowd make their feelings known.",
            "\(p) walks the ball to the spot at a funeral pace. Yellow card.",
            "\(p) is booked for kicking the ball away to waste time.",
            "Cramp, apparently, for \(p). The referee isn't convinced and books him for time-wasting.",
            "\(p) holds onto the ball at a throw-in until the referee shows him a card.",
            "\(c) have been slowing it down all half, and \(p) is the one who gets booked for it."
        ]
    }

    // MARK: - Knocks and injuries

    static func knock(player: Player, club: Club) -> [String] {
        let p = player.fullName, c = club.name
        return [
            "\(p) needs treatment after a heavy challenge, but he's back on his feet and carries on.",
            "\(p) goes down holding his ankle. The physio has a look; he'll try to run it off.",
            "A knock for \(p), who limps for a few moments before carrying on. \(c)'s bench will be watching him.",
            "Play is held up while \(p) is treated for a dead leg. He continues, gingerly.",
            "\(p) takes a boot to the shin. Some magic spray, and he's back up.",
            "\(p) lands awkwardly after a header and stays down. After treatment, he's OK to continue.",
            "A clash of heads! \(p) is checked over by the medical staff and allowed to carry on.",
            "\(p) is caught in the face by a flailing arm. He's patched up and back on.",
            "\(p) is limping, but signals to the bench that he can continue.",
            "\(p) gets a whack on the thigh. He's hobbling, but stays on.",
            "Treatment for \(p), who rolled his ankle. He tests it, nods, and carries on.",
            "\(p) is winded after a collision and needs a minute. He's fine to continue.",
            "\(p) needs strapping on his knee, but he won't be coming off just yet."
        ]
    }

    static func playingThroughInjury(player: Player, club: Club) -> [String] {
        let p = player.fullName, c = club.name
        return [
            "\(p) pulls up and grabs the back of his thigh. He insists he can carry on, but he's clearly not right.",
            "\(p) is hobbling. He waves away the physio for now, but \(c) may need to make a change.",
            "Something has gone for \(p). He's still out there, but he's a passenger at the moment.",
            "\(p) is running at half pace. That looks like a muscle problem.",
            "\(p) is clutching his hamstring between plays. He wants to stay on, but it looks a gamble.",
            "\(p) has gone very quiet since that challenge, and he's limping badly.",
            "The \(c) bench are talking to the physio about \(p), who is struggling to run.",
            "\(p) stretches his calf every time the ball goes dead. He won't last much longer.",
            "\(p) is trying to run it off. He can barely jog."
        ]
    }

    static func injuryOff(player: Player, club: Club, injury: String) -> [String] {
        let p = player.fullName, c = club.name
        let capitalised = injury.prefix(1).uppercased() + String(injury.dropFirst())
        return [
            "Play stops as \(p) goes down clutching his leg in obvious pain. The physios rush on, and he's signalled off with what looks like \(injury).",
            "Bad news for \(c). \(p) pulls up sharply and sits on the turf. It looks like \(injury), and he can't continue.",
            "\(p) goes down after the challenge and doesn't get up. The stretcher is called for. It looks like \(injury).",
            "\(p) tries to carry on but it's no good. He limps off with what looks like \(injury).",
            "A worrying moment. \(p) is down, the medical team are on, and he's helped off with \(injury).",
            "\(p) lands awkwardly and immediately signals to the bench. That looks like \(injury).",
            "The applause rings round the ground as \(p) is carried off. It looks like \(injury), and \(c) will be sweating on the scan.",
            "\(p) clutches the back of his leg after a sprint. It's \(injury), by the look of it, and he's done for the day.",
            "\(p) goes over on his ankle and is in real pain. \(capitalised) is the early fear.",
            "\(c)'s physio shakes his head. \(p) is coming off with \(injury).",
            "\(p) is helped off with his arms around two members of the medical staff. It looks like \(injury).",
            "\(p) sinks to the floor in tears. That looks like \(injury), and a long lay-off could follow."
        ]
    }

    /// Appended to an injury once the replacement comes on.
    static func injuryReplacement(incoming: Player, injured: Player) -> [String] {
        let i = incoming.fullName, o = injured.lastName
        return [
            "\(i) comes on in his place.",
            "\(i) replaces him.",
            "\(i) is sent on to take \(o)'s place.",
            "\(i) strips off on the touchline and comes on for \(o).",
            "On comes \(i) as the replacement.",
            "\(i) is the man to replace \(o)."
        ]
    }

    // MARK: - Substitutions

    static func substitution(incoming: Player, outgoing: Player, club: Club, reason: MatchEngine.SubReason) -> [String] {
        let i = incoming.fullName, o = outgoing.fullName, ol = outgoing.lastName, c = club.name
        switch reason {
        case .injury:
            return [
                "\(o) cannot continue and is helped off. \(i) comes on in his place.",
                "Enforced change for \(c): the injured \(o) makes way for \(i).",
                "\(i) replaces the injured \(o), who is helped down the tunnel.",
                "\(ol) is out of the game. \(i) gets the call from the bench.",
                "\(c) lose \(o) to injury. On comes \(i), with a few hurried instructions.",
                "\(i) comes on for \(o), who limps straight down the tunnel for treatment."
            ]
        case .fatigue:
            return [
                "\(o) has run himself into the ground and makes way for fresh legs: \(i) is on.",
                "Tired legs for \(o), who is replaced by \(i).",
                "\(c) freshen things up: \(i) on for the weary \(o).",
                "\(o) is out on his feet. \(i) replaces him.",
                "\(o) gets a warm hand from the crowd after a tireless shift. \(i) comes on.",
                "\(i) comes on to give \(c) some energy, with \(o) running on empty.",
                "\(o) is cramping up and comes off. \(i) is on."
            ]
        case .chasing:
            return [
                "\(c) need a goal. \(o) is sacrificed for another attacker, \(i).",
                "All hands to the pumps for \(c): \(i) comes on, \(o) comes off.",
                "\(c) go for broke. \(i), an extra forward, replaces \(o).",
                "\(i) is thrown on to chase the game. \(o) makes way.",
                "Attacking change from \(c): \(i) on for \(o). It's now or never.",
                "\(o) off, \(i) on, and \(c) are going to throw everything at this."
            ]
        case .protecting:
            return [
                "\(c) look to shut up shop: \(i) comes on to shore things up, \(o) makes way.",
                "\(i) on, \(o) off. \(c) are protecting what they have.",
                "A defensive change from \(c): \(i) replaces \(o) to see the game out.",
                "\(c) bring on \(i) for \(o). Clearly, they're happy with this scoreline.",
                "Time to batten down the hatches: \(i) comes on for \(o).",
                "\(o) makes way for \(i), an extra body in front of the back four."
            ]
        case .booked:
            return [
                "\(o), on a yellow card and living dangerously, is taken off before he gets a second. \(i) replaces him.",
                "\(c) aren't taking any chances with the booked \(o). \(i) comes on.",
                "\(o) has been flirting with a second yellow. Off he comes, on goes \(i).",
                "A sensible change: \(i) on for \(o), who was one tackle from an early bath.",
                "\(o) is withdrawn on a booking. \(i) takes his place."
            ]
        case .poorForm:
            return [
                "It hasn't been \(o)'s day, and the manager has seen enough. \(i) is on.",
                "\(o) is hooked. \(i) replaces him after a quiet afternoon.",
                "\(o) trudges off without a glance at the bench. \(i) is on.",
                "\(c) make a change: \(i) for the struggling \(o).",
                "\(o) has been off the pace and makes way for \(i).",
                "The manager has given \(o) long enough. On comes \(i)."
            ]
        case .tactical:
            return [
                "A tactical change for \(c): \(i) on, \(o) off.",
                "\(c) switch things around: \(i) replaces \(o).",
                "\(i) comes on for \(o) as \(c) change shape.",
                "Rethink from the bench: \(o) off, \(i) on.",
                "\(i) is on for \(o), and \(c) look to change the pattern of the game.",
                "A like-for-like swap for \(c): \(i) replaces \(o)."
            ]
        case .manager:
            return [
                "The manager makes his move: \(i) comes on for \(o) with instructions from the touchline.",
                "\(i) replaces \(o). The manager has a long word with him before he goes on.",
                "Change for \(c): \(i) on, \(o) off.",
                "\(o) makes way, and \(i) jogs on with a slap on the back from the manager.",
                "\(i) comes on for \(o). Can he make a difference?",
                "\(c)'s manager turns to his bench: \(i) for \(o)."
            ]
        }
    }

    // MARK: - Goals: the extras

    /// Credit for the provider.
    static func assistPraise(assister: Player, scorer: Player) -> [String] {
        let a = assister.fullName, al = assister.lastName, s = scorer.lastName
        return [
            "Take a bow, \(a). What a ball.",
            "The assist from \(a) deserves just as much credit.",
            "\(al) made that. Superb vision.",
            "\(s) will be buying \(al) dinner after that delivery.",
            "\(a) picked him out perfectly.",
            "Lovely work from \(a) in the build-up.",
            "\(a)'s pass took three defenders out of the game.",
            "\(al) with the assist, and it was a beauty.",
            "\(s) runs straight to \(al) to celebrate. He knows who to thank.",
            "That's \(al)'s doing as much as \(s)'s."
        ]
    }

    /// The scorer's celebration.
    static func celebration(scorer: Player, club: Club) -> [String] {
        let s = scorer.fullName, l = scorer.lastName
        return [
            "\(l) wheels away, arms outstretched.",
            "\(s) sprints to the corner flag and slides on his knees.",
            "\(l) kisses the badge.",
            "\(s) points to the sky.",
            "\(l) is mobbed by his team-mates.",
            "\(s) leaps into the crowd!",
            "A somersault from \(l)! That's how much it meant.",
            "\(s) stands still in front of the fans, soaking it in.",
            "\(l) runs to the bench and hugs the manager.",
            "\(s) does his trademark celebration.",
            "\(l) can't stop smiling as the team pile on top of him.",
            "\(s) shushes the crowd.",
            "\(l) holds up his shirt to the fans.",
            "\(s) is buried under a pile of bodies.",
            "\(l) beats his chest in front of the supporters."
        ]
    }

    /// How the keeper felt about it.
    static func keeperReaction(keeper name: String) -> [String] {
        // "the keeper" starts a sentence here.
        let keeper = name.prefix(1).uppercased() + String(name.dropFirst())
        return [
            "\(keeper) had no chance.",
            "\(keeper) didn't move.",
            "\(keeper) got a touch, but not enough.",
            "\(keeper) will feel he could have done better.",
            "\(keeper) is left on the floor, punching the turf.",
            "\(keeper) was beaten all ends up.",
            "\(keeper) dived the right way, but it was too well placed.",
            "\(keeper) is screaming at his defenders.",
            "\(keeper) can only pick the ball out of the net."
        ]
    }

    // MARK: - The mood of the ground

    static func atmosphereExtra(home: Club, away: Club, minute: Int, homeGoals: Int, awayGoals: Int) -> [String] {
        let h = home.name, a = away.name
        if minute <= 20 {
            return [
                "A scrappy start. Neither side has settled on the ball yet.",
                "\(a) are happy to sit deep and let \(h) have the ball in these early stages.",
                "The noise from the stands hasn't let up since kick-off.",
                "Early free kicks and plenty of fouls: this is going to be a battle.",
                "\(h) are probing down the flanks, looking for the early opening.",
                "Long balls from \(a) early on, trying to turn the \(h) defence.",
                "A lot of hit and hope so far. Somebody needs to get the ball down and play.",
                "\(a)'s fans are in fine voice in the corner of the ground."
            ]
        }
        if minute >= 75 {
            if homeGoals == awayGoals {
                return [
                    "Both managers are on the edge of their technical areas. Every decision is being argued.",
                    "One goal will surely win this. Who wants it more?",
                    "\(h) are pushing, but \(a) look dangerous every time they break.",
                    "Legs are tiring. Space is opening up all over the pitch.",
                    "The fourth official is getting an earful from both benches."
                ]
            }
            return [
                "The trailing side are throwing men forward. It's backs to the wall now.",
                "Every clearance is being cheered like a goal.",
                "The leaders are taking the ball into the corner at every opportunity.",
                "Fans are whistling for full time.",
                "Nerves are fraying. A long ball is hoisted into the box, and headed clear."
            ]
        }
        return [
            "A long spell of possession for \(h), but nothing is opening up.",
            "\(a) press high and force a hurried clearance.",
            "The game has settled into a rhythm now, a lot of it in midfield.",
            "Neither side is giving anything away. It's tight and tactical.",
            "\(h) switch the play from left to right, looking for a gap.",
            "A Mexican wave goes round the ground. The football has gone a little quiet.",
            "\(a)'s full-backs are pushing on. It's leaving gaps at the back.",
            "The referee is letting a lot go. Both sides are happy to get stuck in.",
            "\(h) try to play through the lines, but \(a) are compact.",
            "The ball is pinging around the middle of the park without either side taking control."
        ]
    }

    static func halfTime(home: Club, away: Club, homeGoals: Int, awayGoals: Int) -> [String] {
        let h = home.name, a = away.name
        if homeGoals == awayGoals && homeGoals == 0 {
            return [
                "Half-time, and it's goalless. A cagey 45 minutes; both managers will want more after the break.",
                "No goals at the break. Plenty of effort, very little end product.",
                "0-0 at half-time. Chances have been at a premium.",
                "The whistle goes for half-time with nothing to separate \(h) and \(a)."
            ]
        }
        if homeGoals == awayGoals {
            return [
                "An entertaining first half ends level at \(homeGoals)-\(awayGoals). This one is on a knife-edge.",
                "All square at the break, \(homeGoals)-\(awayGoals), after a lively half.",
                "\(h) and \(a) go in level at \(homeGoals)-\(awayGoals). Plenty to talk about in both dressing rooms.",
                "Half-time: honours even at \(homeGoals)-\(awayGoals)."
            ]
        }
        let leader = homeGoals > awayGoals ? h : a
        let trailer = homeGoals > awayGoals ? a : h
        let score = "\(max(homeGoals, awayGoals))-\(min(homeGoals, awayGoals))"
        return [
            "Half-time, and \(leader) lead \(score). \(trailer) need a response.",
            "\(leader) go in \(score) up. \(trailer)'s manager has some talking to do.",
            "The whistle goes with \(leader) \(score) ahead. A good half's work.",
            "\(score) to \(leader) at the break. \(trailer) have it all to do."
        ]
    }

    static func fullTime(home: Club, away: Club, homeGoals: Int, awayGoals: Int) -> [String] {
        let h = home.name, a = away.name
        if homeGoals == awayGoals {
            return [
                "Full time! Points shared after a hard-fought match. A draw is probably a fair result.",
                "The final whistle goes. \(h) and \(a) can't be separated.",
                "It ends level at \(homeGoals)-\(awayGoals). Both sides will feel they could have won it.",
                "Full time, \(homeGoals)-\(awayGoals). A point apiece."
            ]
        }
        let winner = homeGoals > awayGoals ? h : a
        let loser = homeGoals > awayGoals ? a : h
        let score = "\(max(homeGoals, awayGoals))-\(min(homeGoals, awayGoals))"
        let margin = abs(homeGoals - awayGoals)
        if margin >= 3 {
            return [
                "Full time, and a thrashing: \(winner) win \(score). \(loser) were never in it.",
                "\(winner) run riot! It finishes \(score).",
                "A statement win for \(winner), \(score). \(loser) will want to forget this one quickly."
            ]
        }
        return [
            "Full time! \(winner) take the points with a \(score) win.",
            "The final whistle goes and \(winner) have done it, \(score).",
            "\(winner) see it out to win \(score). \(loser) head home empty-handed.",
            "It finishes \(score) to \(winner). Job done."
        ]
    }
}
