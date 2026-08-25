# frozen_string_literal: true

require "test_helper"

class Components::NavigationTest < ActiveSupport::TestCase
  test "renders signed-in commissioner navigation" do
    html = ApplicationController.renderer.render(Components::Navigation.new(current_user: users(:commissioner)))

    assert_includes html, "Draft home"
    assert_includes html, "League admin"
    assert_includes html, "Commissioner"
    assert_not_includes html, users(:commissioner).email
    assert_includes html, "Sign out"
  end

  test "identifies a member by their newest team instead of email" do
    user = users(:member)
    newer_league = League.create!(name: "Next Season", season: 2027, roster_size: 2)
    newer_team = newer_league.teams.create!(name: "Future Foxes", owner_name: "Riley", abbreviation: "FOX")
    newer_team.team_memberships.create!(user:)

    html = ApplicationController.renderer.render(Components::Navigation.new(current_user: user))

    assert_includes html, newer_team.name
    assert_not_includes html, user.email
  end

  test "prefers the team from the current draft context" do
    user = users(:member)
    html = ApplicationController.renderer.render(Components::Navigation.new(current_user: user, team: teams(:one)))

    assert_includes html, teams(:one).name
    assert_not_includes html, user.email
  end

  test "renders the sign-in link for guests" do
    html = ApplicationController.renderer.render(Components::Navigation.new(current_user: nil))

    assert_includes html, "Sign in"
    assert_not_includes html, "League admin"
  end
end
