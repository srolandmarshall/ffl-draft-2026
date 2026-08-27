# Draft-room image loading

## Reported behavior

On a first visit, the player list and draft board can feel unresponsive while batches of
player portraits and NFL team logos are fetched.

## What was actually happening

Portrait size was chosen per call site, so the same player resolved to a different URL in
each placement: 80px in the desktop player row, 64px in the mobile row and in recent picks,
40px in a mobile board cell, 80px again in the team roster. Because the draft room renders
both the mobile and desktop markup for every player and pick, a single drafted player could
cost three separate downloads and three separate Active Storage variants.

Two other costs compounded it:

- Variants were generated on demand. Source headshots are ~3MB PNGs at 3400x2450, so the
  first request for each portrait pulled the original from storage and resized it inside the
  web request.
- NFL logos were fetched from ESPN at 500px (30-130KB each) and rendered at 36px or smaller.

## What changed

- `Player::PORTRAIT_SIZE` fixes one 80px portrait for every placement, so the duplicated
  responsive markup resolves to one URL and the browser downloads it once. Largest render is
  40 CSS pixels, so 80px still covers 2x.
- The portrait is a named `:portrait` variant with `preprocessed: true`, generated in the
  background on attach instead of during the first request, and encoded as WebP (2KB versus
  9KB for the same PNG crop, with the alpha channel these headshots need).
- `nfl_team_logo_url` requests logos through ESPN's combiner endpoint at 80px, which brings
  each one from ~32KB to ~3KB.
- `player_portrait_attributes` / `nfl_team_logo_attributes` centralize the image markup, so
  size and loading hints can no longer drift apart between call sites. All of these images are
  decorative and below the fold, so they carry `loading="lazy"`, `decoding="async"` and
  `fetchpriority="low"`.
- The layout preconnects to `a.espncdn.com`.
- `rake headshots:backfill_portraits` generates the variant for headshots that were attached
  before preprocessing existed.

## Deliberately not done

- **A loading placeholder.** The stored headshots are RGBA with transparent backgrounds, so
  any silhouette or shimmer painted behind the image would stay visible around the player
  after it loaded rather than being covered. The wrapper already provides a correctly sized,
  filled circle behind every portrait, so there is no layout shift and no empty gap while one
  loads.
- **Collapsing the duplicate mobile/desktop markup.** Now that both variants share a URL, the
  duplication costs DOM nodes rather than downloads. Worth revisiting as a layout change if
  DOM size shows up in profiling, but it is no longer a network problem.

## Acceptance checks

- Initial document and controls become interactive before non-visible portraits load.
- Switching between mobile and desktop layouts does not duplicate portrait downloads. Covered
  by `test/integration/draft_flow_test.rb` ("duplicated mobile and desktop markup shares one
  portrait download per player").
- Player filters, board updates, and Turbo frame refreshes retain stable image URLs and do not
  regress image display.
