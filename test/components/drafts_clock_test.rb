# frozen_string_literal: true

require "test_helper"

class Components::Drafts::ClockTest < ActiveSupport::TestCase
  test "renders current team and pick distance" do
    draft = drafts(:one)
    team = teams(:one)
    html = ApplicationController.renderer.render(
      Components::Drafts::Clock.new(
        draft:, selected_team: team, picks_until_selected_team: 2, picks: [], current_pick_elapsed_seconds: 0,
        current_user: users(:member)
      )
    )

    assert_includes html, "On the clock"
    assert_includes html, draft.current_team.name
    assert_includes html, "#{team.name}:"
    assert_includes html, "2 picks away"
    assert_includes html, "data-draft-pick-target=\"currentTeam\""
    assert_includes html, "data-draft-pick-target=\"turnPosition\""
    assert_includes html, "draft:timer-reset->pick-timer#reset"
    assert_includes html, "w-full"
    refute_includes html, "fixed"
  end

  test "commissioner can undo the latest pick" do
    draft = drafts(:one)
    pick = draft.picks.create!(team: teams(:one), player: players(:one), round: 1, overall_number: 1)
    html = ApplicationController.renderer.render(
      Components::Drafts::Clock.new(
        draft:, selected_team: nil, picks_until_selected_team: nil, picks: [ pick ], current_pick_elapsed_seconds: 0,
        current_user: users(:commissioner)
      )
    )

    assert_includes html, "Undo last"
    assert_includes html, draft_pick_path(draft.public_id, pick)
    assert_includes html, broadcast_message_admin_league_draft_path(draft.league, draft)
    assert_includes html, "Broadcast a message…"
    assert_includes html, "data-controller=\"broadcast-cooldown\""
    assert_includes html, "data-broadcast-cooldown-seconds-value=\"5\""
  end

  test "members do not see the broadcast message controls" do
    draft = drafts(:one)
    html = ApplicationController.renderer.render(
      Components::Drafts::Clock.new(
        draft:, selected_team: teams(:one), picks_until_selected_team: 0, picks: [], current_pick_elapsed_seconds: 0,
        current_user: users(:member)
      )
    )

    refute_includes html, "Broadcast a message…"
  end
end
