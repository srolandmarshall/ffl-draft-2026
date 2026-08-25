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

  test "shows twelve picks on desktop while limiting mobile to four" do
    draft = drafts(:one)
    pick = draft.picks.create!(team: teams(:one), player: players(:one), round: 1, overall_number: 1, elapsed_seconds: 61)
    html = ApplicationController.renderer.render(
      Components::Drafts::RecentPicks.new(
        draft:,
        picks: Array.new(12, pick),
        pick_elapsed_seconds: { pick.id => 61 }
      )
    )
    document = Nokogiri::HTML5.fragment(html)

    assert_equal 12, document.css("[data-recent-pick]").size
    assert_equal 8, document.css("[data-recent-pick].hidden.lg\\:flex").size
    assert_equal 4, document.css("[data-recent-pick]:not(.hidden)").size
  end
end
