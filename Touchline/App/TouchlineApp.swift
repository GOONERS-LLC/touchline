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
        // Native segmented controls match the capsule tabs: navy track,
        // white selected segment, condensed capitals.
        let seg = UISegmentedControl.appearance()
        seg.selectedSegmentTintColor = .white
        seg.backgroundColor = UIColor(red: 0.063, green: 0.188, blue: 0.212, alpha: 0.95)
        let font = UIFont.systemFont(ofSize: 12, weight: .heavy)
        seg.setTitleTextAttributes([.foregroundColor: UIColor.white, .font: font], for: .normal)
        seg.setTitleTextAttributes([.foregroundColor: UIColor(red: 0.027, green: 0.09, blue: 0.1, alpha: 1), .font: font], for: .selected)
        // Crash-test start states (only with a -uitest- launch argument).
        if let harness = UITestHarness.makeState() {
            _gameState = State(initialValue: harness)
            return
        }
        // Attempt to load an existing autosave, otherwise bootstrap a new world.
        do {
            let savedState = try SaveManager.shared.loadAutoSave()
            // Always land on the main menu when the app opens, so the user
            // deliberately chooses "Continue Career" rather than being dropped
            // mid-screen. The career state itself is preserved.
            savedState.currentScreen = .mainMenu
            savedState.isMatchInProgress = false
            savedState.compactArchivedResults()
            savedState.seedRivalriesIfNeeded()
            savedState.ensureGoalkeepersEverywhere()
            _gameState = State(initialValue: savedState)
        } catch SaveManagerError.fileNotFound(_) {
            _gameState = State(initialValue: GameState.makeFreshWorld())
        } catch {
            // The autosave exists but could not be read (for example it was
            // written by an incompatible build). Move it aside instead of letting
            // the next background autosave silently overwrite the career.
            SaveManager.shared.quarantineUnreadableSave(.autoSave)
            _gameState = State(initialValue: GameState.makeFreshWorld())
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(gameState)
        }
        .onChange(of: scenePhase) { _, newPhase in
            // Save once when the app is backgrounded. `.inactive` also fires for
            // transient interruptions (Control Centre, notifications), and
            // encoding the whole world twice in a row there caused visible hitches.
            guard newPhase == .background else { return }
            // A freshly bootstrapped world is not a career; never let it
            // overwrite a real autosave.
            guard gameState.hasStartedCareer else { return }
            // Synchronous: the write must finish before iOS suspends the app.
            try? SaveManager.shared.autoSaveNow(gameState: gameState)
        }
    }
}
