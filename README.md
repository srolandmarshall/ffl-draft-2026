# Fantasy football draft app

A shared fantasy-football snake draft room built with Rails 8. Commissioners maintain leagues, teams, draft order, and the player pool in an in-app admin area. Managers open one draft URL, select their team, and draft without accounts during the MVP phase.

## What works

- League and team administration
- Manual player management and idempotent CSV imports
- Shareable, unguessable draft URLs
- Browser-session team selection
- Transactional server-side snake-order enforcement
- Live room refreshes with Turbo Streams
- ESPN-oriented roster CSV and structured JSON exports
- Responsive commissioner and draft-room UI

## Run locally

Ruby 3.4.2 and SQLite are expected.

```sh
bundle install
bin/rails db:prepare
bin/rails db:seed
bin/dev
```

Open `http://localhost:52477`. The seed task creates a demo league and teams. Populate the current player pool from Admin → Players → Sync ESPN player pool, then use Refresh rankings to order it.

The first email entered in a fresh database becomes a commissioner. Commissioners can create leagues and drafts, choose team count, snake or linear order, pick clock, PPR scoring, and roster slots, then assign one or more email addresses to every team. Additional commissioners can be promoted from Admin → Users. Team managers enter an assigned email to open their draft room; there is intentionally no password or email verification in this lightweight local workflow.

Player ordering uses the free [LeagueLogs API](https://developer.leaguelogs.com/docs) redraft market rankings and displays its required attribution. Ranking providers implement a shared strategy interface; set `PLAYER_RANKINGS_SOURCE=fantasy_football_calculator` to switch back to the Fantasy Football Calculator strategy. The ESPN player sync follows the read-only endpoint and identifier mappings documented by the MIT-licensed [cwendt94/espn-api](https://github.com/cwendt94/espn-api) project. ESPN does not publish or support these fantasy endpoints, so that integration is deliberately isolated behind an adapter.

## Player CSV format

Required headers:

```csv
name,position,pro_team
Alex Example,QB,BUF
```

Optional headers are `espn_id`, `bye_week`, and `active`. When `espn_id` is present, subsequent imports update that record. Otherwise, name + NFL team + position forms the natural key. Valid positions are `QB`, `RB`, `WR`, `TE`, `K`, and `DST`.

## ESPN handoff

ESPN currently documents offline-draft roster entry for League Manager leagues but does not publish a supported bulk results-import API. The CSV export is therefore a commissioner-friendly roster worksheet containing team, owner, roster slot, player identity, ESPN ID, round, and overall pick. JSON exposes the same data behind a stable adapter boundary for a future supported API or browser-assisted importer.

In ESPN, configure the league as an offline draft, then use League Manager Tools → Input Offline Draft Results and enter each exported team roster before making rosters available.

## Architecture

`Drafts::MakePick` owns pick validation and progression inside a database lock. Controllers coordinate HTTP only; models hold associations, invariants, and snake-order queries; exporters and CSV importers are isolated service objects. Unique database indexes backstop the domain rules under concurrent requests.

## Verification

```sh
bin/rails test
bin/rubocop
bin/brakeman --no-pager
```

Run the opt-in browser rehearsal in Docker (the same command used by the manual GitHub Actions workflow):

```sh
bin/system-test
```

It runs Rails in one container and Chrome/Selenium in another, so it does not require a browser on the host. By default it simulates a 12-team, 16-round snake draft (192 picks); set `DRAFT_SIMULATION_TEAM_COUNT` and `DRAFT_SIMULATION_ROUNDS` to rehearse a different format.

Authentication, pick clocks, traded picks, keepers, roster-position validation, and a supported direct ESPN adapter are intentionally left as later increments.
