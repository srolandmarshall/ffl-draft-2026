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
  end
end
