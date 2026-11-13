//
//  UITestHarness.swift
//  Touchline
//
//  Test-only start states for the automated crash tests that run in CI.
//  Nothing here runs unless the app is launched with one of these arguments:
//
//    -uitest-matchday   a fresh manager career, already on match day
//    -uitest-owner      a fresh owner career, already on match day
//    -uitest-season     a manager career with half a season simulated
//

import Foundation

enum UITestHarness {
    static var isActive: Bool {
        ProcessInfo.processInfo.arguments.contains { $0.hasPrefix("-uitest-") }
    }

    /// Builds the requested start state, or nil for a normal launch.
    static func makeState() -> GameState? {
        let args = ProcessInfo.processInfo.arguments
        let owner = args.contains("-uitest-owner")
        guard args.contains("-uitest-matchday") || owner || args.contains("-uitest-season") else { return nil }

        let state = GameState.makeFreshWorld()
        state.gameMode = owner ? .createClub : .manageClub
        if owner {
            // Exactly what the owner's club-creation screen does.
            guard let replaced = state.clubs.first(where: { $0.leagueTier == .eng4 }) else { return state }
            state.owner = OwnerProfile(name: "Test Owner", vision: ClubVision.allCases.first!)
            guard state.createCustomClub(name: "Harbour Town", shortName: "HBT", stadium: "Quayside Park",
                                         stadiumCapacity: 5000, city: "Harbour", primaryColor: "#2F5BEA",
                                         secondaryColor: "#FFB020", replaceClubId: replaced.id) != nil else { return state }
        } else {
            // A mid-table Premier League side: a full squad and a busy fixture list.
            let candidates = state.clubs.filter { $0.leagueTier == .eng1 }.sorted { $0.reputation < $1.reputation }
            guard let club = candidates.dropFirst(candidates.count / 2).first ?? state.clubs.first,
                  state.takeOverExistingClub(clubId: club.id) != nil else { return state }
        }

        // Fast playback; stop at half-time so the break is exercised too.
        state.matchSettings.speed = .veryFast
        state.matchSettings.stopAtHalfTime = true
        state.matchSettings.animateCalendar = false
        // An injury stop would put "Resume" where the test expects the break.
        state.matchSettings.stopForInjuries = false

        if args.contains("-uitest-season") {
            // Play nineteen rounds through the same code the buttons use.
            for _ in 0..<19 {
                state.continueToMatchDay()
                guard state.selectTodaysUserFixture(), let fixture = state.activeMatchFixture else { break }
                _ = state.simulateFixture(id: fixture.id)
                state.finishMatchweekAfterUserMatch()
                state.closeFinishedMatch()
            }
        }

        // Stop on the next match day so the dashboard offers "Play vs".
        var guardCount = 0
        while state.todaysUserFixture == nil && !state.isEndOfSeason && guardCount < 5 {
            state.continueToMatchDay()
            guardCount += 1
        }
        state.currentScreen = .dashboard
        return state
    }
}
