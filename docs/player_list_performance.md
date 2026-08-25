# Draft player-list performance

The draft room now returns at most 36 undrafted players, approximately three rounds in a 12-team league. Search, position, and NFL-team filters run against the complete undrafted pool on the server and return a fresh 36-player window through a Turbo Frame.

## Baseline and result

The representative local 2026 draft had 216 available players. After warming the renderer, its full desktop and mobile player list averaged **120.97 ms** and produced **2,111,097 bytes** of HTML. Rendering the first 36 players averaged **20.77 ms** and produced **392,051 bytes**.

That is an **82.8% render-time reduction** and an **81.4% HTML payload reduction** for the player-list portion of the initial draft room. Filter responses have the same 36-player ceiling. Drafted-player broadcasts retain their existing `data-draft-player-id` targets and remove matching desktop and mobile entries from the current window.

## Repeatable profiling

Run the profiler against a populated draft:

```sh
bin/rails runner script/profile_player_list.rb [draft_id]
```

The script preloads the same associations used by the controller, warms both paths, then compares ten renders of the complete available pool with ten renders of the 36-player window. Results still vary somewhat in development mode.
