//
//  MatchEngine.swift
//  Touchline
//
//  Created for Touchline - iOS Football Manager Game.
//  Core match simulation engine simulating minute-by-minute action, tactical duels,
//  set pieces, fatigue progression, substitutions, extra time, and penalty shootouts.
//

import Foundation

public struct MatchEngine {
    
    // MARK: - Match Configuration
    
    public struct SimulationConfig {
        public var neutralVenue: Bool
        public var matchWeek: Int
        public var competition: String
        public var date: String
        public var isKnockout: Bool
        /// 0 for an ordinary match; 1-3 for a derby of rising ferocity.
        public var derbyIntensity: Int
        /// Coaching influence on each side (1.0 = neutral; a few percent either way).
        public var homeCoachingMultiplier: Double
        public var awayCoachingMultiplier: Double
        
        public init(
            neutralVenue: Bool = false,
            matchWeek: Int = 1,
            competition: String = "League Match",
            date: String = "2024-09-01",
            isKnockout: Bool = false,
            derbyIntensity: Int = 0,
            homeCoachingMultiplier: Double = 1.0,
            awayCoachingMultiplier: Double = 1.0
        ) {
            self.neutralVenue = neutralVenue
            self.matchWeek = matchWeek
            self.competition = competition
            self.date = date
            self.isKnockout = isKnockout
            self.derbyIntensity = max(0, min(3, derbyIntensity))
            self.homeCoachingMultiplier = max(0.9, min(1.1, homeCoachingMultiplier))
            self.awayCoachingMultiplier = max(0.9, min(1.1, awayCoachingMultiplier))
        }
    }
    
    // MARK: - In-Match Active Player State
    
    struct ActiveMatchPlayer {
        var player: Player
        var currentFatigue: Double = 0.0 // 0 to 100% fatigue during the game
        var currentRating: Double = 6.0
        var goals: Int = 0
        var assists: Int = 0
        var yellowCards: Int = 0
        var isSentOff: Bool = false
        var isSubstitutedOut: Bool = false
        var minutesPlayed: Int = 0
        
        /// Dynamic effective performance level accounting for base attributes, form, morale, and in-game fatigue.
        func effectiveSkill(for roleCategory: PositionCategory) -> Double {
            guard !isSentOff else { return 0.0 }
            
            // Base skill
            var skill = Double(player.overall)
            
            // Form modifier (±10%)
            let avgForm = player.averageForm // 1.0 - 10.0 scale, average ~6.5
            let formModifier = 1.0 + ((avgForm - 6.5) * 0.02)
            skill *= min(1.10, max(0.90, formModifier))
            
            // Morale modifier (±10%)
            skill *= player.morale.performanceMultiplier

            // Persistent condition: a player arriving short of match fitness or
            // sharpness (e.g. after injury or a long lay-off) is below their best.
            let fitnessModifier = 0.85 + (min(100.0, max(0.0, player.matchFitness)) / 100.0) * 0.15
            let sharpnessModifier = 0.92 + (min(100.0, max(0.0, player.sharpness)) / 100.0) * 0.08
            skill *= fitnessModifier * sharpnessModifier
            
            // In-match fatigue penalty (up to -25% when completely exhausted)
            let fatiguePenalty = (currentFatigue / 100.0) * 0.25
            skill *= (1.0 - fatiguePenalty)
            
            return skill
        }
    }
    
    // MARK: - Public API
    
    /// Standard convenience signature conforming to specification.
    public static func simulateMatch(
        home: Club,
        away: Club,
        neutralVenue: Bool = false
    ) -> MatchResult {
        var mutableHome = home
        var mutableAway = away
        let config = SimulationConfig(
            neutralVenue: neutralVenue,
            matchWeek: 1,
            competition: "League Match",
            date: "2024-09-01",
            isKnockout: false
        )
        return simulate(homeClub: &mutableHome, awayClub: &mutableAway, config: config)
    }
    
    /// Full match simulation returning updated club rosters (with fatigue, cards, injuries applied) and MatchResult.
    public static func simulateFullMatch(
        home: inout Club,
        away: inout Club,
        config: SimulationConfig
    ) -> MatchResult {
        return simulate(homeClub: &home, awayClub: &away, config: config)
    }

    /// A match stopped at half-time: everything the engine needs to play
    /// the second half, plus the story so far.
    public struct PausedMatch {
        var homeActive: [ActiveMatchPlayer]
        var awayActive: [ActiveMatchPlayer]
        var homeDeparted: [ActiveMatchPlayer]
        var awayDeparted: [ActiveMatchPlayer]
        var homeBench: [Player]
        var awayBench: [Player]
        var homeSubsUsed: Int
        var awaySubsUsed: Int
        var homeGoals: Int
        var awayGoals: Int
        var events: [MatchEvent]
        var counters: [Double]
        var secondHalfStoppage: Int
        var maxMinute: Int
        var minute: Int
        /// The first half as a result: score, events and stats so far.
        public var snapshot: MatchResult

        public var homeOnPitch: [UUID] { homeActive.map { $0.player.id } }
        public var awayOnPitch: [UUID] { awayActive.map { $0.player.id } }
        public var homeBenchIds: [UUID] { homeBench.map { $0.id } }
        public var awayBenchIds: [UUID] { awayBench.map { $0.id } }
        public var homeSubsRemaining: Int { max(0, 5 - homeSubsUsed) }
        public var awaySubsRemaining: Int { max(0, 5 - awaySubsUsed) }
        /// Players who have already gone off (or been sent off) and cannot return.
        public var unavailableIds: Set<UUID> {
            Set((homeDeparted + awayDeparted).map { $0.player.id })
                .union((homeActive + awayActive).filter { $0.isSentOff }.map { $0.player.id })
        }
        public var sentOffIds: Set<UUID> {
            Set((homeActive + awayActive).filter { $0.isSentOff }.map { $0.player.id })
        }
    }

    /// Plays the first half only. Nothing is written back to the clubs yet.
    public static func playFirstHalf(home: inout Club, away: inout Club, config: SimulationConfig) -> PausedMatch? {
        simulateCore(homeClub: &home, awayClub: &away, config: config, resume: nil, pauseAfter: 45).1
    }

    /// Plays the rest of a paused match. The clubs' current tactics and
    /// starting elevens are used, so half-time changes take effect.
    public static func resume(_ paused: PausedMatch, home: inout Club, away: inout Club, config: SimulationConfig) -> MatchResult {
        simulateCore(homeClub: &home, awayClub: &away, config: config, resume: paused, pauseAfter: nil).0
    }

    /// Brings the players on the pitch into line with the club's chosen
    /// eleven: new names come on for those left out (while substitutions
    /// remain), and the order follows the lineup so players take their
    /// new positions.
    private static func applyLineupChanges(
        club: Club,
        active: inout [ActiveMatchPlayer],
        bench: inout [Player],
        departed: inout [ActiveMatchPlayer],
        subsUsed: inout Int,
        isHome: Bool,
        minute: Int,
        events: inout [MatchEvent]
    ) {
        let wanted = club.tactics.startingXI
        let onPitch = Set(active.map { $0.player.id })
        let gone = Set(departed.map { $0.player.id })
        var incoming = wanted.filter { !onPitch.contains($0) && !gone.contains($0) }
            .compactMap { id in club.players.first { $0.id == id } }
            .filter { $0.injury == nil && $0.suspendedMatches == 0 }
        let outgoingIdx = active.indices.filter { !wanted.contains(active[$0].player.id) && !active[$0].isSentOff }
        for idx in outgoingIdx {
            guard subsUsed < 5, !incoming.isEmpty else { break }
            let playerIn = incoming.removeFirst()
            let out = active[idx]
            var marked = out
            marked.isSubstitutedOut = true
            departed.append(marked)
            active[idx] = ActiveMatchPlayer(player: playerIn, currentFatigue: 0.0, currentRating: 6.0)
            bench.removeAll { $0.id == playerIn.id }
            subsUsed += 1
            let commentary = Commentary.substitution(playerIn: playerIn, playerOut: out.player, club: club, minute: minute)
            events.append(MatchEvent(minute: minute, type: .substitution, clubId: club.id, playerId: playerIn.id,
                                     shortText: commentary.short, detailText: commentary.detail, isHomeTeam: isHome))
        }
        // Positions follow the order of the chosen eleven.
        let order = Dictionary(uniqueKeysWithValues: wanted.enumerated().map { ($1, $0) })
        active = active.enumerated().sorted { a, b in
            (order[a.element.player.id] ?? 100 + a.offset) < (order[b.element.player.id] ?? 100 + b.offset)
        }.map { $0.element }
        // The bench is whoever is still available and not on the pitch.
        let nowOn = Set(active.map { $0.player.id })
        let nowGone = Set(departed.map { $0.player.id })
        bench = club.substitutePlayers.filter { !nowOn.contains($0.id) && !nowGone.contains($0.id) }
            + bench.filter { b in !nowOn.contains(b.id) && !nowGone.contains(b.id) && !club.substitutePlayers.contains { $0.id == b.id } }
    }
    
    // MARK: - Core Simulation Loop
    
    private static func simulate(
        homeClub: inout Club,
        awayClub: inout Club,
        config: SimulationConfig
    ) -> MatchResult {
        simulateCore(homeClub: &homeClub, awayClub: &awayClub, config: config, resume: nil, pauseAfter: nil).0
    }

    private static func simulateCore(
        homeClub: inout Club,
        awayClub: inout Club,
        config: SimulationConfig,
        resume: PausedMatch?,
        pauseAfter: Int?
    ) -> (MatchResult, PausedMatch?) {
        homeClub.ensureTacticalIntegrity()
        awayClub.ensureTacticalIntegrity()
        
        // 1. Prepare active rosters
        var homeActive = homeClub.startingXIPlayers.map { ActiveMatchPlayer(player: $0) }
        var awayActive = awayClub.startingXIPlayers.map { ActiveMatchPlayer(player: $0) }
        var homeDeparted: [ActiveMatchPlayer] = []
        var awayDeparted: [ActiveMatchPlayer] = []
        var homeBench = homeClub.substitutePlayers
        var awayBench = awayClub.substitutePlayers
        
        var homeSubsUsed = 0
        var awaySubsUsed = 0
        let maxSubs = 5
        
        var homeGoals = 0
        var awayGoals = 0
        var events: [MatchEvent] = []
        
        var homeShots = 0
        var awayShots = 0
        var homeShotsOnTarget = 0
        var awayShotsOnTarget = 0
        var homeCorners = 0
        var awayCorners = 0
        var homeFouls = 0
        var awayFouls = 0
        var homeXG = 0.0
        var awayXG = 0.0
        var homeSaves = 0
        var awaySaves = 0
        var homePossessionSeconds = 0.0
        var awayPossessionSeconds = 0.0
        
        // Kickoff event
        if resume == nil { events.append(
            MatchEvent(
                minute: 1,
                type: .kickOff,
                shortText: config.derbyIntensity > 0
                    ? "Derby day! \(homeClub.name) vs \(awayClub.name) is underway."
                    : "Kick-off! \(homeClub.name) vs \(awayClub.name) is underway.",
                detailText: config.derbyIntensity > 0
                    ? "A ferocious atmosphere at \(homeClub.stadium) as the referee gets the derby underway. Bragging rights are on the line."
                    : "The referee blows the whistle and the match begins at \(homeClub.stadium).",
                isHomeTeam: true
            )
        ) }
        
        // Second-half stoppage time (first-half added time is folded into
        // the minute-by-minute flow rather than extending the clock).
        var secondHalfStoppage = Int.random(in: 2...6)
        
        // Determine total minutes (90 + stoppage, or 120 if knockout & draw)
        var maxMinute = 90 + secondHalfStoppage
        
        // Minute-by-minute simulation
        var minute = 1

        // Picking a paused match back up: restore the state at the whistle
        // and apply any half-time changes to either side.
        if let r = resume {
            homeActive = r.homeActive; awayActive = r.awayActive
            homeDeparted = r.homeDeparted; awayDeparted = r.awayDeparted
            homeBench = r.homeBench; awayBench = r.awayBench
            homeSubsUsed = r.homeSubsUsed; awaySubsUsed = r.awaySubsUsed
            homeGoals = r.homeGoals; awayGoals = r.awayGoals
            events = r.events
            homeShots = Int(r.counters[0]); awayShots = Int(r.counters[1])
            homeShotsOnTarget = Int(r.counters[2]); awayShotsOnTarget = Int(r.counters[3])
            homeCorners = Int(r.counters[4]); awayCorners = Int(r.counters[5])
            homeFouls = Int(r.counters[6]); awayFouls = Int(r.counters[7])
            homeXG = r.counters[8]; awayXG = r.counters[9]
            homeSaves = Int(r.counters[10]); awaySaves = Int(r.counters[11])
            homePossessionSeconds = r.counters[12]; awayPossessionSeconds = r.counters[13]
            secondHalfStoppage = r.secondHalfStoppage
            maxMinute = r.maxMinute
            minute = r.minute
            applyLineupChanges(club: homeClub, active: &homeActive, bench: &homeBench, departed: &homeDeparted,
                               subsUsed: &homeSubsUsed, isHome: true, minute: minute, events: &events)
            applyLineupChanges(club: awayClub, active: &awayActive, bench: &awayBench, departed: &awayDeparted,
                               subsUsed: &awaySubsUsed, isHome: false, minute: minute, events: &events)
        }

        while minute <= maxMinute {
            
            // Half-time whistle
            if minute == 45 {
                let ht = Commentary.halfTimeSummary(
                    home: homeClub,
                    away: awayClub,
                    homeGoals: homeGoals,
                    awayGoals: awayGoals
                )
                events.append(
                    MatchEvent(
                        minute: 45,
                        type: .halfTime,
                        shortText: ht.short,
                        detailText: ht.detail,
                        isHomeTeam: true
                    )
                )
            }
            
            // Atmospheric commentary check (~every 15-20 mins)
            if minute == 15 || minute == 32 || minute == 62 || minute == 80 {
                let atmos = Commentary.atmosphere(
                    homeClub: homeClub,
                    awayClub: awayClub,
                    minute: minute,
                    homeGoals: homeGoals,
                    awayGoals: awayGoals
                )
                events.append(
                    MatchEvent(
                        minute: minute,
                        type: .commentary,
                        shortText: atmos.short,
                        detailText: atmos.detail,
                        isHomeTeam: true
                    )
                )
            }
            
            // 2. Increment minutes & fatigue
            updateFatigue(activePlayers: &homeActive, tactics: homeClub.tactics)
            updateFatigue(activePlayers: &awayActive, tactics: awayClub.tactics)
            
            // 3. AI / Tactical Substitutions (Between 58' and 82')
            if minute >= 58 && minute <= 82 {
                tryPerformSubstitution(
                    activePlayers: &homeActive,
                    bench: &homeBench,
                    subsUsed: &homeSubsUsed,
                    maxSubs: maxSubs,
                    club: homeClub,
                    isHome: true,
                    minute: minute,
                    events: &events,
                    departed: &homeDeparted
                )
                tryPerformSubstitution(
                    activePlayers: &awayActive,
                    bench: &awayBench,
                    subsUsed: &awaySubsUsed,
                    maxSubs: maxSubs,
                    club: awayClub,
                    isHome: false,
                    minute: minute,
                    events: &events,
                    departed: &awayDeparted
                )
            }
            
            // 4. Calculate relative team strengths for this minute
            let homeStrength = calculateTeamStrength(
                activePlayers: homeActive,
                tactics: homeClub.tactics,
                isHome: true,
                neutralVenue: config.neutralVenue
            ) * config.homeCoachingMultiplier
            let awayStrength = calculateTeamStrength(
                activePlayers: awayActive,
                tactics: awayClub.tactics,
                isHome: false,
                neutralVenue: config.neutralVenue
            ) * config.awayCoachingMultiplier
            
            // Possession allocation for this minute. Clamp so a stronger side cannot
            // monopolise every chance; real matches rarely exceed ~70/30 possession.
            // Tactics shift the possession battle: pressing/compact shape and a short
            // passing game retain the ball for the side employing them.
            let homePossessionFactor = homeClub.tactics.passingStyle.possessionMultiplier
                * homeClub.tactics.pressing.defensiveMultiplier
            let awayPossessionFactor = awayClub.tactics.passingStyle.possessionMultiplier
                * awayClub.tactics.pressing.defensiveMultiplier
            // Quality differences are amplified (a power curve rather than a
            // straight ratio): with a linear split an 80-rated side facing a
            // 70-rated one won only 53% of the match's events, so favourites
            // won barely more often than underdogs.
            // In a derby the form book counts for less.
            let sensitivity = strengthSensitivity - Double(config.derbyIntensity) * 1.2
            let homeWeight = pow(max(1.0, homeStrength * homePossessionFactor), sensitivity)
            let awayWeight = pow(max(1.0, awayStrength * awayPossessionFactor), sensitivity)
            let rawPossessionChance = homeWeight / (homeWeight + awayWeight)
            let homePossessionChance = min(0.78, max(0.22, rawPossessionChance))
            let isHomeInPossession = Double.random(in: 0...1) < homePossessionChance
            if isHomeInPossession {
                homePossessionSeconds += 60.0
            } else {
                awayPossessionSeconds += 60.0
            }
            
            // 5. Roll for minute events (Tempo influences event frequency)
            let attackingTactics = isHomeInPossession ? homeClub.tactics : awayClub.tactics
            let tempoChanceModifier: Double
            switch attackingTactics.tempo {
            case .fast: tempoChanceModifier = 1.25
            case .normal: tempoChanceModifier = 1.00
            case .slow: tempoChanceModifier = 0.80
            }
            
            // Game-state modifier: as the goal margin grows, both sides create fewer
            // clear chances — the leading team eases off and the trailing side tightens.
            // This keeps individual scorelines realistic while still allowing the odd
            // heavy win without routine cricket scores.
            let margin = abs(homeGoals - awayGoals)
            let marginModifier: Double
            switch margin {
            case 0, 1: marginModifier = 1.0
            case 2: marginModifier = 0.78
            case 3: marginModifier = 0.60
            default: marginModifier = 0.45
            }
            
            let eventRoll = Double.random(in: 0...100)
            
            // The defending side's tactical solidity reduces the chance of events.
            let defendingTactics = isHomeInPossession ? awayClub.tactics : homeClub.tactics
            let defenceModifier = 1.0 / defensiveFactor(tactics: defendingTactics)

            // Cumulative thresholds for each event band. Each band starts where
            // the previous one ends, so a fast tempo widens the attacking bands
            // without swallowing the foul and injury bands (previously a fast
            // tempo pushed the free-kick band past the fixed foul ceiling of 18,
            // so sides facing a fast-tempo team never committed a foul or
            // received a card).
            let chanceCeiling = 10.5 * tempoChanceModifier * marginModifier * defenceModifier
            let cornerCeiling = max(chanceCeiling, 13.0 * tempoChanceModifier)
            let freeKickCeiling = max(cornerCeiling, 14.5 * tempoChanceModifier)
            // Derbies are fiercer: more fouls and, through them, more cards.
            let foulCeiling = freeKickCeiling + 3.5 + Double(config.derbyIntensity) * 1.2
            let injuryCeiling = foulCeiling + 1.5
            
            if eventRoll < chanceCeiling {
                // Open play chance
                resolveChance(
                    isHomeAttacking: isHomeInPossession,
                    homeActive: &homeActive,
                    awayActive: &awayActive,
                    homeClub: homeClub,
                    awayClub: awayClub,
                    homeGoals: &homeGoals,
                    awayGoals: &awayGoals,
                    homeShots: &homeShots,
                    awayShots: &awayShots,
                    homeShotsOnTarget: &homeShotsOnTarget,
                    awayShotsOnTarget: &awayShotsOnTarget,
                    homeSaves: &homeSaves,
                    awaySaves: &awaySaves,
                    homeXG: &homeXG,
                    awayXG: &awayXG,
                    minute: minute,
                    events: &events
                )
            } else if eventRoll < cornerCeiling {
                // Corner Kick
                resolveCorner(
                    isHomeAttacking: isHomeInPossession,
                    homeActive: &homeActive,
                    awayActive: &awayActive,
                    homeClub: homeClub,
                    awayClub: awayClub,
                    homeGoals: &homeGoals,
                    awayGoals: &awayGoals,
                    homeCorners: &homeCorners,
                    awayCorners: &awayCorners,
                    homeShots: &homeShots,
                    awayShots: &awayShots,
                    homeShotsOnTarget: &homeShotsOnTarget,
                    awayShotsOnTarget: &awayShotsOnTarget,
                    homeXG: &homeXG,
                    awayXG: &awayXG,
                    minute: minute,
                    events: &events
                )
            } else if eventRoll < freeKickCeiling {
                // Dangerous Free Kick
                resolveFreeKick(
                    isHomeAttacking: isHomeInPossession,
                    homeActive: &homeActive,
                    awayActive: &awayActive,
                    homeClub: homeClub,
                    awayClub: awayClub,
                    homeGoals: &homeGoals,
                    awayGoals: &awayGoals,
                    homeShots: &homeShots,
                    awayShots: &awayShots,
                    homeShotsOnTarget: &homeShotsOnTarget,
                    awayShotsOnTarget: &awayShotsOnTarget,
                    homeXG: &homeXG,
                    awayXG: &awayXG,
                    minute: minute,
                    events: &events
                )
            } else if eventRoll < foulCeiling {
                // Foul and Disciplinary check
                resolveFoul(
                    isHomeTeamFouling: !isHomeInPossession,
                    homeActive: &homeActive,
                    awayActive: &awayActive,
                    homeClub: homeClub,
                    awayClub: awayClub,
                    homeFouls: &homeFouls,
                    awayFouls: &awayFouls,
                    homeGoals: &homeGoals,
                    awayGoals: &awayGoals,
                    homeShots: &homeShots,
                    awayShots: &awayShots,
                    homeShotsOnTarget: &homeShotsOnTarget,
                    awayShotsOnTarget: &awayShotsOnTarget,
                    homeSaves: &homeSaves,
                    awaySaves: &awaySaves,
                    homeXG: &homeXG,
                    awayXG: &awayXG,
                    minute: minute,
                    events: &events
                )
            } else if eventRoll < injuryCeiling {
                // In-match injury roll
                checkInMatchInjury(
                    homeActive: &homeActive,
                    awayActive: &awayActive,
                    homeClub: homeClub,
                    awayClub: awayClub,
                    minute: minute,
                    events: &events
                )
            }
            
            // Minor, unpunished fouls that break up play. They feed the match
            // stats (real matches see ~20 fouls) without triggering cards or set
            // pieces; only the disciplinary fouls above can be booked.
            if Double.random(in: 0..<1) < 0.17 {
                if isHomeInPossession { awayFouls += 1 } else { homeFouls += 1 }
            }
            
            // Check if knockout match reached full time tied -> Trigger Extra Time (91-120)
            if minute == (90 + secondHalfStoppage) && config.isKnockout && homeGoals == awayGoals && maxMinute < 120 {
                events.append(
                    MatchEvent(
                        minute: 90,
                        type: .extraTimeStart,
                        shortText: "EXTRA TIME! Scores tied at \(homeGoals)-\(awayGoals)",
                        detailText: "90 minutes could not separate these sides. We head into 30 minutes of extra time!",
                        isHomeTeam: true
                    )
                )
                maxMinute = 120
            }

            // Half-time: hand the match back so changes can be made.
            if let pauseAfter, minute == pauseAfter {
                let total = max(1.0, homePossessionSeconds + awayPossessionSeconds)
                let homePoss = ((homePossessionSeconds / total) * 1000.0).rounded() / 10.0
                func stats(_ poss: Double, _ shots: Int, _ onTarget: Int, _ corners: Int, _ fouls: Int, _ saves: Int, _ xg: Double) -> MatchStats {
                    MatchStats(possession: poss, shots: shots, shotsOnTarget: onTarget, corners: corners, fouls: fouls,
                               offsides: 0, passAccuracy: 82, tacklesWon: 8, saves: saves, xG: (xg * 100).rounded() / 100)
                }
                var ratings: [UUID: Double] = [:]
                for ap in homeActive + homeDeparted + awayActive + awayDeparted { ratings[ap.player.id] = (ap.currentRating * 10).rounded() / 10 }
                let snapshot = MatchResult(
                    homeClubId: homeClub.id, awayClubId: awayClub.id, homeGoals: homeGoals, awayGoals: awayGoals,
                    events: events, matchWeek: config.matchWeek, competition: config.competition, date: config.date,
                    attendance: homeClub.finances.expectedAttendance(opponentReputation: awayClub.reputation),
                    homeStats: stats(homePoss, homeShots, homeShotsOnTarget, homeCorners, homeFouls, homeSaves, homeXG),
                    awayStats: stats(((100.0 - homePoss) * 10).rounded() / 10, awayShots, awayShotsOnTarget, awayCorners, awayFouls, awaySaves, awayXG),
                    playerRatings: ratings, manOfTheMatch: nil)
                let paused = PausedMatch(
                    homeActive: homeActive, awayActive: awayActive, homeDeparted: homeDeparted, awayDeparted: awayDeparted,
                    homeBench: homeBench, awayBench: awayBench, homeSubsUsed: homeSubsUsed, awaySubsUsed: awaySubsUsed,
                    homeGoals: homeGoals, awayGoals: awayGoals, events: events,
                    counters: [Double(homeShots), Double(awayShots), Double(homeShotsOnTarget), Double(awayShotsOnTarget),
                               Double(homeCorners), Double(awayCorners), Double(homeFouls), Double(awayFouls), homeXG, awayXG,
                               Double(homeSaves), Double(awaySaves), homePossessionSeconds, awayPossessionSeconds],
                    secondHalfStoppage: secondHalfStoppage, maxMinute: maxMinute, minute: minute + 1, snapshot: snapshot)
                return (snapshot, paused)
            }
            
            minute += 1
        }
        
        // 6. Penalty Shootout if tied after 120 minutes in knockout match
        if config.isKnockout && homeGoals == awayGoals {
            resolvePenaltyShootout(
                homeClub: homeClub,
                awayClub: awayClub,
                homeActive: homeActive,
                awayActive: awayActive,
                homeGoals: &homeGoals,
                awayGoals: &awayGoals,
                events: &events
            )
        }
        
        // 7. Full-time whistle event
        let homeAll = homeActive + homeDeparted
        let awayAll = awayActive + awayDeparted
        let motm = determineManOfTheMatch(homeActive: homeAll, awayActive: awayAll)
        let ftSummary = Commentary.fullTimeSummary(
            home: homeClub,
            away: awayClub,
            homeGoals: homeGoals,
            awayGoals: awayGoals,
            motm: motm?.player
        )
        events.append(
            MatchEvent(
                minute: max(1, minute - 1),
                type: .fullTime,
                shortText: ftSummary.short,
                detailText: ftSummary.detail,
                isHomeTeam: true
            )
        )
        
        // 8. Compile Match Statistics
        let totalSeconds = max(1.0, homePossessionSeconds + awayPossessionSeconds)
        let homePossession = ((homePossessionSeconds / totalSeconds) * 1000.0).rounded() / 10.0
        let awayPossession = ((100.0 - homePossession) * 10.0).rounded() / 10.0
        
        let homeStats = MatchStats(
            possession: homePossession,
            shots: homeShots,
            shotsOnTarget: homeShotsOnTarget,
            corners: homeCorners,
            fouls: homeFouls,
            offsides: Int.random(in: 1...4),
            passAccuracy: round(Double.random(in: 78...88) * 10) / 10,
            tacklesWon: Int.random(in: 12...22),
            saves: homeSaves,
            xG: (homeXG * 100).rounded() / 100
        )
        
        let awayStats = MatchStats(
            possession: awayPossession,
            shots: awayShots,
            shotsOnTarget: awayShotsOnTarget,
            corners: awayCorners,
            fouls: awayFouls,
            offsides: Int.random(in: 1...4),
            passAccuracy: round(Double.random(in: 76...87) * 10) / 10,
            tacklesWon: Int.random(in: 12...22),
            saves: awaySaves,
            xG: (awayXG * 100).rounded() / 100
        )
        
        // Player ratings map
        var ratingsMap: [UUID: Double] = [:]
        for ap in homeAll { ratingsMap[ap.player.id] = (ap.currentRating * 10).rounded() / 10 }
        for ap in awayAll { ratingsMap[ap.player.id] = (ap.currentRating * 10).rounded() / 10 }
        
        // Gate size reflects the home club's usual pull and the appeal of the
        // visiting side, rather than a flat random fill of the stadium.
        let attendance = homeClub.finances.expectedAttendance(opponentReputation: awayClub.reputation)
        
        // Offsides: real flags in the commentary that match the stat line.
        events.append(contentsOf: offsideEvents(count: homeStats.offsides, club: homeClub, squad: homeAll, isHome: true, lastMinute: maxMinute))
        events.append(contentsOf: offsideEvents(count: awayStats.offsides, club: awayClub, squad: awayAll, isHome: false, lastMinute: maxMinute))
        events = events.enumerated()
            .sorted { $0.element.minute == $1.element.minute ? $0.offset < $1.offset : $0.element.minute < $1.element.minute }
            .map { $0.element }

        var matchResult = MatchResult(
            homeClubId: homeClub.id,
            awayClubId: awayClub.id,
            homeGoals: homeGoals,
            awayGoals: awayGoals,
            events: events,
            matchWeek: config.matchWeek,
            competition: config.competition,
            date: config.date,
            attendance: attendance,
            homeStats: homeStats,
            awayStats: awayStats,
            playerRatings: ratingsMap,
            manOfTheMatch: motm?.player.id
        )
        matchResult.homeLineup = homeClub.tactics.startingXI
        matchResult.awayLineup = awayClub.tactics.startingXI
        matchResult.homeFormation = homeClub.tactics.formation
        matchResult.awayFormation = awayClub.tactics.formation
        
        // 9. Sync results back to clubs and update players' persistent models
        applyMatchToClub(club: &homeClub, activePlayers: homeAll, opponentGoals: awayGoals, motmId: motm?.player.id)
        applyMatchToClub(club: &awayClub, activePlayers: awayAll, opponentGoals: homeGoals, motmId: motm?.player.id)
        
        homeClub.seasonResults.append(matchResult)
        awayClub.seasonResults.append(matchResult)
        
        return (matchResult, nil)
    }
    
    /// Builds offside flags at believable moments, avoiding the half-time whistle.
    private static func offsideEvents(count: Int, club: Club, squad: [ActiveMatchPlayer], isHome: Bool, lastMinute: Int) -> [MatchEvent] {
        let runners = squad.filter { [.forward, .midfielder].contains($0.player.primaryPosition.category) }
        guard !runners.isEmpty else { return [] }
        var minutes = Set<Int>()
        while minutes.count < count { minutes.insert([Int](2...min(88, lastMinute)).filter { $0 != 45 }.randomElement()!) }
        return minutes.sorted().map { minute in
            let runner = (runners.filter { $0.player.primaryPosition.category == .forward }.randomElement() ?? runners.randomElement()!).player
            let commentary = Commentary.offside(player: runner, club: club, minute: minute)
            return MatchEvent(minute: minute, type: .offside, clubId: club.id, playerId: runner.id,
                              shortText: commentary.short, detailText: commentary.detail, isHomeTeam: isHome)
        }
    }

    // MARK: - Chance Resolution
    
    private static func resolveChance(
        isHomeAttacking: Bool,
        homeActive: inout [ActiveMatchPlayer],
        awayActive: inout [ActiveMatchPlayer],
        homeClub: Club,
        awayClub: Club,
        homeGoals: inout Int,
        awayGoals: inout Int,
        homeShots: inout Int,
        awayShots: inout Int,
        homeShotsOnTarget: inout Int,
        awayShotsOnTarget: inout Int,
        homeSaves: inout Int,
        awaySaves: inout Int,
        homeXG: inout Double,
        awayXG: inout Double,
        minute: Int,
        events: inout [MatchEvent]
    ) {
        if isHomeAttacking { homeShots += 1 } else { awayShots += 1 }
        
        let attackingClub = isHomeAttacking ? homeClub : awayClub
        let defendingClub = isHomeAttacking ? awayClub : homeClub
        
        // Pick shooter and assister
        let attackingSquad = isHomeAttacking ? homeActive : awayActive
        let availableShooters = attackingSquad.filter { !$0.isSentOff }
        guard !availableShooters.isEmpty else { return }
        
        // Weight forwards and attacking midfielders higher for shots
        let weightedShooters = availableShooters.sorted { p1, p2 in
            let score1 = p1.player.attributes.shooting + (p1.player.primaryPosition.isAttacking ? 30 : 0)
            let score2 = p2.player.attributes.shooting + (p2.player.primaryPosition.isAttacking ? 30 : 0)
            return score1 > score2
        }
        let shooterIdxInAvailable = Int.random(in: 0..<min(4, weightedShooters.count))
        let shooter = weightedShooters[shooterIdxInAvailable]
        
        let assisterCandidates = availableShooters.filter { $0.player.id != shooter.player.id }
        let assister = Double.random(in: 0...1) < 0.75 ? assisterCandidates.randomElement() : nil
        
        // Calculate shot quality and xG
        let shootingSkill = Double(shooter.player.attributes.shooting)
        let composureSkill = Double(shooter.player.attributes.composure)
        let baseChanceQuality = (shootingSkill * 0.6 + composureSkill * 0.4) / 100.0
        
        let chanceXG = min(0.50, max(0.03, baseChanceQuality * Double.random(in: 0.25...0.70)))
        // Reported xG is the chance's real scoring probability against an
        // average keeper (the raw chance quality used to be reported, which
        // overstated xG nearly twofold: 11 shots could show 3.8 xG).
        let reportedXG = chanceXG * 0.78 * (1.20 - 0.70 * 0.55)
        if isHomeAttacking { homeXG += reportedXG } else { awayXG += reportedXG }
        
        // Opposition goalkeeper
        let defendingSquad = isHomeAttacking ? awayActive : homeActive
        guard let gk = defendingSquad.first(where: { $0.player.primaryPosition == .GK && !$0.isSentOff }) ??
            defendingSquad.first(where: { !$0.isSentOff }) ?? defendingSquad.first else { return }
        let gkReflexes = Double(gk.player.attributes.reflexes)
        let gkPositioning = Double(gk.player.attributes.gkPositioning)
        let gkSkill = (gkReflexes * 0.6 + gkPositioning * 0.4) / 100.0
        
        // Realistic finishing: a single open-play chance converts ~15-18% of the time
        // before goalkeeper quality is factored in. A strong keeper suppresses this further.
        let conversionProbability = chanceXG * 0.78 * (1.20 - (gkSkill * 0.55))
        let roll = Double.random(in: 0...1)
        
        if roll < conversionProbability {
            // GOAL SCORED!
            if isHomeAttacking {
                homeGoals += 1
                homeShotsOnTarget += 1
            } else {
                awayGoals += 1
                awayShotsOnTarget += 1
            }
            
            // Update shooter stats & rating
            if let idx = (isHomeAttacking ? homeActive : awayActive).firstIndex(where: { $0.player.id == shooter.player.id }) {
                if isHomeAttacking {
                    homeActive[idx].goals += 1
                    homeActive[idx].currentRating = min(10.0, homeActive[idx].currentRating + 1.2)
                } else {
                    awayActive[idx].goals += 1
                    awayActive[idx].currentRating = min(10.0, awayActive[idx].currentRating + 1.2)
                }
            }
            // Update assister stats
            if let a = assister, let aIdx = (isHomeAttacking ? homeActive : awayActive).firstIndex(where: { $0.player.id == a.player.id }) {
                if isHomeAttacking {
                    homeActive[aIdx].assists += 1
                    homeActive[aIdx].currentRating = min(10.0, homeActive[aIdx].currentRating + 0.6)
                } else {
                    awayActive[aIdx].assists += 1
                    awayActive[aIdx].currentRating = min(10.0, awayActive[aIdx].currentRating + 0.6)
                }
            }
            
            let commentary = Commentary.goal(
                scorer: shooter.player,
                assister: assister?.player,
                club: attackingClub,
                opponent: defendingClub,
                minute: minute,
                homeGoals: homeGoals,
                awayGoals: awayGoals,
                isHome: isHomeAttacking
            )
            
            events.append(
                MatchEvent(
                    minute: minute,
                    type: .goal,
                    clubId: attackingClub.id,
                    playerId: shooter.player.id,
                    assistPlayerId: assister?.player.id,
                    shortText: commentary.short,
                    detailText: commentary.detail,
                    isHomeTeam: isHomeAttacking
                )
            )
        } else if roll < conversionProbability + 0.35 {
            // Shot on target saved by Goalkeeper
            if isHomeAttacking {
                homeShotsOnTarget += 1
                awaySaves += 1
            } else {
                awayShotsOnTarget += 1
                homeSaves += 1
            }
            
            if isHomeAttacking {
                if let gkIdx = awayActive.firstIndex(where: { $0.player.id == gk.player.id }) {
                    awayActive[gkIdx].currentRating = min(10.0, awayActive[gkIdx].currentRating + 0.3)
                }
            } else {
                if let gkIdx = homeActive.firstIndex(where: { $0.player.id == gk.player.id }) {
                    homeActive[gkIdx].currentRating = min(10.0, homeActive[gkIdx].currentRating + 0.3)
                }
            }
            
            let commentary = Commentary.save(
                keeper: gk.player,
                shooter: shooter.player,
                keeperClub: defendingClub,
                minute: minute,
                isHome: !isHomeAttacking
            )
            events.append(
                MatchEvent(
                    minute: minute,
                    type: .shotOnTarget,
                    clubId: attackingClub.id,
                    playerId: shooter.player.id,
                    shortText: commentary.short,
                    detailText: commentary.detail,
                    isHomeTeam: isHomeAttacking
                )
            )
        } else if roll < conversionProbability + 0.45 {
            // Hit woodwork
            let commentary = Commentary.miss(
                shooter: shooter.player,
                club: attackingClub,
                minute: minute,
                isWoodwork: true
            )
            events.append(
                MatchEvent(
                    minute: minute,
                    type: .woodwork,
                    clubId: attackingClub.id,
                    playerId: shooter.player.id,
                    shortText: commentary.short,
                    detailText: commentary.detail,
                    isHomeTeam: isHomeAttacking
                )
            )
        } else if Double.random(in: 0...1) < 0.3 {
            // Blocked by a defender before it reaches the goalkeeper.
            let blockers = (isHomeAttacking ? awayActive : homeActive)
                .filter { !$0.isSentOff && !$0.isSubstitutedOut && $0.player.primaryPosition.category == .defender }
            let commentary = Commentary.blocked(
                shooter: shooter.player,
                blocker: blockers.randomElement()?.player,
                club: attackingClub,
                minute: minute
            )
            events.append(
                MatchEvent(
                    minute: minute,
                    type: .shotBlocked,
                    clubId: attackingClub.id,
                    playerId: shooter.player.id,
                    shortText: commentary.short,
                    detailText: commentary.detail,
                    isHomeTeam: isHomeAttacking
                )
            )
        } else {
            // Chance missed off-target
            let commentary = Commentary.miss(
                shooter: shooter.player,
                club: attackingClub,
                minute: minute,
                isWoodwork: false
            )
            events.append(
                MatchEvent(
                    minute: minute,
                    type: .chanceMissed,
                    clubId: attackingClub.id,
                    playerId: shooter.player.id,
                    shortText: commentary.short,
                    detailText: commentary.detail,
                    isHomeTeam: isHomeAttacking
                )
            )
        }
    }
    
    // MARK: - Corner Resolution
    
    private static func resolveCorner(
        isHomeAttacking: Bool,
        homeActive: inout [ActiveMatchPlayer],
        awayActive: inout [ActiveMatchPlayer],
        homeClub: Club,
        awayClub: Club,
        homeGoals: inout Int,
        awayGoals: inout Int,
        homeCorners: inout Int,
        awayCorners: inout Int,
        homeShots: inout Int,
        awayShots: inout Int,
        homeShotsOnTarget: inout Int,
        awayShotsOnTarget: inout Int,
        homeXG: inout Double,
        awayXG: inout Double,
        minute: Int,
        events: inout [MatchEvent]
    ) {
        if isHomeAttacking { homeCorners += 1 } else { awayCorners += 1 }
        
        let attackingClub = isHomeAttacking ? homeClub : awayClub
        let defendingClub = isHomeAttacking ? awayClub : homeClub
        let attackingSquad = isHomeAttacking ? homeActive : awayActive
        
        // Find designated or best corner taker
        let cornerTakerId = attackingClub.tactics.cornerTaker
        let available = attackingSquad.filter { !$0.isSentOff && !$0.isSubstitutedOut }
        guard let taker = available.first(where: { $0.player.id == cornerTakerId }) ??
            available.max(by: { $0.player.attributes.crossing < $1.player.attributes.crossing }) ??
            available.first else { return }
        
        let cornerCommentary = Commentary.corner(taker: taker.player, club: attackingClub, minute: minute)
        events.append(
            MatchEvent(
                minute: minute,
                type: .corner,
                clubId: attackingClub.id,
                playerId: taker.player.id,
                shortText: cornerCommentary.short,
                detailText: cornerCommentary.detail,
                isHomeTeam: isHomeAttacking
            )
        )

        // Find top aerial threat
        let aerialTargets = available.filter { $0.player.id != taker.player.id }
        let headerTarget = aerialTargets.max(by: { ($0.player.attributes.heading + $0.player.attributes.jumping) < ($1.player.attributes.heading + $1.player.attributes.jumping) }) ?? taker
        
        // Goal chance (~4% for high quality set-pieces)
        let headingSkill = Double(headerTarget.player.attributes.heading)
        let goalChance = (Double(taker.player.attributes.crossing) * 0.02 + headingSkill * 0.035) / 100.0

        // xG for the header is its real scoring chance.
        if isHomeAttacking { homeXG += goalChance } else { awayXG += goalChance }
        if isHomeAttacking { homeShots += 1 } else { awayShots += 1 }
        
        if Double.random(in: 0...1) < goalChance {
            if isHomeAttacking {
                homeGoals += 1
                homeShotsOnTarget += 1
            } else {
                awayGoals += 1
                awayShotsOnTarget += 1
            }
            
            if let idx = (isHomeAttacking ? homeActive : awayActive).firstIndex(where: { $0.player.id == headerTarget.player.id }) {
                if isHomeAttacking {
                    homeActive[idx].goals += 1
                    homeActive[idx].currentRating += 1.2
                } else {
                    awayActive[idx].goals += 1
                    awayActive[idx].currentRating += 1.2
                }
            }
            if let tIdx = (isHomeAttacking ? homeActive : awayActive).firstIndex(where: { $0.player.id == taker.player.id }) {
                if isHomeAttacking {
                    homeActive[tIdx].assists += 1
                    homeActive[tIdx].currentRating += 0.6
                } else {
                    awayActive[tIdx].assists += 1
                    awayActive[tIdx].currentRating += 0.6
                }
            }
            
            let commentary = Commentary.goal(
                scorer: headerTarget.player,
                assister: taker.player,
                club: attackingClub,
                opponent: defendingClub,
                minute: minute,
                homeGoals: homeGoals,
                awayGoals: awayGoals,
                isHome: isHomeAttacking,
                goalType: .glancingCornerHeader
            )
            
            events.append(
                MatchEvent(
                    minute: minute,
                    type: .goal,
                    clubId: attackingClub.id,
                    playerId: headerTarget.player.id,
                    assistPlayerId: taker.player.id,
                    shortText: commentary.short,
                    detailText: commentary.detail,
                    isHomeTeam: isHomeAttacking
                )
            )
        }
    }
    
    // MARK: - Free Kick Resolution
    
    private static func resolveFreeKick(
        isHomeAttacking: Bool,
        homeActive: inout [ActiveMatchPlayer],
        awayActive: inout [ActiveMatchPlayer],
        homeClub: Club,
        awayClub: Club,
        homeGoals: inout Int,
        awayGoals: inout Int,
        homeShots: inout Int,
        awayShots: inout Int,
        homeShotsOnTarget: inout Int,
        awayShotsOnTarget: inout Int,
        homeXG: inout Double,
        awayXG: inout Double,
        minute: Int,
        events: inout [MatchEvent]
    ) {
        let attackingClub = isHomeAttacking ? homeClub : awayClub
        let defendingClub = isHomeAttacking ? awayClub : homeClub
        let attackingSquad = isHomeAttacking ? homeActive : awayActive
        
        let freeKickTakerId = attackingClub.tactics.freeKickTaker
        let available = attackingSquad.filter { !$0.isSentOff && !$0.isSubstitutedOut }
        guard let taker = available.first(where: { $0.player.id == freeKickTakerId }) ??
            available.max(by: { $0.player.attributes.freeKicks < $1.player.attributes.freeKicks }) ??
            available.first else { return }
        
        let fkSkill = Double(taker.player.attributes.freeKicks)
        let conversionChance = (fkSkill * 0.05) / 100.0
        // A direct free kick's xG is its real conversion chance (~3-5%).
        if isHomeAttacking {
            homeShots += 1
            homeXG += conversionChance
        } else {
            awayShots += 1
            awayXG += conversionChance
        }

        if Double.random(in: 0...1) < conversionChance {
            if isHomeAttacking {
                homeGoals += 1
                homeShotsOnTarget += 1
            } else {
                awayGoals += 1
                awayShotsOnTarget += 1
            }
            
            if let idx = (isHomeAttacking ? homeActive : awayActive).firstIndex(where: { $0.player.id == taker.player.id }) {
                if isHomeAttacking {
                    homeActive[idx].goals += 1
                    homeActive[idx].currentRating += 1.3
                } else {
                    awayActive[idx].goals += 1
                    awayActive[idx].currentRating += 1.3
                }
            }
            
            let commentary = Commentary.goal(
                scorer: taker.player,
                assister: nil,
                club: attackingClub,
                opponent: defendingClub,
                minute: minute,
                homeGoals: homeGoals,
                awayGoals: awayGoals,
                isHome: isHomeAttacking,
                goalType: .curlingFreeKick
            )
            
            events.append(
                MatchEvent(
                    minute: minute,
                    type: .goal,
                    clubId: attackingClub.id,
                    playerId: taker.player.id,
                    shortText: commentary.short,
                    detailText: commentary.detail,
                    isHomeTeam: isHomeAttacking
                )
            )
        }
    }
    
    // MARK: - Foul & Penalty Resolution
    
    private static func resolveFoul(
        isHomeTeamFouling: Bool,
        homeActive: inout [ActiveMatchPlayer],
        awayActive: inout [ActiveMatchPlayer],
        homeClub: Club,
        awayClub: Club,
        homeFouls: inout Int,
        awayFouls: inout Int,
        homeGoals: inout Int,
        awayGoals: inout Int,
        homeShots: inout Int,
        awayShots: inout Int,
        homeShotsOnTarget: inout Int,
        awayShotsOnTarget: inout Int,
        homeSaves: inout Int,
        awaySaves: inout Int,
        homeXG: inout Double,
        awayXG: inout Double,
        minute: Int,
        events: inout [MatchEvent]
    ) {
        if isHomeTeamFouling { homeFouls += 1 } else { awayFouls += 1 }

        let foulingClub = isHomeTeamFouling ? homeClub : awayClub
        let foulingSquad = isHomeTeamFouling ? homeActive : awayActive

        let activeFoulers = foulingSquad.filter { !$0.isSentOff && !$0.isSubstitutedOut }
        guard let fouler = activeFoulers.randomElement() else { return }
        guard let foulerIdx = (isHomeTeamFouling ? homeActive : awayActive).firstIndex(where: { $0.player.id == fouler.player.id }) else { return }

        let aggression = Double(fouler.player.attributes.aggression)
        let tackling = Double(fouler.player.attributes.tackling)

        // The spot-kick decision is independent of the card roll: a clear box
        // offence can be a penalty without also producing a booking (and vice
        // versa). Previously penalties only existed inside the card branch, so
        // most box fouls were silently ignored.
        let isPenalty = Double.random(in: 0...1) < 0.12
        if isPenalty {
            resolveInMatchPenalty(
                isHomeKicking: !isHomeTeamFouling,
                homeActive: &homeActive,
                awayActive: &awayActive,
                homeClub: homeClub,
                awayClub: awayClub,
                homeGoals: &homeGoals,
                awayGoals: &awayGoals,
                homeShots: &homeShots,
                awayShots: &awayShots,
                homeShotsOnTarget: &homeShotsOnTarget,
                awayShotsOnTarget: &awayShotsOnTarget,
                homeSaves: &homeSaves,
                awaySaves: &awaySaves,
                homeXG: &homeXG,
                awayXG: &awayXG,
                minute: minute,
                events: &events
            )
        }

        // Probability of a card given foul. Penalty-box offences are more likely
        // to be punished, but still depend on the challenge.
        // Scaled so a typical match produces around three bookings, in line
        // with real top-flight football (it previously averaged just over one).
        var cardProbability = min(0.9, (aggression * 0.45 + (100.0 - tackling) * 0.3) / 100.0 * 2.0)
        if isPenalty { cardProbability = min(0.92, cardProbability + 0.30) }

        guard Double.random(in: 0...1) < cardProbability else {
            // No booking: still describe the foul so the commentary never skips it.
            if !isPenalty {
                let victimClub = isHomeTeamFouling ? awayClub : homeClub
                let victims = (isHomeTeamFouling ? awayActive : homeActive).filter { !$0.isSentOff && !$0.isSubstitutedOut }
                let commentary = Commentary.foul(
                    fouler: fouler.player,
                    victim: victims.randomElement()?.player,
                    club: foulingClub,
                    victimClub: victimClub,
                    minute: minute
                )
                events.append(
                    MatchEvent(
                        minute: minute,
                        type: .foul,
                        clubId: foulingClub.id,
                        playerId: fouler.player.id,
                        shortText: commentary.short,
                        detailText: commentary.detail,
                        isHomeTeam: isHomeTeamFouling
                    )
                )
            }
            return
        }

        // Card roll: yellow or straight red
        let isStraightRed = Double.random(in: 0...1) < 0.03

        if isStraightRed {
            if isHomeTeamFouling {
                homeActive[foulerIdx].isSentOff = true
                homeActive[foulerIdx].currentRating = max(4.0, homeActive[foulerIdx].currentRating - 1.5)
            } else {
                awayActive[foulerIdx].isSentOff = true
                awayActive[foulerIdx].currentRating = max(4.0, awayActive[foulerIdx].currentRating - 1.5)
            }

            let commentary = Commentary.card(
                player: fouler.player,
                club: foulingClub,
                isRed: true,
                isSecondYellow: false,
                minute: minute
            )
            events.append(
                MatchEvent(
                    minute: minute,
                    type: .redCard,
                    clubId: foulingClub.id,
                    playerId: fouler.player.id,
                    shortText: commentary.short,
                    detailText: commentary.detail,
                    isHomeTeam: isHomeTeamFouling
                )
            )
        } else {
            // Yellow card
            let currentYellows = isHomeTeamFouling ? homeActive[foulerIdx].yellowCards : awayActive[foulerIdx].yellowCards
            if currentYellows >= 1 {
                // Second yellow -> Red
                if isHomeTeamFouling {
                    homeActive[foulerIdx].yellowCards += 1
                    homeActive[foulerIdx].isSentOff = true
                    homeActive[foulerIdx].currentRating = max(4.0, homeActive[foulerIdx].currentRating - 1.2)
                } else {
                    awayActive[foulerIdx].yellowCards += 1
                    awayActive[foulerIdx].isSentOff = true
                    awayActive[foulerIdx].currentRating = max(4.0, awayActive[foulerIdx].currentRating - 1.2)
                }

                let commentary = Commentary.card(
                    player: fouler.player,
                    club: foulingClub,
                    isRed: true,
                    isSecondYellow: true,
                    minute: minute
                )
                events.append(
                    MatchEvent(
                        minute: minute,
                        type: .secondYellow,
                        clubId: foulingClub.id,
                        playerId: fouler.player.id,
                        shortText: commentary.short,
                        detailText: commentary.detail,
                        isHomeTeam: isHomeTeamFouling
                    )
                )
            } else {
                // First yellow
                if isHomeTeamFouling {
                    homeActive[foulerIdx].yellowCards = 1
                    homeActive[foulerIdx].currentRating = max(4.0, homeActive[foulerIdx].currentRating - 0.4)
                } else {
                    awayActive[foulerIdx].yellowCards = 1
                    awayActive[foulerIdx].currentRating = max(4.0, awayActive[foulerIdx].currentRating - 0.4)
                }

                let commentary = Commentary.card(
                    player: fouler.player,
                    club: foulingClub,
                    isRed: false,
                    minute: minute
                )
                events.append(
                    MatchEvent(
                        minute: minute,
                        type: .yellowCard,
                        clubId: foulingClub.id,
                        playerId: fouler.player.id,
                        shortText: commentary.short,
                        detailText: commentary.detail,
                        isHomeTeam: isHomeTeamFouling
                    )
                )
            }
        }
    }
    
    // MARK: - In-Match Penalty Kick
    
    private static func resolveInMatchPenalty(
        isHomeKicking: Bool,
        homeActive: inout [ActiveMatchPlayer],
        awayActive: inout [ActiveMatchPlayer],
        homeClub: Club,
        awayClub: Club,
        homeGoals: inout Int,
        awayGoals: inout Int,
        homeShots: inout Int,
        awayShots: inout Int,
        homeShotsOnTarget: inout Int,
        awayShotsOnTarget: inout Int,
        homeSaves: inout Int,
        awaySaves: inout Int,
        homeXG: inout Double,
        awayXG: inout Double,
        minute: Int,
        events: inout [MatchEvent]
    ) {
        let kickingClub = isHomeKicking ? homeClub : awayClub
        let defendingClub = isHomeKicking ? awayClub : homeClub
        let kickingSquad = isHomeKicking ? homeActive : awayActive
        let defendingSquad = isHomeKicking ? awayActive : homeActive
        
        let availableTakers = kickingSquad.filter { !$0.isSentOff && !$0.isSubstitutedOut }
        let penaltyTakerId = kickingClub.tactics.penaltyTaker
        guard let taker = availableTakers.first(where: { $0.player.id == penaltyTakerId }) ??
            availableTakers.max(by: { $0.player.attributes.penalties < $1.player.attributes.penalties }) ??
            availableTakers.first else { return }

        let availableDefenders = defendingSquad.filter { !$0.isSentOff && !$0.isSubstitutedOut }
        guard let gk = availableDefenders.first(where: { $0.player.primaryPosition == .GK }) ??
            availableDefenders.first else { return }

        // A penalty is a shot with a fixed, high-quality expected-goal value.
        if isHomeKicking {
            homeShots += 1
            homeXG += 0.76
        } else {
            awayShots += 1
            awayXG += 0.76
        }
        
        let penaltySkill = Double(taker.player.attributes.penalties)
        let composure = Double(taker.player.attributes.composure)
        let gkOneOnOnes = Double(gk.player.attributes.oneOnOnes)
        let gkReflexes = Double(gk.player.attributes.reflexes)
        
        let conversionRate = 0.76 + ((penaltySkill + composure) - (gkOneOnOnes + gkReflexes)) * 0.0015
        let isScored = Double.random(in: 0...1) < min(0.92, max(0.55, conversionRate))
        
        if isScored {
            if isHomeKicking {
                homeGoals += 1
                homeShotsOnTarget += 1
            } else {
                awayGoals += 1
                awayShotsOnTarget += 1
            }
            
            if let idx = (isHomeKicking ? homeActive : awayActive).firstIndex(where: { $0.player.id == taker.player.id }) {
                if isHomeKicking {
                    homeActive[idx].goals += 1
                    homeActive[idx].currentRating += 1.0
                } else {
                    awayActive[idx].goals += 1
                    awayActive[idx].currentRating += 1.0
                }
            }
            
            let commentary = Commentary.goal(
                scorer: taker.player,
                assister: nil,
                club: kickingClub,
                opponent: defendingClub,
                minute: minute,
                homeGoals: homeGoals,
                awayGoals: awayGoals,
                isHome: isHomeKicking,
                goalType: .clinicalPenalty
            )
            events.append(
                MatchEvent(
                    minute: minute,
                    type: .goal,
                    clubId: kickingClub.id,
                    playerId: taker.player.id,
                    shortText: commentary.short,
                    detailText: commentary.detail,
                    isHomeTeam: isHomeKicking
                )
            )
        } else {
            if isHomeKicking {
                homeShotsOnTarget += 1
                awaySaves += 1
            } else {
                awayShotsOnTarget += 1
                homeSaves += 1
            }
            let shortText = "PENALTY SAVED! \(taker.player.displayName) misses! \(minute)'"
            let detailText = "\(taker.player.fullName) struck it towards the bottom corner, but \(gk.player.fullName) guessed correctly and pulled off a stunning penalty save!"
            events.append(
                MatchEvent(
                    minute: minute,
                    type: .penaltyMissed,
                    clubId: kickingClub.id,
                    playerId: taker.player.id,
                    shortText: shortText,
                    detailText: detailText,
                    isHomeTeam: isHomeKicking
                )
            )
        }
    }
    
    // MARK: - Penalty Shootout
    
    private static func resolvePenaltyShootout(
        homeClub: Club,
        awayClub: Club,
        homeActive: [ActiveMatchPlayer],
        awayActive: [ActiveMatchPlayer],
        homeGoals: inout Int,
        awayGoals: inout Int,
        events: inout [MatchEvent]
    ) {
        events.append(
            MatchEvent(
                minute: 120,
                type: .penaltyShootout,
                            shortText: "PENALTY SHOOTOUT BEGINS!",
                detailText: "All square after 120 minutes! The tie will be decided from twelve yards.",
                isHomeTeam: true
            )
        )
        
        guard !homeActive.isEmpty, !awayActive.isEmpty else { return }
        let homeOnPitch = homeActive.filter { !$0.isSentOff && !$0.isSubstitutedOut }
        let awayOnPitch = awayActive.filter { !$0.isSentOff && !$0.isSubstitutedOut }
        var homeTakers = homeOnPitch.sorted { $0.player.attributes.penalties > $1.player.attributes.penalties }
        var awayTakers = awayOnPitch.sorted { $0.player.attributes.penalties > $1.player.attributes.penalties }
        if homeTakers.isEmpty { homeTakers = homeActive }
        if awayTakers.isEmpty { awayTakers = awayActive }
        guard !homeTakers.isEmpty, !awayTakers.isEmpty else { return }
        
        guard let homeGk = homeOnPitch.first(where: { $0.player.primaryPosition == .GK }) ?? homeActive.first,
              let awayGk = awayOnPitch.first(where: { $0.player.primaryPosition == .GK }) ?? awayActive.first else { return }
        
        var homeShootoutScore = 0
        var awayShootoutScore = 0

        func conversionChance(taker: ActiveMatchPlayer, keeper: ActiveMatchPlayer) -> Double {
            let raw = 0.75 + Double(taker.player.attributes.penalties - keeper.player.attributes.reflexes) * 0.002
            return min(0.95, max(0.55, raw))
        }

        // Best-of-five, with early clinching, followed by sudden death. Each
        // round is one kick per side; the shootout ends as soon as one side can
        // no longer be caught, or once the scores differ after round five.
        var round = 1
        while round <= 50 {
            let homeTaker = homeTakers[(round - 1) % homeTakers.count]
            let awayTaker = awayTakers[(round - 1) % awayTakers.count]

            if Double.random(in: 0...1) < conversionChance(taker: homeTaker, keeper: awayGk) {
                homeShootoutScore += 1
            }

            // After the home kick, the away side may still have regulation kicks
            // left. If they cannot mathematically catch up, the tie is over.
            if round <= 5 {
                let awayKicksRemaining = 6 - round
                if homeShootoutScore > awayShootoutScore + awayKicksRemaining { break }
            }

            if Double.random(in: 0...1) < conversionChance(taker: awayTaker, keeper: homeGk) {
                awayShootoutScore += 1
            }

            if round >= 5 {
                if homeShootoutScore != awayShootoutScore { break }
            } else {
                let kicksRemaining = 5 - round
                if abs(homeShootoutScore - awayShootoutScore) > kicksRemaining { break }
            }

            round += 1
        }

        // Safeguard after 50 sudden-death rounds (practically impossible): always
        // produce a winner rather than awarding the tie to the away side by default.
        if homeShootoutScore == awayShootoutScore {
            if Bool.random() {
                homeShootoutScore += 1
            } else {
                awayShootoutScore += 1
            }
        }
        if homeShootoutScore > awayShootoutScore {
            homeGoals += 1
            events.append(
                MatchEvent(
                    minute: 120,
                    type: .penaltyShootout,
                                shortText: "\(homeClub.name) win on penalties (\(homeShootoutScore)-\(awayShootoutScore))!",
                    detailText: "Jubilation for \(homeClub.name) as they prevail in the dramatic penalty shootout!",
                    isHomeTeam: true
                )
            )
        } else {
            awayGoals += 1
            events.append(
                MatchEvent(
                    minute: 120,
                    type: .penaltyShootout,
                                shortText: "\(awayClub.name) win on penalties (\(awayShootoutScore)-\(homeShootoutScore))!",
                    detailText: "Heroics in the shootout! \(awayClub.name) triumph from the spot!",
                    isHomeTeam: false
                )
            )
        }
    }
    
    // MARK: - Tactical Strength Calculator
    
    /// Exponent applied to team strength when sharing out the match's events.
    /// Tuned by simulating full seasons of every league so that home/draw/away
    /// lands near 48/22/30 and a clearly stronger side (8+ rating points) wins
    /// about three times in four, as in real football.
    static let strengthSensitivity = 8.0
    /// Strength multiplier for the home side.
    static let homeAdvantage = 1.05

    private static func calculateTeamStrength(
        activePlayers: [ActiveMatchPlayer],
        tactics: Tactics,
        isHome: Bool,
        neutralVenue: Bool
    ) -> Double {
        var baseStrength = 0.0
        var count = 0
        
        for ap in activePlayers where !ap.isSentOff {
            baseStrength += ap.effectiveSkill(for: ap.player.primaryPosition.category)
            count += 1
        }
        
        guard count > 0 else { return 30.0 }
        let average = baseStrength / Double(count)
        
        // Red card handicap (playing with 10 or 9 men severely damages performance)
        let redCardPenalty = Double(11 - count) * 4.5
        var total = max(20.0, average - redCardPenalty)
        
        // Mentality modifier (attacking intent scales overall threat)
        total *= tactics.mentality.attackingMultiplier
        // Width shapes attacking intent (wide = more chance creation).
        total *= tactics.width.attackingMultiplier
        // Passing style slightly shifts threat (direct/long create more chances).
        total *= tactics.passingStyle.chanceMultiplier
        // Formation shape shapes threat (more forwards = more attacking bite).
        total *= tactics.formation.attackingBias
        
        // Home advantage. Small, because it is amplified by the strength curve
        // used to share out the match's events (see `strengthSensitivity`).
        if isHome && !neutralVenue {
            total *= homeAdvantage
        }
        
        return total
    }
    
    /// Defensive solidity factor derived from tactics: applied to reduce the
    /// opponent's possession share and chance quality.
    private static func defensiveFactor(tactics: Tactics) -> Double {
        return tactics.mentality.defensiveMultiplier
            * tactics.pressing.defensiveMultiplier
            * tactics.width.defensiveMultiplier
            * tactics.formation.defensiveBias
    }
    
    // MARK: - Fatigue Progression
    
    private static func updateFatigue(
        activePlayers: inout [ActiveMatchPlayer],
        tactics: Tactics
    ) {
        let pressingDrain = tactics.pressing.staminaDrainMultiplier
        
        for idx in 0..<activePlayers.count {
            guard !activePlayers[idx].isSentOff && !activePlayers[idx].isSubstitutedOut else { continue }
            activePlayers[idx].minutesPlayed += 1
            
            let staminaStat = Double(activePlayers[idx].player.attributes.stamina)
            let baseDrain = (0.28 - (staminaStat * 0.0015)) * pressingDrain
            activePlayers[idx].currentFatigue = min(100.0, activePlayers[idx].currentFatigue + baseDrain)
        }
    }
    
    // MARK: - Substitutions
    
    private static func tryPerformSubstitution(
        activePlayers: inout [ActiveMatchPlayer],
        bench: inout [Player],
        subsUsed: inout Int,
        maxSubs: Int,
        club: Club,
        isHome: Bool,
        minute: Int,
        events: inout [MatchEvent],
        departed: inout [ActiveMatchPlayer]
    ) {
        guard subsUsed < maxSubs && !bench.isEmpty else { return }
        
        // Find most fatigued starter (excluding GK unless injured)
        let candidates = activePlayers.enumerated().filter { _, ap in
            !ap.isSentOff && !ap.isSubstitutedOut && ap.player.primaryPosition != .GK
        }
        guard let (outIdx, playerToSub) = candidates.max(by: { $0.1.currentFatigue < $1.1.currentFatigue }),
              playerToSub.currentFatigue > 60.0 else { return }
        
        // Find compatible player on bench
        let cat = playerToSub.player.primaryPosition.category
        let benchMatchIdx = bench.firstIndex(where: { $0.primaryPosition.category == cat }) ?? 0
        let incomingPlayer = bench.remove(at: benchMatchIdx)
        
        // Mark outgoing
        activePlayers[outIdx].isSubstitutedOut = true
        departed.append(playerToSub)
        
        // Insert fresh legs into active match players
        let freshSub = ActiveMatchPlayer(player: incomingPlayer, currentFatigue: 0.0, currentRating: 6.0)
        activePlayers[outIdx] = freshSub
        subsUsed += 1
        
        let commentary = Commentary.substitution(
            playerIn: incomingPlayer,
            playerOut: playerToSub.player,
            club: club,
            minute: minute
        )
        events.append(
            MatchEvent(
                minute: minute,
                type: .substitution,
                clubId: club.id,
                playerId: incomingPlayer.id,
                shortText: commentary.short,
                detailText: commentary.detail,
                isHomeTeam: isHome
            )
        )
    }
    
    // MARK: - In-Match Injury Check
    
    private static func checkInMatchInjury(
        homeActive: inout [ActiveMatchPlayer],
        awayActive: inout [ActiveMatchPlayer],
        homeClub: Club,
        awayClub: Club,
        minute: Int,
        events: inout [MatchEvent]
    ) {
        let isHome = Double.random(in: 0...1) < 0.5
        let intensity = isHome ? homeClub.tactics.pressing.staminaDrainMultiplier : awayClub.tactics.pressing.staminaDrainMultiplier
        
        if isHome {
            let candidates = homeActive.indices.filter {
                !homeActive[$0].isSentOff && !homeActive[$0].isSubstitutedOut
            }
            guard let idx = candidates.randomElement() else { return }
            if let injury = InjuryEngine.checkForInjury(player: homeActive[idx].player, matchMinute: minute, intensity: intensity) {
                homeActive[idx].player.injury = injury
                let commentary = Commentary.injury(player: homeActive[idx].player, club: homeClub, minute: minute, injuryType: injury.type)
                events.append(
                    MatchEvent(
                        minute: minute,
                        type: .injury,
                        clubId: homeClub.id,
                        playerId: homeActive[idx].player.id,
                        shortText: commentary.short,
                        detailText: commentary.detail,
                        isHomeTeam: true
                    )
                )
            }
        } else {
            let candidates = awayActive.indices.filter {
                !awayActive[$0].isSentOff && !awayActive[$0].isSubstitutedOut
            }
            guard let idx = candidates.randomElement() else { return }
            if let injury = InjuryEngine.checkForInjury(player: awayActive[idx].player, matchMinute: minute, intensity: intensity) {
                awayActive[idx].player.injury = injury
                let commentary = Commentary.injury(player: awayActive[idx].player, club: awayClub, minute: minute, injuryType: injury.type)
                events.append(
                    MatchEvent(
                        minute: minute,
                        type: .injury,
                        clubId: awayClub.id,
                        playerId: awayActive[idx].player.id,
                        shortText: commentary.short,
                        detailText: commentary.detail,
                        isHomeTeam: false
                    )
                )
            }
        }
    }
    
    // MARK: - Man of the Match
    
    private static func determineManOfTheMatch(
        homeActive: [ActiveMatchPlayer],
        awayActive: [ActiveMatchPlayer]
    ) -> ActiveMatchPlayer? {
        let all = homeActive + awayActive
        return all.max(by: { $0.currentRating < $1.currentRating })
    }
    
    // MARK: - Post-Match Club State Synchronization
    
    private static func applyMatchToClub(
        club: inout Club,
        activePlayers: [ActiveMatchPlayer],
        opponentGoals: Int,
        motmId: UUID?
    ) {
        let isCleanSheet = (opponentGoals == 0)
        
        for ap in activePlayers {
            if var p = club.player(withId: ap.player.id) {
                let isMotm = (p.id == motmId)
                let gotYellow = (ap.yellowCards >= 1)
                let gotRed = ap.isSentOff
                
                p.recordMatch(
                    rating: (ap.currentRating * 10).rounded() / 10,
                    minutes: ap.minutesPlayed,
                    goals: ap.goals,
                    assists: ap.assists,
                    yellowCard: gotYellow,
                    redCard: gotRed,
                    cleanSheet: isCleanSheet,
                    isMotm: isMotm
                )
                
                if let inj = ap.player.injury {
                    p.injury = inj
                }
                
                club.updatePlayer(p)
            }
        }
    }
}
