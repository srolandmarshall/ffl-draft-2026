# ESPN league snapshot captures

These fixtures are reduced, redacted captures from issue #131's payload-shape
investigation. `league_snapshot_2016.json` preserves ESPN's pre-2018
array-wrapped `leagueHistory` response; `league_snapshot_2025.json` preserves
the current object response.

Real league/member identifiers, names, abbreviations, logos, owners, draft
picks, and roster entries have been removed or replaced with placeholders.
Team IDs, ranks, records, schedule scores, and per-season settings remain so
the standings and matchup parsers can be tested against representative data.

## Confirmed response shape

- Both endpoint generations return `teams[].record.overall` with `wins`,
  `losses`, `ties`, `pointsFor`, and `pointsAgainst`.
- Both return the complete `schedule[]` history.
- `mMatchup` alone does not populate `playoffTierType`. Adding
  `mMatchupScore` to the same snapshot request populates `NONE`,
  `WINNERS_BRACKET`, `LOSERS_CONSOLATION_LADDER`, and
  `WINNERS_CONSOLATION_LADDER` without adding another HTTP request.
- `playoffSeed` is present for all 12 teams, including non-qualifiers. It is a
  complete 1–12 regular-season rank in both captures, not a nullable bracket
  seed.
- In both seasons, ordering by regular-season wins and then points for exactly
  matches `playoffSeed`, and the totals recomputed from the first
  `matchupPeriodCount` schedule periods match `record.overall`.
- `rankCalculatedFinal` demonstrably includes consolation results. In each
  capture, the team with regular-season rank 10 won three consolation games
  and received `rankCalculatedFinal: 7`.

These findings mean the importer can use ESPN's `playoffSeed` as the canonical
regular-season rank while cross-checking it against regular-season matchup
rows. It must retain `mMatchupScore` if it needs ESPN's bracket tier rather
than infer the tier from seeds and matchup periods.
