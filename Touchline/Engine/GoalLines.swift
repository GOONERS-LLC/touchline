//
//  GoalLines.swift
//  Touchline
//
//  The words behind every goal. Each kind of finish has several ways of
//  being told, and the line about what it means for the match is drawn from
//  its own pool, so even two tap-ins in the same game read differently.
//

import Foundation

enum GoalLines {

    static func body(type: Commentary.GoalType, scorer: Player, assister: Player?, keeper: String,
                     club: Club, opponent: Club, minute: Int) -> String {
        let S = scorer.fullName
        let s = scorer.lastName
        let A = assister?.fullName ?? "a team-mate"
        let a = assister?.lastName ?? "his team-mate"
        let from = assister.map { " from \($0.fullName)" } ?? ""
        let K = keeper
        let lines: [String]
        switch type {
        case .tapIn:
            lines = [
                "\(A) broke free down the flank and drilled a low, fizzing cross across the six-yard box. \(S) ghosted in between two defenders to bundle it home from point-blank range.",
                "It's the simplest of finishes. \(A) squares it across the face of goal and \(S) only has to put his foot through it from two yards.",
                "\(A) beats his man on the byline and pulls it back along the turf. \(S) has gambled on the near post and taps it in before anyone can react.",
                "A low ball fizzes across the six-yard box\(from), \(K) can't get a glove to it, and \(S) is there at the back post to stab it over the line.",
                "Poacher's goal. \(S) reads the cross\(from) a split second before his marker and prods it in from close range."
            ]
        case .toweringHeader:
            lines = [
                "A pinpoint cross is whipped into the danger zone by \(A)! \(S) rises majestically above the centre-backs and powers a header into the top corner. \(K) was rooted to the spot.",
                "\(A) floats it to the far post and \(S) hangs in the air for what feels like a second before nodding it down and in off the turf.",
                "What a leap! \(S) climbs above two defenders to meet \(a)'s cross and thumps a header past \(K).",
                "\(S) loses his marker with a little shove-free shuffle and heads \(a)'s inswinger back across \(K) and into the corner.",
                "The cross\(from) is deep but \(S) gets there, arching his neck to loop a header over \(K) and under the bar."
            ]
        case .longRangeScreamer:
            lines = [
                "WHAT A STRIKE! \(S) picks the ball up 30 yards out, takes one touch to set himself and unleashes a rocket that swerves into the top corner!",
                "Nobody closes \(s) down, so he has a go from 25 yards. It never gets more than a foot off the ground and skids in off the inside of the post.",
                "\(S) lets fly from distance and the ball dips viciously at the last moment. \(K) gets nowhere near it.",
                "Out of nothing! A clearance falls to \(S) way out and he smashes it first time. It's still rising as it hits the net.",
                "\(S) shifts it half a yard and curls one from range that bends away from \(K)'s dive and kisses the inside of the post on its way in."
            ]
        case .clinicalPenalty:
            lines = [
                "\(S) steps up amid deafening whistles, stutters his run-up and sends \(K) the wrong way, rolling it calmly into the bottom corner.",
                "No messing about from \(s). He smashes the penalty high into the roof of the net, and \(K) is still in mid-dive when it hits the netting.",
                "\(K) guesses right and gets a hand to it, but \(S) has struck it so firmly that it squirms over the line.",
                "The cheekiest of penalties! \(S) waits for \(K) to commit and dinks it straight down the middle.",
                "\(S) places the ball, walks back, and drills it low into the corner. Textbook.",
                "A long wait for the referee's check, but it doesn't bother \(s). He sends \(K) left and the ball goes right."
            ]
        case .curlingFreeKick:
            lines = [
                "Breathtaking technique from \(S)! From 25 yards he whips the free kick up and over the wall, and it dips viciously into the top corner.",
                "\(S) goes for power instead of placement and the free kick zips through a gap in the wall and past the unsighted \(K).",
                "\(S) curls the free kick around the outside of the wall. \(K) takes a step the wrong way and can only watch it nestle inside the post.",
                "A free kick from a tight angle, and \(s) catches everyone out by going for goal. It sneaks inside the near post!",
                "The wall jumps and \(S) rolls it underneath them. Cheeky, clever and in the bottom corner."
            ]
        case .soloRun:
            lines = [
                "Sensational from \(S)! He picks the ball up near halfway, drops a shoulder to skip past two challenges, cuts inside the full-back and slots it past \(K).",
                "\(S) just keeps running. Past one, past two, into the box, and a calm finish across \(K). A goal entirely of his own making.",
                "Nobody can get near \(s)! He glides down the wing, cuts inside and leaves three defenders on the floor before finishing.",
                "\(S) takes on the whole defence and wins. A stepover, a burst of pace and a low finish under \(K).",
                "Collecting it in his own half, \(S) runs at \(opponent.shortName)'s back line, rides one tackle, then another, and finishes with the outside of his boot."
            ]
        case .reboundAfterSpill:
            lines = [
                "A stinging drive\(from) is too hot for \(K), who can only parry it into the path of \(S). He smashes the rebound into the roof of the net.",
                "\(K) makes a fine save, but the ball runs loose and \(S) is first to it to slam it home.",
                "First shot blocked, second shot saved, third time lucky: \(S) keeps his composure in the chaos and finds the net.",
                "\(K) spills a routine shot and \(S), who never stopped running, pounces on the mistake.",
                "The ball comes back off the post and \(S) is perfectly placed to tuck in the rebound."
            ]
        case .glancingCornerHeader:
            lines = [
                "A dangerous corner from \(A) causes chaos at the near post. \(S) gets across his marker and flicks a glancing header inside the far post.",
                "\(A)'s corner is whipped in with pace and \(S) attacks it at the penalty spot, bulleting a header past \(K).",
                "Corner from \(a), and \(S) peels off to the back post unmarked. He nods it back across goal and in.",
                "A rehearsed corner routine: \(A) drives it to the near post, \(S) gets there first and glances it into the far corner.",
                "\(K) comes for the corner and doesn't get there. \(S) heads it into the empty net.",
                "From \(a)'s corner it's a towering header from \(S), who was left alone by some sleepy marking."
            ]
        case .cheekyChip:
            lines = [
                "Audacity! Slipped through by \(A), \(S) sees \(K) charging out and dinks a sumptuous chip over him into the empty net.",
                "\(S) is through and doesn't even look up. A delicate lift over \(K), and the ball drops in just under the bar.",
                "Ice in his veins. With \(K) diving at his feet, \(S) scoops it over him from eight yards."
            ]
        case .thunderousVolley:
            lines = [
                "A headed clearance drops outside the box. \(S) meets it on the full with a blistering volley that tears through a crowded area and into the corner.",
                "\(A) hooks it into the box, it sits up perfectly and \(S) leathers a volley into the net.",
                "\(S) watches the ball drop over his shoulder and volleys it first time past \(K)! Technique of the highest order.",
                "The ball is cleared only as far as \(s), who half-volleys it straight back where it came from and into the bottom corner."
            ]
        case .deflectedStrike:
            lines = [
                "\(S) tries his luck from the edge of the area. A wicked deflection wrong-foots \(K) and the ball trickles over the line.",
                "It takes a big nick off a defender's knee, but \(S) won't care one bit. That counts!",
                "\(S)'s shot is going wide until it hits a defender and loops over the stranded \(K).",
                "Fortune favours the brave. \(S) shoots on sight, the ball cannons off a defender and in."
            ]
        case .counterAttackBreakaway:
            lines = [
                "Devastating counter-attack! From their own box to a goal in three passes. \(A) sends a 50-yard ball into \(S)'s stride and he strokes it home.",
                "\(opponent.shortName) had everyone forward for a corner and they pay for it. \(A) breaks clear and finds \(S), who has the whole half to himself.",
                "A lightning break. \(A) carries it 40 yards before releasing \(S), who sprints clear and finishes past \(K).",
                "Three against two on the break, and \(a) makes the right choice. \(S) is unmarked and makes no mistake.",
                "\(K) is caught off his line by the speed of the counter and \(S) finishes into the empty net from 30 yards!"
            ]
        case .divingHeader:
            lines = [
                "Total commitment from \(S)! He throws himself at a low cross\(from) and diverts a diving header into the net, inches above the turf.",
                "\(S) launches himself full-length at \(a)'s centre and heads it past \(K) before landing in a heap.",
                "Bravery rewarded. \(S) dives in among the flying boots to head home from six yards."
            ]
        case .sideFootCurler:
            lines = [
                "After patient build-up, \(S) receives it on the edge of the box, shifts it onto his stronger foot and caresses a curling effort inside the far post.",
                "\(S) opens up his body and side-foots it into the far corner. \(K) dives but it's beyond him.",
                "Placement over power. \(S) passes the ball into the net from 18 yards like it's a training drill.",
                "\(A) lays it back to \(S), who bends a first-time curler around the defender and in off the post."
            ]
        case .oneOnOneFinish:
            lines = [
                "A defence-splitting pass\(from) puts \(S) clean through. One-on-one, he keeps his composure and slides it under the onrushing \(K).",
                "\(S) races onto \(a)'s through ball, waits for \(K) to go down and slots it past him.",
                "Through on goal, \(S) rounds \(K) and passes it into the empty net.",
                "\(S) beats the offside trap and drills it low past \(K) before the defenders can recover.",
                "Clean through, \(S) shapes to shoot, sends \(K) to ground with a feint and finishes into the other corner."
            ]
        case .bicycleKick:
            lines = [
                "UNBELIEVABLE! A looping cross\(from) floats into the box and \(S) leaps into an acrobatic overhead kick that flies into the net! The stadium can't believe it.",
                "\(S) has his back to goal, the ball is above his head, and he goes for the overhead kick. It flies past \(K)! A goal for the highlights reel."
            ]
        case .cutback:
            lines = [
                "\(A) reaches the byline and cuts it back to the edge of the six-yard box, where \(S) sweeps it in first time.",
                "The cutback is the killer ball. \(a) pulls it back and \(S), arriving late, side-foots past \(K).",
                "Patient work down the right ends with \(A) cutting it back for \(S), who finishes before the defence can turn.",
                "\(A) drives to the byline and stands it up, \(S) checks his run and rifles the cutback into the roof of the net."
            ]
        case .nearPostFinish:
            lines = [
                "\(S) darts in front of his marker at the near post and flicks \(a)'s low ball past \(K).",
                "A near-post run from \(S) and a first-time finish that beats \(K) at his near post. He'll feel he should have done better.",
                "\(A) drills it in low and hard, and \(S) just has to get the faintest touch at the near post."
            ]
        case .nutmegKeeper:
            lines = [
                "\(S) bears down on goal and slips it straight through \(K)'s legs! Embarrassing for the keeper, brilliant from the striker.",
                "Nutmeg! \(S) waits for \(K) to spread himself and rolls it through his legs."
            ]
        case .firstTimeFinish:
            lines = [
                "\(A) slides it across and \(S) hits it first time, no hesitation, into the bottom corner.",
                "Instinctive from \(S). The pass\(from) arrives and he swivels and shoots in one movement.",
                "A one-two with \(a) on the edge of the box, and \(S) finishes the move with a crisp first-time strike.",
                "\(S) doesn't break stride. He meets \(a)'s pass on the run and drills it past \(K)."
            ]
        case .goalmouthScramble:
            lines = [
                "Absolute chaos in the box! The ball pinballs between bodies before \(S) prods it over the line from a yard out.",
                "It's not pretty but they all count. After two blocked shots, \(S) forces it in with his knee.",
                "A goalmouth scramble from the set piece, and \(S) is the one who finally gets a toe to it.",
                "\(K) and two defenders are on the floor, and \(S) somehow squeezes it in from under the bar."
            ]
        case .pressingTurnover:
            lines = [
                "\(S) hunts down the defender, steals the ball on the edge of the box and finishes before \(opponent.shortName) can react.",
                "A sloppy pass out from the back, \(S) intercepts, and it's in the net in a heartbeat. That's what the high press is for.",
                "\(S) pressures \(K) into a hurried clearance, charges it down and walks the ball into the net!",
                "\(opponent.shortName) try to play out from the back and \(S) punishes them, nicking it off a centre-back and lifting it over \(K)."
            ]
        case .backheelFlick:
            lines = [
                "Outrageous! With his back to goal, \(S) flicks \(a)'s cross in with a backheel. The defenders didn't see that coming.",
                "\(S) improvises brilliantly, steering the ball past \(K) with the back of his heel."
            ]
        case .overlapCross:
            lines = [
                "The full-back overlaps, \(A) whips in a cross on the run and \(S) attacks it at the penalty spot to head home.",
                "\(A) charges forward from defence and crosses for \(S), who arrives on cue to steer it past \(K).",
                "Great width from \(club.shortName). \(a) gets to the byline and crosses, and \(S) volleys it in at the back post."
            ]
        case .lobFromDistance:
            lines = [
                "\(S) spots \(K) off his line and lobs him from 40 yards! It drops just under the bar. Audacious!",
                "From near the halfway line! \(S) sees \(K) wandering and chips it over his head into the net."
            ]
        case .tikiTakaMove:
            lines = [
                "A goal of real beauty: 20 passes, every \(club.shortName) player touching the ball, and \(S) finishing it off from \(a)'s final pass.",
                "One-touch football at its best. \(A) and \(S) exchange passes around the box and \(S) finishes calmly.",
                "\(club.shortName) pass \(opponent.shortName) to sleep and then strike. \(a) threads it through and \(S) passes it into the corner."
            ]
        case .driveIntoBox:
            lines = [
                "\(S) drives forward from midfield, nobody steps out to meet him, and he hammers it past \(K) from the edge of the area.",
                "A powerful run from \(S) through the middle. He shrugs off one challenge and fires low into the corner.",
                "\(S) carries the ball 40 yards and \(opponent.shortName) back off. He takes the invitation and shoots, and it's in!"
            ]
        }
        let body = (lines + moreLines(type: type, S: S, s: s, A: A, a: a, from: from, K: K, club: club, opponent: opponent)).randomElement()!
        return moment(minute: minute) + body
    }

    /// An opener for goals at telling moments of the match, sometimes.
    private static func moment(minute: Int) -> String {
        guard Double.random(in: 0..<1) < 0.45 else { return "" }
        let pool: [String]
        switch minute {
        case ...3: pool = ["Barely a minute on the clock! ", "Straight from the kick-off, more or less! ", "What a start! "]
        case 4...10: pool = ["An early goal! ", "Inside the first ten minutes! ", "A flying start! "]
        case 43...45: pool = ["On the stroke of half-time! ", "Right before the break! ", "The perfect time to score! "]
        case 46...50: pool = ["Straight after the restart! ", "Whatever was said at half-time worked! "]
        case 88...89: pool = ["Late, late drama! ", "With the clock running down! "]
        case 90...: pool = ["Deep into stoppage time! ", "In the dying seconds! ", "With the fourth official's board already up! "]
        default: return ""
        }
        return pool.randomElement()!
    }

    /// Extra ways of telling each goal, so the same kind of finish rarely
    /// reads the same twice in a season.
    private static func moreLines(type: Commentary.GoalType, S: String, s: String, A: String, a: String, from: String,
                                  K: String, club: Club, opponent: Club) -> [String] {
        switch type {
        case .tapIn:
            return ["\(A) does all the hard work, and \(S) just has to pass it into an empty net.",
                    "The keeper parries it straight across goal and \(S) is on hand to tap it in.",
                    "\(S) times his run to perfection and side-foots \(a)'s low cross in from three yards.",
                    "Simple, but deadly. \(S) is in the right place again, turning in \(a)'s centre at the far post."]
        case .toweringHeader:
            return ["\(S) attacks \(a)'s cross like it owes him money and buries a header into the bottom corner.",
                    "A bullet header! \(S) meets the cross\(from) at the near post and it's past \(K) before he can move.",
                    "\(S) out-jumps the whole defence and plants his header back across \(K).",
                    "Classic centre-forward's goal: \(A) crosses, \(S) heads, net bulges."]
        case .longRangeScreamer:
            return ["\(S) catches it sweetly from 30 yards and it flies into the top corner. Unstoppable!",
                    "A swerving, dipping drive from \(S) beats \(K) all ends up.",
                    "Give him space and he'll punish you. \(S) cracks a low shot from 25 yards into the corner.",
                    "\(S) takes aim from distance and the ball rockets in off the underside of the bar!"]
        case .clinicalPenalty:
            return ["\(S) rolls it into the corner with \(K) going the other way. Composure itself.",
                    "\(S) waits, waits, and slots it low to the keeper's left.",
                    "A stutter, a pause and the penalty is buried in the top corner by \(S).",
                    "\(K) dives early and \(S) chips it softly straight down the middle. Nerves of steel."]
        case .curlingFreeKick:
            return ["\(S) bends the free kick over the wall and in off the post! \(K) was rooted to the spot.",
                    "Everyone expects a cross. \(S) shoots instead, and it sneaks in at the near post.",
                    "\(S) whips the free kick into the far top corner. A perfect strike.",
                    "From 30 yards, \(S) strikes the free kick with venom, and it dips under the bar."]
        case .soloRun:
            return ["\(S) dances through the defence like they aren't there and slots home. A wonder goal!",
                    "Nobody can lay a glove on \(s). He beats four men and rolls it into the corner.",
                    "\(S) wins it in midfield, runs 60 yards and finishes. What a goal!",
                    "Shimmy, step-over, finish. \(S) makes it look so easy."]
        case .reboundAfterSpill:
            return ["\(K) can only push the shot out, and \(S) is first to react to the loose ball.",
                    "The ball rebounds off a defender into \(S)'s path, and he makes no mistake.",
                    "\(S) follows in after \(K) spills a long-range effort and stabs it home.",
                    "A goal for the striker who never gave up on the chance: \(S) follows up and scores."]
        case .glancingCornerHeader:
            return ["\(a)'s inswinging corner is met at the near post by \(S), who flicks it into the far corner.",
                    "\(S) climbs highest at the back post from \(a)'s corner and nods it down past \(K).",
                    "Corner, flick-on, finish. \(S) heads in at the back post after a near-post flick.",
                    "\(S) breaks free of his marker and plants \(a)'s corner firmly into the net."]
        case .cheekyChip:
            return ["\(S) spots \(K) off his line and lifts it delicately over him. Cheeky!",
                    "One-on-one, \(S) dinks it over the diving \(K) and it drops in. Sublime.",
                    "A deft little chip from \(S) after \(a)'s pass sends him clear."]
        case .thunderousVolley:
            return ["\(S) hits a volley so hard \(K) barely moves. It nearly takes the net off!",
                    "\(a)'s cross drops over the defender and \(S) volleys it straight into the roof of the net.",
                    "\(S) watches it all the way and smashes a volley across \(K) and into the corner."]
        case .deflectedStrike:
            return ["\(S)'s shot deflects off a defender's heel and loops in. A huge slice of luck!",
                    "Off the defender and in! \(S) won't mind how it went in.",
                    "\(S)'s effort takes a wicked deflection and wrong-foots \(K) completely."]
        case .counterAttackBreakaway:
            return ["From defending a corner to scoring at the other end in ten seconds! \(S) finishes the break.",
                    "\(A) leads the break and squares for \(S), who passes it into the empty net.",
                    "Lightning on the counter! \(S) races clear of the last defender and slots past \(K).",
                    "\(club.shortName) catch \(opponent.shortName) on the break, and \(S) finishes it off with a cool finish."]
        case .divingHeader:
            return ["\(S) throws himself at the low cross and heads it home before anyone else can react!",
                    "A diving header from \(S), meeting \(a)'s cross six inches above the grass.",
                    "\(S) launches himself at the ball and powers a header past \(K)."]
        case .sideFootCurler:
            return ["\(S) curls it beautifully into the far corner, beyond \(K)'s dive.",
                    "\(S) opens his body and places it into the top corner with his instep.",
                    "A beautiful curling effort from \(S) from the edge of the area.",
                    "\(S) cuts inside and bends it round the defender and in."]
        case .oneOnOneFinish:
            return ["\(S) is clean through and slots it past \(K) without breaking stride.",
                    "\(S) rounds the keeper and walks it in.",
                    "\(a)'s through ball sends \(S) away, and he finishes low into the corner.",
                    "\(S) holds off the defender, steadies himself and slides it under \(K)."]
        case .bicycleKick:
            return ["\(S) launches into an overhead kick from \(a)'s looping cross. It's in! Unbelievable!",
                    "With his back to goal, \(S) attempts the impossible and succeeds. A bicycle kick for the ages!"]
        case .cutback:
            return ["\(A) pulls it back from the byline for \(S), who sweeps it home first time.",
                    "\(S) arrives in the box right on cue and side-foots \(a)'s cut-back into the corner.",
                    "The cut-back is perfect, and so is \(S)'s finish."]
        case .nearPostFinish:
            return ["\(S) gets in front of his marker and flicks \(a)'s cross in at the near post.",
                    "A near-post finish from \(S), squeezing the ball between \(K) and the post.",
                    "\(S) beats \(K) at his near post. The keeper will be disappointed with that."]
        case .nutmegKeeper:
            return ["\(S) slips it through \(K)'s legs! The keeper won't want to see that again.",
                    "Cheeky from \(S): he waits for \(K) to go down and rolls it through his legs."]
        case .firstTimeFinish:
            return ["\(S) meets \(a)'s pass first time and fires it into the bottom corner.",
                    "No touch needed. \(S) strikes it first time and the ball flies past \(K).",
                    "A first-time finish of real quality from \(S)."]
        case .goalmouthScramble:
            return ["Pinball in the six-yard box, and \(S) finally forces it over the line.",
                    "\(S) bundles it in after a scramble from the corner. Ugly, but they all count!",
                    "After an almighty scramble, \(S) toe-pokes it over the line."]
        case .pressingTurnover:
            return ["\(S) closes down the defender, wins the ball and slots it into the corner.",
                    "A mistake at the back and \(S) pounces, finishing before \(opponent.shortName) can recover.",
                    "\(S) charges down the clearance and the ball rolls into the net!"]
        case .backheelFlick:
            return ["A backheel from \(S)! The finish is pure improvisation and it beats \(K).",
                    "\(S) flicks \(a)'s low cross in with his heel. Outrageous skill."]
        case .overlapCross:
            return ["\(A) overlaps, crosses first time, and \(S) slides in at the far post to score.",
                    "\(a)'s cross from the overlap finds \(S), whose header nestles in the corner."]
        case .lobFromDistance:
            return ["\(S) spots \(K) off his line and lobs him from 40 yards. Genius!",
                    "From halfway, \(S) chips \(K)! The ball drops under the bar."]
        case .tikiTakaMove:
            return ["Pass after pass after pass, and \(S) finishes it off. A team goal of real beauty.",
                    "\(club.shortName) keep the ball for over a minute before \(S) finishes off the move.",
                    "A slick one-two with \(a) puts \(S) clear, and he finishes calmly."]
        case .driveIntoBox:
            return ["\(S) drives into the box, holds off a challenge and fires low past \(K).",
                    "A surging run into the area from \(S), and a firm finish into the corner.",
                    "\(S) bursts between two defenders and finishes with his weaker foot."]
        }
    }

    /// What the goal means for the match, as its own sentence.
    static func situation(club: Club, opponent: Club, minute: Int, teamGoals: Int, oppGoals: Int, scorer: Player) -> String {
        let score = "\(teamGoals)-\(oppGoals)"
        let lines: [String]
        if teamGoals == oppGoals {
            lines = minute > 80
                ? ["EQUALISER! Pandemonium!", "Level at \(score) with the clock ticking down. Game on!",
                   "\(club.shortName) have rescued something late on!", "Just when it looked lost, \(club.shortName) are level!"]
                : ["That levels it at \(score).", "All square again at \(score).", "\(club.shortName) are back in it!",
                   "Parity restored. \(score).", "And just like that, we have a new game."]
        } else if teamGoals == oppGoals + 1 {
            if minute > 82 {
                lines = ["A CRUCIAL LATE GOAL! \(club.shortName) lead \(score)!", "Surely that's the winner!",
                         "That could be worth three points!", "\(club.shortName) lead at the death!"]
            } else if teamGoals == 1 {
                lines = ["\(club.shortName) take the lead!", "The deadlock is broken!", "1-0 \(club.shortName)!",
                         "The breakthrough \(club.shortName) were looking for!", "First blood to \(club.shortName)."]
            } else {
                lines = ["\(club.shortName) are back in front, \(score)!", "\(club.shortName) lead \(score) again.",
                         "The lead is restored!", "Back in front!"]
            }
        } else if teamGoals == oppGoals + 2 {
            lines = ["\(club.shortName) have a two-goal cushion now.", "That's \(score), and \(club.shortName) are in control.",
                     "\(opponent.shortName) have a mountain to climb.", "Daylight between the sides: \(score)."]
        } else if teamGoals > oppGoals + 2 {
            lines = ["This is turning into a rout: \(score)!", "\(opponent.shortName) have collapsed. \(score).",
                     "The goals keep coming. \(score)!", "\(scorer.lastName) twists the knife. \(score)."]
        } else {
            lines = ["A goal back for \(club.shortName). \(score).", "\(club.shortName) pull one back!",
                     "Is this the start of a comeback? \(score).", "Consolation, or the spark for a fightback?"]
        }
        return lines.randomElement()!
    }
}
