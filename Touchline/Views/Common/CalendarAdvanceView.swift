//
//  CalendarAdvanceView.swift
//  Touchline
//
//  The animated calendar shown when the manager presses Continue: the days
//  tick by one at a time on a week strip, with results and news appearing
//  as they happen, until match day arrives. Skip jumps straight there.
//

import SwiftUI

struct CalendarAdvanceView: View {
    @Environment(GameState.self) private var gameState
    /// Called once the calendar stops: `true` when match day has arrived.
    let onFinish: (Bool) -> Void

    @State private var currentDate = ""
    @State private var startDate = ""
    @State private var targetDate = ""
    @State private var events: [FeedEvent] = []
    @State private var seenNews: Set<UUID> = []
    @State private var arrived = false
    @State private var finished = false
    /// Important new mail the calendar has stopped for.
    @State private var pausedMail: [NewsItem] = []

    private struct FeedEvent: Identifiable, Equatable {
        let id = UUID()
        let icon: String
        let text: String
        let highlight: Bool
    }

    private static let parser: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    private func date(_ string: String) -> Date? { Self.parser.date(from: string) }

    private var progress: Double {
        guard let start = date(startDate), let end = date(targetDate), let now = date(currentDate) else { return 0 }
        let total = end.timeIntervalSince(start)
        guard total > 0 else { return 1 }
        return min(1, max(0, now.timeIntervalSince(start) / total))
    }

    var body: some View {
        VStack(spacing: 20) {
            header
            weekStrip
            ProgressView(value: progress)
                .tint(Color.accentColor)
                .animation(.easeInOut(duration: 0.25), value: progress)
                .accessibilityLabel("Progress to match day")
            feed
            Spacer(minLength: 0)
            Button {
                skip()
            } label: {
                Text(arrived ? "Match Day!" : "Skip to Match Day")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .disabled(finished)
        }
        .padding()
        .stadiumBackground()
        .task { await run() }
        .sheet(isPresented: Binding(get: { !pausedMail.isEmpty }, set: { if !$0 { closeMail() } })) {
            NavigationStack {
                List {
                    Section {
                        Text("The calendar has paused. Close this window to carry on.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    ForEach(pausedMail) { item in
                        MailRow(item: item)
                    }
                }
                .navigationTitle(pausedMail.count == 1 ? "New Mail" : "\(pausedMail.count) New Messages")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Continue") { closeMail() }
                    }
                }
            }
            .presentationDetents([.medium, .large])
        }
    }

    private func closeMail() {
        for item in pausedMail { gameState.markMailRead(id: item.id) }
        pausedMail = []
    }

    /// Mail worth stopping the calendar for: anything needing a decision,
    /// the board, contracts, injuries and the club's own transfer business.
    private func isImportant(_ item: NewsItem) -> Bool {
        if let offerId = item.transferOfferId,
           gameState.pendingTransferOffers.contains(where: { $0.id == offerId && $0.isLive }) {
            return true
        }
        switch item.category {
        case .board, .contractExpiry, .injury: return true
        case .transfer:
            return !["Transfer Desk", "Club News Desk"].contains(item.sender)
        case .general:
            return item.sender == "Medical Department"
        default:
            return false
        }
    }

    // MARK: - Pieces

    private var header: some View {
        VStack(spacing: 6) {
            Text(arrived ? "MATCH DAY" : "ADVANCING")
                .font(.caption.weight(.bold))
                .tracking(2)
                .foregroundStyle(arrived ? Color.winGreen : .secondary)
            Text(longDate(currentDate))
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .contentTransition(.numericText())
                .animation(.snappy, value: currentDate)
            if let fixture = gameState.nextUserFixture, let uid = gameState.userClubId,
               let opponentId = fixture.opponentId(for: uid), let opponent = gameState.club(withId: opponentId) {
                HStack(spacing: 8) {
                    CrestView(club: opponent, size: 22)
                    Text("\(fixture.homeClubId == uid ? "vs" : "at") \(opponent.name)")
                        .font(.subheadline.weight(.semibold))
                    Text("· \(shortDate(fixture.date))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Text(fixture.cupRound.map { "\(fixture.competition) • \($0)" } ?? fixture.competition)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 12)
    }

    private var weekStrip: some View {
        let days = stripDays()
        return HStack(spacing: 6) {
            ForEach(days, id: \.self) { day in
                let isToday = day == currentDate
                let isMatch = day == targetDate
                let isPast = day < currentDate
                VStack(spacing: 4) {
                    Text(weekdayLetter(day))
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(dayNumber(day))
                        .font(.headline.monospacedDigit())
                    Image(systemName: isMatch ? "soccerball" : "circle.fill").accessibilityHidden(true)
                        .font(.system(size: isMatch ? 12 : 4))
                        .foregroundStyle(isMatch ? Color.winGreen : (isPast ? Color.secondary : Color.clear))
                }
                .frame(maxWidth: .infinity, minHeight: 64)
                .background(isToday ? Color.accentColor.opacity(0.9) : Color(UIColor.secondarySystemGroupedBackground))
                .foregroundStyle(isToday ? Color.white : Color.primary)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .scaleEffect(isToday ? 1.08 : 1)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentDate)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Today is \(longDate(currentDate)). Match day is \(longDate(targetDate)).")
    }

    private var feed: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(events.prefix(7)) { event in
                HStack(spacing: 10) {
                    Image(systemName: event.icon).accessibilityHidden(true)
                        .frame(width: 22)
                        .foregroundStyle(event.highlight ? Color.accentColor : .secondary)
                    Text(event.text)
                        .font(.subheadline)
                        .fontWeight(event.highlight ? .semibold : .regular)
                        .lineLimit(2)
                    Spacer(minLength: 0)
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .animation(.easeOut(duration: 0.3), value: events)
    }

    // MARK: - Driving the calendar

    private func run() async {
        currentDate = gameState.season.currentDate
        startDate = currentDate
        targetDate = gameState.nextUserFixture?.date ?? currentDate
        seenNews = Set(gameState.news.map { $0.id })
        while !finished && !Task.isCancelled {
            try? await Task.sleep(for: .milliseconds(380))
            // Hold the calendar while new mail is open.
            while !pausedMail.isEmpty && !finished && !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(200))
            }
            if finished || Task.isCancelled { return }
            let step = gameState.advanceCalendarOneDay()
            collectEvents()
            switch step {
            case .advanced(let date):
                currentDate = date
                // The next fixture can change (e.g. a European tie scheduled).
                if let next = gameState.nextUserFixture?.date, next != targetDate {
                    targetDate = next
                    startDate = min(startDate, currentDate)
                }
            case .matchDay:
                currentDate = targetDate
                arrived = true
                try? await Task.sleep(for: .milliseconds(900))
                finish(true)
                return
            case .seasonOver:
                finish(false)
                return
            }
        }
    }

    private func skip() {
        guard !finished else { return }
        if arrived { finish(true); return }
        finished = true
        let reached = gameState.advanceCalendar()
        onFinish(reached)
    }

    private func finish(_ reachedMatch: Bool) {
        guard !finished else { return }
        finished = true
        onFinish(reachedMatch)
    }

    /// New inbox items and the day's results in the user's competitions.
    private func collectEvents() {
        var fresh: [FeedEvent] = []
        if let uid = gameState.userClubId,
           let league = gameState.leagues.first(where: { $0.clubIds.contains(uid) }) {
            let today = gameState.season.currentDate
            let results = gameState.season.fixtures.filter {
                $0.isPlayed && $0.date == today && $0.competition == league.name
            }
            for fixture in results.prefix(4) {
                guard let r = fixture.result else { continue }
                let home = gameState.club(withId: fixture.homeClubId)?.name ?? "?"
                let away = gameState.club(withId: fixture.awayClubId)?.name ?? "?"
                fresh.append(FeedEvent(icon: "sportscourt", text: "\(home) \(r.homeGoals)-\(r.awayGoals) \(away)", highlight: false))
            }
            if results.count > 4 {
                fresh.append(FeedEvent(icon: "ellipsis", text: "\(results.count - 4) more \(league.name) results", highlight: false))
            }
        }
        var important: [NewsItem] = []
        for item in gameState.news where !seenNews.contains(item.id) {
            seenNews.insert(item.id)
            fresh.append(FeedEvent(icon: item.category.iconName, text: item.headline,
                                   highlight: item.transferOfferId != nil || item.category == .transfer))
            if isImportant(item) { important.append(item) }
        }
        if gameState.matchSettings.pauseCalendarForMail && !important.isEmpty && !finished {
            pausedMail = important
        }
        if !fresh.isEmpty {
            events.insert(contentsOf: fresh, at: 0)
            if events.count > 20 { events.removeLast(events.count - 20) }
        }
    }

    // MARK: - Date helpers

    private func stripDays() -> [String] {
        guard let now = date(currentDate) else { return [] }
        // Seven days, starting a day before today so the next days are visible.
        return (-1...5).compactMap { offset in
            Calendar.current.date(byAdding: .day, value: offset, to: now).map { Self.parser.string(from: $0) }
        }
    }

    private func formatted(_ string: String, _ format: String) -> String {
        guard let d = date(string) else { return string }
        let f = DateFormatter()
        f.dateFormat = format
        return f.string(from: d)
    }

    private func longDate(_ s: String) -> String { formatted(s, "EEE d MMM yyyy") }
    private func shortDate(_ s: String) -> String { formatted(s, "EEE d MMM") }
    private func weekdayLetter(_ s: String) -> String { formatted(s, "EEEEE") }
    private func dayNumber(_ s: String) -> String { formatted(s, "d") }
}
