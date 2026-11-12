//
//  PostMatchView.swift
//  Touchline
//
//  The full-time report: scoreboard, every goal with its scorer, assist and
//  how it was scored, cards and injuries, player of the match, the user's
//  player ratings, momentum, team stats and (on request) the other results.
//

import SwiftUI

public struct PostMatchView: View {
    @Environment(GameState.self) private var gameState
    @State private var showElsewhere = false
    @State private var pressReply: String?

    // The full-time journey, one screen at a time.
    private enum Step { case fullTime, playerOfMatch, results }
    private enum Tab: String, CaseIterable { case facts = "Match Facts", ratings = "Ratings", stats = "Stats" }
    @State private var step: Step = .fullTime
    @State private var tab: Tab = .facts
    @State private var ratingsShowHome = true
    @State private var profilePlayer: ProfileTarget?
    @State private var playedFeedback = false
    @AccessibilityFocusState private var headingFocused: Bool

    private struct ProfileTarget: Identifiable { let id: UUID }

    public var body: some View {
        VStack(spacing: 0) {
            if let fixture = gameState.activeMatchFixture,
               let res = fixture.result,
               let home = gameState.club(withId: fixture.homeClubId),
               let away = gameState.club(withId: fixture.awayClubId) {
                ScrollView {
                    VStack(spacing: 16) {
                        switch step {
                        case .fullTime:
                            scoreboard(fixture: fixture, res: res, home: home, away: away)
                                .accessibilityFocused($headingFocused)
                            GFTabs(selection: $tab)
                                .onChange(of: tab) { _, _ in Haptics.selection() }
                            switch tab {
                            case .facts:
                                matchFacts(res: res, home: home, away: away)
                                pressCard(fixture: fixture)
                            case .ratings:
                                ratingsTab(res: res, home: home, away: away)
                            case .stats:
                                if res.events.contains(where: { $0.type == .goal || $0.type == .shotOnTarget || $0.type == .chance }) {
                                    MomentumChartView(
                                        result: res,
                                        homeName: home.name,
                                        awayName: away.name,
                                        homeColor: Color(hex: home.primaryColor),
                                        awayColor: Color(hex: away.primaryColor == home.primaryColor ? away.secondaryColor : away.primaryColor)
                                    )
                                    .gfCard()
                                }
                                statsCard(res: res, home: home, away: away)
                            }
                        case .playerOfMatch:
                            playerOfMatchScreen(res: res)
                        case .results:
                            divisionResults(fixture: fixture)
                            tableCard(fixture: fixture)
                        }
                    }
                    .padding()
                }
                continueBar
            } else {
                ContentUnavailableView("No Match Summary", systemImage: "sportscourt",
                                       description: Text("Play a match to see the full-time recap."))
            }
        }
        .stadiumBackground()
        .navigationTitle(step == .fullTime ? "Full Time" : step == .playerOfMatch ? "Player of the Match" : "Around the Division")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .animation(.easeInOut(duration: 0.22), value: step)
        .onChange(of: step) { _, _ in headingFocused = true }
        .sheet(item: $profilePlayer) { target in
            NavigationStack { PlayerDetailView(playerId: target.id) }
                .environment(gameState)
        }
        .onAppear {
            guard !playedFeedback,
                  let fixture = gameState.activeMatchFixture,
                  let res = fixture.result,
                  let userClub = gameState.userClub else { return }
            playedFeedback = true
            CrowdAtmosphere.shared.stopMatch()
            switch res.outcomeLetter(for: userClub.id) {
            case "W": SoundManager.shared.play(.win, enabled: gameState.soundEnabled); Haptics.success()
            case "L": SoundManager.shared.play(.loss, enabled: gameState.soundEnabled); Haptics.error()
            default: SoundManager.shared.play(.draw, enabled: gameState.soundEnabled); Haptics.warning()
            }
            headingFocused = true
        }
    }

    // MARK: - Continue

    private var continueBar: some View {
        VStack(spacing: 8) {
            Button {
                Haptics.tap()
                switch step {
                case .fullTime: step = .playerOfMatch
                case .playerOfMatch: step = .results
                case .results:
                    // Forget the finished match so the next match day selects the
                    // next fixture, never this one again.
                    gameState.closeFinishedMatch()
                    gameState.currentScreen = .dashboard
                }
            } label: {
                Text(step == .results ? "Back to Home" : "Continue")
            }
            .buttonStyle(.gfPrimary)
            .accessibilityHint(step == .fullTime ? "Shows the player of the match"
                               : step == .playerOfMatch ? "Shows this week's results in your division"
                               : "Returns to your club's home screen")
            if step == .results {
                Button {
                    gameState.closeFinishedMatch()
                    gameState.currentScreen = .matchHistory
                } label: {
                    Text("Fixtures and Results")
                }
                .buttonStyle(.gfOutline)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }

    // MARK: - Match Facts: goals mixed in order with cards, injuries and changes

    private func matchFacts(res: MatchResult, home: Club, away: Club) -> some View {
        let timeline = res.events.filter { $0.type.isTimelineEvent || $0.type == .halfTime }
        var runningHome = 0, runningAway = 0
        var rows: [(event: MatchEvent, score: String?)] = []
        for ev in timeline {
            switch ev.type {
            case .goal, .penalty:
                if ev.isHomeTeam { runningHome += 1 } else { runningAway += 1 }
                rows.append((ev, "\(runningHome) - \(runningAway)"))
            case .ownGoal:
                if ev.isHomeTeam { runningAway += 1 } else { runningHome += 1 }
                rows.append((ev, "\(runningHome) - \(runningAway)"))
            default:
                rows.append((ev, nil))
            }
        }
        return VStack(spacing: 0) {
            GFSectionHeader(title: "Match Facts", icon: "list.bullet.rectangle")
                .padding(.bottom, 6)
            if rows.allSatisfy({ $0.event.type == .halfTime }) {
                Text("A quiet game: no goals, cards or changes.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 12)
            }
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                if row.event.type == .halfTime {
                    HStack {
                        Rectangle().fill(Color.white.opacity(0.15)).frame(height: 1)
                        Text("Half-time").font(.caption.weight(.bold)).foregroundStyle(.secondary)
                        Rectangle().fill(Color.white.opacity(0.15)).frame(height: 1)
                    }
                    .padding(.vertical, 8)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Half-time")
                } else {
                    factRow(row.event, score: row.score, home: home, away: away)
                }
            }
        }
        .gfCard()
    }

    private func factRow(_ ev: MatchEvent, score: String?, home: Club, away: Club) -> some View {
        let player = ev.playerId.flatMap { gameState.player(withId: $0)?.player }
        let assist = ev.assistPlayerId.flatMap { gameState.player(withId: $0)?.player }
        let club = ev.isHomeTeam ? home : away
        let name = ev.type == .substitution ? "Substitution" : (player?.fullName ?? ev.shortText)
        let detail: String? = {
            switch ev.type {
            case .goal: return assist.map { "Assist: \($0.fullName)" }
            case .penalty: return "Penalty"
            case .ownGoal: return "Own goal"
            case .substitution: return ev.shortText.components(separatedBy: ": ").last
            default: return nil
            }
        }()
        var spoken = "\(ev.minute) minutes. \(ev.type.spokenName). "
        spoken += ev.type == .substitution ? (detail ?? "") : name
        spoken += ", \(club.name)."
        if let detail, ev.type != .substitution { spoken += " \(detail)." }
        if let score { spoken += " Score \(score.replacingOccurrences(of: " - ", with: " to "))." }

        return HStack(alignment: .top, spacing: 10) {
            Text("\(ev.minute)'")
                .font(.subheadline.weight(.bold).monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(width: 36, alignment: .trailing)
            EventBadge(type: ev.type)
            VStack(alignment: .leading, spacing: 2) {
                Text(name).font(.subheadline.weight(.semibold))
                if let detail { Text(detail).font(.caption).foregroundStyle(.secondary) }
                Text(club.name).font(.caption2).foregroundStyle(.tertiary)
            }
            Spacer(minLength: 4)
            if let score {
                Text(score)
                    .font(.subheadline.weight(.heavy).monospacedDigit())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color.white.opacity(0.12)))
            }
        }
        .padding(.vertical, 7)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(spoken)
    }

    // MARK: - Ratings: both line-ups on the pitch with match ratings

    @ViewBuilder
    private func ratingsTab(res: MatchResult, home: Club, away: Club) -> some View {
        let club = ratingsShowHome ? home : away
        let lineupIds = (ratingsShowHome ? res.homeLineup : res.awayLineup) ?? club.tactics.startingXI
        let formation = (ratingsShowHome ? res.homeFormation : res.awayFormation) ?? club.tactics.formation
        let lineup: [Player] = lineupIds.compactMap { gameState.player(withId: $0)?.player }
        let starters = Set(lineupIds)
        let subs: [(player: Player, rating: Double)] = res.playerRatings
            .compactMap { entry -> (player: Player, rating: Double)? in
                guard !starters.contains(entry.key), let lookup = gameState.player(withId: entry.key),
                      lookup.club?.id == club.id else { return nil }
                return (lookup.player, entry.value)
            }
            .sorted { $0.rating > $1.rating }

        GFTabs(selection: $ratingsShowHome, options: [(true, home.name), (false, away.name)])
        if lineup.count >= 11 {
            FormationPitchView(
                formation: formation,
                players: lineup,
                selectedPlayerId: res.manOfTheMatch,
                gameRatings: res.playerRatings,
                tapHint: "Double tap to open the player's profile",
                onSelect: { profilePlayer = ProfileTarget(id: $0.id) }
            )
        } else {
            ratingsCard(res: res)
        }
        if !subs.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                GFSectionHeader(title: "Off the Bench", icon: "arrow.left.arrow.right")
                ForEach(subs, id: \.player.id) { sub in
                    Button { profilePlayer = ProfileTarget(id: sub.player.id) } label: {
                        HStack {
                            Text(sub.player.fullName).font(.subheadline)
                            Spacer()
                            RatingPill(rating: sub.rating)
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(sub.player.fullName), substitute, match rating \(String(format: "%.1f", sub.rating))")
                }
            }
            .gfCard()
        }
    }

    // MARK: - Player of the Match screen

    @ViewBuilder
    private func playerOfMatchScreen(res: MatchResult) -> some View {
        if let id = res.manOfTheMatch ?? res.playerRatings.max(by: { $0.value < $1.value })?.key,
           let lookup = gameState.player(withId: id) {
            let player = lookup.player
            let rating = res.playerRatings[id] ?? 0
            let goals = res.events.filter { ($0.type == .goal || $0.type == .penalty) && $0.playerId == id }.count
            let assists = res.events.filter { $0.type == .goal && $0.assistPlayerId == id }.count
            let isMine = lookup.club?.id == gameState.userClubId

            VStack(spacing: 6) {
                Image(systemName: "star.circle.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(Color.highlight)
                    .accessibilityHidden(true)
                Text("Player of the Match")
                    .font(.gfDisplay(24))
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityFocused($headingFocused)
            }
            .padding(.top, 8)

            Button {
                Haptics.tap()
                profilePlayer = ProfileTarget(id: id)
            } label: {
                VStack(spacing: 14) {
                    FaceView(player: player, size: 120, style: .full)
                        .frame(width: 120, height: 120)
                        .padding(6)
                        .background(Circle().fill(Color.white.opacity(0.08)))
                        .overlay(Circle().stroke(Color.highlight, lineWidth: 3))
                    Text(player.fullName)
                        .font(.title2.weight(.bold))
                        .multilineTextAlignment(.center)
                    Text("\(player.primaryPosition.displayName) · \(lookup.club?.name ?? "Free agent") · Age \(player.age)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    HStack(spacing: 10) {
                        potmTile(String(format: "%.1f", rating), "Rating")
                        potmTile("\(goals)", goals == 1 ? "Goal" : "Goals")
                        potmTile("\(assists)", assists == 1 ? "Assist" : "Assists")
                        potmTile("\(player.overall)", "Overall")
                    }
                    Label(isMine ? "View profile" : "View profile and make an offer",
                          systemImage: isMine ? "person.text.rectangle" : "signature")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.highlight)
                }
                .padding(20)
                .frame(maxWidth: .infinity)
                .gfCard()
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(player.fullName), \(player.primaryPosition.displayName) for \(lookup.club?.name ?? "no club"), age \(player.age). Match rating \(String(format: "%.1f", rating)). \(goals) \(goals == 1 ? "goal" : "goals"), \(assists) \(assists == 1 ? "assist" : "assists"). Overall \(player.overall).")
            .accessibilityHint(isMine ? "Opens the player's profile" : "Opens the player's profile, where you can make a transfer offer")
            .accessibilityAddTraits(.isButton)
        } else {
            Text("No player of the match was recorded.")
                .foregroundStyle(.secondary)
                .padding(.top, 40)
        }
    }

    private func potmTile(_ value: String, _ label: String) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.headline.weight(.heavy).monospacedDigit())
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.white.opacity(0.08)))
    }

    // MARK: - Around the division

    private func divisionResults(fixture: Fixture) -> some View {
        let week = gameState.season.fixtures(forWeek: fixture.matchWeek)
            .filter { $0.isPlayed && $0.competition == fixture.competition }
            .sorted { a, b in a.id == fixture.id ? true : (b.id == fixture.id ? false : a.date < b.date) }
        return VStack(alignment: .leading, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(fixture.competition)
                    .font(.gfDisplay(22))
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityFocused($headingFocused)
                Text("Matchweek \(fixture.matchWeek) results")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, 4)
            ForEach(week, id: \.id) { f in
                if let r = f.result,
                   let h = gameState.club(withId: f.homeClubId),
                   let a = gameState.club(withId: f.awayClubId) {
                    resultRow(home: h, away: a, result: r, isUser: f.id == fixture.id)
                }
            }
        }
    }

    private func resultRow(home: Club, away: Club, result: MatchResult, isUser: Bool) -> some View {
        HStack(spacing: 8) {
            HStack(spacing: 6) {
                Text(home.name)
                    .font(.subheadline.weight(result.homeGoals > result.awayGoals ? .bold : .regular))
                    .lineLimit(2)
                    .multilineTextAlignment(.trailing)
                CrestView(club: home, size: 22)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            Text("\(result.homeGoals) - \(result.awayGoals)")
                .font(.headline.weight(.heavy).monospacedDigit())
                .frame(minWidth: 54)
                .padding(.vertical, 4)
                .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(isUser ? Color.brand : Color.white.opacity(0.1)))
            HStack(spacing: 6) {
                CrestView(club: away, size: 22)
                Text(away.name)
                    .font(.subheadline.weight(result.awayGoals > result.homeGoals ? .bold : .regular))
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(isUser ? Color.brand.opacity(0.18) : Color.white.opacity(0.05)))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(isUser ? "Your match. " : "")\(home.name) \(result.homeGoals), \(away.name) \(result.awayGoals)")
    }

    // MARK: - Scoreboard


    private func scoreboard(fixture: Fixture, res: MatchResult, home: Club, away: Club) -> some View {
        let outcome = gameState.userClubId.map { res.outcomeLetter(for: $0) } ?? "-"
        return VStack(spacing: 12) {
            HStack(spacing: 6) {
                Text(fixture.cupRound.map { "\(fixture.competition) • \($0)" } ?? "\(fixture.competition) • Matchweek \(fixture.matchWeek)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.85))
                if let derby = gameState.derbyName(for: fixture) {
                    GFPill(text: derby, color: .white, icon: "flame.fill")
                }
            }
            HStack(alignment: .center) {
                teamColumn(home)
                VStack(spacing: 2) {
                    Text("\(res.homeGoals) – \(res.awayGoals)")
                        .font(.system(size: 34, weight: .black, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.white)
                    Text("FULL TIME").font(.caption2.weight(.heavy)).tracking(1.5).foregroundStyle(.white.opacity(0.8))
                }
                teamColumn(away)
            }
            if outcome != "-" {
                Text(outcome == "W" ? "VICTORY" : outcome == "D" ? "DRAW" : "DEFEAT")
                    .font(.caption.weight(.heavy))
                    .tracking(2)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 5)
                    .background(
                        (outcome == "W" ? Color.winGreen : outcome == "D" ? Color.drawGray : Color.lossRed),
                        in: Capsule()
                    )
                    .foregroundStyle(.white)
            }
            if res.attendance > 0 {
                Label("\(res.attendance.formatted()) at \(home.stadium)", systemImage: "person.3.fill")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity)
        .background(
            ZStack {
                LinearGradient(colors: [Color(hex: home.primaryColor), Color(hex: away.primaryColor)],
                               startPoint: .leading, endPoint: .trailing)
                Color.black.opacity(0.35)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    private func teamColumn(_ club: Club) -> some View {
        VStack(spacing: 6) {
            CrestView(club: club, size: 36)
            Text(club.name)
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Goals

    private func playerName(_ id: UUID?) -> String? {
        guard let id else { return nil }
        return gameState.player(withId: id)?.player.fullName
    }

    private func goalsCard(res: MatchResult, home: Club, away: Club) -> some View {
        var running = (home: 0, away: 0)
        let rows: [(event: MatchEvent, score: String)] = res.goalEvents.map { event in
            if event.isHomeTeam { running.home += 1 } else { running.away += 1 }
            return (event, "\(running.home)-\(running.away)")
        }
        return VStack(alignment: .leading, spacing: 12) {
            GFSectionHeader(title: "Goals", icon: "soccerball")
            ForEach(rows, id: \.event.id) { row in
                let event = row.event
                let club = event.isHomeTeam ? home : away
                HStack(alignment: .top, spacing: 12) {
                    VStack(spacing: 4) {
                        Text("\(event.minute)'")
                            .font(.subheadline.weight(.heavy).monospacedDigit())
                        Text(row.score)
                            .font(.caption2.weight(.bold).monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                    .frame(width: 42)
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 6) {
                            CrestView(club: club, size: 16)
                            Text(playerName(event.playerId) ?? event.shortText)
                                .font(.subheadline.weight(.bold))
                            if event.type == .penalty { GFPill(text: "PEN", color: .orange) }
                            if event.type == .ownGoal { GFPill(text: "OG", color: .lossRed) }
                        }
                        if let assist = playerName(event.assistPlayerId) {
                            Label("Assist: \(assist)", systemImage: "arrowshape.turn.up.right.fill")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color.accentColor)
                        }
                        if !event.detailText.isEmpty {
                            Text(event.detailText)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    Spacer(minLength: 0)
                }
                .accessibilityElement(children: .combine)
                if row.event.id != rows.last?.event.id { Divider() }
            }
        }
        .gfCard()
    }

    // MARK: - Press conference

    @ViewBuilder
    private func pressCard(fixture: Fixture) -> some View {
        if let reply = pressReply {
            VStack(alignment: .leading, spacing: 8) {
                GFSectionHeader(title: "Press Conference", icon: "mic.fill")
                Text(reply).font(.subheadline)
            }
            .gfCard()
        } else if let question = gameState.pressQuestion(for: fixture) {
            VStack(alignment: .leading, spacing: 10) {
                GFSectionHeader(title: "Press Conference", icon: "mic.fill")
                Text("“\(question)”")
                    .font(.subheadline.italic())
                ForEach(PressTone.allCases) { tone in
                    Button {
                        withAnimation(.snappy) {
                            pressReply = gameState.answerPressConference(fixtureId: fixture.id, tone: tone)
                        }
                    } label: {
                        Label(tone.rawValue, systemImage: tone.icon)
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(12)
                            .background(Color.accentColor.opacity(0.1), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
            .gfCard()
        }
    }

    // MARK: - Cards and injuries

    @ViewBuilder
    private func disciplineCard(res: MatchResult, home: Club, away: Club) -> some View {
        let events = res.events.filter { [.yellowCard, .redCard, .secondYellow, .injury].contains($0.type) }
        if !events.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                GFSectionHeader(title: "Cards & Injuries", icon: "exclamationmark.triangle.fill")
                ForEach(events) { event in
                    HStack(spacing: 10) {
                        Text("\(event.minute)'")
                            .font(.caption.weight(.bold).monospacedDigit())
                            .frame(width: 34, alignment: .leading)
                        disciplineIcon(event.type)
                        Text(playerName(event.playerId) ?? event.shortText)
                            .font(.subheadline)
                        Spacer()
                        Text(event.isHomeTeam ? home.name : away.name)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityElement(children: .combine)
                }
            }
            .gfCard()
        }
    }

    @ViewBuilder
    private func disciplineIcon(_ type: MatchEventType) -> some View {
        switch type {
        case .yellowCard:
            RoundedRectangle(cornerRadius: 2).fill(.yellow).frame(width: 11, height: 15)
                .accessibilityLabel("Yellow card")
        case .redCard, .secondYellow:
            RoundedRectangle(cornerRadius: 2).fill(.red).frame(width: 11, height: 15)
                .accessibilityLabel("Red card")
        default:
            Image(systemName: "cross.case.fill").foregroundStyle(.red).font(.caption)
                .accessibilityLabel("Injury")
        }
    }

    // MARK: - Player of the match & ratings

    /// The man of the match in the spotlight: portrait, name, rating and
    /// goal contributions.
    private func potmCard(_ potm: (player: Player, clubName: String, rating: Double), res: MatchResult) -> some View {
        let goals = res.goalEvents.filter { $0.playerId == potm.player.id && $0.type != .ownGoal }.count
        let assists = res.goalEvents.filter { $0.assistPlayerId == potm.player.id }.count
        return Button {
            gameState.currentScreen = .playerDetail(potm.player.id)
        } label: {
            VStack(spacing: 10) {
                FaceView(player: potm.player, size: 76, style: .full)
                    .frame(width: 120, height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .shadow(color: Color(hex: "D4AF37").opacity(0.5), radius: 14)
                Text(potm.player.fullName.uppercased())
                    .font(.gfDisplay(18))
                    .multilineTextAlignment(.center)
                Text("MATCH MVP · \(potm.clubName.uppercased())")
                    .font(.gfLabel(14))
                    .foregroundStyle(Color(hex: "D4AF37"))
                HStack(spacing: 14) {
                    statChip(icon: "star.fill", text: String(format: "%.1f", potm.rating), highlight: true)
                    if goals > 0 { statChip(icon: "soccerball", text: "\(goals)", highlight: false) }
                    if assists > 0 { statChip(icon: "shoe.fill", text: "\(assists)", highlight: false) }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                RadialGradient(colors: [Color(hex: "D4AF37").opacity(0.25), .clear], center: .top, startRadius: 5, endRadius: 260)
            )
            .gfCard(padding: 0)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Match MVP, \(potm.player.fullName), rating \(String(format: "%.1f", potm.rating))\(goals > 0 ? ", \(goals) goals" : "")\(assists > 0 ? ", \(assists) assists" : "")")
    }

    private func statChip(icon: String, text: String, highlight: Bool) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon).font(.caption)
            Text(text)
                .font(.gfLabel(13).monospacedDigit())
                .foregroundStyle(Color.gfNight)
                .padding(.horizontal, 12).padding(.vertical, 3)
                .background(Capsule().fill(highlight ? Color.gfMint : Color.white))
        }
    }

    @ViewBuilder
    private func ratingsCard(res: MatchResult) -> some View {
        if let club = gameState.userClub {
            let rated = club.players
                .compactMap { p in res.playerRatings[p.id].map { (player: p, rating: $0) } }
                .sorted { $0.rating > $1.rating }
            if !rated.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    GFSectionHeader(title: "Your Ratings", icon: "chart.bar.fill")
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(rated, id: \.player.id) { entry in
                                VStack(spacing: 6) {
                                    FaceView(player: entry.player, size: 40)
                                    Text(entry.player.displayName)
                                        .font(.caption2.weight(.semibold))
                                        .lineLimit(1)
                                    Text(String(format: "%.1f", entry.rating))
                                        .font(.subheadline.weight(.heavy).monospacedDigit())
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 2)
                                        .background(ratingColor(entry.rating), in: Capsule())
                                }
                                .frame(width: 72)
                                .padding(.vertical, 8)
                                .background(Color(UIColor.tertiarySystemGroupedBackground),
                                            in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                                .accessibilityElement(children: .combine)
                            }
                        }
                    }
                }
                .gfCard()
            }
        }
    }

    private func ratingColor(_ rating: Double) -> Color {
        switch rating {
        case 8...: return Color(hex: "1E8449")
        case 7..<8: return Color.winGreen
        case 6..<7: return Color.orange
        default: return Color.lossRed
        }
    }

    // MARK: - Stats

    private func statsCard(res: MatchResult, home: Club, away: Club) -> some View {
        let h = res.homeStats, a = res.awayStats
        let homeColor = Color(hex: home.primaryColor)
        let awayColor = Color(hex: away.primaryColor == home.primaryColor ? away.secondaryColor : away.primaryColor)
        return VStack(alignment: .leading, spacing: 14) {
            GFSectionHeader(title: "Match Stats", icon: "chart.xyaxis.line")
            DualStatBar(title: "Possession", home: h.possession, away: a.possession,
                        homeText: "\(Int(h.possession))%", awayText: "\(Int(a.possession))%", homeColor: homeColor, awayColor: awayColor)
            DualStatBar(title: "Expected goals", home: h.xG, away: a.xG,
                        homeText: String(format: "%.2f", h.xG), awayText: String(format: "%.2f", a.xG), homeColor: homeColor, awayColor: awayColor)
            DualStatBar(title: "Shots", home: Double(h.shots), away: Double(a.shots),
                        homeText: "\(h.shots)", awayText: "\(a.shots)", homeColor: homeColor, awayColor: awayColor)
            DualStatBar(title: "On target", home: Double(h.shotsOnTarget), away: Double(a.shotsOnTarget),
                        homeText: "\(h.shotsOnTarget)", awayText: "\(a.shotsOnTarget)", homeColor: homeColor, awayColor: awayColor)
            DualStatBar(title: "Corners", home: Double(h.corners), away: Double(a.corners),
                        homeText: "\(h.corners)", awayText: "\(a.corners)", homeColor: homeColor, awayColor: awayColor)
            DualStatBar(title: "Fouls", home: Double(h.fouls), away: Double(a.fouls),
                        homeText: "\(h.fouls)", awayText: "\(a.fouls)", homeColor: homeColor, awayColor: awayColor)
        }
        .gfCard()
    }

    // MARK: - Elsewhere

    @ViewBuilder
    private func elsewhereCard(fixture: Fixture) -> some View {
        let others = otherResultsThisWeek(for: fixture)
        if !others.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Button {
                    withAnimation(.snappy) { showElsewhere.toggle() }
                } label: {
                    HStack {
                        Image(systemName: "list.bullet.rectangle.portrait").foregroundStyle(Color.accentColor)
                        Text("Elsewhere in Matchweek \(fixture.matchWeek)").font(.headline)
                        Spacer()
                        Text("\(others.count)").font(.subheadline.monospacedDigit()).foregroundStyle(.secondary)
                        Image(systemName: "chevron.down")
                            .rotationEffect(.degrees(showElsewhere ? 180 : 0))
                            .foregroundStyle(.secondary)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityHint(showElsewhere ? "Hides the other results" : "Shows the other results")
                if showElsewhere {
                    ForEach(others, id: \.fixture.id) { entry in
                        HStack {
                            Text(entry.homeName)
                                .font(.subheadline)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                            Text("\(entry.result.homeGoals) – \(entry.result.awayGoals)")
                                .font(.subheadline.weight(.bold).monospacedDigit())
                                .padding(.horizontal, 10)
                                .padding(.vertical, 3)
                                .background(Color(UIColor.tertiarySystemGroupedBackground), in: Capsule())
                            Text(entry.awayName)
                                .font(.subheadline)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
            }
            .gfCard()
        }
    }

    /// The league table around the user's club after a league match.
    @ViewBuilder
    private func tableCard(fixture: Fixture) -> some View {
        if let league = gameState.currentLeague, fixture.competition == league.name, let uid = gameState.userClubId {
            let table = gameState.currentLeagueStandings
            if let mine = table.firstIndex(where: { $0.clubId == uid }) {
                let lower = max(0, min(mine - 2, table.count - 5))
                let upper = min(table.count, lower + 5)
                VStack(spacing: 8) {
                    HStack {
                        Text("STANDINGS").font(.gfDisplay(18))
                        Spacer()
                        Text(league.name).font(.caption).foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("#").frame(width: 26, alignment: .leading)
                        Text("TEAM").frame(maxWidth: .infinity, alignment: .leading)
                        Text("P").frame(width: 28)
                        Text("GD").frame(width: 34)
                        Text("PTS").frame(width: 34)
                    }
                    .font(.gfLabel(12))
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
                    ForEach(lower..<upper, id: \.self) { i in
                        let row = table[i]
                        let club = gameState.club(withId: row.clubId)
                        HStack {
                            Text("\(i + 1)").frame(width: 26, alignment: .leading)
                            HStack(spacing: 6) {
                                if let club { CrestView(club: club, size: 18) }
                                Text(club?.name ?? "–").lineLimit(1)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            Text("\(row.played)").frame(width: 28)
                            Text(row.goalDifference > 0 ? "+\(row.goalDifference)" : "\(row.goalDifference)").frame(width: 34)
                            Text("\(row.points)").frame(width: 34).fontWeight(.heavy)
                        }
                        .font(.subheadline.monospacedDigit())
                        .fontWeight(row.clubId == uid ? .heavy : .regular)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 6)
                        .background(RoundedRectangle(cornerRadius: 8).fill(row.clubId == uid ? Color.white.opacity(0.14) : Color.clear))
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("\(i + 1). \(club?.name ?? ""), played \(row.played), goal difference \(row.goalDifference), \(row.points) points")
                    }
                }
                .gfCard()
            }
        }
    }

    private var actions: some View {
        VStack(spacing: 10) {
            Button {
                // Forget the finished match so the next match day selects the
                // next fixture, never this one again.
                gameState.closeFinishedMatch()
                gameState.currentScreen = .dashboard
            } label: {
                Text("Continue")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .foregroundStyle(.white)
            }
            Button {
                gameState.closeFinishedMatch()
                gameState.currentScreen = .matchHistory
            } label: {
                Label("Fixtures & Results", systemImage: "calendar")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(12)
            }
        }
        .padding(.top, 4)
    }

    // MARK: - Data

    private func otherResultsThisWeek(for fixture: Fixture) -> [(fixture: Fixture, homeName: String, awayName: String, result: MatchResult)] {
        gameState.season.fixtures(forWeek: fixture.matchWeek)
            .filter { $0.isPlayed && $0.id != fixture.id && $0.competition == fixture.competition }
            .compactMap { f in
                guard let result = f.result,
                      let home = gameState.club(withId: f.homeClubId),
                      let away = gameState.club(withId: f.awayClubId) else { return nil }
                return (f, home.name, away.name, result)
            }
    }

    /// The engine's Player of the Match, or the highest-rated player.
    private func potmPlayer(for res: MatchResult) -> (player: Player, clubName: String, rating: Double)? {
        guard let id = res.manOfTheMatch ?? res.playerRatings.max(by: { $0.value < $1.value })?.key,
              let lookup = gameState.player(withId: id) else { return nil }
        return (lookup.player, lookup.club?.name ?? "Unknown", res.playerRatings[id] ?? 0)
    }
}

/// Coloured icon for a timeline event. Colour is never the only signal: each
/// row also names the event in text and to VoiceOver.
struct EventBadge: View {
    let type: MatchEventType
    var body: some View {
        Group {
            switch type {
            case .yellowCard:
                RoundedRectangle(cornerRadius: 2).fill(Color(hex: "FACC15")).frame(width: 12, height: 16)
            case .redCard:
                RoundedRectangle(cornerRadius: 2).fill(Color(hex: "EF4444")).frame(width: 12, height: 16)
            case .secondYellow:
                ZStack {
                    RoundedRectangle(cornerRadius: 2).fill(Color(hex: "FACC15")).frame(width: 12, height: 16).offset(x: -3, y: -2)
                    RoundedRectangle(cornerRadius: 2).fill(Color(hex: "EF4444")).frame(width: 12, height: 16).offset(x: 3, y: 2)
                }
            case .goal, .penalty:
                Image(systemName: "soccerball").foregroundStyle(Color.white)
            case .ownGoal:
                Image(systemName: "soccerball").foregroundStyle(Color.lossRed)
            case .injury:
                Image(systemName: "cross.case.fill").foregroundStyle(Color.lossRed)
            case .substitution:
                Image(systemName: "arrow.left.arrow.right").foregroundStyle(Color.winGreen)
            default:
                Image(systemName: type.icon).foregroundStyle(.secondary)
            }
        }
        .frame(width: 24, height: 22)
        .accessibilityHidden(true)
    }
}

struct RatingPill: View {
    let rating: Double
    var body: some View {
        Text(String(format: "%.1f", rating))
            .font(.caption)
            .fontWeight(.heavy)
            .monospacedDigit()
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(rating >= 8 ? Color(hex: "1E9E62") : rating >= 7 ? Color.brand : rating >= 6 ? Color(hex: "B7791F") : Color(hex: "C53030"))
            .clipShape(Capsule())
    }
}

