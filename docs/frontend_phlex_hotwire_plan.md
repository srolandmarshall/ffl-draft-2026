# Front-end migration plan: Phlex + Hotwire

## Goal

Move server-rendered UI from scattered ERB templates into composable Phlex components, then use Turbo Frames, Turbo Streams, and Action Cable so draft-room changes arrive without full-page refreshes.

## Principles

- Keep routing, authorization, and domain behavior in controllers/models/services; components should present state, not own business rules.
- Preserve the current HTML semantics and responsive visual system during the migration.
- Migrate one surface at a time with request/system coverage before deleting its ERB.
- Use Turbo for navigation and targeted replacement; use Stimulus only for local interaction and transient UI state.
- Broadcast draft events from the pick/timer domain layer, not from views.

## Phase 1 — Baseline and component foundation

- Add Phlex and configure a shared component base with the existing Tailwind pipeline.
- Capture the current draft room, board, admin league, and history pages with system screenshots and HTML assertions.
- Establish conventions for components, slots, collections, accessibility labels, and `render` boundaries.
- Add component tests for the base layout, navigation, buttons, badges, team logos, player headshots, and stat rows.

## Phase 2 — Shared chrome and low-risk surfaces

- Convert the application layout, navigation, flash region, shared errors, and authentication pages.
- Convert admin forms and league/team cards next; keep form submission behavior unchanged.
- Add Turbo Frames around admin league sections so edits, ordering, and deletes update only the affected section.
- Verify commissioner authorization and destructive-action confirmations remain server-enforced.

## Phase 3 — Draft room composition

- Break the room into Phlex components: `DraftHeader`, `DraftClock`, `RecentPicks`, `PlayerFilters`, `PlayerRow`, `PlayerStats`, `DraftAction`, and `DraftBoard`.
- Give each independently refreshable area a stable Turbo Frame ID.
- Keep filtering/search local in Stimulus initially; make server-side filtering an optional later optimization.
- Preserve the fixed clock, full-page player scroll, tiled recent picks, logos, headshots, rookie badges, and responsive layouts as explicit component contracts.

## Phase 4 — Live draft updates

- Add a draft-specific Action Cable stream keyed by the draft public ID.
- After a pick, broadcast Turbo Stream updates for the clock, recent picks, draft board, available-player rows, player count, and status message.
- Broadcast timer pause/resume and elapsed-time updates without replacing the entire room.
- Use idempotent partial updates and server authorization so a stale browser cannot make an invalid pick.
- Add multi-client system tests: commissioner, current drafter, and observers viewing the same draft.

## Phase 5 — Board, results, and history

- Convert the draft board, completed results, exports controls, and league history tabs/charts to Phlex.
- Use Turbo Frames for year tabs and team selectors; use Turbo Streams only where data changes in place.
- Keep visualizations as dedicated components with small, testable data presenters.

## Phase 6 — Remove ERB duplication and harden delivery

- Delete migrated ERB partials only after component/request/system coverage is green.
- Run full test, RuboCop, Zeitwerk, Tailwind, accessibility, and production asset checks in CI.
- Verify direct navigation, browser back/forward, reconnects, duplicate Turbo submissions, and mobile layouts.
- Add monitoring for Action Cable disconnects, failed stream renders, stale draft clocks, and failed headshot variants.

## Suggested delivery order

1. Shared layout and primitives
2. Admin league/team surfaces
3. Draft room static composition
4. Draft board and results
5. Turbo Frame navigation
6. Action Cable pick broadcasts
7. Timer broadcasts and reconnect handling
8. History and visualization surfaces
9. ERB removal and production hardening

## Definition of done

- No draft-room full-page refresh is needed after a pick, timer action, filter/navigation action, or board update.
- Every live update is authorized, scoped to the correct draft, and safe to replay.
- Phlex components have focused tests and stable accessible markup.
- The application remains usable when JavaScript or Action Cable is unavailable through normal HTML form/navigation fallbacks.

## Progress

Completed:

- Phlex 2.4 component foundation and Rails autoloading.
- Shared navigation, flash messages, and validation errors migrated to Phlex.
- Draft header, clock, recent picks, results, and draft board migrated to tested Phlex components.
- Draft player filters migrated to a tested Phlex component while retaining Stimulus debounce and multi-select behavior.
- Desktop/mobile player identity markup is shared through a tested Phlex component.
- Picks now broadcast targeted Turbo updates for the clock frame, recent picks, draft board, and drafted player rows; completion transitions through a stable Turbo content frame.
- Pick events also replace the shared flash region, preserving the pick announcement without a full-page navigation.
- Multi-viewer integration coverage verifies pick convergence, stale duplicate rejection, Turbo-frame responses, and timer refresh broadcasts.
- Stable Turbo Frames added around draft-room regions and admin league team/draft sections.
- Existing Stimulus filtering, timer, form submissions, authorization, and HTML fallbacks preserved.

Next:

- Extract the player filters and player rows into independently testable components.
- Add targeted Turbo Stream updates for the user-specific draft room without broadcasting one user’s team state to other viewers.
- Add multi-client system coverage for picks, pause/resume, reconnects, and stale submissions.
