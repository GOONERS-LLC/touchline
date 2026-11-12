# Touchline

**Touchline** is an offline football management game for iPhone and iPad by Gooners LLC. Own a club and run it from the boardroom, or take a manager's job and win matches from the dugout. It is built in SwiftUI for iOS 17 and designed from the start to be fully playable with VoiceOver.

## Highlights

- **802 clubs in 45 leagues**, with real 2026-27 squads from Wikipedia and Transfermarkt, promotion, relegation, cups, continental competitions and international tournaments.
- **Two careers.** Owners hire managers and staff, negotiate sponsors, build facilities, field takeover bids and watch their team live. Managers pick the side, set tactics, train and make half-time changes.
- **Match day.** Live matches with detailed spoken commentary for every foul, chance, save and goal, a crowd that reacts, haptics, and a real half-time break.
- **Full time.** Match Facts, Ratings and Stats tabs, then Player of the Match (tap to make an offer), then the division's results and table.
- **Kits.** Real colours and famous patterns, sponsors on the shirt, and a Kit Designer whose changes supporters judge.
- **Datapack editor** with import and export.

## Accessibility

- VoiceOver reads full club names, never three-letter codes.
- No emoji or symbol characters carry meaning.
- Live Match Accessibility settings: commentary detail, wait for VoiceOver to finish each line before the clock moves, score after goals, quarter-hour updates and a Very Slow replay speed.
- Lineups are ordered lists for VoiceOver, ratings are spoken in words, and every screen scales with Dynamic Type.

## Building

Requirements: macOS 14 or later, Xcode 16 or later, and XcodeGen (`brew install xcodegen`).

```bash
xcodegen generate
open Touchline.xcodeproj
```

## Releases and tests

Every push to `main` runs **Build iOS App** in GitHub Actions. It first runs the crash tests in `TouchlineUITests` on an iPhone simulator (a live match through half-time, an instant result, the owner's watch mode, half a season, and the kit designer); if any fail, nothing is published. It then builds an unsigned `Touchline.ipa` and attaches it, with a `release-manifest.json`, to a GitHub Release.

After each release, run `node tools/publish-website.js` to put the new IPA on the Gooners LLC website.

## Data tools

- `tools/scrape-transfermarkt.js` rebuilds league files from Transfermarkt squad pages.
- `tools/enrich-from-transfermarkt.js` merges those squads into the bundled data (ages and feet; placeholder squads replaced).

## License

MIT. Copyright Gooners LLC.
