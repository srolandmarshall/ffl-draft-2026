require "test_helper"

class EspnFranchiseTest < ActiveSupport::TestCase
  test "ESPN numeric slots do not merge franchises with different abbreviations" do
    league = League.create!(name: "Slot Reuse League", season: 2026)
    oconnor = league.teams.create!(name: "Team O'Connor", owner_name: "Eamon", abbreviation: "OCON")
    resolver = DataSources::Espn::FranchiseResolver.new(league:)

    current = resolver.resolve(abbreviation: "OCON", name: "Team O'Connor", espn_team_id: 2, season: 2026)
    munz = resolver.resolve(abbreviation: "MUNZ", name: "Diamond Dogs", espn_team_id: 2, season: 2022)

    assert_equal oconnor, current.team
    assert_nil munz.team
    assert_not_equal current, munz
    assert_equal "Diamond Dogs", munz.name
  end

  test "merging franchise aliases preserves the target identity" do
    league = leagues(:one)
    target = league.espn_franchises.create!(key: "MUNZ", name: "Diamond Dogs", aliases: [ "MUNZ" ], owner_ids: [ "owner-1" ])
    source = league.espn_franchises.create!(key: "MU", name: "Blake Panther", aliases: [ "M-U" ], owner_ids: [ "owner-2" ])
    pick = espn_draft_picks(:one)
    pick.update!(espn_franchise: source)

    DataSources::Espn::FranchiseMerge.new(target:, sources: [ source ], name: "Diamond Dogs").call

    assert_equal target, pick.reload.espn_franchise
    assert_equal [ "MUNZ", "M-U" ], target.reload.aliases
    assert_equal [ "owner-1", "owner-2" ], target.owner_ids
    assert_equal "Diamond Dogs", target.name
  end

  test "team import gives a reused ESPN slot to the returning franchise" do
    league = League.create!(name: "Returning Franchise League", season: 2026)
    oconnor = league.teams.create!(name: "Team O'Connor", owner_name: "Eamon", abbreviation: "OCON", espn_team_id: 2)
    league.espn_franchises.create!(team: oconnor, key: "OCON", name: "Team O'Connor", aliases: [ "OCON" ])
    munz = league.espn_franchises.create!(key: "MUNZ", name: "Diamond Dogs", aliases: [ "MUNZ", "M-U" ], owner_ids: [ "owner-munz" ])
    identity = DataSources::Espn::LeagueSnapshot::TeamIdentity.new(
      id: 2,
      name: "Diamond Dogs",
      abbreviation: "MUNZ",
      owner_ids: [ "owner-munz" ],
      owner_names: [ "Munz" ],
      final_rank: 1
    )

    result = DataSources::Espn::TeamImport.new(league:, teams: [ identity ]).call

    returning_team = league.teams.find_by!(abbreviation: "MUNZ")
    assert_equal 1, result.created
    assert_nil oconnor.reload.espn_team_id
    assert_equal 2, returning_team.espn_team_id
    assert_equal returning_team, munz.reload.team
  end

  test "stable owner ID connects a renamed historical team to its current franchise" do
    league = League.create!(name: "Renamed Team League", season: 2026)
    team = league.teams.create!(name: "Team Strauss", owner_name: "Andrew", abbreviation: "STRA")
    resolver = DataSources::Espn::FranchiseResolver.new(league:)

    current = resolver.resolve(
      abbreviation: "STRA", name: "Team Strauss", espn_team_id: 1, season: 2026,
      owner_ids: [ "owner-strauss" ]
    )
    current.update!(team:)
    historical = resolver.resolve(
      abbreviation: "STR", name: "Wire 2 Wire 1st", espn_team_id: 1, season: 2016,
      owner_ids: [ "owner-strauss" ]
    )

    assert_equal current, historical
    assert_equal [ "STRA", "STR" ], current.reload.aliases
    assert_equal [ "owner-strauss" ], current.owner_ids
  end
end
