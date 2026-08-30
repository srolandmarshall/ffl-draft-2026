require "test_helper"

class Admin::EspnFranchiseBackfillsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @league = leagues(:one)
    @league.update!(espn_league_id: "123456")
    teams(:one).update!(espn_team_id: 1)
    espn_seasons(:one).update!(teams: [ {
      "id" => 1,
      "name" => "Example Team",
      "abbreviation" => "RED",
      "owner_ids" => [ "owner-1" ],
      "owner_names" => [ "Riley" ],
      "final_rank" => 4
    } ])
  end

  test "commissioner can rebuild season-scoped franchise identities" do
    matchup_id = espn_matchups(:one).id
    sign_in_as users(:commissioner)

    post admin_league_espn_franchise_backfill_path(@league)

    assert_redirected_to admin_league_path(@league)
    assert_equal 1, @league.espn_team_seasons.count
    assert_equal 1, @league.espn_franchises.count
    assert_equal @league.espn_team_seasons.sole.espn_franchise, espn_draft_picks(:one).reload.espn_franchise
    assert EspnMatchup.exists?(matchup_id)
    assert_match(/Repaired 1 ESPN team season/, flash[:notice])
  end

  test "league admin page offers the repair beside ESPN sync" do
    sign_in_as users(:commissioner)

    get admin_league_path(@league)

    assert_response :success
    assert_select "form[action='#{admin_league_espn_franchise_backfill_path(@league)}'] button", text: "Repair ESPN history"
  end

  test "ordinary members cannot run the repair" do
    sign_in_as users(:member)

    assert_no_changes -> { @league.espn_franchises.count } do
      post admin_league_espn_franchise_backfill_path(@league)
    end

    assert_redirected_to root_path
  end
end
