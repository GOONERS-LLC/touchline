//
//  MatchFlowTests.swift
//  TouchlineUITests
//
//  Crash tests that run on an iPhone simulator in CI before every release.
//  They drive the real screens: match day, a live match through half-time,
//  the three full-time screens, the instant result, the owner's watch mode,
//  a half-season career and the kit designer. A crash anywhere fails the build.
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

    /// Full time: Match Facts, Ratings and Stats tabs, then Player of the
    /// Match, then the division's results, then home.
    private func walkFullTime(_ app: XCUIApplication) {
        XCTAssertTrue(app.buttons["Continue"].waitForExistence(timeout: 30), "Full time never appeared")
        for tab in ["Ratings", "Stats", "Match Facts"] {
            tap(app.buttons[tab], "\(tab) tab", timeout: 10)
        }
        tap(app.buttons["Continue"], "Continue to Player of the Match")
        XCTAssertTrue(app.staticTexts["Player of the Match"].waitForExistence(timeout: 10))
        tap(app.buttons["Continue"], "Continue to division results")
        tap(app.buttons["Back to Home"], "Back to Home")
        // Home again: the full-time screens are gone and the app is still running.
        XCTAssertFalse(app.buttons["Back to Home"].waitForExistence(timeout: 3), "Still on the full-time screens")
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
        tap(button(app, beginsWith: "Continue"), "Continue to the next match day")
        XCTAssertTrue(button(app, beginsWith: "Play vs").waitForExistence(timeout: 30), "Next match day not reached")
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

    func testKitDesignerOpens() {
        let app = launch("-uitest-matchday")
        tap(app.buttons["Kit"], "Kit tile")
        tap(app.buttons["Design Kit"], "Design Kit button")
        tap(app.buttons["Hoops"], "Hoops pattern")
        tap(app.buttons["Unveil"], "Unveil the new kit")
    }
}
