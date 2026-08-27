# Draft-room image loading

## Reported behavior

On a first visit, the player list and draft board can feel unresponsive while batches of
player portraits and NFL team logos are fetched. Page and Turbo requests appear to get stuck
behind image requests.

## Root cause

CloudFront fronts the Fly app (`draft.sammarshall.us`), with a `/rails/active_storage/*`
behavior on Managed-CachingOptimized. That part is right. But it fronts the **app**, not the
bucket, so a cache miss still lands on Puma.

`config.active_storage.resolve_model_to_route = :rails_storage_proxy` makes every portrait
URL a route into the app. `ActiveStorage::Representations::ProxyController` downloads the file
from S3 into the machine and streams it back through Puma, per image, per request.

Puma runs 3 threads by default (`config/puma.rb`), on one Fly machine with one shared CPU,
with Solid Queue sharing the same process (`SOLID_QUEUE_IN_PUMA`). So a cold draft room's
~36 portrait misses queued three at a time through the same threads serving the page and its
Turbo frames. The images were not slow; they were occupying the whole web tier.

Edge caching does not rescue the first visit, which is the reported symptom, and CloudFront
caches per edge location, so a small audience keeps missing. Changing the variant size or
format also changes every URL and invalidates the whole cache at once.

A second, smaller problem sat on top of it: portrait size was chosen per call site, so one
player resolved to a different URL in each placement — 80px in a desktop player row, 64px in a
mobile row and in recent picks, 40px in a mobile board cell, 80px again in the team roster.
Because the draft room renders both mobile and desktop markup for every player and pick, a
single drafted player could cost three of those proxy requests and three Active Storage
variants.

## What changed

**Serving (the actual fix).** Portraits now link at a CDN distribution over the bucket, so
even a cache miss goes CloudFront -> S3 and never touches Fly. The bucket stays private —
CloudFront reads it through an origin access control.
Note that `public: true` is deliberately *not* set on the service: `S3Service#initialize` adds
`acl: "public-read"` to every upload when it is. This bucket is `BucketOwnerEnforced` with
full Block Public Access, so that would fail every upload and break headshot syncing. The URL
is built from the variant's storage key instead.

- With `CDN_HOST` set, **no image read reaches Rails**. A portrait whose variant has not been
  generated yet has no key to link to, and `player_portrait?` returns false so it renders the
  position letter instead of falling back to the proxy. Preprocessing keeps that gap to the
  length of one transform job; the backfill task closes it for older headshots.
- `CDN_HOST` unset keeps the proxy, which is development and test. Deploying is safe before
  the distribution exists.
- `Player::PORTRAIT_INCLUDES` preloads variant records. Without it, reading the key to build a
  CDN URL costs a query per portrait (16 on the draft room, versus 2 preloaded).
- Uploads set `cache-control: public, max-age=31536000, immutable`. Variants are immutable
  once generated. This applies to newly written objects only.

**Sizing.** `Player::PORTRAIT_SIZE` fixes one 80px portrait for every placement, so the
duplicated responsive markup resolves to a single URL. Largest render is 40 CSS pixels, so
80px still covers 2x.

**Generation.** `:portrait` is a named variant with `preprocessed: true`, built in the
background on attach rather than inside the first request — source headshots are ~3MB PNGs at
3400x2450 — and encoded as WebP (2KB against 9KB for the same PNG crop, keeping the alpha
channel these headshots need). `rake headshots:backfill_portraits` covers headshots attached
before preprocessing existed.

**Logos.** Requested through ESPN's combiner endpoint at 80px, ~32KB down to ~3KB each, with a
`preconnect` to the CDN.

**Threads.** `RAILS_MAX_THREADS = '5'` in `fly.toml`, up from the default 3. This is a
mitigation for whatever still falls back to the proxy, not the fix.

## Deploying the CDN

1. Create a CloudFront distribution with the S3 bucket as origin, using an **origin access
   control**; leave Block Public Access on. Add the generated bucket policy. This is separate
   from the existing app distribution: tracked variants get random keys at the bucket root,
   indistinguishable from the multi-megabyte originals, so there is no path pattern that could
   route them from the app distribution instead.
2. Set `CDN_HOST` on the app (`fly secrets set CDN_HOST=…`) — bare host or full origin, both
   are accepted.
3. Run `bin/rails headshots:backfill_portraits` so existing headshots have a variant to link
   to. Until a given portrait is backfilled it serves through the proxy, which is correct but
   slow.

## Deliberately not done

- **A loading placeholder.** The stored headshots are RGBA with transparent backgrounds, so
  any silhouette or shimmer painted behind the image would stay visible around the player
  after it loaded rather than being covered. The wrapper already provides a correctly sized,
  filled circle behind every portrait, so there is no layout shift and no empty gap.
- **Collapsing the duplicate mobile/desktop markup.** Now that both variants share a URL, the
  duplication costs DOM nodes rather than downloads.

## Acceptance checks

- Initial document and controls become interactive before non-visible portraits load.
- Switching between mobile and desktop layouts does not duplicate portrait downloads. Covered
  by `draft_flow_test.rb`, "duplicated mobile and desktop markup shares one portrait download
  per player".
- Portraits do not cost a query per player. Covered by `draft_flow_test.rb`, "linking portraits
  at the CDN does not cost a query per player".
- Player filters, board updates, and Turbo frame refreshes retain stable image URLs and do not
  regress image display.
