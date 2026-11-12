# Touchline

**Touchline** is an offline football management game for iPhone and iPad, made by Gooners LLC. Found a club and run it from the boardroom, or take a manager's job and win matches from the dugout. It is built in SwiftUI for iOS 17 and designed from the start to be fully playable with VoiceOver.

## Highlights

- **Two careers.** *Own a New Club* is a boardroom career: appoint managers, hire staff, sign sponsors and build facilities. *Manage Existing Club* puts you in charge of tactics, selection, training and matchday.
- **A calendar that breathes.** Continue to Match Day walks you through the days before each fixture; Play Match only appears when the day actually arrives.
- **Minute-by-minute match engine** with possession, shots, expected goals, cards, injuries, fatigue, commentary and player ratings.
- **Live match board** showing a top-down replay of every minute, with key moments announced to VoiceOver.
- **Full football pyramid** with promotion, relegation, play-offs, continental cups and international tournaments.
- **Transfer market, contract renewals, youth academy and AI clubs** that scout, bid and manage their own squads.
- **Procedural crests and faces.** No real badges or likenesses are used, and the game needs no network connection.
- **Floodlight design.** A night-match palette of deep navy, cobalt and amber with high-contrast text throughout.

## Accessibility

- Club abbreviations are shown on screen but never spoken. VoiceOver always reads the full club name, on crests, scoreboards, fixtures and commentary.
- No emoji or symbol characters are used for meaning; stars and arrows are written as words.
- Ratings are spoken as words ("Excellent", "Average") as well as numbers.
- Every metric pairs colour with text, and all screens scale with Dynamic Type.

## Building

Requirements: macOS 14 or later, Xcode 15 or later, and XcodeGen (`brew install xcodegen`).

```bash
xcodegen generate
open Touchline.xcodeproj
```

Choose an iOS 17 simulator or device and run.

## Releases

Every push to `main` runs **Build iOS App** in GitHub Actions. It builds an unsigned `Touchline.ipa`, attaches it with a `release-manifest.json` (version, commit and SHA-256) to a new GitHub Release, and bumps the minor version. Sideload the IPA with a tool such as Feather.

From Windows, `tools/Push-And-FetchIPA.ps1` pushes, waits for the build and downloads the verified IPA.

## Project layout

```
Touchline/
  App/            entry point and screens
  Models/         game state, clubs, players, leagues, careers
  Engine/         match engine, commentary, injuries
  Data/           bundled league data and builders
  Views/          theme, crests, faces, pitch and live match
  Persistence/    save slots and autosave
  Accessibility/  VoiceOver helpers
tools/            data and icon generators, release helpers
```

## License

MIT. Copyright Gooners LLC.
