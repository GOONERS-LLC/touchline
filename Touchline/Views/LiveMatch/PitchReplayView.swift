//
//  PitchReplayView.swift
//  Touchline
//
//  Created for Touchline - iOS Football Manager Game.
//  Two-dimensional position-cam match replay. Renders 22 interpolated player dots
//  and the ball on a top-down pitch, driven by a minute ticker, and announces major
//  events for VoiceOver. Animation only; match outcome is decided by MatchEngine.
//

import SwiftUI
import Accessibility

// MARK: - Pitch Replay View

public struct PitchReplayView: View {
    public let fixture: Fixture
    public let homeClub: Club
    public let awayClub: Club
    public let minute: Int
    
    public var body: some View {
        GeometryReader { geo in
            let size = geo.size
            Canvas { context, canvasSize in
                drawPitch(in: &context, size: canvasSize)
                drawPlayers(in: &context, size: canvasSize)
                drawBall(in: &context, size: canvasSize)
            }
            .frame(width: size.width, height: size.height)
            .background(Color.pitchGrassDark)
        }
        .aspectRatio(68.0 / 105.0, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.25), lineWidth: 2)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Match pitch replay, minute \(minute). Visual pitch only; use the live commentary list below for each match event.")
    }
    
    // MARK: - Pitch Drawing
    
    private func drawPitch(in context: inout GraphicsContext, size: CGSize) {
        let w = size.width
        let h = size.height
        
        // Mowing stripes
        let stripeCount = 8
        for i in 0..<stripeCount {
            let rect = CGRect(
                x: 0,
                y: h * CGFloat(i) / CGFloat(stripeCount),
                width: w,
                height: h / CGFloat(stripeCount)
            )
            let color = i % 2 == 0 ? Color.pitchGrassLight : Color.pitchGrassDark
            context.fill(Path(rect), with: .color(color))
        }
        
        // Outer boundary
        let lineColor = Color.white.opacity(0.7)
        let lineWidth = max(1.5, w * 0.005)
        let inset = w * 0.03
        let field = CGRect(x: inset, y: inset, width: w - inset * 2, height: h - inset * 2)
        context.stroke(Path(field), with: .color(lineColor), lineWidth: lineWidth)
        
        // Halfway line
        var halfway = Path()
        halfway.move(to: CGPoint(x: field.minX, y: field.midY))
        halfway.addLine(to: CGPoint(x: field.maxX, y: field.midY))
        context.stroke(halfway, with: .color(lineColor), lineWidth: lineWidth)
        
        // Centre circle
        let circleRadius = field.width * 0.13
        context.stroke(
            Path(ellipseIn: CGRect(
                x: field.midX - circleRadius,
                y: field.midY - circleRadius,
                width: circleRadius * 2,
                height: circleRadius * 2
            )),
            with: .color(lineColor),
            lineWidth: lineWidth
        )
        
        // Penalty boxes (top & bottom)
        let boxW = field.width * 0.55
        let boxH = field.height * 0.14
        let topBox = CGRect(x: field.midX - boxW / 2, y: field.minY, width: boxW, height: boxH)
        let bottomBox = CGRect(x: field.midX - boxW / 2, y: field.maxY - boxH, width: boxW, height: boxH)
        context.stroke(Path(topBox), with: .color(lineColor), lineWidth: lineWidth)
        context.stroke(Path(bottomBox), with: .color(lineColor), lineWidth: lineWidth)
        
        // Goal boxes
        let goalW = field.width * 0.28
        let goalH = boxH * 0.42
        let topGoal = CGRect(x: field.midX - goalW / 2, y: field.minY, width: goalW, height: goalH)
        let bottomGoal = CGRect(x: field.midX - goalW / 2, y: field.maxY - goalH, width: goalW, height: goalH)
        context.stroke(Path(topGoal), with: .color(lineColor), lineWidth: lineWidth)
        context.stroke(Path(bottomGoal), with: .color(lineColor), lineWidth: lineWidth)
    }
    
    // MARK: - Player Positioning
    
    /// Returns a normalised (0...1) attacking position for a player index at the given minute.
    /// The shape drifts toward the attacking goal and wobbles deterministically over time.
    private func position(for index: Int, isHome: Bool, minute: Int) -> CGPoint
    {
        // Formation slot layout (x: 0..1 across width, y: 0..1 up the pitch from own goal).
        let homeSlots: [CGPoint] = [
            CGPoint(x: 0.50, y: 0.06), // GK
            CGPoint(x: 0.14, y: 0.24), CGPoint(x: 0.38, y: 0.22), CGPoint(x: 0.62, y: 0.22), CGPoint(x: 0.86, y: 0.24),
            CGPoint(x: 0.16, y: 0.44), CGPoint(x: 0.38, y: 0.46), CGPoint(x: 0.62, y: 0.46), CGPoint(x: 0.84, y: 0.44),
            CGPoint(x: 0.40, y: 0.68), CGPoint(x: 0.60, y: 0.68)
        ]
        let slot = homeSlots[min(index, homeSlots.count - 1)]
        
        // Time-based deterministic wobble so the picture breathes as minutes pass.
        let phase = Double(minute) * 0.35 + Double(index) * 1.7
        let wobbleX = sin(phase) * 0.045
        let wobbleY = cos(phase * 0.8) * 0.035
        
        // A gentle push toward the opponent goal grows through the match.
        let push = min(0.12, Double(minute) / 90.0 * 0.12) * (slot.y > 0.3 ? 1 : 0)
        
        var nx = slot.x + wobbleX
        var ny = slot.y + wobbleY + push
        
        // Flip vertically for the away team (attacking the other way).
        if !isHome {
            ny = 1.0 - ny
            nx = 1.0 - nx
        }
        
        nx = min(0.98, max(0.02, nx))
        ny = min(0.98, max(0.02, ny))
        return CGPoint(x: nx, y: ny)
    }
    
    private func drawPlayers(in context: inout GraphicsContext, size: CGSize) {
        let w = size.width
        let h = size.height
        let radius = max(4, w * 0.018)
        let homeColor = Color(hex: homeClub.primaryColor)
        let awayColor = Color(hex: awayClub.primaryColor)
        
        for index in 0..<11 {
            let homePos = position(for: index, isHome: true, minute: minute)
            let homeCenter = CGPoint(x: homePos.x * w, y: homePos.y * h)
            let homeRect = CGRect(
                x: homeCenter.x - radius,
                y: homeCenter.y - radius,
                width: radius * 2,
                height: radius * 2
            )
            context.fill(Path(ellipseIn: homeRect), with: .color(homeColor))
            context.stroke(Path(ellipseIn: homeRect), with: .color(.white.opacity(0.85)), lineWidth: 1.2)
            
            let awayPos = position(for: index, isHome: false, minute: minute)
            let awayCenter = CGPoint(x: awayPos.x * w, y: awayPos.y * h)
            let awayRect = CGRect(
                x: awayCenter.x - radius,
                y: awayCenter.y - radius,
                width: radius * 2,
                height: radius * 2
            )
            context.fill(Path(ellipseIn: awayRect), with: .color(awayColor))
            context.stroke(Path(ellipseIn: awayRect), with: .color(.black.opacity(0.6)), lineWidth: 1.2)
        }
    }
    
    private func drawBall(in context: inout GraphicsContext, size: CGSize) {
        let w = size.width
        let h = size.height
        let radius = max(2.5, w * 0.010)
        
        // The ball roams around the middle third, moving deterministically with the clock.
        let phase = Double(minute) * 0.9
        let bx = 0.5 + sin(phase) * 0.28
        let by = 0.5 + cos(phase * 1.3) * 0.33
        let center = CGPoint(x: bx * w, y: by * h)
        let rect = CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
        
        context.fill(Path(ellipseIn: rect), with: .color(.white))
        context.stroke(Path(ellipseIn: rect), with: .color(.black.opacity(0.7)), lineWidth: 1)
    }
}

// MARK: - Live Match Screen

public struct LiveMatchView: View {
    @Environment(GameState.self) private var gameState
    
    @State private var minute = 0
    @State private var isPlaying = false
    @State private var didSimulate = false
    @State private var ticker: Timer?
    @State private var goalFlash: MatchEvent?
    @State private var pane: Pane = .pitch
    /// Lines waiting for VoiceOver. While non-empty (and "Wait for VoiceOver"
    /// is on) the match clock holds, so no commentary is talked over.
    @State private var speechQueue: [String] = []
    @State private var isSpeaking = false
    @State private var speechWatchdog: DispatchWorkItem?

    enum Pane: String, CaseIterable { case pitch = "Pitch", commentary = "Commentary", stats = "Stats", lineups = "Lineups" }
    
    private var fixture: Fixture? { gameState.activeMatchFixture }
    /// The full result once the match is over; the first half while it is
    /// stopped at the break.
    private var result: MatchResult? {
        if let played = fixture?.result { return played }
        if let session = gameState.liveMatch, session.fixtureId == fixture?.id { return session.firstHalf }
        return nil
    }
    private var secondHalfPending: Bool { fixture?.isPlayed == false }
    @State private var atHalfTime = false
    @State private var editingLineup = false
    @State private var editingTactics = false

    /// The last minute the replay runs to. The engine plays stoppage time (and
    /// extra time in knockouts), so capping the replay at 90' used to hide late
    /// goals from the live scoreboard and VoiceOver announcements.
    private var finalMinute: Int {
        if secondHalfPending { return 45 }
        return max(90, result?.events.map { $0.minute }.max() ?? 90)
    }
    
    public var body: some View {
        VStack(spacing: 14) {
            if let fixture = fixture,
               let home = gameState.club(withId: fixture.homeClubId),
               let away = gameState.club(withId: fixture.awayClubId) {
                
                scoreboard(home: home, away: away)

                GFTabs(selection: $pane, compact: true)
                    .padding(.horizontal)

                Group {
                    switch pane {
                    case .pitch:
                        PitchReplayView(
                            fixture: fixture,
                            homeClub: home,
                            awayClub: away,
                            minute: minute
                        )
                        .padding(.horizontal, 12)
                        timelineFeed(home: home, away: away)
                    case .commentary:
                        commentaryCards(home: home, away: away)
                    case .stats:
                        liveStats(home: home, away: away)
                    case .lineups:
                        lineups(home: home, away: away)
                    }
                }
                .frame(maxHeight: .infinity, alignment: .top)
                .overlay {
                    if let goal = goalFlash {
                        goalBanner(goal, club: goal.isHomeTeam ? home : away)
                            .transition(.scale(scale: 0.6).combined(with: .opacity))
                    }
                }
                .overlay {
                    if atHalfTime { halfTimePanel(home: home, away: away) }
                }

                controls(fixture: fixture)
            } else {
                ContentUnavailableView("No Active Match", systemImage: "sportscourt")
            }
        }
        .padding(.vertical)
        .stadiumBackground()
        .navigationTitle(gameState.gameMode == .createClub ? "Watching" : "Live Match")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: prepare)
        .onDisappear {
            stopTicker()
            speechWatchdog?.cancel()
            CrowdAtmosphere.shared.stopMatch()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIAccessibility.announcementDidFinishNotification)) { _ in
            speakNext()
        }
        .sheet(isPresented: $editingLineup) {
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("You have \(gameState.liveSubsRemaining) substitution\(gameState.liveSubsRemaining == 1 ? "" : "s") left. Bring players on from the bench by swapping them with a starter; starters can also swap positions. Players already taken off cannot return.",
                              systemImage: "info.circle")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        LineupEditorView()
                    }
                    .padding()
                }
                .stadiumBackground()
                .navigationTitle("Half-Time Changes")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { editingLineup = false } } }
            }
        }
        .sheet(isPresented: $editingTactics) {
            NavigationStack {
                TacticsView()
                    .stadiumBackground()
                    .navigationTitle("Tactics")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { editingTactics = false } } }
            }
        }
    }

    /// The break: the score, and the chance to change things.
    private func halfTimePanel(home: Club, away: Club) -> some View {
        let manages = gameState.gameMode == .manageClub
        return VStack(spacing: 14) {
            Text("HALF-TIME").font(.gfDisplay(22))
            Text("\(home.name) \(currentHomeGoals) - \(currentAwayGoals) \(away.name)").font(.gfDisplay(22))
            if manages {
                Text("Substitutions left: \(gameState.liveSubsRemaining)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                HStack(spacing: 10) {
                    Button("Lineup") { editingLineup = true }
                        .buttonStyle(.gfOutline)
                        .accessibilityHint("Make substitutions and change positions")
                    Button("Tactics") { editingTactics = true }
                        .buttonStyle(.gfOutline)
                }
            }
            Button("Start Second Half") { startSecondHalf() }
                .buttonStyle(.gfPrimary)
                .padding(.horizontal, 20)
        }
        .padding(22)
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(Color.gfNight.opacity(0.96)))
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(Color.white.opacity(0.5), lineWidth: 1.5))
        .padding(.horizontal, 20)
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isModal)
    }

    /// Plays the second half with whatever was changed at the break.
    private func startSecondHalf() {
        guard let fixture else { return }
        atHalfTime = false
        gameState.simulateFixture(id: fixture.id)
        startTicker()
    }
    
    // MARK: - Subviews
    
    private func scoreboard(home: Club, away: Club) -> some View {
        VStack(spacing: 8) {
            Text(fixture.flatMap { f in f.cupRound.map { "\(f.competition) • \($0)" } } ?? fixture?.competition ?? "Match")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.85))
            HStack {
                VStack(spacing: 4) {
                    CrestView(club: home, size: 34)
                    Text(home.name.uppercased()).font(.gfLabel(14)).lineLimit(1).minimumScaleFactor(0.6)
                }
                .frame(maxWidth: .infinity)
                VStack(spacing: 2) {
                    Text(scoreText)
                        .font(.gfDisplay(32))
                        .monospacedDigit()
                        .contentTransition(.numericText())
                        .animation(.snappy, value: scoreText)
                    Text(minute >= finalMinute ? "FT" : minute == 45 && !isPlaying ? "HT" : "\(minute)'")
                        .font(.caption.weight(.heavy).monospacedDigit())
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.black.opacity(0.25), in: Capsule())
                }
                VStack(spacing: 4) {
                    CrestView(club: away, size: 34)
                    Text(away.name.uppercased()).font(.gfLabel(14)).lineLimit(1).minimumScaleFactor(0.6)
                }
                .frame(maxWidth: .infinity)
            }
            .foregroundStyle(.white)
            if let attendance = result?.attendance, attendance > 0 {
                Text("\(home.stadium) (\(attendance.formatted()) fans)")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
            }
            ProgressView(value: Double(minute), total: Double(finalMinute))
                .tint(Color.gfMint)
        }
        .padding(.horizontal, 14)
        .padding(.horizontal)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(home.name) \(currentHomeGoals), \(away.name) \(currentAwayGoals), minute \(minute)")
    }

    private func goalBanner(_ goal: MatchEvent, club: Club) -> some View {
        let scorer = goal.playerId.flatMap { gameState.player(withId: $0)?.player.fullName }
        let assist = goal.assistPlayerId.flatMap { gameState.player(withId: $0)?.player.fullName }
        return VStack(spacing: 6) {
            Text("GOAL!")
                .font(.system(size: 32, weight: .black, design: .rounded))
                .foregroundStyle(.white)
            HStack(spacing: 6) {
                CrestView(club: club, size: 22)
                Text(scorer ?? club.name).font(.headline).foregroundStyle(.white)
            }
            if let assist {
                Text("Assist: \(assist)").font(.caption.weight(.semibold)).foregroundStyle(.white.opacity(0.85))
            }
        }
        .padding(.horizontal, 26)
        .padding(.vertical, 16)
        .background(Color(hex: club.primaryColor).opacity(0.92), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: .black.opacity(0.35), radius: 12)
    }
    
    private func timelineFeed(home: Club, away: Club) -> some View {
        List {
            let visible = (result?.events ?? []).filter { $0.minute <= minute }
            if visible.isEmpty {
                Text(minute == 0 ? "Kick-off imminent..." : "No key events yet.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(visible.reversed()) { ev in
                    let isGoal = ev.type == .goal || ev.type == .penalty || ev.type == .ownGoal
                    let club = ev.isHomeTeam ? home : away
                    HStack(alignment: .top, spacing: 10) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color(hex: club.primaryColor))
                            .frame(width: 4)
                        Text("\(ev.minute)'")
                            .font(.caption.weight(.heavy).monospacedDigit())
                            .frame(width: 30, alignment: .leading)
                        Image(systemName: ev.type.icon)
                            .foregroundStyle(isGoal ? Color.winGreen : ev.type == .redCard || ev.type == .secondYellow ? .red : ev.type == .yellowCard ? .yellow : .secondary)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(ev.shortText)
                                .font(.subheadline.weight(isGoal ? .bold : .regular))
                            if isGoal || ev.type == .chanceMissed || ev.type == .woodwork {
                                Text(ev.detailText)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(3)
                            }
                        }
                    }
                    .listRowBackground(isGoal ? Color.winGreen.opacity(0.1) : Color.clear)
                    .accessibleMatchEvent(ev)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }
    
    private func controls(fixture: Fixture) -> some View {
        HStack(spacing: 10) {
            Menu {
                ForEach(MatchSettings.Speed.allCases) { speed in
                    Button(speed.displayName) {
                        gameState.matchSettings.speed = speed
                        if isPlaying { startTicker() }
                    }
                }
            } label: {
                Image(systemName: "gauge.with.dots.needle.67percent")
                    .font(.title3.weight(.bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .foregroundStyle(.white)
                    .background(Capsule().fill(Color.gfNavy.opacity(0.7)))
                    .overlay(Capsule().stroke(Color.white.opacity(0.75), lineWidth: 1.5))
            }
            .accessibilityLabel("Replay speed, \(gameState.matchSettings.speed.displayName)")

            Button {
                isPlaying ? stopTicker() : startTicker()
            } label: {
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    .font(.title3.weight(.bold))
            }
            .buttonStyle(.gfPrimary)
            .disabled(minute >= finalMinute || atHalfTime)
            .accessibilityLabel(isPlaying ? "Pause match" : "Play match")

            Button {
                finish(fixture: fixture)
            } label: {
                Image(systemName: "forward.end.fill")
                    .font(.title3.weight(.bold))
            }
            .buttonStyle(.gfOutline)
            .accessibilityLabel("Skip to full time")
        }
        .padding(.horizontal, 24)
    }

    /// Every event so far as a card: goals in the scorer's club colours,
    /// cards and chances in white, the home side's minute on the right.
    private func commentaryCards(home: Club, away: Club) -> some View {
        let visible = (result?.events ?? []).filter { $0.minute <= minute }
        return ScrollView {
            LazyVStack(spacing: 8) {
                if visible.isEmpty {
                    Text(minute == 0 ? "Kick-off imminent..." : "No key events yet.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.top, 20)
                }
                ForEach(visible.reversed()) { ev in
                    let isGoal = ev.type == .goal || ev.type == .penalty || ev.type == .ownGoal
                    let club = ev.isHomeTeam ? home : away
                    let fill = isGoal ? Color(hex: club.primaryColor) : Color.white
                    let text = isGoal ? Color.readable(on: club.primaryColor) : Color.black
                    let marker = VStack(spacing: 2) {
                        Image(systemName: ev.type.icon).font(.caption)
                        Text("\(ev.minute)'").font(.caption2.weight(.heavy).monospacedDigit())
                    }
                    .foregroundStyle(Color.gfNight)
                    .frame(width: 38)
                    .frame(maxHeight: .infinity)
                    .background(Color.white)
                    HStack(spacing: 0) {
                        if !ev.isHomeTeam { marker }
                        VStack(alignment: ev.isHomeTeam ? .leading : .trailing, spacing: 3) {
                            if isGoal {
                                let scorer = ev.playerId.flatMap { gameState.player(withId: $0)?.player.displayName }
                                Text("\((scorer ?? club.name).uppercased())!").font(.gfDisplay(18))
                            }
                            Text(ev.detailText)
                                .font(.subheadline)
                                .multilineTextAlignment(ev.isHomeTeam ? .leading : .trailing)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .foregroundStyle(text)
                        .frame(maxWidth: .infinity, alignment: ev.isHomeTeam ? .leading : .trailing)
                        .padding(12)
                        if ev.isHomeTeam { marker }
                    }
                    .background(fill)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .accessibleMatchEvent(ev)
                }
            }
            .padding(.horizontal)
        }
    }

    /// Match stats so far. Totals are scaled to the minute reached, so the
    /// replay does not give away what is still to come.
    private func liveStats(home: Club, away: Club) -> some View {
        let share = finalMinute > 0 ? Double(minute) / Double(finalMinute) : 1
        func scaled(_ v: Int) -> Int { Int((Double(v) * share).rounded()) }
        let goals = (result?.goalEvents ?? []).filter { $0.minute <= minute }
        let h = result?.homeStats, a = result?.awayStats
        let homeColor = Color(hex: home.primaryColor)
        let awayColor = Color(hex: away.primaryColor == home.primaryColor ? away.secondaryColor : away.primaryColor)
        return ScrollView {
            VStack(spacing: 14) {
                if let h, let a {
                    DualStatBar(title: "Possession %", home: h.possession, away: a.possession,
                                homeText: "\(Int(h.possession.rounded()))", awayText: "\(Int(a.possession.rounded()))",
                                homeColor: homeColor, awayColor: awayColor)
                    DualStatBar(title: "xG", home: h.xG * share, away: a.xG * share,
                                homeText: String(format: "%.1f", h.xG * share), awayText: String(format: "%.1f", a.xG * share),
                                homeColor: homeColor, awayColor: awayColor)
                    let hg = goals.filter { $0.isHomeTeam }.count, ag = goals.count - goals.filter { $0.isHomeTeam }.count
                    let hOn = max(hg, scaled(h.shotsOnTarget)), aOn = max(ag, scaled(a.shotsOnTarget))
                    DualStatBar(title: "Shots on target", home: Double(hOn), away: Double(aOn),
                                homeText: "\(hOn)", awayText: "\(aOn)", homeColor: homeColor, awayColor: awayColor)
                    DualStatBar(title: "Shots", home: Double(max(hOn, scaled(h.shots))), away: Double(max(aOn, scaled(a.shots))),
                                homeText: "\(max(hOn, scaled(h.shots)))", awayText: "\(max(aOn, scaled(a.shots)))",
                                homeColor: homeColor, awayColor: awayColor)
                    DualStatBar(title: "Corners", home: Double(scaled(h.corners)), away: Double(scaled(a.corners)),
                                homeText: "\(scaled(h.corners))", awayText: "\(scaled(a.corners))", homeColor: homeColor, awayColor: awayColor)
                    DualStatBar(title: "Fouls", home: Double(scaled(h.fouls)), away: Double(scaled(a.fouls)),
                                homeText: "\(scaled(h.fouls))", awayText: "\(scaled(a.fouls))", homeColor: homeColor, awayColor: awayColor)
                    let cards = (result?.events ?? []).filter { $0.minute <= minute }
                    let hy = cards.filter { $0.isHomeTeam && $0.type == .yellowCard }.count
                    let ay = cards.filter { !$0.isHomeTeam && $0.type == .yellowCard }.count
                    DualStatBar(title: "Yellow cards", home: Double(hy), away: Double(ay),
                                homeText: "\(hy)", awayText: "\(ay)", homeColor: homeColor, awayColor: awayColor)
                }
            }
            .gfCard()
            .padding(.horizontal)
        }
    }

    /// Both starting elevens, with match ratings once the whistle has gone.
    private func lineups(home: Club, away: Club) -> some View {
        let done = minute >= finalMinute
        func column(_ club: Club, alignment: HorizontalAlignment) -> some View {
            VStack(alignment: alignment, spacing: 6) {
                Text(club.tactics.formation.rawValue).font(.gfLabel(14)).foregroundStyle(.secondary)
                ForEach(club.startingXIPlayers) { player in
                    HStack(spacing: 6) {
                        if alignment == .trailing { Spacer(minLength: 0) }
                        Text(player.primaryPosition.abbreviation)
                            .font(.gfLabel(11))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 5).padding(.vertical, 2)
                            .background(Capsule().fill(player.primaryPosition.category.accentColor))
                        Text(player.displayName).font(.caption.weight(.semibold)).lineLimit(1)
                        if done, let rating = result?.playerRatings[player.id] {
                            Text(String(format: "%.1f", rating))
                                .font(.caption2.weight(.heavy).monospacedDigit())
                                .padding(.horizontal, 4)
                                .background(Capsule().fill(rating >= 7 ? Color.gfMint : Color.white.opacity(0.85)))
                                .foregroundStyle(Color.gfNight)
                        }
                        if alignment == .leading { Spacer(minLength: 0) }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: alignment == .leading ? .leading : .trailing)
        }
        return ScrollView {
            HStack(alignment: .top, spacing: 12) {
                column(home, alignment: .leading)
                column(away, alignment: .trailing)
            }
            .gfCard()
            .padding(.horizontal)
        }
    }
    
    // MARK: - Logic
    
    private var currentHomeGoals: Int {
        (result?.goalEvents ?? []).filter { $0.minute <= minute && $0.isHomeTeam }.count
    }
    
    private var currentAwayGoals: Int {
        (result?.goalEvents ?? []).filter { $0.minute <= minute && !$0.isHomeTeam }.count
    }
    
    private var scoreText: String {
        "\(currentHomeGoals) - \(currentAwayGoals)"
    }
    
    private func prepare() {
        // Never replay a finished match: if the active fixture has already
        // been played and we are not mid-replay, pick today's match instead.
        if !didSimulate, let current = fixture, current.isPlayed {
            if !gameState.selectTodaysUserFixture() {
                gameState.currentScreen = .dashboard
                return
            }
        }
        guard let fixture = fixture else { return }
        // Simulate first (pre-decides the outcome), then replay it minute by minute.
        if !didSimulate {
            if !fixture.isPlayed {
                gameState.applyTeamTalkIfNeeded()
                // Live: play to half-time and stop there for changes.
                if !gameState.beginLiveMatch(fixtureId: fixture.id) {
                    gameState.simulateFixture(id: fixture.id)
                }
            }
            didSimulate = true
        }
        minute = 0
        CrowdAtmosphere.shared.startMatch()
        Haptics.matchEvent(.kickOff)
        if let home = gameState.club(withId: fixture.homeClubId), let away = gameState.club(withId: fixture.awayClubId) {
            enqueue("Kick-off at \(home.stadium). \(home.name) against \(away.name).")
        }
        startTicker()
    }
    
    private var holdsForVoiceOver: Bool {
        UIAccessibility.isVoiceOverRunning && Preferences.waitForVoiceOver
    }

    private func startTicker() {
        guard minute < finalMinute else { return }
        isPlaying = true
        CrowdAtmosphere.shared.resume()
        scheduleTimer()
    }

    private func scheduleTimer() {
        ticker?.invalidate()
        ticker = nil
        guard isPlaying, minute < finalMinute else { return }
        if holdsForVoiceOver && (isSpeaking || !speechQueue.isEmpty) { return }
        let interval = gameState.matchSettings.speed.tickInterval
        ticker = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { timer in
            Task { @MainActor in
                advanceMinute()
                if minute >= finalMinute {
                    timer.invalidate()
                    isPlaying = false
                    if secondHalfPending {
                        // An owner only watches: no half-time changes to make.
                        if gameState.matchSettings.stopAtHalfTime && gameState.gameMode == .manageClub {
                            withAnimation { atHalfTime = true }
                            enqueue("Half-time. \(scoreText). You can make substitutions and change tactics, then start the second half.")
                            Haptics.matchEvent(.halfTime)
                        } else {
                            startSecondHalf()
                        }
                    } else {
                        Haptics.matchEvent(.fullTime)
                    }
                } else if holdsForVoiceOver && (isSpeaking || !speechQueue.isEmpty) {
                    // Hold the clock until VoiceOver has read the latest lines.
                    timer.invalidate()
                    ticker = nil
                }
            }
        }
    }
    
    private func stopTicker() {
        ticker?.invalidate()
        ticker = nil
        isPlaying = false
    }
    
    private func advanceMinute() {
        let previous = minute
        minute = min(finalMinute, minute + 1)
        
        CrowdAtmosphere.shared.tickMinute()
        let detail = Preferences.commentaryDetail
        let newEvents = (result?.events ?? []).filter { $0.minute > previous && $0.minute <= minute }
        for ev in newEvents {
            CrowdAtmosphere.shared.react(to: ev)
            let isGoal = ev.type == .goal || ev.type == .penalty || ev.type == .ownGoal
            if isGoal {
                let userId = gameState.userClubId
                Haptics.goal(forUser: ev.type == .ownGoal ? ev.clubId != userId : ev.clubId == userId)
            } else {
                Haptics.matchEvent(ev.type)
            }
            if detail.includes(ev.type), ev.type != .kickOff {
                enqueue("\(ev.minute) minutes. \(ev.detailText)")
                if isGoal, Preferences.announceScore { enqueue("The score is \(scoreText).") }
            }
            if isGoal {
                SoundManager.shared.play(.goal, enabled: gameState.soundEnabled)
                withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) { goalFlash = ev }
                let shown = ev.id
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
                    if goalFlash?.id == shown { withAnimation(.easeOut) { goalFlash = nil } }
                }
            }
        }
        quarterHourUpdate()
        CrowdAtmosphere.shared.maybeChant(homeLeading: currentHomeGoals > currentAwayGoals)
    }
    
    private func quarterHourUpdate() {
        guard Preferences.minuteUpdates, minute % 15 == 0, minute > 0, minute < 90, minute != 45 else { return }
        enqueue("\(minute) minutes played. \(scoreText).")
    }

    // MARK: - VoiceOver pacing

    private func enqueue(_ line: String) {
        guard UIAccessibility.isVoiceOverRunning else { return }
        speechQueue.append(line)
        if !isSpeaking { speakNext() }
    }

    /// Reads the next queued line; called again when VoiceOver reports the
    /// last one finished, with a watchdog in case that never arrives.
    private func speakNext() {
        speechWatchdog?.cancel()
        guard !speechQueue.isEmpty else {
            isSpeaking = false
            if isPlaying && ticker == nil && minute < finalMinute { scheduleTimer() }
            return
        }
        isSpeaking = true
        let line = speechQueue.removeFirst()
        var announcement = AttributedString(line)
        announcement.accessibilitySpeechAnnouncementPriority = .high
        AccessibilityNotification.Announcement(announcement).post()
        let words = Double(line.split(separator: " ").count)
        let watchdog = DispatchWorkItem { speakNext() }
        speechWatchdog = watchdog
        DispatchQueue.main.asyncAfter(deadline: .now() + max(3, words * 0.45 + 1.5), execute: watchdog)
    }

    private func finish(fixture: Fixture) {
        speechWatchdog?.cancel()
        speechQueue.removeAll()
        isSpeaking = false
        stopTicker()
        if gameState.season.fixtures.contains(where: { $0.id == fixture.id }) {
            gameState.simulateFixture(id: fixture.id)
            minute = finalMinute
            gameState.finishMatchweekAfterUserMatch()
            gameState.currentScreen = .postMatch
        }
    }
}
