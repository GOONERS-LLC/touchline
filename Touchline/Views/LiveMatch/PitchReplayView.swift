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
    /// Lines waiting to be read by VoiceOver. While this is non-empty and
    /// "Wait for VoiceOver" is on, the clock holds so nothing is skipped.
    @State private var speechQueue: [String] = []
    @State private var isSpeaking = false
    @State private var speechWatchdog: DispatchWorkItem?

    private var fixture: Fixture? { gameState.activeMatchFixture }
    private var result: MatchResult? { fixture?.result }
    private var detail: CommentaryDetail { Preferences.commentaryDetail }

    public var body: some View {
        VStack(spacing: 12) {
            if let fixture = fixture,
               let home = gameState.club(withId: fixture.homeClubId),
               let away = gameState.club(withId: fixture.awayClubId) {

                scoreboard(home: home, away: away)

                PitchReplayView(
                    fixture: fixture,
                    homeClub: home,
                    awayClub: away,
                    minute: minute
                )
                .frame(maxHeight: 220)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .padding(.horizontal, 16)
                .accessibilityHidden(true)

                timelineFeed(home: home, away: away)

                controls(fixture: fixture)
            } else {
                ContentUnavailableView("No Active Match", systemImage: "sportscourt")
            }
        }
        .padding(.vertical, 8)
        .background(Color.ink.ignoresSafeArea())
        .navigationTitle("Live Match")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .onAppear(perform: prepare)
        .onDisappear {
            stopTicker()
            CrowdAtmosphere.shared.stopMatch()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIAccessibility.announcementDidFinishNotification)) { _ in
            speakNext()
        }
    }

    // MARK: - Subviews

    private func scoreboard(home: Club, away: Club) -> some View {
        VStack(spacing: 8) {
            HStack(spacing: 6) {
                Circle().fill(isPlaying ? Color.lossRed : Color.drawGray).frame(width: 8, height: 8)
                Text(isPlaying ? "LIVE" : (minute >= 90 ? "FULL TIME" : minute == 0 ? "PRE-MATCH" : "PAUSED"))
                    .font(.caption2).fontWeight(.heavy).tracking(1.2)
                Text("· \(fixture?.competition ?? "Match")")
                    .font(.caption2).foregroundStyle(.secondary).lineLimit(1)
            }
            HStack {
                VStack(spacing: 4) {
                    CrestView(club: home, size: 40)
                    Text(home.name).font(.caption).fontWeight(.semibold).lineLimit(2).multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                VStack(spacing: 2) {
                    Text(scoreText)
                        .font(.system(size: 38, weight: .black, design: .rounded))
                        .monospacedDigit()
                        .contentTransition(.numericText())
                    Text("\(minute)'")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.highlight)
                        .monospacedDigit()
                }
                .frame(width: 120)
                VStack(spacing: 4) {
                    CrestView(club: away, size: 40)
                    Text(away.name).font(.caption).fontWeight(.semibold).lineLimit(2).multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(14)
        .background(Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(Color.hairline, lineWidth: 1))
        .padding(.horizontal, 16)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(home.name) \(currentHomeGoals), \(away.name) \(currentAwayGoals). Minute \(minute).")
        .accessibilityAddTraits(.updatesFrequently)
    }

    private func timelineFeed(home: Club, away: Club) -> some View {
        let visible = (result?.events ?? []).filter { $0.minute <= minute && detail.includes($0.type) }
        return ScrollView {
            LazyVStack(alignment: .leading, spacing: 8) {
                if visible.isEmpty {
                    Text(minute == 0 ? "The teams are in the tunnel. Kick-off is moments away." : "No incidents yet.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 12)
                } else {
                    ForEach(visible.reversed()) { ev in
                        HStack(alignment: .top, spacing: 10) {
                            Text("\(ev.minute)'")
                                .font(.caption)
                                .fontWeight(.bold)
                                .monospacedDigit()
                                .foregroundStyle(.secondary)
                                .frame(width: 30, alignment: .trailing)
                            EventBadge(type: ev.type)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(ev.shortText)
                                    .font(.subheadline)
                                    .fontWeight(ev.type.isMajorEvent ? .bold : .semibold)
                                Text(ev.detailText)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(ev.type.isMajorEvent ? Color.surfaceRaised : Color.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("\(ev.minute) minutes. \(ev.type.spokenName). \(ev.detailText)")
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }

    private func controls(fixture: Fixture) -> some View {
        HStack(spacing: 10) {
            Button {
                Haptics.tap()
                isPlaying ? pauseMatch() : startTicker()
            } label: {
                Label(isPlaying ? "Pause" : (minute == 0 ? "Kick Off" : "Resume"), systemImage: isPlaying ? "pause.fill" : "play.fill")
                    .font(.headline)
            }
            .buttonStyle(SecondaryActionStyle())
            .disabled(minute >= 90)
            .accessibilityLabel(isPlaying ? "Pause match" : "Resume match")

            Button {
                Haptics.tap()
                finish(fixture: fixture)
            } label: {
                Label(minute >= 90 ? "Full Time" : "Skip to End", systemImage: "flag.checkered")
                    .font(.headline)
            }
            .buttonStyle(PrimaryActionStyle())
            .accessibilityLabel(minute >= 90 ? "Go to full time" : "Skip to full time")
        }
        .padding(.horizontal, 16)
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

    private var holdsForVoiceOver: Bool {
        UIAccessibility.isVoiceOverRunning && Preferences.waitForVoiceOver
    }

    private func prepare() {
        guard let fixture = fixture else { return }
        // Simulate first (pre-decides the outcome), then replay it minute by minute.
        if !didSimulate {
            if !fixture.isPlayed,
               let idx = gameState.season.fixtures.firstIndex(where: { $0.id == fixture.id }) {
                gameState.applyTeamTalkIfNeeded()
                gameState.simulateMatch(fixture: &gameState.season.fixtures[idx])
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

    private func startTicker() {
        guard minute < 90 else { return }
        isPlaying = true
        CrowdAtmosphere.shared.resume()
        scheduleTimer()
    }

    private func scheduleTimer() {
        ticker?.invalidate()
        guard isPlaying, minute < 90 else { return }
        // Hold the clock while VoiceOver still has commentary to read.
        if holdsForVoiceOver && (isSpeaking || !speechQueue.isEmpty) { ticker = nil; return }
        let interval = gameState.matchSettings.speed.tickInterval
        ticker = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { timer in
            Task { @MainActor in
                advanceMinute()
                if minute >= 90 {
                    timer.invalidate()
                    isPlaying = false
                    Haptics.matchEvent(.fullTime)
                } else if gameState.matchSettings.stopAtHalfTime && minute == 45 {
                    timer.invalidate()
                    isPlaying = false
                    enqueue("Half-time. The match is paused so you can make changes.")
                } else if holdsForVoiceOver && (isSpeaking || !speechQueue.isEmpty) {
                    timer.invalidate()
                    ticker = nil
                }
            }
        }
    }

    private func pauseMatch() {
        stopTicker()
        CrowdAtmosphere.shared.pause()
    }

    private func stopTicker() {
        ticker?.invalidate()
        ticker = nil
        isPlaying = false
    }

    private func advanceMinute() {
        let previous = minute
        minute = min(90, minute + 1)
        CrowdAtmosphere.shared.tickMinute()

        let newEvents = (result?.events ?? []).filter { $0.minute > previous && $0.minute <= minute }
        for ev in newEvents {
            CrowdAtmosphere.shared.react(to: ev)
            switch ev.type {
            case .goal, .penalty, .ownGoal:
                let userId = gameState.userClub?.id
                let scoringForUser = (ev.type == .ownGoal) ? ev.clubId != userId : ev.clubId == userId
                Haptics.goal(forUser: scoringForUser)
                SoundManager.shared.play(.goal, enabled: gameState.soundEnabled)
            default:
                Haptics.matchEvent(ev.type)
            }
            guard detail.includes(ev.type), ev.type != .kickOff else { continue }
            enqueue("\(ev.minute) minutes. \(ev.detailText)")
            if Preferences.announceScore, [MatchEventType.goal, .penalty, .ownGoal].contains(ev.type),
               let fixture, let home = gameState.club(withId: fixture.homeClubId), let away = gameState.club(withId: fixture.awayClubId) {
                enqueue("The score is \(home.name) \(currentHomeGoals), \(away.name) \(currentAwayGoals).")
            }
        }

        if Preferences.minuteUpdates, minute % 15 == 0, minute < 90, minute != 45,
           let fixture, let home = gameState.club(withId: fixture.homeClubId), let away = gameState.club(withId: fixture.awayClubId) {
            enqueue("\(minute) minutes played. \(home.name) \(currentHomeGoals), \(away.name) \(currentAwayGoals).")
        }
        CrowdAtmosphere.shared.maybeChant(homeLeading: currentHomeGoals > currentAwayGoals)
    }

    // MARK: - VoiceOver pacing

    private func enqueue(_ line: String) {
        guard UIAccessibility.isVoiceOverRunning else { return }
        speechQueue.append(line)
        if !isSpeaking { speakNext() }
    }

    /// Reads the next queued line. Called again when VoiceOver reports the
    /// previous announcement finished, with a watchdog in case it never does.
    private func speakNext() {
        speechWatchdog?.cancel()
        guard !speechQueue.isEmpty else {
            isSpeaking = false
            if isPlaying && ticker == nil && minute < 90 { scheduleTimer() }
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
        stopTicker()
        speechWatchdog?.cancel()
        speechQueue.removeAll()
        if let idx = gameState.season.fixtures.firstIndex(where: { $0.id == fixture.id }) {
            if !gameState.season.fixtures[idx].isPlayed {
                gameState.simulateMatch(fixture: &gameState.season.fixtures[idx])
            }
            minute = 90
            gameState.finishMatchweekAfterUserMatch()
            gameState.currentScreen = .postMatch
        }
    }
}
