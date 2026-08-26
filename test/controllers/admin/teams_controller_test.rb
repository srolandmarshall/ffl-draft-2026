require "test_helper"

class Admin::TeamsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @league = leagues(:one)
    @team = teams(:one)
  end

  test "commissioner can archive a team" do
    sign_in_as users(:commissioner)

    patch archive_admin_league_team_path(@league, @team)

    assert_redirected_to admin_league_path(@league)
    assert @team.reload.archived?
  end

  test "commissioner can restore an archived team" do
    @team.update!(archived: true)
    sign_in_as users(:commissioner)

    patch unarchive_admin_league_team_path(@league, @team)

    assert_redirected_to admin_league_path(@league)
    assert_not @team.reload.archived?
  end

  test "regular members cannot archive a team" do
    sign_in_as users(:member)

    patch archive_admin_league_team_path(@league, @team)

    assert_redirected_to root_path
    assert_not @team.reload.archived?
  end

  test "archived teams drop out of the draft order form but stay listed as archived" do
    @team.update!(archived: true)
    sign_in_as users(:commissioner)

    get admin_league_path(@league)

    assert_select "input[name='team_ids[]'][value='#{@team.id}']", count: 0
    assert_select "h3", text: "Archived teams"
    assert_select "form[action='#{unarchive_admin_league_team_path(@league, @team)}']"
  end
end
