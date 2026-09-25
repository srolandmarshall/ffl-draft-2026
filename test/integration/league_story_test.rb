require "test_helper"

class LeagueStoryTest < ActionDispatch::IntegrationTest
  setup do
    @league = leagues(:one)
    sign_in_as users(:member)
  end

  test "renders the story for a league the member belongs to" do
    get league_story_path(@league)

    assert_response :success
    assert_select "h1", text: @league.name
  end

  test "links to the story from the draft history page" do
    get league_history_path(@league)

    assert_response :success
    assert_select "a[href=?]", league_story_path(@league)
  end

  test "redirects a member who is not in the league" do
    other = League.create!(name: "Someone else's league", season: 2026, roster_size: 15)

    get league_story_path(other)

    assert_redirected_to root_path
  end

  test "requires sign in" do
    delete session_path

    get league_story_path(@league)

    assert_redirected_to new_session_path
  end
end
