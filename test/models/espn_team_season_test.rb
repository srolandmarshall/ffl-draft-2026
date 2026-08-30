require "test_helper"

class EspnTeamSeasonTest < ActiveSupport::TestCase
  test "database prevents one franchise from claiming two teams in a season" do
    league = League.create!(name: "Identity Guard League", season: 2026)
    season = league.espn_seasons.create!(season: 2026, name: "2026", team_count: 2, settings: {}, teams: [], synced_at: Time.current)
    franchise = league.espn_franchises.create!(key: "ONE", name: "Example One", aliases: [ "ONE" ])
    season.team_seasons.create!(
      espn_franchise: franchise, espn_team_id: 1, team_name: "Example One",
      team_abbreviation: "ONE", owner_ids: [], owner_names: []
    )

    assert_raises ActiveRecord::RecordNotUnique do
      EspnTeamSeason.insert_all!([ {
        espn_season_id: season.id,
        espn_franchise_id: franchise.id,
        espn_team_id: 2,
        team_name: "Example Two",
        team_abbreviation: "TWO",
        owner_ids: [],
        owner_names: [],
        wins: 0,
        losses: 0,
        ties: 0,
        created_at: Time.current,
        updated_at: Time.current
      } ])
    end
  end


  test "exposes regular-season record and separate playoff result" do
    team_season = espn_team_seasons(:one)

    assert_equal "1-1-1", team_season.record
    assert_equal 0.5, team_season.win_pct
    assert team_season.made_playoffs?
    assert team_season.champion?
    assert_equal "Champion", team_season.playoff_result_label

    team_season.update!(playoff_finish: nil)
    assert_equal "Playoff result pending", team_season.playoff_result_label

    team_season.update!(playoff_finish: nil, playoff_seed: nil)
    assert_not team_season.made_playoffs?
    assert_equal "Missed the playoffs", team_season.playoff_result_label
  end
end
