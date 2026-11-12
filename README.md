# Touchline

**Touchline** is an offline football management game for iPhone and iPad by Gooners LLC, built on the GridironFC 1.6.0 engine. Own a club and run it from the boardroom, or take a manager's job and win matches from the dugout. It is built in SwiftUI for iOS 17 and is fully playable with VoiceOver.

## What it has

- 802 clubs in 45 leagues with current squads, promotion and relegation, domestic cups, continental competitions and international tournaments.
- Owner careers: hire managers and staff, sponsors that come to you, facilities, takeovers, and watching your team live.
- Manager careers: squad selection, tactics, training, transfers and loans, and real half-time changes.
- Live matches with commentary, momentum, stats and lineups, and a full-time report with ratings, press conference and the table.
- A real stadium crowd recorded at football grounds that reacts to the match, and haptics.
- Datapack editor with import and export.

## Building

Requirements: macOS 14 or later, Xcode 16 or later, and XcodeGen (`brew install xcodegen`).

```bash
xcodegen generate
open Touchline.xcodeproj
```

## Releases and tests

Every push to `main` runs **Build iOS App** in GitHub Actions. Crash tests in `TouchlineUITests` play a live match through half-time, an instant result, an owner watching a match and half a season on an iPhone simulator; if any fail, nothing is published. The unsigned `Touchline.ipa` is then attached to a GitHub Release.

After each release, run `node tools/publish-website.js` to put the new IPA on the Gooners LLC website.

## Crowd sound

`Touchline/Sounds` holds public-domain (CC0) recordings from Freesound, listed in `Touchline/Sounds/CREDITS.md`. `tools/build-crowd-sounds.js` rebuilds them from the source files.

## License

MIT. Copyright Gooners LLC.
