# AGENTS.md

Working agreements for this repo. `README.md` covers what the app is and how to run it; this file covers how to change it without breaking the parts that are load-bearing on draft night.

## Before you call it done

```sh
bin/rails test
bin/rubocop
bin/brakeman --no-pager
```

CI runs those plus `bin/bundler-audit` and `bin/importmap audit`, and `main` deploys on green. Don't push a red branch expecting to fix it after.

## Hard rules

**Use Rails generators for Rails-owned artifacts.** Migrations, models, controllers, jobs, mailers, channels, and their generated tests must come from `bin/rails generate ...` before you edit them. Customize the generated file with normal patches afterward. Never hand-write one as a substitute. If the generator can't run, or there's no obvious generator for what you need, stop and ask rather than improvising.

**Never commit secrets or real member data.** `.env`, `config/master.key`, `team_assignments.csv`, and `db/seeds/*.json` are git-ignored and must stay that way. The private seed file holds real league members' names and email addresses; `db/seeds.rb` falls back to generated placeholder teams when it's absent. Never commit that file, un-ignore its path, or copy real names or addresses into code, tests, fixtures, or commit messages. Placeholder data uses `example.com`.

**Don't commit unless asked.** Leave changes in the working tree by default.

## Where code goes

| Layer | Responsibility |
|---|---|
| `app/controllers` | HTTP only: find the record, authorize, delegate, respond. No business rules. |
| `app/models` | Associations, validations, invariants, and scopes like snake-order lookups. |
| `app/services` | Anything multi-step, transactional, network-bound, or file-producing. |
| `app/view_models` | Assemble everything a screen needs in one object, so components take one argument instead of ten. |
| `app/components` | Phlex components. All markup lives here. |
| `app/views` | One-line ERB shells that render a component, plus layouts and mailer templates. |

If you're adding an `if` to a controller that isn't about authorization or response format, it probably belongs in a model or service.

## Picks are concurrency-sensitive

`Drafts::MakePick` is the only place a `Pick` may be created. It takes a row lock on the draft, resets its associations, revalidates turn order and player availability, and relies on unique indexes on `(draft_id, overall_number)` and `(draft_id, player_id)` to catch the race it can't lock away. `Drafts::UndoPick` is the only place one may be removed.

Do not add a second path that creates picks, do not validate turn order in a controller or component, and do not drop those indexes. Two managers tapping the same player at the same instant is the normal case on draft night, not an edge case.

`Drafts::AutoDraft` goes through `MakePick` like everything else. Keep it that way.

## Live updates

The broadcast services (`Drafts::BroadcastPick`, `BroadcastUndoPick`, `BroadcastAnnouncement`) own every Turbo Stream payload the room receives. They send targeted replacements for the ticker, the affected board cells, and the turn indicator — not a whole-page refresh.

The acting user's own request deliberately returns `head :no_content`. The broadcast already updated their screen; rendering a response too makes the room render twice, flicker, and sometimes race into "Content missing." There are comments in `PicksController` saying so. If a change makes you want to return markup there, you're about to reintroduce a fixed bug.

## Views are Phlex

Components subclass `Components::Base`, define `view_template`, and keep everything else private. Tailwind classes are written inline. A component takes plain data — usually a view model or a record — never a controller instance variable.

Test a component by rendering it and asserting on the HTML:

```ruby
html = ApplicationController.renderer.render(Components::Drafts::PlayerIdentity.new(player:, variant: :desktop))
assert_includes html, player.name
```

Component tests assert real accessibility affordances (`sr-only` text, `aria-label`, `title`) alongside layout classes. Keep those assertions when you restyle; the room is used on phones and screen readers.

Don't verify UI work by describing what a screenshot would show. If a change needs a human eye, say so and ask.

## External data sources

Every outside API lives in `app/services/data_sources/<vendor>/client.rb`. Models, controllers, and components never make HTTP calls.

Clients take an injectable `fetcher:` so tests stub the transport instead of hitting the network. Follow that pattern for anything new, and never let a test make a real request.

ESPN's fantasy endpoints are undocumented and unsupported. They're isolated behind an adapter on purpose, and the identifier mappings follow the MIT-licensed `cwendt94/espn-api` project. Assume the shape can change without warning, and keep parsing defensive and confined to the client.

Rankings are chosen by `Rankings::StrategyFactory` from `PLAYER_RANKINGS_SOURCE`. New providers implement the same strategy interface rather than adding a branch anywhere else. LeagueLogs requires visible attribution — `Components::RankingAttribution` renders it, so don't remove it.

## Tests

Minitest with fixtures, run in parallel. The test tree mirrors `app/`. Integration tests sign in with the `sign_in_as(user)` helper in `test/test_helper.rb`, which mints a known login code rather than sending mail.

Because tests run in parallel, don't write ones that depend on global mutable state or on another test's ordering.

## Gotchas

- **The player pool starts empty.** A freshly seeded database has a league, teams, and drafts but no players until you sync ESPN, refresh rankings, and refresh stats from the admin area.
- **Development sends real email.** `delivery_method = :resend` is set in development, with `raise_delivery_errors = true`. Without `RESEND_API_KEY`, sign-in raises. Mint a code from the console instead of chasing the error.
- **Round count is derived.** While a draft is in `setup`, `rounds` is recomputed from the roster slot totals on every validation. Setting it directly won't stick.
- **`storage/` holds thousands of cached headshots.** It's git-ignored. Don't glob it into searches or tooling.
- **New environment variables go in `.env.example`** as well as the table in `README.md`.
