# frozen_string_literal: true

require "test_helper"

class Components::Drafts::RecentPicksTest < ActiveSupport::TestCase
  test "renders pick ownership and round details" do
    draft = drafts(:one)
    pick = draft.picks.create!(team: teams(:one), player: players(:one), round: 1, overall_number: 1, elapsed_seconds: 61)
    html = ApplicationController.renderer.render(
      Components::Drafts::RecentPicks.new(draft:, picks: [ pick ], pick_elapsed_seconds: { pick.id => 61 })
    )

    assert_includes html, "Recent picks · 1/#{draft.total_picks}"
    assert_includes html, "#{pick.team.abbreviation} · R#{pick.round} · Pick #{pick.overall_number}"
    assert_includes html, "1:01"
  end
end
