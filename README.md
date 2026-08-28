# ffl-draft

A live snake-draft room for a fantasy football league, built with Rails 8 and Hotwire. The commissioner sets up the league, teams, and roster rules in an admin area; managers sign in with an emailed code and draft together in a room that updates in real time for everyone.

The player pool, rankings, stats, headshots, and past-season draft history are pulled from ESPN, nflverse, and a rankings provider so the room has real data on draft night. Results export as a commissioner-friendly CSV for ESPN's offline-draft entry.

## Stack

| | |
|---|---|
| Ruby / Rails | 3.4.2 / 8.1 |
| Database | SQLite (app, plus Solid Cache / Queue / Cable schemas) |
| Views | Phlex components (`app/components`) with ERB layouts |
| Front end | Hotwire (Turbo Streams + Stimulus), import maps, Tailwind |
| Background jobs | Solid Queue (runs inside Puma in production) |
| Assets / uploads | Propshaft, Active Storage (local in dev, S3 in production) |
| Email | Resend |

## Quick start

```sh
cp .env.example .env   # then fill in the Resend and ESPN values
bundle install
bin/rails db:prepare
bin/rails db:seed
bin/dev
```

Open <http://localhost:52477>.

`db:seed` creates a league, its teams, a commissioner, and a live + test draft. Real league rosters are never committed, so a fresh clone gets ten placeholder teams with `example.com` addresses. To seed real data instead, drop a private JSON file at `db/seeds/*.json` (git-ignored) or point `SEED_DATA` at one; see the shape built by `placeholder_seed_data` in `db/seeds.rb`.

Then populate the player pool from the admin area:

1. **Admin → Players → Sync ESPN player pool** — imports the current player universe.
2. **Refresh rankings** — orders the pool from the rankings provider.
3. **Refresh actual stats** — pulls prior-season stats, rookie flags, and headshots from nflverse.

### Signing in locally

Sign-in sends a six-digit code by email through Resend, in development too, so `RESEND_API_KEY` must be set for the email to arrive. To skip email entirely, mint a code from the console after submitting your email on the sign-in page:

```sh
bin/rails runner 'puts User.find_by_any_email("you@example.com").issue_login_code!'
```

Only addresses assigned to a team — or a commissioner's address — may sign in. A user can hold several addresses (`user_emails`), so managers can sign in with whichever one they remember.

## How a draft works

**Roles.** Users are `member` or `commissioner`. Members reach only the drafts and league history for teams they belong to. Commissioners get the admin area, can pick on behalf of the team on the clock, undo picks, and control the timer.

**Setup.** A draft belongs to a league and carries its own copy of the rules: snake or linear order, PPR value, and per-position roster slots (QB/RB/WR/TE/FLEX/K/DST/bench). Round count is derived from the roster size while the draft is in `setup`. Draft order lives in `draft_entries`, and each draft gets an unguessable `public_id` for its URL.

**Lifecycle.** `setup → live → complete`. A commissioner starts the draft manually, or sets `scheduled_start_at` and `StartScheduledDraftJob` starts it at that time. Completing the last pick flips the draft to `complete` and enqueues `PrecomputeDraftFactsJob`.

**Making a pick.** `Drafts::MakePick` takes a row lock on the draft, re-reads picks and entries, then checks that the draft is live, the roster isn't full, it is that team's turn, the player is undrafted, and the player is active. Unique indexes on `(draft_id, overall_number)` and `(draft_id, player_id)` backstop those rules, so a simultaneous double-pick surfaces as "That player was just selected" rather than corrupt state. Each pick records its own `elapsed_seconds` and resets the clock.

**The clock.** Time on the current pick is computed from the last pick's timestamp, minus accumulated paused time. Commissioners can pause and resume; undoing a pick pauses the clock automatically.

**Live updates.** Committed picks, undos, and commissioner announcements broadcast targeted Turbo Stream updates (`Drafts::BroadcastPick`, `BroadcastUndoPick`, `BroadcastAnnouncement`) to every viewer. Controllers deliberately return `head :no_content` for the acting user so the room isn't re-rendered twice and made to flicker.

**Auto draft.** `Drafts::AutoDraft` runs an entire draft for rehearsals. It fills open starter slots in order, but picks from the top three eligible players with 60/25/15 weighting so the result looks like human drafting rather than a straight ranking dump.

**After the draft.** `Drafts::FactGenerator` produces up to twelve "facts" about the draft — position runs, hoarders, stacks, pace, longest deliberation — mixing current-draft observations with historical ones and caching by draft and completion time. `Drafts::HistoricalTendencies` summarizes imported ESPN seasons per franchise for the league history page.

## Data sources

Every external integration lives under `app/services/data_sources` behind its own client, so none of them leak into models or controllers.

**Rankings** (`Rankings::StrategyFactory`) resolve a strategy from `PLAYER_RANKINGS_SOURCE`. The default is the free [LeagueLogs API](https://developer.leaguelogs.com/docs) redraft market rankings, whose required attribution is displayed in-app; setting `PLAYER_RANKINGS_SOURCE=fantasy_football_calculator` switches to Fantasy Football Calculator, which derives its scoring format and team count from the league.

**ESPN** (`Espn::Client`) reads the league-manager endpoints for the player catalog, league settings, past-season drafts, and player scores. Identifier mappings follow the MIT-licensed [cwendt94/espn-api](https://github.com/cwendt94/espn-api) project. ESPN neither publishes nor supports these fantasy endpoints, which is exactly why the integration is isolated behind an adapter. Private-league reads need `ESPN_S2` and `ESPN_SWID` cookies; the admin ESPN connection screen accepts them per browser session instead of persisting them.

**nflverse** (`Nflverse::PlayerDataSync`) supplies prior-season stats, rookie flags, and headshot images, which are cached into Active Storage and served as generated portrait variants.

**CSV** (`Players::CsvImport`) covers manual pool edits and is idempotent. Required headers:

```csv
name,position,pro_team
Alex Example,QB,BUF
```

`espn_id`, `bye_week`, and `active` are optional. When `espn_id` is present it is the update key; otherwise name + pro team + position forms the natural key. Valid positions are `QB`, `RB`, `WR`, `TE`, `K`, and `DST`.

## Architecture

```
app/
  components/     Phlex components — the draft room, admin screens, shared UI
  controllers/    HTTP coordination only
  models/         associations, invariants, snake-order queries
  services/
    drafts/       MakePick, UndoPick, AutoDraft, broadcasts, facts, export
    data_sources/ espn/, nflverse/, league_logs/, rankings/ — one client per source
    players/      CSV import
  view_models/    DraftRoom and friends: assemble what a screen needs, once
  jobs/           scheduled starts, fact precomputation, headshot sync
```

The rules that must hold under concurrency live in one place — `Drafts::MakePick`, inside a lock, with unique indexes behind it. Controllers stay thin, models own invariants, and anything that talks to the network or produces a file is a service object. Screens get their data through a view model rather than a scatter of instance variables, which keeps the draft room's query count flat as it re-renders.

## Commands

```sh
bin/rails test          # full test suite
bin/rubocop             # rails-omakase styling
bin/brakeman --no-pager # static security analysis
bin/bundler-audit       # vulnerable gems
bin/importmap audit     # vulnerable JS
```

CI runs all five on every pull request and push to `main`.

Operational rake tasks:

```sh
bin/rails headshots:portrait_status      # how many headshots still need a variant
bin/rails headshots:enqueue_portraits    # queue variant generation
bin/rails headshots:verify               # find missing or truncated files
bin/rails headshots:repair               # re-download them
bin/rails storage:report                 # reclaimable space in the bucket
bin/rails storage:purge_orphans CONFIRM=yes
bin/rails storage:purge_superseded_variants CONFIRM=yes
```

`script/profile_draft_board.rb` and `script/profile_player_list.rb` profile the two hottest screens; findings live in `docs/`.

## Configuration

Copy `.env.example` to `.env` and fill it in; dotenv loads it in development and test only. Production values belong in the host's secret manager.

| Variable | Purpose |
|---|---|
| `RESEND_API_KEY`, `RESEND_FROM_EMAIL` | login-code delivery |
| `ESPN_S2`, `ESPN_SWID` | ESPN cookies for private-league reads |
| `PLAYER_RANKINGS_SOURCE` | `league_logs` (default) or `fantasy_football_calculator` |
| `APP_HOST` | canonical host for generated URLs |
| `S3_BUCKET`, `AWS_REGION`, `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `CDN_HOST` | Active Storage in production |
| `SOLID_QUEUE_IN_PUMA` | run background jobs inside the web process |
| `PORT`, `WEB_CONCURRENCY`, `RAILS_MAX_THREADS`, `JOB_CONCURRENCY` | server sizing |

## Deployment

`Dockerfile` builds the production image, and pushes to `main` deploy automatically once the scan, lint, and test jobs pass. The runtime expects three things from whatever hosts it: a persistent volume mounted at `/rails/storage` for the SQLite databases and Active Storage files, a health check against `/up`, and `SOLID_QUEUE_IN_PUMA=true` if no separate worker process is running. A Kamal config is checked in as an alternative path.

Verify the image locally before shipping a risky change:

```sh
make production-check   # build the image, boot it, poll /up, dump logs, clean up
make production-run     # leave a container running on :8080
```

`docs/launch_checklist.md` is the pre-draft-day checklist: S3 migration, secrets, email deliverability, backups, and the multi-device rehearsal.

## Exporting to ESPN

ESPN documents offline-draft roster entry for League Manager leagues but publishes no supported bulk results-import API. So the CSV export is a roster worksheet — team, owner, roster slot, player identity, ESPN ID, round, overall pick — and the JSON export exposes the same data behind a stable boundary for a future API or browser-assisted importer.

In ESPN, configure the league as an offline draft, then use **League Manager Tools → Input Offline Draft Results** and enter each exported team roster before making rosters available.

## Contributing

`AGENTS.md` carries the one hard rule: create Rails-owned artifacts (migrations, models, controllers, jobs, mailers, channels, tests) with `bin/rails generate` before editing them, rather than hand-writing them.

Traded picks, keepers, and roster-position validation at pick time are deliberately left for later.
