# frozen_string_literal: true

require "test_helper"

class Components::Drafts::TeamRosterTest < ActiveSupport::TestCase
  test "renders an empty manager roster" do
    html = render_roster

    assert_includes html, "My team"
    assert_includes html, teams(:one).name
    assert_includes html, "No picks yet"
    refute_includes html, "Choose roster team"
  end

  test "groups drafted players with pick details and elapsed time" do
    pick = drafts(:one).picks.create!(team: teams(:one), player: players(:one), round: 1, overall_number: 1, elapsed_seconds: 61)
    html = render_roster(picks: [ pick ], elapsed: { pick.id => 61 })

    assert_includes html, players(:one).name
    assert_includes html, "R1 · Pick 1"
    assert_includes html, "1:01"
    assert_match(/<h3[^>]*>QB<\/h3>/, html)
  end

  test "renders a commissioner team selector" do
    other_team = teams(:one).league.teams.create!(name: "Green Foxes", owner_name: "Morgan", abbreviation: "GRN")
    drafts(:one).draft_entries.create!(team: other_team, position: 2)
    html = render_roster(team: other_team, commissioner: true)

    assert_includes html, "Roster review"
    assert_includes html, "Choose roster team"
    assert_includes html, "GRN"
    assert_match(/aria-current="page"[^>]*>GRN</, html)
  end

  private

  def render_roster(team: teams(:one), picks: [], elapsed: {}, commissioner: false)
    ApplicationController.renderer.render(
      Components::Drafts::TeamRoster.new(
        draft: drafts(:one), team:, picks:, pick_elapsed_seconds: elapsed, commissioner:
      )
    )
  end
end
