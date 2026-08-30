require "test_helper"

class Admin::LeaguesControllerTest < ActionDispatch::IntegrationTest
  test "commissioner sees linked and historical-only ESPN franchises" do
    league = leagues(:one)
    linked = espn_franchises(:one)
    linked.update!(name: "Linked Archive Team")
    historical = league.espn_franchises.create!(key: "HISTORY", name: "Historical Only Team", aliases: [ "HIS" ])
    season = espn_seasons(:one)
    season.update!(season: 2025)
    season.team_seasons.create!(
      espn_franchise: historical, espn_team_id: 2,
      team_name: historical.name, team_abbreviation: "HIS",
      owner_ids: [], owner_names: [], regular_season_rank: 2
    )
    sign_in_as users(:commissioner)

    get admin_league_path(league)

    assert_response :success
    assert_select "details summary", text: /ESPN franchise archive/
    assert_select "details", text: /Linked Archive Team/
    assert_select "details", text: /Linked to Red Hawks/
    assert_select "details", text: /Historical Only Team/
    assert_select "details", text: /Historical only/
    assert_select "details", text: /2025/
  end
end
