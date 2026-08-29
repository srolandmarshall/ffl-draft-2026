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
end
