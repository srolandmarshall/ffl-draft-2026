# Draft board performance

## Finding and baseline

Profiling used the local 2026 draft with 12 teams, 15 rounds, and 41 completed picks. Before this change, every pick rendered and broadcast the complete 180-cell board. Ten warmed renders averaged **142.61 ms** and produced **98,617 bytes** of HTML per live update. Associations were already preloaded, so the render averaged 0.1 SQL queries; repeated component and HTML generation, rather than an N+1 query, was the measured live-update bottleneck.

Initial navigation to the board also loaded the player catalog even though that view does not render it. On the same draft, loading the 216 unused available players, league scores, and headshot attachments took **159.91 ms** and four SQL queries. The board route now skips that work.

## Result

The stable board grid renders once. A pick broadcasts replacements only for the completed cell and the newly active cell. With the same draft, the repeatable profiler measured those two cells at **2.59 ms** and **1,394 bytes**, compared with **111,427 bytes** for the equivalent current full board—a **98.7% payload reduction**. Recent-pick broadcasts load only a five-pick window instead of every completed pick.

The manager team is resolved once in the controller. Its header and persistent column wrappers receive an accessible lime highlight, so viewer-neutral live cell replacements do not perform authorization checks or erase the highlight. A commissioner with no team membership sees no highlighted column; a commissioner who is also assigned to a team sees that assigned team highlighted.

## Repeatable profiling

Use a representative local draft, preferably 10–12 teams with most of its rounds populated:

```sh
bin/rails runner script/profile_draft_board.rb [draft_id]
```

The script reports dimensions, initial board render time and payload, plus the two-cell live-update time, payload, and reduction. Run it after a warm-up pass and compare several runs because development-mode rendering varies.

For client-side timing, record a browser Performance trace while navigating to `?view=board`, then make a pick in a second session. Compare the initial Turbo navigation and the subsequent Turbo Stream event. The live event should replace two `draft-…-board-cell-…` elements without a full board layout/repaint.
