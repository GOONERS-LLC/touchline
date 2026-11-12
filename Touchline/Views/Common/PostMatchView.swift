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

    public var body: some View {
        ScrollView {
            if let fixture = gameState.activeMatchFixture,
               let res = fixture.result,
               let home = gameState.club(withId: fixture.homeClubId),
               let away = gameState.club(withId: fixture.awayClubId) {
                VStack(spacing: 16) {
                    scoreboard(fixture: fixture, res: res, home: home, away: away)
                    if let potm = potmPlayer(for: res) { potmCard(potm, res: res) }
                    if !res.goalEvents.isEmpty { goalsCard(res: res, home: home, away: away) }
                    disciplineCard(res: res, home: home, away: away)
                    pressCard(fixture: fixture)
                    ratingsCard(res: res)
                    if res.events.contains(where: { $0.type == .goal || $0.type == .shotOnTarget || $0.type == .chance }) {
                        MomentumChartView(
                            result: res,
                            homeName: home.shortName,
                            awayName: away.shortName,
                            homeColor: Color(hex: home.primaryColor),
                            awayColor: Color(hex: away.primaryColor == home.primaryColor ? away.secondaryColor : away.primaryColor)
                        )
                        .gfCard()
                    }
                    statsCard(res: res, home: home, away: away)
                    tableCard(fixture: fixture)
                    elsewhereCard(fixture: fixture)
                    actions
                }
                .padding()
            } else {
                ContentUnavailableView("No Match Summary", systemImage: "sportscourt",
                                       description: Text("Play a match to see the full-time recap."))
            }
        }
        .stadiumBackground()
        .navigationTitle("Full Time")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            guard let fixture = gameState.activeMatchFixture,
                  let res = fixture.result,
                  let userClub = gameState.userClub else { return }
            switch res.outcomeLetter(for: userClub.id) {
            case "W": SoundManager.shared.play(.win, enabled: gameState.soundEnabled)
            case "L": SoundManager.shared.play(.loss, enabled: gameState.soundEnabled)
            default: SoundManager.shared.play(.draw, enabled: gameState.soundEnabled)
            }
        }
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
                        Text(event.isHomeTeam ? home.shortName : away.shortName)
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
