//
//  PostMatchFlow.swift
//  Touchline
//
//  The full-time journey after every match, one clear screen at a time:
//
//   1. Full time: the scoreboard with three tabs along the top.
//      Match Facts (goals mixed in order with cards, injuries and changes),
//      Ratings (both line-ups on the pitch with match ratings) and Stats.
//   2. Player of the Match: a screen of its own. Tap the player to open their
//      profile and make an offer.
//   3. Around the division: every result in your competition that week.
//

import SwiftUI

public struct PostMatchView: View {
    @Environment(GameState.self) private var gameState

    private enum Step { case fullTime, playerOfMatch, results }
    private enum Tab: String, CaseIterable, Identifiable {
        case facts = "Match Facts", ratings = "Ratings", stats = "Stats"
        var id: String { rawValue }
    }

    @State private var step: Step = .fullTime
    @State private var tab: Tab = .facts
    @State private var ratingsShowHome = true
    @State private var profilePlayerId: UUID?
    @State private var playedFeedback = false
    @AccessibilityFocusState private var headerFocused: Bool

    public init() {}

    public var body: some View {
        Group {
            if let fixture = gameState.activeMatchFixture,
               let res = fixture.result,
               let home = gameState.club(withId: fixture.homeClubId),
               let away = gameState.club(withId: fixture.awayClubId) {
                VStack(spacing: 0) {
                    switch step {
                    case .fullTime: fullTime(fixture: fixture, res: res, home: home, away: away)
                    case .playerOfMatch: playerOfMatch(res: res, home: home, away: away)
                    case .results: divisionResults(fixture: fixture)
                    }
                    continueBar
                }
                .animation(.easeInOut(duration: 0.25), value: step)
            } else {
                ContentUnavailableView("No Match Summary", systemImage: "sportscourt",
                                       description: Text("Play a match to see the full-time recap."))
            }
        }
        .background(Color.ink.ignoresSafeArea())
        .navigationTitle(stepTitle)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .sheet(item: Binding(get: { profilePlayerId.map(IdentifiedID.init) }, set: { profilePlayerId = $0?.id })) { item in
            NavigationStack {
                PlayerDetailView(playerId: item.id, onDone: { profilePlayerId = nil })
            }
            .environment(gameState)
            .touchlineChrome()
        }
        .onAppear(perform: celebrate)
        .onChange(of: step) { _, _ in headerFocused = true }
    }

    private var stepTitle: String {
        switch step {
        case .fullTime: return "Full Time"
        case .playerOfMatch: return "Player of the Match"
        case .results: return "Around the Division"
        }
    }

    // MARK: - Continue

    private var continueBar: some View {
        VStack(spacing: 0) {
            Divider().overlay(Color.hairline)
            Button {
                Haptics.tap()
                switch step {
                case .fullTime: step = .playerOfMatch
                case .playerOfMatch: step = .results
                case .results: gameState.currentScreen = .dashboard
                }
            } label: {
                HStack {
                    Text(step == .results ? "Back to Home" : "Continue")
                        .font(.headline)
                    Spacer()
                    Image(systemName: "arrow.right").font(.headline)
                }
            }
            .buttonStyle(PrimaryActionStyle())
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .accessibilityHint(step == .fullTime ? "Shows the player of the match"
                               : step == .playerOfMatch ? "Shows this week's results in your division"
                               : "Returns to your club's home screen")
        }
        .background(Color.ink)
    }

    // MARK: - Step 1: Full Time

    private func fullTime(fixture: Fixture, res: MatchResult, home: Club, away: Club) -> some View {
        VStack(spacing: 0) {
            scoreboard(res: res, home: home, away: away)
                .padding(.horizontal, 16)
                .padding(.top, 8)
            tabBar
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            ScrollView {
                Group {
                    switch tab {
                    case .facts: matchFacts(res: res, home: home, away: away)
                    case .ratings: ratings(res: res, home: home, away: away)
                    case .stats: stats(res: res, home: home, away: away)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
        }
    }

    private func scoreboard(res: MatchResult, home: Club, away: Club) -> some View {
        VStack(spacing: 10) {
            Text("FULL TIME · \(res.competition.uppercased())")
                .font(.caption2)
                .fontWeight(.heavy)
                .tracking(1.2)
                .foregroundStyle(Color.highlight)
            HStack(alignment: .center, spacing: 8) {
                VStack(spacing: 6) {
                    CrestView(club: home, size: 48)
                    Text(home.name).font(.footnote).fontWeight(.semibold).multilineTextAlignment(.center).lineLimit(2)
                }
                .frame(maxWidth: .infinity)
                Text("\(res.homeGoals)  -  \(res.awayGoals)")
                    .font(.system(size: 40, weight: .black, design: .rounded))
                    .monospacedDigit()
                    .fixedSize()
                VStack(spacing: 6) {
                    CrestView(club: away, size: 48)
                    Text(away.name).font(.footnote).fontWeight(.semibold).multilineTextAlignment(.center).lineLimit(2)
                }
                .frame(maxWidth: .infinity)
            }
            if res.attendance > 0 {
                Text("Attendance \(res.attendance.formatted()) at \(home.stadium)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(
            ZStack {
                Color.surface
                LinearGradient(colors: [Color(hex: home.primaryColor).opacity(0.28), .clear, Color(hex: away.primaryColor).opacity(0.28)],
                               startPoint: .leading, endPoint: .trailing)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(Color.hairline, lineWidth: 1))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Full time. \(home.name) \(res.homeGoals), \(away.name) \(res.awayGoals). \(res.competition).")
        .accessibilityAddTraits(.isHeader)
        .accessibilityFocused($headerFocused)
    }

    private var tabBar: some View {
        HStack(spacing: 6) {
            ForEach(Tab.allCases) { item in
                Button {
                    Haptics.selection()
                    withAnimation(.easeInOut(duration: 0.2)) { tab = item }
                } label: {
                    Text(item.rawValue)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .foregroundStyle(tab == item ? Color.white : Color.secondary)
                        .background(tab == item ? Color.brand : Color.clear)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(item.rawValue) tab")
                .accessibilityAddTraits(tab == item ? [.isSelected, .isButton] : .isButton)
            }
        }
        .padding(4)
        .background(Color.surface)
        .clipShape(Capsule())
        .overlay(Capsule().stroke(Color.hairline, lineWidth: 1))
    }

    // MARK: Match Facts

    private func matchFacts(res: MatchResult, home: Club, away: Club) -> some View {
        let timeline = res.events.filter { $0.type.isTimelineEvent || $0.type == .halfTime }
        var runningHome = 0, runningAway = 0
        let rows: [(MatchEvent, String?)] = timeline.map { ev in
            switch ev.type {
            case .goal, .penalty:
                if ev.isHomeTeam { runningHome += 1 } else { runningAway += 1 }
                return (ev, "\(runningHome) - \(runningAway)")
            case .ownGoal:
                // Own goals are recorded against the side that conceded.
                if ev.isHomeTeam { runningAway += 1 } else { runningHome += 1 }
                return (ev, "\(runningHome) - \(runningAway)")
            default:
                return (ev, nil)
            }
        }
        return VStack(spacing: 0) {
            if rows.allSatisfy({ $0.0.type == .halfTime }) {
                Text("A quiet game: no goals, cards or changes.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 24)
            }
            ForEach(rows, id: \.0.id) { ev, score in
                if ev.type == .halfTime {
                    HStack {
                        Rectangle().fill(Color.hairline).frame(height: 1)
                        Text("Half-time").font(.caption).fontWeight(.bold).foregroundStyle(.secondary)
                        Rectangle().fill(Color.hairline).frame(height: 1)
                    }
                    .padding(.vertical, 10)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Half-time")
                } else {
                    factRow(ev, score: score, home: home, away: away)
                }
            }
        }
        .padding(14)
        .background(Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func factRow(_ ev: MatchEvent, score: String?, home: Club, away: Club) -> some View {
        let player = ev.playerId.flatMap { gameState.player(withId: $0)?.player }
        let assist = ev.assistPlayerId.flatMap { gameState.player(withId: $0)?.player }
        let club = ev.isHomeTeam ? home : away
        let name = player?.fullName ?? ev.shortText
        let detail: String? = {
            switch ev.type {
            case .goal: return assist.map { "Assist: \($0.fullName)" }
            case .penalty: return "Penalty"
            case .ownGoal: return "Own goal"
            case .substitution: return ev.shortText.components(separatedBy: ": ").last
            default: return nil
            }
        }()
        let badge = EventBadge(type: ev.type)

        return HStack(alignment: .top, spacing: 10) {
            Text("\(ev.minute)'")
                .font(.subheadline)
                .fontWeight(.bold)
                .monospacedDigit()
                .foregroundStyle(.secondary)
                .frame(width: 36, alignment: .trailing)
            badge
            VStack(alignment: .leading, spacing: 2) {
                Text(ev.type == .substitution ? "Substitution" : name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                if let detail {
                    Text(detail).font(.caption).foregroundStyle(.secondary)
                }
                Text(club.name).font(.caption2).foregroundStyle(.tertiary)
            }
            Spacer(minLength: 4)
            if let score {
                Text(score)
                    .font(.subheadline)
                    .fontWeight(.heavy)
                    .monospacedDigit()
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.surfaceRaised)
                    .clipShape(Capsule())
            }
        }
        .padding(.vertical, 8)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(ev.minute) minutes. \(ev.type.spokenName). \(ev.type == .substitution ? (detail ?? "") : name), \(club.name).\(detail != nil && ev.type != .substitution ? " \(detail!)." : "")\(score.map { " Score \($0.replacingOccurrences(of: " - ", with: " to "))." } ?? "")")
    }

    // MARK: Ratings

    private func ratings(res: MatchResult, home: Club, away: Club) -> some View {
        let club = ratingsShowHome ? home : away
        let lineupIds = (ratingsShowHome ? res.homeLineup : res.awayLineup) ?? club.tactics.startingXI
        let formation = (ratingsShowHome ? res.homeFormation : res.awayFormation) ?? club.tactics.formation
        let lineup: [Player] = lineupIds.compactMap { id in gameState.player(withId: id)?.player }
        let starters = Set(lineupIds)
        let subs: [(Player, Double)] = res.playerRatings
            .compactMap { id, rating -> (Player, Double)? in
                guard !starters.contains(id), let lookup = gameState.player(withId: id),
                      lookup.club?.id == club.id else { return nil }
                return (lookup.player, rating)
            }
            .sorted { $0.1 > $1.1 }

        return VStack(spacing: 14) {
            Picker("Team", selection: $ratingsShowHome) {
                Text(home.name).tag(true)
                Text(away.name).tag(false)
            }
            .pickerStyle(.segmented)
            .onChange(of: ratingsShowHome) { _, _ in Haptics.selection() }

            if lineup.count >= 11 {
                FormationPitchView(
                    formation: formation,
                    players: lineup,
                    selectedPlayerId: res.manOfTheMatch,
                    ratings: res.playerRatings,
                    tapHint: "Double tap to open the player's profile",
                    onSelect: { profilePlayerId = $0.id }
                )
            } else {
                Text("Line-up not recorded for this match.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if !subs.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    SectionEyebrow("Came off the bench")
                    ForEach(subs, id: \.0.id) { player, rating in
                        Button { profilePlayerId = player.id } label: {
                            HStack {
                                Text(player.fullName).font(.subheadline)
                                Spacer()
                                RatingPill(rating: rating)
                            }
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(player.fullName), substitute, match rating \(String(format: "%.1f", rating))")
                    }
                }
                .footballCardStyle()
            }
        }
    }

    // MARK: Stats

    private func stats(res: MatchResult, home: Club, away: Club) -> some View {
        let h = res.homeStats, a = res.awayStats
        let rows: [(String, Double, Double, String, String)] = [
            ("Possession", h.possession, a.possession, "\(Int(h.possession))%", "\(Int(a.possession))%"),
            ("Expected goals", h.xG, a.xG, String(format: "%.2f", h.xG), String(format: "%.2f", a.xG)),
            ("Shots", Double(h.shots), Double(a.shots), "\(h.shots)", "\(a.shots)"),
            ("Shots on target", Double(h.shotsOnTarget), Double(a.shotsOnTarget), "\(h.shotsOnTarget)", "\(a.shotsOnTarget)"),
            ("Saves", Double(h.saves), Double(a.saves), "\(h.saves)", "\(a.saves)"),
            ("Corners", Double(h.corners), Double(a.corners), "\(h.corners)", "\(a.corners)"),
            ("Fouls", Double(h.fouls), Double(a.fouls), "\(h.fouls)", "\(a.fouls)"),
            ("Offsides", Double(h.offsides), Double(a.offsides), "\(h.offsides)", "\(a.offsides)"),
            ("Tackles won", Double(h.tacklesWon), Double(a.tacklesWon), "\(h.tacklesWon)", "\(a.tacklesWon)"),
            ("Pass accuracy", h.passAccuracy, a.passAccuracy, "\(Int(h.passAccuracy))%", "\(Int(a.passAccuracy))%"),
        ]
        return VStack(spacing: 16) {
            HStack {
                Text(home.name).font(.caption).fontWeight(.bold).lineLimit(1)
                Spacer()
                Text(away.name).font(.caption).fontWeight(.bold).lineLimit(1)
            }
            .foregroundStyle(.secondary)
            .accessibilityHidden(true)
            ForEach(rows, id: \.0) { row in
                StatComparisonRow(title: row.0, home: row.3, away: row.4, homeValue: row.1, awayValue: row.2,
                                  homeColor: Color(hex: home.primaryColor), awayColor: Color(hex: away.primaryColor),
                                  homeName: home.name, awayName: away.name)
            }
        }
        .footballCardStyle()
    }

    // MARK: - Step 2: Player of the Match

    private func playerOfMatch(res: MatchResult, home: Club, away: Club) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                if let potm = potmPlayer(for: res) {
                    let goals = res.events.filter { ($0.type == .goal || $0.type == .penalty) && $0.playerId == potm.player.id }.count
                    let assists = res.events.filter { $0.type == .goal && $0.assistPlayerId == potm.player.id }.count
                    let isUserPlayer = potm.club?.id == gameState.userClub?.id

                    VStack(spacing: 6) {
                        Image(systemName: "star.circle.fill")
                            .font(.system(size: 34))
                            .foregroundStyle(Color.highlight)
                            .accessibilityHidden(true)
                        Text("Player of the Match")
                            .font(.title2)
                            .fontWeight(.black)
                            .accessibilityAddTraits(.isHeader)
                            .accessibilityFocused($headerFocused)
                    }
                    .padding(.top, 12)

                    Button {
                        Haptics.tap()
                        profilePlayerId = potm.player.id
                    } label: {
                        VStack(spacing: 14) {
                            FaceView(player: potm.player, size: 120, style: .full)
                                .frame(width: 120, height: 120)
                                .padding(6)
                                .background(Circle().fill(Color.surfaceRaised))
                                .overlay(Circle().stroke(Color.highlight, lineWidth: 3))
                            Text(potm.player.fullName)
                                .font(.title2)
                                .fontWeight(.bold)
                                .multilineTextAlignment(.center)
                            Text("\(potm.player.primaryPosition.displayName) · \(potm.club?.name ?? "Free agent") · Age \(potm.player.age)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                            HStack(spacing: 12) {
                                statTile(String(format: "%.1f", potm.rating), "Rating")
                                statTile("\(goals)", goals == 1 ? "Goal" : "Goals")
                                statTile("\(assists)", assists == 1 ? "Assist" : "Assists")
                                statTile("\(potm.player.overall)", "Overall")
                            }
                            Label(isUserPlayer ? "View profile" : "View profile and make an offer",
                                  systemImage: isUserPlayer ? "person.text.rectangle" : "signature")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(Color.highlight)
                        }
                        .padding(20)
                        .frame(maxWidth: .infinity)
                        .background(
                            ZStack {
                                Color.surface
                                RadialGradient(colors: [Color.highlight.opacity(0.18), .clear], center: .top, startRadius: 10, endRadius: 260)
                            }
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 26, style: .continuous).stroke(Color.highlight.opacity(0.5), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(potm.player.fullName), \(potm.player.primaryPosition.displayName) for \(potm.club?.name ?? "no club"), age \(potm.player.age). Match rating \(String(format: "%.1f", potm.rating)). \(goals) \(goals == 1 ? "goal" : "goals"), \(assists) \(assists == 1 ? "assist" : "assists"). Overall \(potm.player.overall).")
                    .accessibilityHint(isUserPlayer ? "Opens the player's profile" : "Opens the player's profile, where you can make a transfer offer")
                    .accessibilityAddTraits(.isButton)
                } else {
                    Text("No player of the match was recorded.")
                        .foregroundStyle(.secondary)
                        .padding(.top, 40)
                }
            }
            .padding(16)
        }
    }

    private func statTile(_ value: String, _ label: String) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.headline).fontWeight(.heavy).monospacedDigit()
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color.surfaceRaised)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func potmPlayer(for res: MatchResult) -> (player: Player, club: Club?, rating: Double)? {
        var playerId = res.manOfTheMatch
        if playerId == nil { playerId = res.playerRatings.max(by: { $0.value < $1.value })?.key }
        guard let id = playerId, let lookup = gameState.player(withId: id) else { return nil }
        return (lookup.player, lookup.club, res.playerRatings[id] ?? 0)
    }

    // MARK: - Step 3: Around the Division

    private func divisionResults(fixture: Fixture) -> some View {
        let week = gameState.season.fixtures(forWeek: fixture.matchWeek)
            .filter { $0.isPlayed && $0.competition == fixture.competition }
            .sorted { a, b in a.id == fixture.id ? true : (b.id == fixture.id ? false : a.date < b.date) }
        return ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(fixture.competition)
                        .font(.title2)
                        .fontWeight(.black)
                        .accessibilityAddTraits(.isHeader)
                        .accessibilityFocused($headerFocused)
                    Text("Matchweek \(fixture.matchWeek) results")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.bottom, 6)
                ForEach(week, id: \.id) { f in
                    if let r = f.result,
                       let h = gameState.club(withId: f.homeClubId),
                       let a = gameState.club(withId: f.awayClubId) {
                        resultRow(home: h, away: a, result: r, isUser: f.id == fixture.id)
                    }
                }
            }
            .padding(16)
        }
    }

    private func resultRow(home: Club, away: Club, result: MatchResult, isUser: Bool) -> some View {
        HStack(spacing: 10) {
            HStack(spacing: 8) {
                Text(home.name)
                    .font(.subheadline)
                    .fontWeight(result.homeGoals > result.awayGoals ? .bold : .regular)
                    .lineLimit(2)
                    .multilineTextAlignment(.trailing)
                CrestView(club: home, size: 24)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            Text("\(result.homeGoals) - \(result.awayGoals)")
                .font(.headline)
                .fontWeight(.heavy)
                .monospacedDigit()
                .frame(minWidth: 56)
                .padding(.vertical, 4)
                .background(isUser ? Color.brand : Color.surfaceRaised)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            HStack(spacing: 8) {
                CrestView(club: away, size: 24)
                Text(away.name)
                    .font(.subheadline)
                    .fontWeight(result.awayGoals > result.homeGoals ? .bold : .regular)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 10)
        .background(isUser ? Color.brand.opacity(0.14) : Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(isUser ? "Your match. " : "")\(home.name) \(result.homeGoals), \(away.name) \(result.awayGoals)")
    }

    // MARK: - Feedback

    private func celebrate() {
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
        headerFocused = true
    }
}

/// Lets an optional UUID drive `.sheet(item:)`.
private struct IdentifiedID: Identifiable { let id: UUID }

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

/// Two-sided stat with a proportional bar.
public struct StatComparisonRow: View {
    public let title: String
    public let home: String
    public let away: String
    public var homeValue: Double = 0
    public var awayValue: Double = 0
    public var homeColor: Color = .brand
    public var awayColor: Color = .highlight
    public var homeName: String = "Home"
    public var awayName: String = "Away"

    public init(title: String, home: String, away: String, homeValue: Double = 0, awayValue: Double = 0,
                homeColor: Color = .brand, awayColor: Color = .highlight, homeName: String = "Home", awayName: String = "Away") {
        self.title = title; self.home = home; self.away = away
        self.homeValue = homeValue; self.awayValue = awayValue
        self.homeColor = homeColor; self.awayColor = awayColor
        self.homeName = homeName; self.awayName = awayName
    }

    public var body: some View {
        VStack(spacing: 6) {
            HStack {
                Text(home).fontWeight(.bold).monospacedDigit()
                Spacer()
                Text(title).font(.caption).foregroundStyle(.secondary)
                Spacer()
                Text(away).fontWeight(.bold).monospacedDigit()
            }
            .font(.subheadline)
            let total = max(homeValue + awayValue, 0.0001)
            GeometryReader { geo in
                HStack(spacing: 3) {
                    Capsule().fill(barColor(homeColor)).frame(width: max(4, geo.size.width * homeValue / total))
                    Capsule().fill(barColor(awayColor).opacity(0.85))
                }
            }
            .frame(height: 6)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title): \(homeName) \(home), \(awayName) \(away)")
    }

    /// Keeps very dark or white club colours visible on the dark surface.
    private func barColor(_ c: Color) -> Color {
        let ui = UIColor(c)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        ui.getRed(&r, green: &g, blue: &b, alpha: &a)
        let lum = 0.2126 * r + 0.7152 * g + 0.0722 * b
        return lum < 0.12 ? Color(hex: "8A94AD") : c
    }
}
