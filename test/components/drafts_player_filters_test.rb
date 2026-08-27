# frozen_string_literal: true

require "test_helper"

class Components::Drafts::PlayerFiltersTest < ActiveSupport::TestCase
  test "renders search, position, and team filter targets" do
    players = [ players(:one), players(:two) ]
    html = ApplicationController.renderer.render(
      Components::Drafts::PlayerFilters.new(
        draft: drafts(:one),
        players:,
        available_teams: %w[ATL BUF],
        filters: { query: "Alex", positions: [ "QB" ], teams: [ "ATL" ] }
      )
    )

    assert_includes html, "Search players"
    assert_includes html, "action=\"/drafts/sunday-draft/players\""
    assert_includes html, "data-turbo-frame=\"draft-sunday-draft-players\""
    assert_includes html, "id=\"draft-sunday-draft-players-query\""
    assert_includes html, "data-turbo-permanent"
    assert_includes html, "data-draft-filter-target=\"position\""
    assert_includes html, "name=\"positions[]\" value=\"QB\" checked"
    assert_includes html, "name=\"teams[]\" value=\"ATL\" checked"
    assert_includes html, "change->draft-filter#updateTeamSelection change->draft-filter#scheduleSubmit"
    assert_includes html, "draft-filter#clearTeams"
    assert_includes html, "draft-filter#clearFilters"
    assert_includes html, "input->draft-filter#scheduleSubmit"
    assert_includes html, "name=\"positions[]\" value=\"QB\" checked class=\"peer sr-only\" data-draft-filter-target=\"position\" data-action=\"change->draft-filter#scheduleSubmit\""
    assert_includes html, "data-draft-filter-target=\"teamCount\""
    refute_includes html, "change->draft-filter#submit"
    assert_includes html, "value=\"Alex\""
    assert_includes html, "1 selected"
    assert_match(/<details class="[^"]*w-full[^"]*sm:w-auto/, html)
    assert_match(/class="[^"]*absolute[^"]*inset-x-0[^"]*w-full[^"]*sm:left-auto[^"]*sm:right-0[^"]*sm:w-auto/, html)
    assert_match(/title="ATL"[^>]+size-7[^>]+bg-slate-400\/50/, html)
    assert_match(/title="BUF"[^>]+size-7[^>]+bg-slate-400\/50/, html)
  end
end
