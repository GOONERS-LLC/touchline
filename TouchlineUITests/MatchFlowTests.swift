//
//  MatchFlowTests.swift
//  TouchlineUITests
//
//  Crash tests that run on an iPhone simulator in CI before every release.
//  They drive the real screens: match day, a live match through half-time,
//  the full-time report, the instant result, the owner's watch mode and
//  a half-season career. A crash anywhere fails the build.
//

import XCTest

final class MatchFlowTests: XCTestCase {

    override func setUp() {
        continueAfterFailure = false
    }

    private func launch(_ argument: String) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = [argument]
        app.launch()
        return app
    }

    private func button(_ app: XCUIApplication, beginsWith prefix: String) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", prefix)).firstMatch
    }

    private func tap(_ element: XCUIElement, _ what: String, timeout: TimeInterval = 30) {
        XCTAssertTrue(element.waitForExistence(timeout: timeout), "Missing: \(what)")
        element.tap()
    }

    /// Full time: the report scrolls, then Continue returns home.
    private func walkFullTime(_ app: XCUIApplication) {
        let cont = app.buttons["Continue"]
        XCTAssertTrue(cont.waitForExistence(timeout: 30), "Full time never appeared")
        app.swipeUp()
        app.swipeUp()
        if !cont.isHittable { app.swipeUp() }
        cont.tap()
        XCTAssertFalse(app.navigationBars["Full Time"].waitForExistence(timeout: 3), "Still on the full-time screen")
        XCTAssertEqual(app.state, .runningForeground, "The app is no longer running")
    }

    func testLiveMatchThroughHalfTimeToFullTime() {
        let app = launch("-uitest-matchday")
        tap(button(app, beginsWith: "Play vs"), "Play vs button on home")
        tap(app.buttons["Play the match with live commentary"], "Live match button")
        // Very fast playback reaches the break in a few seconds.
        tap(app.buttons["Start Second Half"].firstMatch, "Start Second Half", timeout: 60)
        sleep(4)
        tap(app.buttons["Skip to full time"], "Skip to full time")
        walkFullTime(app)
        // And the next match day works too (no replaying the same match).
        let next = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Continue' OR label BEGINSWITH 'Play vs'")).firstMatch
        if !next.waitForExistence(timeout: 30) { print(app.debugDescription) }
        XCTAssertTrue(next.exists, "No Continue or Play button on the home screen")
        if next.label.hasPrefix("Continue") {
            next.tap()
            let play = button(app, beginsWith: "Play vs")
            if !play.waitForExistence(timeout: 30) { print(app.debugDescription) }
            XCTAssertTrue(play.exists, "Next match day not reached")
        }
    }

    func testInstantResult() {
        let app = launch("-uitest-matchday")
        tap(button(app, beginsWith: "Play vs"), "Play vs button on home")
        tap(app.buttons["Simulate an instant match result"], "Instant result button")
        walkFullTime(app)
    }

    func testOwnerWatchesMatch() {
        let app = launch("-uitest-owner")
        tap(button(app, beginsWith: "Watch vs"), "Watch vs button on the owner home", timeout: 60)
        sleep(5)
        tap(app.buttons["Skip to full time"], "Skip to full time", timeout: 60)
        walkFullTime(app)
    }

    func testHalfSeasonCareerStillPlays() {
        let app = launch("-uitest-season")
        tap(button(app, beginsWith: "Play vs"), "Play vs after nineteen rounds", timeout: 90)
        tap(app.buttons["Simulate an instant match result"], "Instant result button")
        walkFullTime(app)
    }
}
