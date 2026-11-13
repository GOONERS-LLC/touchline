# Changelog

All notable changes to Touchline are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.3.0] - 2026-11-13

A much more realistic match day, injuries that behave like football, and
the manager in charge of his own squad.

- New match engine. Midfields fight for the ball, attacks against defences
  make the chances, and every player is rated for the position he is
  playing: a centre-back up front or a winger at left-back is a real weakness.
- Tactics are trade-offs, not free bonuses: attacking mentality makes chances
  and leaves you open to counter-attacks; a high press wins the ball high,
  tires legs and invites balls in behind; a low block concedes shots but few
  good ones; short passing keeps the ball, direct play makes more (poorer)
  chances. Formation shape counts (numbers in each line).
- Real match numbers: about 2.6 goals, 11-12 shots, 4-5 corners, 11 fouls,
  two bookings and two offsides a side; possession, pass accuracy, tackles
  and offsides come from the play, not a dice roll. Saves, misses and blocks
  are described by how good the chance was.
- Computer managers chase games late, sit on leads, take off booked
  defenders and tired legs, and use five substitutions in three windows.
- Live matches are played a minute at a time. Stop them whenever you like
  (Changes) to make substitutions or change tactics; half-time and extra
  time changes, and the five-subs-in-three-windows rule, work as in real
  football. Players taken off cannot come back.
- Your team is yours: the assistant no longer makes substitutions or picks
  players unless you ask him to (Tactics, Assistant's Subs and Team
  Selection). Changing formation keeps your eleven and moves them into the
  new shape; an injury or ban fills only that player's place.
- Injuries: an injured player no longer plays on. Most knocks are run off;
  some players hobble on and can be replaced; the rest come off. A live
  match stops so you can choose the replacement (Settings, Stop When a
  Player Is Hurt). With no changes left, you play a man down.
- Injury risk depends on match fitness, tiredness, age, the press and the
  player's own body (some are injury-prone). Lay-offs are counted in days,
  from a few days for a dead leg to most of a season for a torn ACL.
  Recovery is faster with better medical facilities and a better physio, and
  players come back short of fitness and sharpness. Long injuries carry over
  the summer.
- Fitness recovers day by day, so two games in a week wear a squad down and
  rotation matters. A second yellow is a one-match ban; a straight red one
  to three matches.

## [2.2.0] - 2026-11-12

- After every match the day finishes where it was played: home offers
  Continue to the next match day instead of jumping straight to Play.
- Full time is three screens: the report (a new scoreboard with each side's
  scorers, Match Facts with goals, cards, injuries and substitutions in order,
  ratings and stats), then Player of the Match, then the other results and
  the table. The press conference and momentum chart are gone.
- The crowd cheers a win and boos a defeat after simulated matches too.
- Full club names everywhere: no three-letter codes on screens, in
  commentary or on crests, and club creation no longer asks for one.
- Much smaller home tiles, five to a row.

## [2.1.0] - 2026-11-12

Touchline is GridironFC 1.6.0, unchanged in play, with:

- A new teal, coral and gold colour theme and a new app icon.
- New default names: Harbour Town (Quayside Park, Bristol) and Sam Carter.
- Real stadium crowd sound recorded at football grounds: the crowd bed is
  chosen by stadium size and the home fans roar, groan, "ooh", boo, applaud
  and sing as the match unfolds. Settings, Crowd and Haptics.
- Haptics for goals, cards, saves and the woodwork.
- Every league plays its real number of matches: 38 in the Scottish
  Premiership, 34 in MLS, 36 in the HNL, 46 in the EFL, with midweek rounds
  so seasons still finish in May.
- More domestic trophies: the EFL Cup, Scottish League Cup, Taça da Liga and
  J.League Cup; the EFL Trophy and Scottish Challenge Cup; and super cups
  such as the Community Shield, Supercopa and DFL-Supercup. Cups are played
  on midweek cup nights.
- A redesigned interface: a new main menu, larger home tiles, a bold next-match
  card, underlined tabs, rounded buttons and an abstract teal background.
- Crash tests on an iPhone simulator before every release.

## [1.6.0] - 2026-11-12

### Changed

- Home screens rebuilt as a short header, one line for the next match and a
  grid of small tiles. Every section opens its own screen; the manager tab
  bar is gone and the owner's pages are split into small screens.
- Smaller cards, buttons, tiles, event cards, titles and match headers
  throughout. The squad screen shows one section at a time.
- Continue now stops on match day so you can read the inbox first. The
  button then becomes "Play vs <club>" (manager) or "Watch vs <club>"
  (owner), with the competition underneath.
- Owners watch their club's matches live, without half-time changes.
- Sponsors now come to the club. Which partners will talk to you depends on
  division and reputation, and deals are priced for the division: a
  fourth-tier club no longer signs a global brand. You can pay an agency to
  look for one.
- Takeover bids arrive at the start of a season. Selling no longer ends the
  career: you choose an affordable club, and what is left becomes its cash.
- Every club has its own backroom staff of varying ability (older saves are
  fixed on load). Staff are hired from a monthly list of candidates pitched
  at the club's level; one-person roles replace the current holder.

### Fixed

- The same match being played again in manager mode: match day always
  selects today's fixture, the full-time screen forgets the finished match,
  and fixtures left behind in earlier weeks are played rather than staying
  "next" for ever.

## [1.5.0] - 2026-11-10

### Changed

- Squads for 732 of 802 clubs rebuilt from Wikipedia's current first-team
  lists; second-tier line-ups set to 2026-27.
- Lineup pitch rebuilt as rows of cards with a bench strip.
- Player profile rebuilt as General / Attributes / Contract / Details tabs.
- Main menu redesigned.

### Added

- Six leagues: Eerste Divisie, TFF 1. Lig, 3. Liga, Brasileirão Série B,
  Swiss Challenge League, USL Championship.
- Datapack editor with import and export.
- Owner view of the manager's team; league table on the full-time screen.

## [1.4.0] - 2026-11-10

### Changed

- Club data updated to 2026-27 from Wikipedia: promotions and relegations
  in eleven leagues, seven new clubs, January and summer 2026 transfers,
  and new managers.
- VoiceOver lineups are plain ordered lists with announcements and rotor
  actions, instead of positioned pitch cards and lazy horizontal scrollers.

### Fixed

- Clubs could start (or end up) without a goalkeeper. Two keepers are now
  guaranteed at load, before AI matchdays, at season start and for old
  saves; AI clubs never sell their last two; auto-pick always fills the GK
  slot with a keeper or the best emergency stopper.

### Added

- Match rating (fitness, sharpness, form, morale) with a Settings toggle.
- About 80 more goal descriptions and moment-aware openers.
- Staff screen for managers; win bonus requests for owners.

## [1.3.0] - 2026-11-10

### Changed

- Lineups use text team-sheet cards (position played, rating, form arrow,
  surname, fitness bar) with a single VoiceOver sentence per player.
- Transfer market: Players (paged, sortable), Filters (rating, value, age,
  nationality, role, status, name) and Deals tabs.
- Negotiations: two pages with the other side's message and adjustable
  steppers for fee, wage and contract.
- Tactics: Tactics / Roles tabs, cyclers, capsule choices and role cards.
- Fixtures & Results is a team calendar of fixture cards.

### Added

- Negotiate on incoming bids: the buyer agrees, raises or walks away.
- 27 goal types and over 100 goal descriptions, chosen to suit the scorer,
  with separate pools for the match situation and crowd reaction.
- Club records (record crowd, biggest win, heaviest defeat) in the news and
  as an owner card.

## [1.2.0] - 2026-11-10

### Changed

- **Stadium theme** across the app (toggle in Settings): navy floodlit
  backdrop, capsule tabs and buttons, value pills, tiles, condensed titles.
  Native segmented controls and group boxes match it.
- **Manager home**: fixture calendar strip, money pills, shortcut tiles and
  a sticky Play / Continue button.
- **Match day** is a pre-match zone with Info / Team / Opponent tabs and
  1 / X / 2 prices.
- **Live match** has Pitch / Commentary / Stats / Lineups tabs, club-coloured
  goal cards and a capsule control bar.
- **Full time**: Match MVP spotlight card.
- **Messages** grouped by day with NEW badges; **transfer market** header.
- **Owner boardroom**: chairman-style event cards, weekly financial report,
  sticky Continue. **Facilities** are illustrated upgrade cards.

### Added

- League **leaderboards** (goals, assists, ratings).
- **The Terrace** social feed, built from the season's results, transfers and
  awards (nothing extra is saved).

## [2.3.0] - 2026-11-13

### Fixed

- **The training ground did nothing** — it now gives young players an
  extra chance to develop (and a poor one holds them back). Clubs start
  with facilities that match their stature instead of all at level 2.

- **A benched or reserve player could not be brought back into the side**
  — only starter/substitute swaps were possible.

- **Players overlapped on the squad pitch** — the goalkeeper sat on top of
  the centre-backs and paired players drifted to one side. Rows are now
  spaced clearly and paired players sit symmetrically.
- **xG was nearly double the real chances** (11 shots could show 3.8 xG).
  Reported xG is now each chance's actual scoring probability, so over a
  season total xG closely matches goals.

- **"Make Transfer Bid" did nothing** — the player profile is pushed on a
  navigation stack, and the button switched the screen underneath it. The
  negotiation now opens as a sheet over the profile.
- **Accepting a counter-offer or meeting a wage demand did nothing visible**
  — it waited a week, went back through the selling club and could still
  fall through. The deal now completes on the spot, and settled inbox
  messages show how the deal ended.
- **Europe was never played by the manager** — European ties were simulated
  in the background. Your ties are now midweek match days after the
  weekend's league game, and the competition uses your real result.
  European rounds follow the UEFA calendar (league phase September to
  January, two-legged knockouts from February, final in May) instead of
  every week from mid-August.

- **Bids for your players almost never arrived** — the bidding club was
  picked at random from every club in the world before checking it could
  afford the player. Bids now come from clubs that can pay and would use him.

- **Saves used ~50 MB each** — saves are now compressed (LZFSE), other
  clubs keep only their last six results instead of a copy of every match,
  and archived results no longer store empty stat blocks. A one-season
  career save drops from about 53 MB to about 7 MB on disk. Older saves
  still load and shrink the next time they are saved.

- **Promoted clubs were paid prize money at their new division's rates**
  (and told they had finished in the division they were promoted to).
  Merit money now uses the division the season was played in.
- **AI clubs could sink to -£100M with no consequence** — clubs deep in
  debt now sell their most valuable players in the summer. Clubs sitting on
  more than a year's turnover see part of the excess leave (dividends, debt
  service, infrastructure) instead of hoarding billions.
- **Squads and veterans vanished over long careers** — AI squads were only
  topped up to 18 players, and no AI club ever renewed a player over 31,
  so the world lost a fifth of its players and almost every veteran in four
  seasons, inflating average ratings. Squads are now kept around 22, good
  veterans get one-year deals, and the free-agent market stays stocked.
- **Young players nearly always hit their potential** — growth from 20 to
  25 is slower and less certain, so world ratings stay stable over a
  ten-season career.
- **AI selection ignored players out of their exact position** — a left
  winger could never play left midfield. Selection now weighs position fit
  against ability, and loans only go to clubs where the player would start
  in his position.

- **AI clubs never changed their line-up** — an AI side only replaced a
  starter who was injured or exhausted, so new signings, loanees and
  players back from injury could sit out a whole season. AI managers now
  pick their best available XI before every match.
- **Gate receipts paid two to four times too much** — every home game
  was priced from full capacity and ticket price rather than the club's
  calibrated matchday income, so clubs banked tens of millions a season
  and balances inflated without limit. Gates now swing around the real
  figure with the size of the crowd the visitors draw; stadium expansions
  scale matchday income proportionally.
- **Hardly any transfers between AI clubs** — about one deal every three
  weeks across the whole world, so talent never moved and money piled up.
- **"Recent transfers" showed the oldest deals** in the save, not the latest.
- End-of-season settlement (prize money, promotion, awards) can no longer
  run twice.

- **Crash after your own match** — the user's fixture was simulated through an
  `inout` reference into `season.fixtures`, while post-match hooks (board
  confidence, owner milestones, news) read `season`. That is a Swift
  exclusivity violation that traps at runtime. Fixtures are now simulated via
  `GameState.simulateFixture(id:)`, which works on a copy.
- **League One never played a match** — the bundled League One has 23 clubs
  and the fixture generator returned no fixtures for odd-sized leagues. Odd
  leagues now get a full double round-robin with one club resting each week,
  and the calendar runs the normal weekly upkeep during a user bye week.
- **No fouls against fast-tempo sides** — with a fast tempo the free-kick band
  overlapped the fixed foul ceiling, so opponents never committed a foul or
  received a card. Event bands are now cumulative.
- **Live replay hid stoppage-time goals** — the replay stopped at 90' while the
  engine plays stoppage time, so late goals never reached the live scoreboard.
- **Starting a second career corrupted the first** — tapping a mode card on the
  main menu switched the live career's mode immediately (even if you backed
  out), and a new career reused the old world, leaving the old club flagged as
  yours. New careers now start from a fresh world after a confirmation, and a
  career-less world is never written over your autosave.
- **Unreadable autosave was silently overwritten** — it is now moved aside to
  `autosave.json.corrupt` instead.
- **Negotiation sliders could not reach the asking price** — the fee and wage
  sliders now always extend past the seller's counter and the player's demand.
- **Stale transfer actions** — AI bids for your players now expire after three
  weeks, finished offers can no longer be accepted again from old inbox mail,
  and leaving a club withdraws its live negotiations.

- **Save files ballooned to hundreds of MB** — every match in the world kept
  its full commentary and player ratings, stored three times. A save grew by
  ~7 MB per week (~350 MB per season) and each autosave blocked the UI for
  several seconds. Matches the user did not play are now archived compactly
  (end-of-season save ~58 MB), older bloated saves are compacted on load, and
  autosaves are encoded on a background queue from a copy-on-write snapshot.
- **Wrong final league table** — between the last matchweek and "Start New
  Season", tables mixed in promoted/relegated clubs' results from the division
  they had just left. Tables are now built from the division's own fixtures.
- **Transfer fees were not real money** — they only moved the transfer
  allowance; they now come out of (and go into) the clubs' bank balances.
- **Lower-league economy** — League Two players were on the £500 minimum
  wage while tickets were priced like the top flight; both rebalanced.
- **Clubs unable to sign anyone** — 78 clubs, including every League Two
  club, started over their wage budget. Clubs now keep wage headroom.
- **Stuck unemployed** — after a second sacking a manager could receive no
  job offers at all; the smallest clubs now always remain an option.
- **Results ignored team quality** — favourites barely won more often than
  underdogs, mid-table sides won titles and lower-division clubs won most
  cups. The engine was retuned over full simulated seasons: home/draw/away is
  now about 48/22/30, clear favourites win about three times in four, and
  the strongest squads usually contend for the title.
- **European seeding** could hand Rangers' place to Queens Park Rangers.
- **Duplicated player names** ("Nacho Nacho Ferri") fixed for 920 players.
- **Unrealistic discipline stats** — matches averaged 3 fouls and 1 booking;
  they now average around 20 fouls and 3 bookings.
- Owner careers no longer have to tap through a dozen idle weeks while longer
  leagues abroad finish their season.

### Added

- **Getting started** — short tips for each career mode on the dashboard
  and in the Boardroom, dismissed one at a time or all at once.
- **Redesigned main menu and live match** — a floodlit-pitch title screen
  with a club-coloured Continue card; the live match has a club-coloured
  scoreboard and clock, a GOAL! banner with scorer and assist, a styled
  event feed and a speed control.

- **Owner: how you compare** — your training ground, academy, medical
  department, stadium and wage bill ranked against your division.
- **Owner: this week's money** — a typical week's income and costs, the
  forecast end-of-season balance and plain-English advice.
- **Owner: club identity** — rename the stadium and choose the club's
  colours.

- **Achievements** — 27 career goals across both modes (first win, derby
  wins, giant killings, unbeaten runs, titles, doubles and trebles,
  invincibles, record signings and sales, club legends, a billion-pound
  valuation and more), with a tab in Club History.
- **Player career history** — season-by-season club, appearances, goals,
  assists and rating, with a progression chart on the player profile.

- **Press conferences** — after each match, answer the press by praising
  the players, demanding more or keeping it calm, with effects on morale
  and the board.
- **Owner: fans turn on the manager** — after a bad run, back him publicly,
  issue an ultimatum or stay quiet; each choice moves the manager's mood
  and the supporters'.
- **Owner: why the fans feel the way they do** — the Boardroom shows the
  supporters' mood and the main reasons behind it.
- **Loans with an option or obligation to buy** — sign a borrowed player
  permanently at the agreed fee during the loan, or commit to buying him
  when it ends. AI clubs use options too.
- **Captain and set-piece takers** in Tactics.
- **Scouted potential** — your players' ceiling is exact; for others a
  range that narrows with your best scout.

- **New Squad screen** — a club-coloured header with formation picker and
  a Best XI button; tap any player then another to swap them, so starters
  can swap positions (left back for right back), and starters, substitutes
  and reserves can trade places in any direction; the bench and reserves
  are horizontal cards with rating, position and fitness; the full squad
  is grouped by position.
- **Lineup for this match only** — change the side on Match Day; your
  usual lineup returns after the final whistle (or keep the changes).
- **Calendar pauses for important mail** — bids, loan requests, board
  messages, contracts and injuries open in a window and the calendar
  carries on when you close it (Settings can turn this off).
- **Redesigned full-time report and match day** — club-coloured
  scoreboard, every goal with scorer, assist and how it was scored, cards
  and injuries, your player ratings, split stat bars, and the other results
  behind an Elsewhere button.

- **Owner: manager contracts and personalities** — candidates have an age
  and a personality (Ambitious, Loyal, Demanding, Level-headed) that sets
  how easily they are poached, how they react to refusals and when they
  walk out. Appoint on a 1-4 year contract: sacking costs half the wages
  left, a poaching club pays the rest of the contract, and an expired deal
  must be renewed (at a raise) by the end of September or he leaves.

- **Club History & Trophies** — a trophy cabinet, a Hall of Fame of the
  club's greatest players (appearances and goals across seasons), the roll
  of honour of every league, cup and European competition with runners-up,
  and end-of-season world awards: World Player of the Year, Young Player of
  the Year, Goalkeeper of the Year and the European Golden Shoe.
- **Pre-match odds** — win/draw/loss chances and prices on the match
  preview, fitted to the match engine over a full simulated season.
- **Match momentum chart** — who was on top in each five-minute spell, with
  goals marked, after every match.
- **Transfer shortlist** — star players from their profile to track them in
  the Transfer hub.

- **Animated calendar** — Continue shows the days ticking by on a week
  strip with your league's results and news as they happen, then match
  day. Skip jumps straight there; can be turned off in Settings.

- **Transfer status and releases** — mark a player Available, Not for Sale,
  Transfer Listed or Loan Listed: listed players attract bids and loan
  requests, untouchables are left alone. Release a player by mutual
  consent for half the wages left on his deal.

- **Storage in Settings** — see how much space your saves use and delete
  backups of unreadable saves.

- **Wonderkids** — about one academy graduate in twenty-five has a
  ceiling far above his first-team level, so new stars keep emerging as
  the current generation ages.
- **Owner: selling stars costs goodwill** — accepting a bid for a
  first-team regular angers supporters (much more if he joins a rival)
  and frustrates the manager.
- **Loan candidates filter** in the transfer market search.

- **Loan requests** — clubs ask to borrow a manager's young players who
  are not making the matchday squad; agree or decline from the inbox.

- **Loans** — loan players out to clubs where they will start (the club
  covers an agreed share of the wage), borrow young or fringe players from
  other clubs by offering 50/75/100% of their wages, recall your loanees
  or send borrowed players back while a window is open. AI clubs farm out
  prospects too. Loanees return every summer, and young players who played
  regularly come back better. An "Out on Loan" panel tracks your players.
- **A living transfer market** — every window, AI clubs try to upgrade
  their weakest starter: big clubs scout the elite, regulars are only sold
  to bigger clubs at a premium, rivals never deal, players signed this
  window are not flipped, and agents take their cut. Around 600 permanent
  deals a season, with record fees in the news.
- **Transfer hub feed** — this season's latest deals, record fees and loans
  from around the world.
- **Owner: sign-off on big sales** — bids for first-team regulars come to
  the owner's inbox to accept or reject instead of being completed by the
  manager.
- **Owner: recruitment policy** — Win Now, Balanced or Youth, which sets
  the age, upgrade size and potential the manager looks for.

- **Owner: the business of running a club** — a Business tab with the club's
  valuation (tracked since you founded it), your personal wealth and
  investment, a season profit-and-loss account, bank loans with weekly
  repayments, stadium naming rights, and a spending limit above which your
  manager must ask you first.
- **Owner: manager relationship** — your manager requests funds for big
  signings; refusals sour the relationship and he may resign. Successful
  managers get poached by bigger clubs, who pay compensation.
- **Owner: administration** — ten weeks overdrawn puts the club into
  administration: a 12-point deduction (10 outside England), a transfer
  embargo and forced sales of your best players.
- **Owner: takeovers** — growing clubs attract bids; selling ends your
  tenure with a summary.
- **Owner: new stadium** — a year-long build with progress in the Boardroom.
- **Coaching matters (both modes)** — your coaching ability (manager mode) or
  your appointed manager's quality (owner mode) gives the club a small edge or
  handicap in matches. A manager's coaching grows season by season.
- **Board targets (manager mode)** — set from where the club ranks in its
  division and shown on the dashboard; beat the target for a transfer bonus,
  miss it badly and you may be sacked in the summer.
- **Owner mode** — a League tab and Fixtures & Results; the appointed manager
  signs players with your transfer allocation; a fresh manager shortlist each
  season; ticket pricing that trades gate income against fan goodwill, fan
  protests and praise.
- **Season review** — an end-of-season summary card in both careers.
- **Derbies and rivalries** — 243 real rivalries (North London Derby, El
  Clásico, Old Firm, Superclásico, Revierderby...). Derbies are fiercer and
  less predictable (about 3.9 cards a game against 2.4), sell out at premium
  prices, and swing squad morale, board confidence and fan mood. Rivals refuse
  to sell to each other and never bid for each other's players.
- **European places on merit** — from the second season, Champions League,
  Europa League and Conference League places come from final league positions
  and domestic cup wins, with UEFA clubs only and spare places spread across
  countries.
- **Contracts expire** — your unrenewed players leave on free transfers
  (with a January reminder); other clubs renew the players they value and
  release the rest.
- **Sackings** — the board sacks a manager whose confidence collapses during
  a winless run; other clubs' offers follow. AI clubs change managers after
  disappointing seasons, opening up vacancies.
- **Playing-time complaints** — established players who are rarely picked
  lose morale and say so in January.
- **Fixtures & Results** — upcoming league and cup fixtures and past results
  with opponent names and crests (the old list never named the opponent).
- **Match Day scouting report** — both starting XIs, table positions, form,
  the opponent's danger man and a bookmakers' verdict.
- **Real club identities** — common names, 3-letter codes, home cities and
  real colours for every club, and reputations derived from squad strength,
  stadium size and history. Previously 31 of 34 leagues gave every club the
  same green-and-white kit, the same reputation and its own name as its city.
- **Accurate 2025-26 divisions** — Port Vale added to League One; League Two
  corrected (Crawley Town, MK Dons and Walsall in; Carlisle, Morecambe and a
  duplicate Doncaster out).
- **Five new divisions** — Segunda División, Serie B, 2. Bundesliga, Ligue 2
  and the Scottish Championship, with promotion and relegation. 39 leagues and
  688 clubs in all.
- **Domestic cups** for every country — FA Cup, Copa del Rey, Coppa Italia,
  DFB-Pokal, Coupe de France, Scottish Cup and more. Single-match knockouts
  with extra time and penalties, seeded byes, a fresh draw each round, prize
  money, giant-killings and cup honours. Browse them from the League tab.
- **Transfer windows** — clubs trade players in the summer and January
  windows only; free agents can be signed at any time.
- **Season awards** — Golden Boot and Player of the Season for every top
  flight and your own division.
- **Local names for generated players** — generated squads, academy intakes
  and regens use nationality-appropriate names.
- **League table overhaul** — zone colours (champions, Europe, promotion,
  play-offs, relegation) with a legend, last-five form guide, crests, and a
  picker to browse every league in the game.
- **Dashboard** — the next-match card shows both clubs' league position and
  form, and the league card has a season progress bar.
- **Squad turnover** — AI clubs promote their best academy graduates and
  release surplus veterans each summer; the free-agent pool is capped.
- **Load and delete saves** — the manual save slots (and the autosave) can now
  be loaded from Settings & Saves; previously they could only be written.
- **Player development, decline and retirement** — each summer young players
  grow toward their potential (faster with regular football), peak-age players
  hold steady, veterans decline, values are re-rated, and players retire in
  their mid-thirties. Clubs are topped back up with young players, and the
  free-agent pool ages and refreshes.

### Changed

- Five tabs instead of six (iOS hid Transfers behind a "More" tab); News and
  Training are in the menu. The dashboard drops the button grid that
  duplicated the tab bar and folds budgets into the club header.
- The board writes to your inbox only when its stance changes, and awards and
  managerial changes are reported only for leagues you follow.
- CI builds on macOS 26 runners with the newest Xcode available (26.6, iOS
  26.5 SDK); builds on the retiring macOS 14 image were being cancelled
  before they started. The newest installed Xcode is picked automatically.

- Faster week simulation: fixtures due by date are found with string date
  comparison, and weekly gate receipts no longer rescan every fixture per club.
- Saves are written as compact JSON, and the app saves once on backgrounding
  instead of on every transient `inactive` transition.
- AI clubs only dip into free agency when their squad is genuinely thin, so
  the free-agent market is no longer emptied in the first week.

## [0.3.0] - 2026-10-20

### Added

- **International management** — take charge of one of 85 national teams
  assembled from real club players by nationality, each with confederation,
  FIFA ranking and coach metadata. The **International** hub (overflow menu)
  shows your nation, squad and the tournaments you are contesting.
- **International tournaments** — the FIFA World Cup plus the EURO, Copa
  América, Africa Cup of Nations and Asian Cup. Each is drawn into groups and
  played out through a knockout bracket, simulated alongside your club season.
- **Rich Latest News feed** — a dedicated **News** tab with category filters,
  full stories and unread state. The Inbox (mail) now lives on the Home screen
  with an unread badge.
- **More formations and meaningful tactics** — ten additional formations, and
  pressing, tempo, width and passing are now sliders that genuinely influence
  possession, chance creation and defensive solidity in the match engine.
- **Match playback settings** — choose replay speed (Slow → Very Fast) and
  pause at half-time for substitutions.
- **Assistant-manager auto-substitutions** — configurable timing (off,
  half-time, second half, throughout) and rotation aggression.
- **Squad edit mode** — tap a player to open their profile as normal, or switch
  on Edit Squad to highlight and swap players for substitutions.

### Changed

- Transfer search is now **filter-then-search**: set your filters and tap
  Search Market. Free agents are hidden unless the Include Free Agents filter
  is switched on.
- The **More options** menu now appears only on the Home screen.
- Transfer and wage budgets are read as separate VoiceOver values and now
  genuinely constrain signings.
- Duplicate players are removed at load (cross-club, by name and age).
- Only file-driven leagues appear; authored non-English lower tiers were
  dropped while the English pyramid remains as a procedural fallback.

### Removed

- **All emojis** — event icons now use SF Symbols and flags render as
  three-letter country codes.

## [2.3.0] - 2026-11-13

### Added

- **Contract renewals** — offer new deals to players entering the final years
  of their contracts directly from their profile. Renewals show the player's
  expected wage and let you choose the length, with board wage-budget validation,
  a confirmed contract update and a squad warning listing expiring deals.
- **Career resignation flow** — managers can now resign from My Profile and
  immediately enter the vacancy market while retaining their career history.
- **Manager pressure and match psychology** — the board now tracks confidence,
  winless runs and job status after every user result. Choose a pre-match team
  talk (calm, fired up, rally, demand more or protect) and see its temporary
  morale/readiness effect applied when the match starts.
- **Owner commercial control** — owners can set a transfer-versus-wage funding
  direction and sign up to three reputation-scaled sponsorship partnerships.
  Deals contribute recurring commercial income instead of granting free cash.
- **More credible deal data** — transfer offers now safely preserve staged
  payments, sell-on clauses and add-ons, including in older saved careers.
- **Clearer VoiceOver match flow** — the visual pitch identifies itself as
  decorative and directs VoiceOver users to the live commentary feed; manager
  readiness announces board confidence alongside squad availability.

- **Manager command centre** — Home now surfaces live starting-XI readiness,
  direct operational controls and a dedicated Training Ground. One focused
  session per matchweek lets managers trade between fitness, sharpness, morale
  and balanced preparation.
- **Meaningful owner interventions** — legacy points can now fund recruitment,
  infrastructure or supporter initiatives, with each board decision changing
  club resources, confidence or reputation without taking football decisions
  away from the appointed manager.
- **Verified release delivery** — each GitHub release now contains a signed
  checksum manifest alongside the IPA. `tools/Push-And-FetchIPA.ps1` waits for
  the matching release workflow, validates the downloaded IPA payload and
  checksum, then saves it as `Touchline.ipa` at the local project root.
- **Role-first career hubs** — manager careers now open with a compact Manager
  HQ and owner careers gain a full Boardroom HQ, club-health metrics, board
  inbox/tools, clearer capital-project context, and an editable club vision.
- **Decision-ready ownership UI** — manager candidates are now presented as
  readable cards with reputation, style and weekly salary announced to
  VoiceOver; appointments and staff offers include explicit action hints.
- **Reliable manager shortcuts** — dashboard links for News, Squad, Tactics,
  League and Transfers now select the intended destination instead of falling
  back to Home.
- **Safer club founding** — club creation validates all required identity and
  colour fields and handles a missing replacement club without crashing.

- **Realistic, multi-week transfer negotiations** — bids are no longer resolved
  instantly. Selling clubs respond over the following weeks, either accepting,
  rejecting, or issuing a **counter-offer** with a specific asking price. Free
  agents negotiate personal terms, and players can hold out for a higher wage.
- **Negotiations run through your inbox** — every offer, counter and rejection
  arrives as actionable mail. Accept a counter, raise your bid, pay a player's
  wage demand, or withdraw, all directly from the message. Your Inbox tab and
  the Transfer Hub both surface outstanding negotiations.
- **AI clubs bid for your players** — rival clubs now make offers for members of
  your squad, which you can accept, reject, or reject-and-hold from the inbox.
- **Smarter valuations** — asking prices account for contract length, the gap in
  stature between clubs, and young high-potential talent. Sell-on clauses now
  pay the player's former club a share of future fees.

- **Youth academy** — every club now runs a youth academy. Prospects (aged
  15-18) develop toward their potential each season and a new intake arrives
  every summer, with quality scaling by academy level, reputation and division.
  Promote standouts to the senior squad or release them from the new
  **Youth Academy** screen (overflow menu).
- **Manager inbox** — correspondence is now addressed to the manager, with a
  sender on every message (The Board, Chief Scout, Head of Youth Development,
  Club Secretary). New **Board & Management** category, per-message read state,
  an unread filter, a "Mark All Read" action, and an unread badge on the Inbox
  tab. Taking over a club seeds a welcome letter and season objectives.

### Removed

- **Create a Player** career mode has been removed to keep the game focused on
  club management.

- **European competitions** — the UEFA Champions League, Europa League and
  Conference League now run in-game with their modern format: a single-table
  league phase (36 clubs, 8 matches each; 32/6 for the Conference League),
  followed by a two-legged knockout play-off, Round of 16, Quarter-Finals,
  Semi-Finals and a single-match Final. Real participant clubs are seeded from
  the dataset and padded with the strongest remaining top-flight clubs.
  View tables and your own fixtures from the overflow menu under
  **European Competitions**.

- **Real-world data import** — the world is now populated from a real
  Transfermarkt dataset (club names, stadiums, capacities, coaches, and full
  squads with real player names, ages, nationalities, positions, and feet).
  Player ratings are derived from real market values and age. The world now spans
  **31 countries** and **40 divisions**, all playable offline.
- **31 playable top flights** — England, Spain, Italy, Germany, France, Portugal,
  Netherlands, Türkiye, Scotland, Belgium, Argentina, Australia, Austria, Brazil,
  Croatia, Czech Republic, Denmark, Greece, Japan, South Korea, Mexico, Norway,
  Poland, Romania, Russia, Saudi Arabia, Serbia, Sweden, Switzerland, Ukraine, and
  the United States — each with its real clubs and squads (~14,500 real players).
- **Country × division grid** — leagues are modelled as a country with up to four
  divisions and a stable index structure; lower divisions (England 2-4, Spain 2-4,
  Italy 2, Germany 2, France 2) carry authored club metadata with procedurally
  generated squads pending a lower-league data source.

> **Accuracy note:** Squad data reflects a recent-season snapshot, not the exact
> 2026-27 rosters; some players may appear at a former club and ages are projected.
> All crests and faces remain procedurally generated.

- **European top flights** — four new fully playable leagues: **La Liga**, **Serie A**,
  **Bundesliga**, and **Ligue 1**, each with real clubs and real players bundled as
  offline JSON (`tier5`–`tier8`). Together with the English pyramid the world now spans
  **five countries and eight divisions** (~2,200 additional players).
- **Country & division structure** — leagues now carry a country grouping; the four
  English divisions keep their promotion/relegation pyramid while the continental
  top flights are standalone leagues. European qualification slots are modelled per
  league (5 for the Premier League, 4 for the continental top flights).

> **Accuracy note:** European club and player data reflects recent squads and is
> provided for identification only; some squad members and ages will be out of date
> relative to the 2026-27 season. All crests and faces remain procedurally generated.

- **Manager customisation** — every career now begins by creating your manager:
  name, nationality, age, and four allocatable coaching attributes, with a
  procedurally generated avatar. Your profile tracks reputation, a coaching
  attribute card, and a season-by-season career history (positions, records,
  honours).
- **Job offers & managerial mobility** — clubs approach you with vacancies, from
  your inbox and a dedicated Job Offers screen (overflow menu). Accept to switch
  clubs (ending a current stint) or decline. Reputation drifts with results.
- **Player of the Match** — the full-time recap now names the match's best player
  with their club and rating before the other details.
- **My Profile / Job Offers** added to the in-game overflow menu.
- **Transfer market search** — filter the market by position, minimum rating, and
  maximum age; sort by rating, value, age, or name; option to include free agents.
- **Inbox tab** — the news inbox is now a first-class tab, seeded with board
  objectives, transfer-window and free-agent scouting messages when you take over.
- **Post-match league results** — the full-time recap now lists every other
  result from the same matchweek.
- **Close/Done buttons** — Settings, Inbox, and Match History can be dismissed
  back to the dashboard.

### Changed

- **Safer world simulation** — fixture generation now handles incomplete league
  data without indexing an empty schedule, and job-offer generation safely
  normalises invalid request limits.
- **Calendar-driven progression** — the dashboard *Continue* button now advances
  day by day to your next fixture (simulating other clubs' matches as it goes)
  instead of requiring a separate *Prepare for Match* step, which was removed.
- **Match engine balance** — possession is now clamped to a realistic 32–68%
  range and chance frequency/conversion retuned for more realistic scorelines,
  with scoring throttled once a side builds a multi-goal lead.

### Fixed

- **Set-piece and penalty goals** — goals from corners, free kicks and in-match
  penalties now register as goals in the scoreline, live commentary, post-match
  timeline and goal sound. Penalties are also resolved independently of the card
  decision and contribute to shots, xG, shots on target and saves.
- **Match fitness and sharpness** — a player's persistent match fitness and
  sharpness now affect their effective ability, so returning from injury or a
  long lay-off has a real performance cost.
- **Injury selection** — substituted-off players can no longer be picked for a
  new in-match injury.
- **Attendance and gate income** — attendance now uses the home club's usual
  attendance rate and the away club's reputation instead of a flat random fill.
- **Full-time and shootouts** — the full-time event reports the actual final
  minute (including stoppage/extra time), and penalty shootouts clinch as soon
  as the result is decided rather than always running to a fixed round.
- **Sell-on clauses** — contracts now remember the former club entitled to a
  sell-on share, so future transfers actually pay that club instead of comparing
  the seller against itself.
- **Transfer finances** — signings revalidate the buyer's transfer and wage
  budgets at completion, AI clubs respect wage limits, and promotion or
  relegation preserves each club's real reputation and stadium capacity when
  recalculating its finances.
- **Transfer negotiations** — counter-offers are no longer overwritten by stale
  state, unanswered counters and wage demands expire instead of auto-resolving,
  revised free-agent wage offers route back to the player, duplicate bids are
  blocked while a club is considering an offer, and the negotiation screen can
  always be dismissed after submitting a bid.
- **Inbox and actions** — opening the Inbox no longer marks every message read,
  so unread badges and filters work; accepting a job or taking over a club now
  only navigates away when the action succeeded.
- **Squad tap-to-substitute** — tapping a bench player and a starter now swaps
  them correctly via the new `swapIntoStartingXI` helper.
- **Full league simulation** — other clubs' fixtures are now simulated through
  the matchweek after your match, so standings no longer stall.
- **Multi-season rollover** — end-of-season now transitions correctly, and the
  dashboard offers *Start New Season* once the campaign is complete.
- **Sound effects** — goal/win/draw/loss/whistle/click cues are now synthesised
  as in-memory WAV tones (previous system-sound approach was unreliable).

## [0.1.0] - 2026-10-20

First public build of Touchline. Ships as an **unsigned `.ipa`** for sideloading
with a tool such as Feather (re-sign with your own certificate).

### Added

- **Three career modes**
  - *Create a Club* — define a name, stadium, city, and kit colours, then replace a League Two side.
  - *Manage Existing Club* — take charge of any of the 92 clubs across the four English divisions.
  - *Create a Player* — build a custom player, assign a starting club, and follow their career.
- **English football pyramid** — 92 real clubs and 2,208 real players across four tiers
  (Premier League, Championship, League One, League Two), bundled as offline JSON.
- **Deep player simulation** — 30+ technical, physical, mental, and goalkeeping attributes
  generated from position-specific templates with randomised variance.
- **Minute-by-minute match engine** — possession, shots, xG, fouls, cards, injuries,
  fatigue, and dynamic commentary with player ratings (1.0–10.0).
- **Position-cam match replay** — top-down animated pitch with 22 interpolated player
  dots and the ball, replaying each minute of the match.
- **Procedural faces and crests** — every player portrait and club badge is generated
  deterministically from a stable seed. No real likenesses or trademarked imagery.
- **Transfer market** — bid for players at other clubs or sign free agents, with budget,
  wage, and valuation checks resolved by the selling club.
- **Season progression** — promotions, relegations (Premier League ↔ Championship ↔
  League One ↔ League Two) and four-team play-offs each season.
- **VoiceOver-first accessibility** — combined elements, custom rotor actions, spoken
  match-event announcements, and Dynamic Type scaling up to `.accessibility3`.
- **Persistence** — multi-slot and autosave JSON saves in the app's Documents container.
  Zero external dependencies or network calls.

### Notes

- Signed release: **no** — build is intentionally unsigned for side-loading.
- Internal app version (`CFBundleShortVersionString`): `0.1.0`.
- Minimum iOS version: `17.0`.

[0.1.0]: https://github.com/GOONERS-LLC/touchline/releases/tag/v0.1.0
