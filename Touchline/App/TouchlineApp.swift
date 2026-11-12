//
//  TouchlineApp.swift
//  Touchline
//
//  Created for Touchline - iOS Football Manager Game.
//  Application entrypoint initializing the root GameState environment
//  and handling background state autosaving.
//

import SwiftUI

@main
struct TouchlineApp: App {
    
    @State private var gameState: GameState
    @Environment(\.scenePhase) private var scenePhase
    
    init() {
        Self.configureAppearance()
        Preferences.registerDefaults()
        CrowdAtmosphere.shared.prepare()
        // Attempt to load existing autosave or bootstrap initial data
        if let savedState = try? SaveManager.shared.loadAutoSave() {
            // Always land on the main menu when the app opens, so the user
            // deliberately chooses "Continue Career" rather than being dropped
            // mid-screen. The career state itself is preserved.
            savedState.currentScreen = .mainMenu
            _gameState = State(initialValue: savedState)
        } else {
            let (clubs, leagues) = DataLoader.loadAllData()
            
            // Build initial season fixtures across all leagues
            var allFixtures: [Fixture] = []
            for league in leagues {
                let fixtures = FixtureGenerator.generateDoubleRoundRobin(
                    clubIds: league.clubIds,
                    competitionName: league.name,
                    startDateString: "2026-08-08"
                )
                allFixtures.append(contentsOf: fixtures)
            }
            
            let initialSeason = Season(
                year: "2026-27",
                currentWeek: 1,
                currentPhase: .preseason,
                fixtures: allFixtures,
                currentDate: "2026-08-01"
            )
            
            let state = GameState(
                gameMode: .createClub,
                clubs: clubs,
                leagues: leagues,
                season: initialSeason,
                currentScreen: .mainMenu,
                europeanCompetitions: EuropeanCompetitionBuilder.build(from: clubs),
                nationalTeams: DataLoader.loadNationalTeams()
            )
            state.seedFreeAgents()
            state.seedAcademies()
            state.seedInternationalTournaments()
            
            _gameState = State(initialValue: state)
        }
    }
    
    /// UIKit chrome (navigation and tab bars) matched to the Floodlight palette.
    private static func configureAppearance() {
        let ink = UIColor(red: 10/255, green: 15/255, blue: 30/255, alpha: 1)
        let surface = UIColor(red: 18/255, green: 26/255, blue: 47/255, alpha: 1)
        let amber = UIColor(red: 1, green: 176/255, blue: 32/255, alpha: 1)

        let nav = UINavigationBarAppearance()
        nav.configureWithOpaqueBackground()
        nav.backgroundColor = ink
        nav.shadowColor = .clear
        nav.titleTextAttributes = [.foregroundColor: UIColor.white]
        nav.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        UINavigationBar.appearance().standardAppearance = nav
        UINavigationBar.appearance().scrollEdgeAppearance = nav
        UINavigationBar.appearance().compactAppearance = nav

        let tab = UITabBarAppearance()
        tab.configureWithOpaqueBackground()
        tab.backgroundColor = surface
        tab.stackedLayoutAppearance.selected.iconColor = amber
        tab.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: amber]
        UITabBar.appearance().standardAppearance = tab
        UITabBar.appearance().scrollEdgeAppearance = tab
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(gameState)
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .background || newPhase == .inactive {
                // Auto-save on backgrounding
                try? SaveManager.shared.autoSave(gameState: gameState)
            }
        }
    }
}
